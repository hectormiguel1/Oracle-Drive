//! # WDB Binary Writer
//!
//! This module provides binary serialization for WDB (WhiteDB) database files.
//! It converts JSON-like record structures back into the binary WDB format.
//!
//! ## Writing Process
//!
//! 1. Process records to extract field values
//! 2. Build string pool from string fields
//! 3. Encode records according to field types
//! 4. Write file header, section headers, and data
//!
//! ## Game-Specific Formats
//!
//! The writer supports two distinct formats:
//!
//! | Game      | Sections                                              |
//! |-----------|------------------------------------------------------|
//! | FF13-1    | !!string, !!strtypelist, !!typelist, !!version       |
//! | FF13-2/LR | + !!strArray, !!strArrayInfo, !structitem, etc.      |
//!
//! ## Bitpacking Algorithm
//!
//! For type 0 fields, values are packed into 32-bit words:
//!
//! 1. Convert each value to binary with appropriate width
//! 2. Reverse bit order for each value
//! 3. Concatenate all reversed values
//! 4. Reverse the entire collected string
//! 5. Parse as u32 and write big-endian

use std::io::{Write, Seek, SeekFrom};
use std::collections::BTreeMap;
use byteorder::{BigEndian, WriteBytesExt};
use anyhow::Result;
use indexmap::IndexMap;
use super::structs::{WdbValue, WdbData, GameCode};
use super::bit_helpers::derive_field_number;

/// Converts an unsigned integer to a fixed-width binary string.
///
/// Zero-pads on the left to reach the specified width.
/// Equivalent to C# `UIntToBinaryFixed`.
fn uint_to_binary_fixed(val: u32, width: usize) -> String {
    format!("{:0>width$b}", val, width = width)
}

/// Converts a signed integer to a fixed-width binary string.
///
/// For negative numbers, uses two's complement representation and
/// extracts the last `width` bits.
/// Equivalent to C# `IntToBinaryFixed`.
fn int_to_binary_fixed(val: i32, width: usize) -> String {
    if val < 0 {
        // For negative numbers, get 32-bit two's complement and take last `width` characters
        let full_binary = format!("{:032b}", val as u32);
        full_binary[32 - width..].to_string()
    } else {
        format!("{:0>width$b}", val, width = width)
    }
}

/// Reverses a binary string.
///
/// Used in the bitpacking algorithm to handle the LSB-first encoding.
fn reverse_binary(s: &str) -> String {
    s.chars().rev().collect()
}

/// Binary writer for WDB database files.
///
/// Wraps a seekable writer and provides methods for serializing
/// WDB records back to binary format.
///
/// # Example
///
/// ```rust,ignore
/// use std::fs::File;
/// use std::io::BufWriter;
///
/// let file = File::create("output.wdb")?;
/// let mut writer = WdbWriter::new(BufWriter::new(file));
/// writer.write_file(&wdb_data, GameCode::FF13_1)?;
/// ```
pub struct WdbWriter<W: Write + Seek> {
    writer: W,
}

impl<W: Write + Seek> WdbWriter<W> {
    /// Creates a new WDB writer wrapping the given seekable stream.
    pub fn new(writer: W) -> Self {
        Self { writer }
    }

    /// Consumes the writer and returns the underlying stream.
    pub fn into_inner(self) -> W {
        self.writer
    }

    /// Writes complete WDB file from parsed data.
    ///
    /// Routes to game-specific writers based on `game_code`.
    ///
    /// # Arguments
    ///
    /// * `data` - The WDB data structure with header and records
    /// * `game_code` - Target game (affects file format)
    pub fn write_file(&mut self, data: &WdbData, game_code: GameCode) -> Result<()> {
        let records = &data.records;
        let header_map = &data.header;

        log::info!("Writing WDB file for {:?}", game_code);

        let record_count = records.len() as u32;

        // Fields definition
        let fields: Vec<String> = if let Some(WdbValue::StringArray(f)) = header_map.get("!structitem") {
            f.clone()
        } else {
            return Err(anyhow::anyhow!("Missing !structitem in header map."));
        };
        let field_count = fields.len();

        // Get strtypelist values
        let strtypelist_values: Vec<u32> = match header_map.get("!!strtypelist") {
            Some(WdbValue::UIntArray(arr)) => arr.clone(),
            _ => Vec::new(),
        };

        // Build records data dict (record_name -> list of values in field order)
        let mut records_data_dict: IndexMap<String, Vec<WdbValue>> = IndexMap::new();
        for record in records {
            let record_name = record.get("record")
                .and_then(|v| match v { WdbValue::String(s) => Some(s.clone()), _ => None })
                .unwrap_or_default();

            if record_name.is_empty() {
                continue;
            }

            let mut values_list = Vec::new();
            for field in &fields {
                if let Some(val) = record.get(field) {
                    values_list.push(val.clone());
                } else {
                    log::warn!("Field {} missing in record {}. Defaulting to 0.", field, record_name);
                    values_list.push(WdbValue::UInt(0));
                }
            }
            records_data_dict.insert(record_name, values_list);
        }

        // ============================================================
        // GAME-SPECIFIC LOGIC
        // ============================================================

        if game_code == GameCode::FF13_1 {
            // FF13-1 (XIII) specific logic
            self.write_xiii(header_map, &fields, field_count, &strtypelist_values, &records_data_dict, record_count)?;
        } else {
            // FF13-2 (XIII-2) and FF13-3 (Lightning Returns) specific logic
            self.write_xiii2lr(header_map, &fields, field_count, &strtypelist_values, &records_data_dict, record_count, game_code)?;
        }

        Ok(())
    }

