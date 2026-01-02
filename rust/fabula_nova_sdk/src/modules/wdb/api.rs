//! # WDB High-Level API
//!
//! This module provides convenient, high-level functions for common WDB
//! operations. These functions handle file I/O, parsing, and serialization.
//!
//! ## Common Operations
//!
//! - [`parse_wdb`] - Load WDB file into [`WdbData`] structure
//! - [`pack_wdb`] - Save [`WdbData`] to WDB binary file
//! - [`extract_wdb_to_json`] - Export WDB to JSON file
//! - [`wdb_to_json_string`] - Convert WdbData to JSON string
//! - [`wdb_from_json_string`] - Parse JSON string to WdbData
//!
//! ## Workflow Example
//!
//! ```rust,ignore
//! use fabula_nova_sdk::modules::wdb;
//! use fabula_nova_sdk::core::GameCode;
//!
//! // Load WDB file
//! let data = wdb::parse_wdb("item.wdb", GameCode::FF13_3)?;
//!
//! // Modify a record
//! if let Some(record) = data.records.get_mut(0) {
//!     record.insert("uPrice".to_string(), wdb::WdbValue::UInt(999));
//! }
//!
//! // Save changes
//! wdb::pack_wdb(&data, "item_modified.wdb", GameCode::FF13_3)?;
//! ```
//!
//! ## Game Code Importance
//!
//! The `game_code` parameter is crucial because each game uses different:
//! - Field name storage formats
//! - Type list encodings
//! - String array structures

use anyhow::Result;
use std::collections::HashMap;
use std::fs::File;
use std::io::{BufReader, BufWriter, SeekFrom};
use std::path::Path;

use super::reader::{derive_string, WdbReader, WdbVariables};
use super::structs::{GameCode, WdbData, WdbValue};