    /// Writes FF13-1 (XIII) format WDB file.
    ///
    /// XIII uses a simpler section layout with exactly 4 metadata sections:
    /// `!!string`, `!!strtypelist`, `!!typelist`, `!!version`
    ///
    /// Supports u64 fields (type 3 with field name starting with "u64").
    fn write_xiii(
        &mut self,
        header_map: &std::collections::HashMap<String, WdbValue>,
        fields: &[String],
        field_count: usize,
        strtypelist_values: &[u32],
        records_data_dict: &IndexMap<String, Vec<WdbValue>>,
        record_count: u32,
    ) -> Result<()> {
        // XIII ALWAYS has 4 sections: !!string, !!strtypelist, !!typelist, !!version
        let record_count_with_sections = record_count + 4;

        // Convert strtypelist values to big-endian bytes (4 bytes per value)
        let strtypelist_data: Vec<u8> = strtypelist_values.iter()
            .flat_map(|&v| v.to_be_bytes())
            .collect();

        // Convert typelist values to big-endian bytes
        let typelist_data: Vec<u8> = match header_map.get("!!typelist") {
            Some(WdbValue::IntArray(arr)) => arr.iter().flat_map(|&v| v.to_be_bytes()).collect(),
            Some(WdbValue::UIntArray(arr)) => arr.iter().flat_map(|&v| (v as i32).to_be_bytes()).collect(),
            _ => Vec::new(),
        };

        // Convert version to big-endian bytes
        let version_data: Vec<u8> = match header_map.get("!!version") {
            Some(WdbValue::UInt(v)) => v.to_be_bytes().to_vec(),
            _ => vec![0, 0, 0, 0],
        };

        // ============================================================
        // CONVERT RECORDS (C# RecordsConversion.ConvertRecordsWithFields)
        // ============================================================

        let mut string_pos: u32 = 1;
        // Use IndexMap to preserve insertion order like C# Dictionary
        let mut processed_strings_dict: IndexMap<String, u32> = IndexMap::new();
        processed_strings_dict.insert(String::new(), 0); // Empty string at offset 0

        let out_per_record_size = strtypelist_values.len() * 4;
        let mut out_per_record_data: IndexMap<String, Vec<u8>> = IndexMap::new();

        for (record_name, record_values) in records_data_dict {
            let mut current_out_data = vec![0u8; out_per_record_size];
            let mut data_index: usize = 0;
            let mut strtypelist_index: usize = 0;
            let mut f: usize = 0;

            while f < field_count {
                if strtypelist_index >= strtypelist_values.len() {
                    break;
                }

                match strtypelist_values[strtypelist_index] {
                    // Type 0: bitpacked values
                    0 => {
                        let mut field_bits_to_process: i32 = 32;
                        let mut collected_binary = String::new();

                        while field_bits_to_process != 0 && f < field_count {
                            let field_name = &fields[f];
                            let field_type = field_name.chars().next().unwrap_or('u');
                            let field_num = derive_field_number(field_name);
                            let actual_field_num = if field_num == 0 { 32 } else { field_num };

                            if actual_field_num as i32 > field_bits_to_process {
                                // Field doesn't fit, decrement f and exit loop
                                // (f will be incremented at end of outer loop, so net effect is f stays same)
                                f = f.saturating_sub(1);
                                field_bits_to_process = 0;
                                continue;
                            }

                            match field_type {
                                'i' => {
                                    // Signed int
                                    let i_val: i32 = match &record_values[f] {
                                        WdbValue::Int(i) => *i,
                                        WdbValue::UInt(u) => *u as i32,
                                        WdbValue::CrystalRole(r) => r.to_u32() as i32,
                                        WdbValue::CrystalNodeType(n) => n.to_u32() as i32,
                                        _ => 0,
                                    };

                                    let mut binary_str = int_to_binary_fixed(i_val, actual_field_num);
                                    if binary_str.len() > actual_field_num {
                                        binary_str = binary_str[binary_str.len() - actual_field_num..].to_string();
                                    }
                                    binary_str = reverse_binary(&binary_str);
                                    collected_binary.push_str(&binary_str);

                                    field_bits_to_process -= actual_field_num as i32;
                                    if field_bits_to_process != 0 {
                                        f += 1;
                                    }
                                },
                                'u' => {
                                    // Unsigned int
                                    let u_val: u32 = match &record_values[f] {
                                        WdbValue::UInt(u) => *u,
                                        WdbValue::Int(i) => *i as u32,
                                        WdbValue::CrystalRole(r) => r.to_u32(),
                                        WdbValue::CrystalNodeType(n) => n.to_u32(),
                                        _ => 0,
                                    };

                                    let binary_str = uint_to_binary_fixed(u_val, actual_field_num);
                                    let reversed = reverse_binary(&binary_str);
                                    collected_binary.push_str(&reversed);

                                    field_bits_to_process -= actual_field_num as i32;
                                    if field_bits_to_process != 0 {
                                        f += 1;
                                    }
                                },
                                'f' => {
                                    // Float (bitpacked as int)
                                    let f_val: i32 = match &record_values[f] {
                                        WdbValue::Int(i) => *i,
                                        WdbValue::UInt(u) => *u as i32,
                                        WdbValue::Float(fv) => *fv as i32,
                                        WdbValue::CrystalRole(r) => r.to_u32() as i32,
                                        WdbValue::CrystalNodeType(n) => n.to_u32() as i32,
                                        _ => 0,
                                    };

                                    let mut binary_str = int_to_binary_fixed(f_val, actual_field_num);
                                    if binary_str.len() > actual_field_num {
                                        binary_str = binary_str[binary_str.len() - actual_field_num..].to_string();
                                    }
                                    binary_str = reverse_binary(&binary_str);
                                    collected_binary.push_str(&binary_str);

                                    field_bits_to_process -= actual_field_num as i32;
                                    if field_bits_to_process != 0 {
                                        f += 1;
                                    }
                                },
                                _ => {
                                    // Unknown field type, skip
                                    if field_bits_to_process != 0 {
                                        f += 1;
                                    }
                                }
                            }
                        }

                        // Reverse collected binary and convert to u32
                        let final_binary = reverse_binary(&collected_binary);
                        let collective_val = if final_binary.is_empty() {
                            0u32
                        } else {
                            u32::from_str_radix(&final_binary, 2).unwrap_or(0)
                        };

                        // Write as big-endian
                        current_out_data[data_index] = (collective_val >> 24) as u8;
                        current_out_data[data_index + 1] = (collective_val >> 16) as u8;
                        current_out_data[data_index + 2] = (collective_val >> 8) as u8;
                        current_out_data[data_index + 3] = collective_val as u8;

                        strtypelist_index += 1;
                        data_index += 4;
                    },

                    // Type 1: float value
                    1 => {
                        let float_val: f32 = match &record_values[f] {
                            WdbValue::Float(fv) => *fv,
                            WdbValue::Int(i) => *i as f32,
                            WdbValue::UInt(u) => *u as f32,
                            _ => 0.0,
                        };

                        let float_bytes = float_val.to_be_bytes();
                        current_out_data[data_index..data_index + 4].copy_from_slice(&float_bytes);

                        strtypelist_index += 1;
                        data_index += 4;
                    },

                    // Type 2: string section offset
                    2 => {
                        let string_val = match &record_values[f] {
                            WdbValue::String(s) => s.clone(),
                            _ => String::new(),
                        };

                        if !string_val.is_empty() {
                            let mut added_string = false;
                            if !processed_strings_dict.contains_key(&string_val) {
                                processed_strings_dict.insert(string_val.clone(), string_pos);
                                added_string = true;
                            }

                            let offset = *processed_strings_dict.get(&string_val).unwrap();

                            // Write offset as big-endian
                            current_out_data[data_index] = (offset >> 24) as u8;
                            current_out_data[data_index + 1] = (offset >> 16) as u8;
                            current_out_data[data_index + 2] = (offset >> 8) as u8;
                            current_out_data[data_index + 3] = offset as u8;

                            if added_string {
                                // C# uses UTF8.GetByteCount(stringVal + "\0")
                                string_pos += string_val.len() as u32 + 1;
                            }
                        }
                        // If string is empty, currentOutData stays 0 (points to offset 0 = empty string)

                        strtypelist_index += 1;
                        data_index += 4;
                    },

                    // Type 3: uint value (or u64 for XIII only)
                    3 => {
                        let field_name = &fields[f];

                        if field_name.starts_with("u64") {
                            // u64 handling - XIII ONLY
                            let ulong_val: u64 = match &record_values[f] {
                                WdbValue::UInt64(u) => *u,
                                WdbValue::UInt(u) => *u as u64,
                                WdbValue::Int(i) => *i as u64,
                                _ => 0,
                            };

                            // Write as big-endian
                            current_out_data[data_index] = (ulong_val >> 56) as u8;
                            current_out_data[data_index + 1] = (ulong_val >> 48) as u8;
                            current_out_data[data_index + 2] = (ulong_val >> 40) as u8;
                            current_out_data[data_index + 3] = (ulong_val >> 32) as u8;
                            current_out_data[data_index + 4] = (ulong_val >> 24) as u8;
                            current_out_data[data_index + 5] = (ulong_val >> 16) as u8;
                            current_out_data[data_index + 6] = (ulong_val >> 8) as u8;
                            current_out_data[data_index + 7] = ulong_val as u8;

                            strtypelist_index += 2; // u64 takes 2 strtypelist entries
                            data_index += 8;
                        } else {
                            // Regular uint
                            let uint_val: u32 = match &record_values[f] {
                                WdbValue::UInt(u) => *u,
                                WdbValue::Int(i) => *i as u32,
                                WdbValue::CrystalRole(r) => r.to_u32(),
                                WdbValue::CrystalNodeType(n) => n.to_u32(),
                                _ => 0,
                            };

                            // Write as big-endian
                            current_out_data[data_index] = (uint_val >> 24) as u8;
                            current_out_data[data_index + 1] = (uint_val >> 16) as u8;
                            current_out_data[data_index + 2] = (uint_val >> 8) as u8;
                            current_out_data[data_index + 3] = uint_val as u8;

                            strtypelist_index += 1;
                            data_index += 4;
                        }
                    },

                    _ => {
                        strtypelist_index += 1;
                    }
                }

                f += 1;
            }

            out_per_record_data.insert(record_name.clone(), current_out_data);
        }

        // Determine if we have a string section
        let has_string_section = processed_strings_dict.len() > 1 ||
            !processed_strings_dict.is_empty();

        // ============================================================
        // BUILD WDB FILE (C# WDBbuilder.BuildWDB)
        // ============================================================

        // Write file header
        self.writer.write_all(b"WPD\0")?;
        self.writer.write_u32::<BigEndian>(record_count_with_sections)?;
        self.writer.write_all(&[0u8; 8])?; // Padding

        // Write section headers (names only, offset/size will be updated later)
        // Section 1: !!string
        self.write_section_name("!!string", 8)?;
        // Section 2: !!strtypelist
        self.write_section_name("!!strtypelist", 13)?;
        // Section 3: !!typelist
        self.write_section_name("!!typelist", 10)?;
        // Section 4: !!version
        self.write_section_name("!!version", 9)?;

        // Write record headers
        for record_name in out_per_record_data.keys() {
            self.write_section_name(record_name, record_name.len())?;
        }

        // Now write data and update offsets
        let mut offset_update_pos: u64 = 32; // After file header (16 bytes) + first 16 bytes of first section header

        // Section 1: !!string
        let sec_pos = self.writer.stream_position()? as u32;
        let mut string_section_size: u32 = 0;

        if has_string_section {
            // Write strings in insertion order (IndexMap preserves this)
            for (string_key, _) in &processed_strings_dict {
                if string_key.is_empty() {
                    self.writer.write_u8(0)?;
                    string_section_size += 1;
                } else {
                    let string_bytes = string_key.as_bytes();
                    self.writer.write_all(string_bytes)?;
                    self.writer.write_u8(0)?;
                    string_section_size += string_bytes.len() as u32 + 1;
                }
            }
        } else {
            self.writer.write_u8(0)?;
            string_section_size = 1;
        }
        self.pad_bytes_after_section()?;
        self.update_offsets(offset_update_pos, sec_pos, string_section_size)?;
        offset_update_pos += 32;

        // Section 2: !!strtypelist
        let sec_pos = self.writer.stream_position()? as u32;
        self.writer.write_all(&strtypelist_data)?;
        self.pad_bytes_after_section()?;
        self.update_offsets(offset_update_pos, sec_pos, strtypelist_data.len() as u32)?;
        offset_update_pos += 32;

        // Section 3: !!typelist
        let sec_pos = self.writer.stream_position()? as u32;
        self.writer.write_all(&typelist_data)?;
        self.pad_bytes_after_section()?;
        self.update_offsets(offset_update_pos, sec_pos, typelist_data.len() as u32)?;
        offset_update_pos += 32;

        // Section 4: !!version
        let sec_pos = self.writer.stream_position()? as u32;
        self.writer.write_all(&version_data)?;
        self.pad_bytes_after_section()?;
        self.update_offsets(offset_update_pos, sec_pos, version_data.len() as u32)?;
        offset_update_pos += 32;

        // Records
        for (_, record_data) in &out_per_record_data {
            let sec_pos = self.writer.stream_position()? as u32;
            self.writer.write_all(record_data)?;
            self.pad_bytes_after_section()?;
            self.update_offsets(offset_update_pos, sec_pos, record_data.len() as u32)?;
            offset_update_pos += 32;
        }

        Ok(())
    }

    /// Writes FF13-2/LR (XIII-2/Lightning Returns) format WDB file.
    ///
    /// XIII-2 and Lightning Returns use an extended section layout with:
    /// - Optional `!!sheetname` for database name
    /// - `!!strArray`, `!!strArrayInfo`, `!!strArrayList` for indexed strings
    /// - `!structitem` and `!structitemnum` for field definitions
    /// - `!!strtypelistb` (byte-sized type codes) or `!!strtypelist`
    #[allow(clippy::too_many_arguments)]
    fn write_xiii2lr(
        &mut self,
        header_map: &std::collections::HashMap<String, WdbValue>,
        fields: &[String],
        field_count: usize,
        strtypelist_values: &[u32],
        records_data_dict: &IndexMap<String, Vec<WdbValue>>,
        record_count: u32,
        _game_code: GameCode,
    ) -> Result<()> {
        // Determine which sections are present
        let sheet_name = match header_map.get("sheetName") {
            Some(WdbValue::String(s)) if s != "Not Specified" => Some(s.clone()),
            _ => None,
        };

        // Check for strArray fields (s# fields where # != 0)
        let has_str_array_section = fields.iter().any(|f| {
            f.starts_with('s') && derive_field_number(f) != 0
        });

        // Check for string fields (type 2 in strtypelist)
        let has_string_section = strtypelist_values.contains(&2);

        // Check for !!strtypelistb vs !!strtypelist
        let parse_strtypelist_as_v1 = !header_map.contains_key("!!strtypelistb");

        // Check for !!typelist
        let has_typelist_section = header_map.contains_key("!!typelist");

        // Calculate section count
        let mut section_count: u32 = 0;
        if sheet_name.is_some() { section_count += 1; }
        if has_str_array_section { section_count += 3; } // strArray, strArrayInfo, strArrayList
        if has_string_section { section_count += 1; }
        section_count += 1; // strtypelist/strtypelistb (always)
        if has_typelist_section { section_count += 1; }
        section_count += 1; // version (always)
        section_count += 2; // structitem, structitemnum (always for XIII-2/LR)

        let record_count_with_sections = record_count + section_count;

        // Prepare section data

        // strtypelist data
        let strtypelist_data: Vec<u8> = if parse_strtypelist_as_v1 {
            // V1: 4 bytes per entry (big-endian)
            strtypelist_values.iter().flat_map(|&v| v.to_be_bytes()).collect()
        } else {
            // V2 (!!strtypelistb): 1 byte per entry
            strtypelist_values.iter().map(|&v| v as u8).collect()
        };

        // typelist data
        let typelist_data: Vec<u8> = match header_map.get("!!typelist") {
            Some(WdbValue::IntArray(arr)) => arr.iter().flat_map(|&v| v.to_be_bytes()).collect(),
            Some(WdbValue::UIntArray(arr)) => arr.iter().flat_map(|&v| (v as i32).to_be_bytes()).collect(),
            _ => Vec::new(),
        };

        // version data
        let version_data: Vec<u8> = match header_map.get("!!version") {
            Some(WdbValue::UInt(v)) => v.to_be_bytes().to_vec(),
            _ => vec![0, 0, 0, 0],
        };

        // structitem data (field names with null terminators)
        let struct_item_data: Vec<u8> = fields.iter()
            .flat_map(|f| {
                let mut bytes = f.as_bytes().to_vec();
                bytes.push(0);
                bytes
            })
            .collect();

        // structitemnum data
        let struct_item_num_data: Vec<u8> = (field_count as u32).to_be_bytes().to_vec();

        // ============================================================
        // STRARRAY HANDLING (if present)
        // ============================================================

        let offsets_per_value = match header_map.get("offsetsPerValue") {
            Some(WdbValue::UInt(u)) => *u as u8,
            _ => 2,
        };
        let bits_per_offset = match header_map.get("bits_per_offset") {
            Some(WdbValue::UInt(u)) => *u as u8,
            _ => 16,
        };

        // Build strArrayDataDict (field -> list of unique strings)
        let mut str_array_data_dict: BTreeMap<String, Vec<String>> = BTreeMap::new();
        if has_str_array_section {
            for (_, record_values) in records_data_dict {
                for (f_idx, field) in fields.iter().enumerate() {
                    if field.starts_with('s') && derive_field_number(field) != 0 {
                        let current_string = match &record_values[f_idx] {
                            WdbValue::String(s) => s.clone(),
                            _ => String::new(),
                        };

                        let entry = str_array_data_dict.entry(field.clone()).or_default();
                        if !entry.contains(&current_string) {
                            entry.push(current_string);
                        }
                    }
                }
            }
        }

        // ============================================================
        // CONVERT RECORDS
        // ============================================================

        let mut string_pos: u32 = 1;
        let mut processed_strings_dict: IndexMap<String, u32> = IndexMap::new();
        processed_strings_dict.insert(String::new(), 0);

        // Build strArray sections if needed
        let mut str_array_data = Vec::new();
        let mut str_array_list_data = Vec::new();
        let str_array_info_data = vec![0u8, 0u8, offsets_per_value, bits_per_offset];

        if has_str_array_section {
            let mut str_array_val_dict: IndexMap<String, Vec<u32>> = IndexMap::new();

            for (current_array_name, current_array_list) in &str_array_data_dict {
                str_array_val_dict.insert(current_array_name.clone(), Vec::new());

                let mut s = 0;
                while s < current_array_list.len() {
                    let mut current_val_binary_list: Vec<String> = Vec::new();

                    for _ in 0..offsets_per_value {
                        if s >= current_array_list.len() {
                            break;
                        }

                        let current_string_item = &current_array_list[s];

                        if !processed_strings_dict.contains_key(current_string_item) {
                            processed_strings_dict.insert(current_string_item.clone(), string_pos);
                            string_pos += current_string_item.len() as u32 + 1;
                        }

                        let string_item_pos = *processed_strings_dict.get(current_string_item).unwrap();
                        let current_offset_val = uint_to_binary_fixed(string_item_pos, bits_per_offset as usize);
                        current_val_binary_list.push(current_offset_val);

                        s += 1;
                    }

                    current_val_binary_list.reverse();
                    let current_val_binary = current_val_binary_list.join("");
                    let packed_value = u32::from_str_radix(&current_val_binary, 2).unwrap_or(0);

                    str_array_val_dict.get_mut(current_array_name).unwrap().push(packed_value);
                }
            }

            // Build strArrayListData and strArrayData
            str_array_list_data = vec![0u8; str_array_val_dict.len() * 4];
            let mut list_start_offset: usize = 0;
            let mut array_start_offset: u32 = 0;

            for (_, values) in &str_array_val_dict {
                // Write array start offset to strArrayListData
                let offset_bytes = array_start_offset.to_be_bytes();
                str_array_list_data[list_start_offset] = offset_bytes[0];
                str_array_list_data[list_start_offset + 1] = offset_bytes[1];
                str_array_list_data[list_start_offset + 2] = offset_bytes[2];
                str_array_list_data[list_start_offset + 3] = offset_bytes[3];

                // Write values to strArrayData
                for &value in values {
                    str_array_data.extend_from_slice(&value.to_be_bytes());
                }

                array_start_offset = str_array_data.len() as u32;
                list_start_offset += 4;
            }
        }

        // Now convert records
        let out_per_record_size = strtypelist_values.len() * 4;
        let mut out_per_record_data: IndexMap<String, Vec<u8>> = IndexMap::new();

        for (record_name, record_values) in records_data_dict {
            let mut current_out_data = vec![0u8; out_per_record_size];
            let mut data_index: usize = 0;
            let mut strtypelist_index: usize = 0;
            let mut f: usize = 0;

            while f < field_count {
                if strtypelist_index >= strtypelist_values.len() {
                    break;
                }

                match strtypelist_values[strtypelist_index] {
                    // Type 0: bitpacked values
                    0 => {
                        let mut field_bits_to_process: i32 = 32;
                        let mut collected_binary = String::new();

                        while field_bits_to_process != 0 && f < field_count {
                            let field_name = &fields[f];
                            let field_type = field_name.chars().next().unwrap_or('u');
                            let field_num = derive_field_number(field_name);
                            let actual_field_num = if field_num == 0 { 32 } else { field_num };

                            if actual_field_num as i32 > field_bits_to_process {
                                f = f.saturating_sub(1);
                                field_bits_to_process = 0;
                                continue;
                            }

                            match field_type {
                                'i' => {
                                    let i_val: i32 = match &record_values[f] {
                                        WdbValue::Int(i) => *i,
                                        WdbValue::UInt(u) => *u as i32,
                                        WdbValue::CrystalRole(r) => r.to_u32() as i32,
                                        WdbValue::CrystalNodeType(n) => n.to_u32() as i32,
                                        _ => 0,
                                    };

                                    let mut binary_str = int_to_binary_fixed(i_val, actual_field_num);
                                    if binary_str.len() > actual_field_num {
                                        binary_str = binary_str[binary_str.len() - actual_field_num..].to_string();
                                    }
                                    binary_str = reverse_binary(&binary_str);
                                    collected_binary.push_str(&binary_str);

                                    field_bits_to_process -= actual_field_num as i32;
                                    if field_bits_to_process != 0 { f += 1; }
                                },
                                'u' => {
                                    let u_val: u32 = match &record_values[f] {
                                        WdbValue::UInt(u) => *u,
                                        WdbValue::Int(i) => *i as u32,
                                        WdbValue::CrystalRole(r) => r.to_u32(),
                                        WdbValue::CrystalNodeType(n) => n.to_u32(),
                                        _ => 0,
                                    };

                                    let binary_str = uint_to_binary_fixed(u_val, actual_field_num);
                                    let reversed = reverse_binary(&binary_str);
                                    collected_binary.push_str(&reversed);

                                    field_bits_to_process -= actual_field_num as i32;
                                    if field_bits_to_process != 0 { f += 1; }
                                },
                                'f' => {
                                    let f_val: i32 = match &record_values[f] {
                                        WdbValue::Int(i) => *i,
                                        WdbValue::UInt(u) => *u as i32,
                                        WdbValue::Float(fv) => *fv as i32,
                                        WdbValue::CrystalRole(r) => r.to_u32() as i32,
                                        WdbValue::CrystalNodeType(n) => n.to_u32() as i32,
                                        _ => 0,
                                    };

                                    let mut binary_str = int_to_binary_fixed(f_val, actual_field_num);
                                    if binary_str.len() > actual_field_num {
                                        binary_str = binary_str[binary_str.len() - actual_field_num..].to_string();
                                    }
                                    binary_str = reverse_binary(&binary_str);
                                    collected_binary.push_str(&binary_str);

                                    field_bits_to_process -= actual_field_num as i32;
                                    if field_bits_to_process != 0 { f += 1; }
                                },
                                's' => {
                                    // strArray item index
                                    let string_item = match &record_values[f] {
                                        WdbValue::String(s) => s.clone(),
                                        _ => String::new(),
                                    };
                                    let s_val = str_array_data_dict.get(field_name)
                                        .and_then(|list| list.iter().position(|s| s == &string_item))
                                        .unwrap_or(0) as u32;

                                    let binary_str = uint_to_binary_fixed(s_val, actual_field_num);
                                    let reversed = reverse_binary(&binary_str);
                                    collected_binary.push_str(&reversed);

                                    field_bits_to_process -= actual_field_num as i32;
                                    if field_bits_to_process != 0 { f += 1; }
                                },
                                _ => {
                                    if field_bits_to_process != 0 { f += 1; }
                                }
                            }
                        }

                        let final_binary = reverse_binary(&collected_binary);
                        let collective_val = if final_binary.is_empty() {
                            0u32
                        } else {
                            u32::from_str_radix(&final_binary, 2).unwrap_or(0)
                        };

                        current_out_data[data_index] = (collective_val >> 24) as u8;
                        current_out_data[data_index + 1] = (collective_val >> 16) as u8;
                        current_out_data[data_index + 2] = (collective_val >> 8) as u8;
                        current_out_data[data_index + 3] = collective_val as u8;

                        strtypelist_index += 1;
                        data_index += 4;
                    },

                    // Type 1: float value
                    1 => {
                        let float_val: f32 = match &record_values[f] {
                            WdbValue::Float(fv) => *fv,
                            WdbValue::Int(i) => *i as f32,
                            WdbValue::UInt(u) => *u as f32,
                            _ => 0.0,
                        };

                        let float_bytes = float_val.to_be_bytes();
                        current_out_data[data_index..data_index + 4].copy_from_slice(&float_bytes);

                        strtypelist_index += 1;
                        data_index += 4;
                    },

                    // Type 2: string section offset
                    2 => {
                        let string_val = match &record_values[f] {
                            WdbValue::String(s) => s.clone(),
                            _ => String::new(),
                        };

                        if !string_val.is_empty() {
                            if !processed_strings_dict.contains_key(&string_val) {
                                processed_strings_dict.insert(string_val.clone(), string_pos);
                                string_pos += string_val.len() as u32 + 1;
                            }

                            let offset = *processed_strings_dict.get(&string_val).unwrap();

                            current_out_data[data_index] = (offset >> 24) as u8;
                            current_out_data[data_index + 1] = (offset >> 16) as u8;
                            current_out_data[data_index + 2] = (offset >> 8) as u8;
                            current_out_data[data_index + 3] = offset as u8;
                        }

                        strtypelist_index += 1;
                        data_index += 4;
                    },

                    // Type 3: uint value (NO u64 for XIII-2/LR!)
                    3 => {
                        let uint_val: u32 = match &record_values[f] {
                            WdbValue::UInt(u) => *u,
                            WdbValue::Int(i) => *i as u32,
                            WdbValue::CrystalRole(r) => r.to_u32(),
                            WdbValue::CrystalNodeType(n) => n.to_u32(),
                            _ => 0,
                        };

                        current_out_data[data_index] = (uint_val >> 24) as u8;
                        current_out_data[data_index + 1] = (uint_val >> 16) as u8;
                        current_out_data[data_index + 2] = (uint_val >> 8) as u8;
                        current_out_data[data_index + 3] = uint_val as u8;

                        strtypelist_index += 1;
                        data_index += 4;
                    },

                    _ => {
                        strtypelist_index += 1;
                    }
                }

                f += 1;
            }

            out_per_record_data.insert(record_name.clone(), current_out_data);
        }

        // ============================================================
        // BUILD WDB FILE
        // ============================================================

        // Write file header
        self.writer.write_all(b"WPD\0")?;
        self.writer.write_u32::<BigEndian>(record_count_with_sections)?;
        self.writer.write_all(&[0u8; 8])?;

        // Write section headers
        if sheet_name.is_some() {
            self.write_section_name("!!sheetname", 11)?;
        }
        if has_str_array_section {
            self.write_section_name("!!strArray", 10)?;
            self.write_section_name("!!strArrayInfo", 14)?;
            self.write_section_name("!!strArrayList", 14)?;
        }
        if has_string_section {
            self.write_section_name("!!string", 8)?;
        }
        if parse_strtypelist_as_v1 {
            self.write_section_name("!!strtypelist", 13)?;
        } else {
            self.write_section_name("!!strtypelistb", 14)?;
        }
        if has_typelist_section {
            self.write_section_name("!!typelist", 10)?;
        }
        self.write_section_name("!!version", 9)?;
        self.write_section_name("!structitem", 11)?;
        self.write_section_name("!structitemnum", 14)?;

        // Record headers
        for record_name in out_per_record_data.keys() {
            self.write_section_name(record_name, record_name.len())?;
        }

        // Write data and update offsets
        let mut offset_update_pos: u64 = 32;

        // sheetname
        if let Some(ref name) = sheet_name {
            let sec_pos = self.writer.stream_position()? as u32;
            let name_bytes = name.as_bytes();
            self.writer.write_all(name_bytes)?;
            self.pad_bytes_after_section()?;
            self.update_offsets(offset_update_pos, sec_pos, name_bytes.len() as u32)?;
            offset_update_pos += 32;
        }

        // strArray sections
        if has_str_array_section {
            // strArray
            let sec_pos = self.writer.stream_position()? as u32;
            self.writer.write_all(&str_array_data)?;
            self.pad_bytes_after_section()?;
            self.update_offsets(offset_update_pos, sec_pos, str_array_data.len() as u32)?;
            offset_update_pos += 32;

            // strArrayInfo
            let sec_pos = self.writer.stream_position()? as u32;
            self.writer.write_all(&str_array_info_data)?;
            self.pad_bytes_after_section()?;
            self.update_offsets(offset_update_pos, sec_pos, str_array_info_data.len() as u32)?;
            offset_update_pos += 32;

            // strArrayList
            let sec_pos = self.writer.stream_position()? as u32;
            self.writer.write_all(&str_array_list_data)?;
            self.pad_bytes_after_section()?;
            self.update_offsets(offset_update_pos, sec_pos, str_array_list_data.len() as u32)?;
            offset_update_pos += 32;
        }

        // string
        if has_string_section {
            let sec_pos = self.writer.stream_position()? as u32;
            let mut string_section_size: u32 = 0;

            for (string_key, _) in &processed_strings_dict {
                if string_key.is_empty() {
                    self.writer.write_u8(0)?;
                    string_section_size += 1;
                } else {
                    let string_bytes = string_key.as_bytes();
                    self.writer.write_all(string_bytes)?;
                    self.writer.write_u8(0)?;
                    string_section_size += string_bytes.len() as u32 + 1;
                }
            }

            self.pad_bytes_after_section()?;
            self.update_offsets(offset_update_pos, sec_pos, string_section_size)?;
            offset_update_pos += 32;
        }

        // strtypelist
        let sec_pos = self.writer.stream_position()? as u32;
        self.writer.write_all(&strtypelist_data)?;
        self.pad_bytes_after_section()?;
        self.update_offsets(offset_update_pos, sec_pos, strtypelist_data.len() as u32)?;
        offset_update_pos += 32;

        // typelist
        if has_typelist_section {
            let sec_pos = self.writer.stream_position()? as u32;
            self.writer.write_all(&typelist_data)?;
            self.pad_bytes_after_section()?;
            self.update_offsets(offset_update_pos, sec_pos, typelist_data.len() as u32)?;
            offset_update_pos += 32;
        }

        // version
        let sec_pos = self.writer.stream_position()? as u32;
        self.writer.write_all(&version_data)?;
        self.pad_bytes_after_section()?;
        self.update_offsets(offset_update_pos, sec_pos, version_data.len() as u32)?;
        offset_update_pos += 32;

        // structitem
        let sec_pos = self.writer.stream_position()? as u32;
        self.writer.write_all(&struct_item_data)?;
        self.pad_bytes_after_section()?;
        self.update_offsets(offset_update_pos, sec_pos, struct_item_data.len() as u32)?;
        offset_update_pos += 32;

        // structitemnum
        let sec_pos = self.writer.stream_position()? as u32;
        self.writer.write_all(&struct_item_num_data)?;
        self.pad_bytes_after_section()?;
        self.update_offsets(offset_update_pos, sec_pos, 4)?;
        offset_update_pos += 32;

        // records
        for (_, record_data) in &out_per_record_data {
            let sec_pos = self.writer.stream_position()? as u32;
            self.writer.write_all(record_data)?;
            self.pad_bytes_after_section()?;
            self.update_offsets(offset_update_pos, sec_pos, record_data.len() as u32)?;
            offset_update_pos += 32;
        }

        Ok(())
    }