/// Parses a WDB file and returns structured data.
///
/// This is the primary function for loading WDB files. It handles all the
/// complexity of the WDB format including section parsing, field type
/// detection, and record extraction.
///
/// # Arguments
/// * `wdb_path` - Path to the WDB file
/// * `game_code` - Which FF13 game (affects parsing logic)
///
/// # Returns
/// A [`WdbData`] structure containing:
/// - `header`: Metadata about the file (version, field names, etc.)
/// - `records`: Vector of records, each a HashMap of field→value
///
/// # Errors
/// Returns an error if:
/// - File cannot be opened
/// - File format is invalid
/// - Parsing fails
pub fn parse_wdb<P: AsRef<Path>>(wdb_path: P, game_code: GameCode) -> Result<WdbData> {
    let wdb_name = wdb_path.as_ref().file_stem().unwrap_or_default().to_string_lossy().into_owned();
    let file = BufReader::new(File::open(&wdb_path)?);
    let mut reader = WdbReader::new(file);
    
    // 1. Read Headers
    let (file_header, sections) = reader.read_headers()?;
    let record_start_pos = reader.stream_position()?;
    
    // 2. Collect Section Data
    let mut strtypelist_data = Vec::new();
    let mut typelist_data = Vec::new();
    let mut structitem_data = Vec::new();
    let mut structitemnum_data = Vec::new();
    let mut version_data = Vec::new();
    let mut strings_data = Vec::new();
    let mut str_array_data = Vec::new();
    let mut str_array_list_data = Vec::new();
    let mut sheet_name_data = Vec::new();
    let mut offsets_per_value = 0u8;
    let mut bits_per_offset = 0u8;
    let mut has_str_array = false;
    
    let mut record_count = file_header.record_count;
    let mut header_map = HashMap::new();
    
    // Find sections
    for section in &sections {
        if section.name.starts_with('!') {
            record_count -= 1;
        }
        
        match section.name.as_str() {
            "!!string" => {
                strings_data = reader.read_section_data(section)?;
            },
            "!!sheetname" => {
                sheet_name_data = reader.read_section_data(section)?;
            },
            "!!strArray" => {
                str_array_data = reader.read_section_data(section)?;
                has_str_array = true;
            },
            "!!strArrayInfo" => {
                let data = reader.read_section_data(section)?;
                if data.len() >= 4 {
                    offsets_per_value = data[2];
                    bits_per_offset = data[3];
                }
            },
            "!!strArrayList" => {
                str_array_list_data = reader.read_section_data(section)?;
            },
            "!!strtypelist" | "!!strtypelistb" => {
                strtypelist_data = reader.read_section_data(section)?;
                header_map.insert(section.name.clone(), WdbValue::Unknown); // Placeholder
            },
            "!!typelist" => {
                typelist_data = reader.read_section_data(section)?;
            },
            "!!version" => {
                version_data = reader.read_section_data(section)?;
            },
            "!structitem" => {
                structitem_data = reader.read_section_data(section)?;
            },
            "!structitemnum" => {
                structitemnum_data = reader.read_section_data(section)?;
            },
            _ => {}
        }
    }

    // 3. Process Section Data
    let mut fields = Vec::new();
    let mut strtypelist_values = Vec::new();
    let mut field_count_from_num = 0usize;
    let mut is_known = false;

    // Process structitemnum
    if !structitemnum_data.is_empty() && structitemnum_data.len() >= 4 {
        field_count_from_num = u32::from_be_bytes(structitemnum_data[0..4].try_into().unwrap()) as usize;
    }

    // Process Version
    if !version_data.is_empty() && version_data.len() >= 4 {
        let version = u32::from_be_bytes(version_data[0..4].try_into().unwrap());
        header_map.insert("!!version".to_string(), WdbValue::UInt(version));
    }

    // Process SheetName
    if !sheet_name_data.is_empty() {
        let sheet_name = derive_string(&sheet_name_data, 0);
        header_map.insert("sheetName".to_string(), WdbValue::String(sheet_name));
    }

    // Process Typelist
    if !typelist_data.is_empty() {
        header_map.insert("!!typelist".to_string(), WdbValue::IntArray(WdbReader::<BufReader<File>>::parse_int_list(&typelist_data)));
    }

    // Process Strtypelist
    if !strtypelist_data.is_empty() {
        // We need to know if it was !!strtypelist or !!strtypelistb
        // Let's re-check the sections to find which one it was
        let mut is_b = false;
        for s in &sections {
            if s.name == "!!strtypelistb" {
                is_b = true;
                break;
            }
        }
        
        if is_b {
            strtypelist_values = WdbReader::<BufReader<File>>::parse_u8_list(&strtypelist_data);
        } else {
            strtypelist_values = WdbReader::<BufReader<File>>::parse_uint_list(&strtypelist_data);
        }
        header_map.insert("!!strtypelist".to_string(), WdbValue::UIntArray(strtypelist_values.clone()));
    }

    // Process Fields (!structitem)
    if !structitem_data.is_empty() {
        if game_code == GameCode::FF13_2 || game_code == GameCode::FF13_3 {
            // XIII-2 and LR embed field names as null-terminated strings
            let mut current_pos = 0;
            while current_pos < structitem_data.len() {
                let s = derive_string(&structitem_data, current_pos);
                if s.is_empty() { break; }
                current_pos += s.len() + 1;
                fields.push(s);
            }
        } else {
            // XIII embeds field names as offsets
            let offsets = WdbReader::<BufReader<File>>::parse_uint_list(&structitem_data);
            for offset in offsets {
                fields.push(derive_string(&strings_data, offset as usize));
            }
        }
    }

    // Process StrArray
    let mut str_array_dict = HashMap::new();
    if has_str_array && !str_array_data.is_empty() && !str_array_list_data.is_empty() {
        let str_array_offsets = WdbReader::<BufReader<File>>::parse_uint_list(&str_array_list_data);
        let s_fields: Vec<String> = fields.iter().filter(|f| f.starts_with('s') && super::bit_helpers::derive_field_number(f) != 0).cloned().collect();
        
        if str_array_offsets.len() == s_fields.len() {
            for (i, &offset) in str_array_offsets.iter().enumerate() {
                let mut current_strings = Vec::new();
                let mut current_pos = offset as usize;
                
                let end_pos = if i + 1 < str_array_offsets.len() {
                    str_array_offsets[i+1] as usize
                } else {
                    str_array_data.len()
                };
                
                while current_pos < end_pos {
                    if current_pos + 4 > str_array_data.len() { break; }
                    let val = u32::from_be_bytes(str_array_data[current_pos..current_pos+4].try_into().unwrap());
                    let mut bit_reader = super::bit_helpers::BitReader::new(val);
                    
                    for _ in 0..offsets_per_value {
                        if let Some(string_offset) = bit_reader.read_bits(bits_per_offset as usize) {
                            let s = derive_string(&strings_data, string_offset as usize);
                            current_strings.push(s);
                        }
                    }
                    current_pos += 4;
                }
                str_array_dict.insert(s_fields[i].clone(), current_strings);
            }
        }
    }

    // FF XIII Logic: Dictionary Lookup
    if fields.is_empty() && (game_code == GameCode::FF13_1) {
        if let Some(sheet_name) = super::dicts::RECORD_IDS.get(wdb_name.as_str()) {
            if let Some(dict_fields) = super::dicts::FIELD_NAMES.get(sheet_name) {
                fields = dict_fields.iter().map(|s| s.to_string()).collect();
                is_known = true;
                header_map.insert("sheetName".to_string(), WdbValue::String(sheet_name.to_string()));
            }
        }
        if !is_known {
            is_known = true;
        }
    }
    
    header_map.insert("recordCount".to_string(), WdbValue::UInt(record_count));
    header_map.insert("isKnown".to_string(), WdbValue::Bool(is_known));
    header_map.insert("gameCode".to_string(), WdbValue::String(match game_code {
        GameCode::FF13_1 => "FF13".to_string(),
        GameCode::FF13_2 => "FF13_2".to_string(),
        GameCode::FF13_3 => "LR".to_string(),
    }));
    header_map.insert("offsetsPerValue".to_string(), WdbValue::UInt(offsets_per_value as u32));
    header_map.insert("bits_per_offset".to_string(), WdbValue::UInt(bits_per_offset as u32));
    
    let mut field_count = if fields.is_empty() { strtypelist_values.len() } else { fields.len() };
    if field_count == 0 && field_count_from_num > 0 {
        field_count = field_count_from_num;
    }

    if fields.is_empty() {
        for i in 0..field_count {
            fields.push(format!("Field_{}", i));
        }
    }
    
    header_map.insert("!structitem".to_string(), WdbValue::StringArray(fields.clone()));
    
    let vars = WdbVariables {
        strtypelist_values,
        field_count,
        fields: fields.clone(),
        strings_data,
        record_count,
        wdb_name: file_header.magic.clone(),
        str_array_dict,
        offsets_per_value,
        bits_per_offset,
    };
    
    reader.seek(SeekFrom::Start(record_start_pos))?;
    let records = reader.parse_records(&vars)?;
    
    // DEBUG: print keys of first record
    if !records.is_empty() {
        log::debug!("First record keys: {:?}", records[0].keys());
    }
    
    Ok(WdbData {
        header: header_map,
        records,
    })
}

pub fn extract_wdb_to_json<P: AsRef<Path>>(wdb_path: P, json_path: P, game_code: GameCode) -> Result<()> {
    let data = parse_wdb(wdb_path, game_code)?;
    let file = File::create(json_path)?;
    let writer = BufWriter::new(file);
    serde_json::to_writer_pretty(writer, &data)?; // Serialize entire WdbData (header + records)
    Ok(())
}

pub fn wdb_to_json_string(data: &WdbData) -> Result<String> {
    Ok(serde_json::to_string_pretty(data)?)
}

pub fn wdb_from_json_string(json: &str) -> Result<WdbData> {
    Ok(serde_json::from_str(json)?)
}

use super::writer::WdbWriter;

pub fn pack_wdb<P: AsRef<Path>>(
    data: &WdbData, 
    output_path: P, 
    game_code: GameCode
) -> Result<()> {
    let file = File::create(output_path)?;
    let mut writer = WdbWriter::new(BufWriter::new(file));
    
    writer.write_file(data, game_code)?;
    Ok(())
}