    /// Writes a section header entry.
    ///
    /// Format: 16 bytes name (null-padded) + 16 bytes for offset/size/reserved.
    /// The offset and size are written later via `update_offsets`.
    fn write_section_name(&mut self, name: &str, name_length: usize) -> Result<()> {
        let name_bytes = name.as_bytes();
        self.writer.write_all(name_bytes)?;

        // Pad to 16 bytes
        let padding = 16 - name_length;
        for _ in 0..padding {
            self.writer.write_u8(0)?;
        }

        // Write 16 null bytes (offset, size, reserved)
        self.writer.write_all(&[0u8; 16])?;

        Ok(())
    }

    /// Pads output to 4-byte alignment.
    ///
    /// WDB sections must be 4-byte aligned. This adds null bytes as needed.
    fn pad_bytes_after_section(&mut self) -> Result<()> {
        let current_pos = self.writer.stream_position()?;
        let pad_value: u64 = 4;

        if current_pos % pad_value != 0 {
            let remainder = current_pos % pad_value;
            let null_bytes_amount = pad_value - remainder;

            for _ in 0..null_bytes_amount {
                self.writer.write_u8(0)?;
            }
        }

        Ok(())
    }

    /// Updates a section header with actual offset and size.
    ///
    /// Seeks back to the header position, writes the values,
    /// then returns to the original position.
    fn update_offsets(&mut self, pos: u64, sec_pos: u32, size: u32) -> Result<()> {
        let current = self.writer.stream_position()?;
        self.writer.seek(SeekFrom::Start(pos))?;
        self.writer.write_u32::<BigEndian>(sec_pos)?;
        self.writer.write_u32::<BigEndian>(size)?;
        self.writer.seek(SeekFrom::Start(current))?;
        Ok(())
    }
}
