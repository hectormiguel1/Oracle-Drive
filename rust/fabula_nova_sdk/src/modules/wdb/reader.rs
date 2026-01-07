//! # WDB Binary Reader
//!
//! This module provides binary parsing for WDB (WhiteDB) database files.
//! WDB files use a section-based format with various encoding schemes.
//!
//! ## Reading Process
//!
//! 1. Read file header (magic + record count)
//! 2. Read section headers (metadata sections starting with `!!`)
//! 3. Parse section data to build field definitions
//! 4. Read record headers and parse record data
//!
//! ## Type Encoding (strtypelist)
//!
//! Each field's encoding is defined by the `!!strtypelist` section:
//!
//! | Type Code | Encoding           | Size      |
//! |-----------|-------------------|-----------|
//! | 0         | Bitpacked fields  | 4 bytes   |
//! | 1         | Float (f32)       | 4 bytes   |
//! | 2         | String offset     | 4 bytes   |
//! | 3         | UInt              | 4 bytes   |
//!
//! ## Bitpacking
//!
//! Type 0 fields pack multiple values into a single 32-bit word.
//! Field names encode bit width: `u4Role` = 4 bits, `i16Value` = 16 bits signed.

use super::bit_helpers::{derive_field_number, BitReader};
use super::enum_registry::{get_enum_type, int_to_enum_value};
use super::structs::{WdbBinaryHeader, WdbRecord, WdbSectionHeader, WdbValue};
use anyhow::Result;
use binrw::BinReaderExt;
use byteorder::ReadBytesExt;
use std::collections::HashMap;
use std::io::{Read, Seek, SeekFrom};

/// Context structure holding parsed WDB metadata.
///
/// This struct aggregates all the context needed to interpret record data:
/// - Field definitions from `!structitem`
/// - Type encodings from `!!strtypelist`
/// - String pool from `!!string`
/// - String array mappings for indexed string fields
pub struct WdbVariables {
    pub strtypelist_values: Vec<u32>,
    pub field_count: usize,
    pub fields: Vec<String>,
    pub strings_data: Vec<u8>,
    pub record_count: u32,
    pub wdb_name: String,
    pub str_array_dict: HashMap<String, Vec<String>>,
    pub offsets_per_value: u8,
    pub bits_per_offset: u8,
    /// When true, fields are unknown and should use type-based generic names
    pub without_fields: bool,
}

/// Binary reader for WDB database files.
///
/// Wraps a seekable reader and provides methods for parsing
/// WDB file structure: headers, sections, and records.
///
/// # Example
///
/// ```rust,ignore
/// use std::fs::File;
/// use std::io::BufReader;
///
/// let file = File::open("item.wdb")?;
/// let mut reader = WdbReader::new(BufReader::new(file));
/// let (header, sections) = reader.read_headers()?;
/// ```
pub struct WdbReader<R: Read + Seek> {
    reader: R,
}

impl<R: Read + Seek> WdbReader<R> {
    /// Creates a new WDB reader wrapping the given seekable stream.
    pub fn new(reader: R) -> Self {
        Self { reader }
    }

    pub fn seek(&mut self, pos: SeekFrom) -> Result<u64> {
        Ok(self.reader.seek(pos)?)
    }

    pub fn stream_position(&mut self) -> Result<u64> {
        Ok(self.reader.stream_position()?)
    }

    /// Reads the WDB file header and all section headers.
    ///
    /// Section headers are read until a record name is encountered
    /// (names not starting with `!`).
    ///
    /// # Returns
    ///
    /// A tuple of (file header, list of section headers)
    pub fn read_headers(&mut self) -> Result<(WdbBinaryHeader, Vec<WdbSectionHeader>)> {
        let header: WdbBinaryHeader = self.reader.read_be()?;
        log::debug!(
            "WDB File Magic: {} Count: {}",
            header.magic,
            header.record_count
        );

        let mut sections = Vec::new();
        loop {
            let current_pos = self.reader.stream_position()?;

            // Peek name to check if it starts with "!!"
            let mut name_buf = [0u8; 16];
            self.reader.read_exact(&mut name_buf)?;
            self.reader.seek(SeekFrom::Start(current_pos))?; // Reset

            let name_str = String::from_utf8_lossy(&name_buf);
            if !name_str.starts_with('!') {
                log::debug!("Stopped reading sections at: {}", name_str);
                break;
            }

            let section: WdbSectionHeader = self.reader.read_be()?;
            log::trace!(
                "Section: {} (Offset: {}, Length: {})",
                section.name,
                section.offset,
                section.length
            );
            sections.push(section);
        }

        Ok((header, sections))
    }

    /// Reads raw bytes from a section.
    ///
    /// Seeks to the section's offset and reads exactly `length` bytes.
    pub fn read_section_data(&mut self, section: &WdbSectionHeader) -> Result<Vec<u8>> {
        self.reader.seek(SeekFrom::Start(section.offset as u64))?;
        let mut buffer = vec![0u8; section.length as usize];
        self.reader.read_exact(&mut buffer)?;
        Ok(buffer)
    }

    /// Parses section data as a list of big-endian u32 values.
    ///
    /// Used for `!!strtypelist` and similar numeric sections.
    pub fn parse_uint_list(data: &[u8]) -> Vec<u32> {
        data.chunks(4)
            .map(|chunk| {
                if chunk.len() == 4 {
                    u32::from_be_bytes(chunk.try_into().unwrap())
                } else {
                    0
                }
            })
            .collect()
    }

    /// Parses section data as a list of big-endian i32 values.
    ///
    /// Used for `!!typelist` sections.
    pub fn parse_int_list(data: &[u8]) -> Vec<i32> {
        data.chunks(4)
            .map(|chunk| {
                if chunk.len() == 4 {
                    i32::from_be_bytes(chunk.try_into().unwrap())
                } else {
                    0
                }
            })
            .collect()
    }

    /// Parses section data as a list of bytes (promoted to u32).
    ///
    /// Used for `!!strtypelistb` (byte-sized type list in XIII-2/LR).
    pub fn parse_u8_list(data: &[u8]) -> Vec<u32> {
        data.iter().map(|&b| b as u32).collect()
    }

    /// Parses all records from the WDB file.
    ///
    /// This is the main parsing function that iterates through records
    /// and decodes field values according to `strtypelist` type codes:
    ///
    /// - **Type 0**: Bitpacked fields - multiple values in 32 bits
    /// - **Type 1**: IEEE 754 float (f32)
    /// - **Type 2**: String offset into `!!string` section
    /// - **Type 3**: Unsigned integer (u32)
    ///
    /// # Arguments
    ///
    /// * `vars` - Parsed metadata context containing field definitions
    ///
    /// # Returns
    ///
    /// Vector of records, each as a HashMap of field name -> value
    pub fn parse_records(&mut self, vars: &WdbVariables) -> Result<Vec<WdbRecord>> {
        let mut records = Vec::new();

        let start_pos = self.reader.stream_position()?;
        let mut current_header_pos = start_pos;

        for _r in 0..vars.record_count {
            self.reader.seek(SeekFrom::Start(current_header_pos))?;

            // Read Record Header (Mini Section Header)
            let mut name_buf = [0u8; 16];
            self.reader.read_exact(&mut name_buf)?;
            let record_name = String::from_utf8_lossy(&name_buf)
                .trim_matches('\0')
                .to_string();

            let offset = self.reader.read_u32::<byteorder::BigEndian>()?;
            let length = self.reader.read_u32::<byteorder::BigEndian>()?;
            let _padding = self.reader.read_u64::<byteorder::BigEndian>()?; // Skip 8 bytes

            // Read Record Data
            self.reader.seek(SeekFrom::Start(offset as u64))?;
            let mut record_data = vec![0u8; length as usize];
            self.reader.read_exact(&mut record_data)?;

            let mut record = WdbRecord::new();
            record.insert("record".to_string(), WdbValue::String(record_name.clone())); // Changed from RecordName to record to match C# JSON

            let mut data_idx = 0;
            let mut type_idx = 0;

            // Without-fields mode: use type-based generic names and raw hex for bitpacked
            if vars.without_fields {
                let mut bitpacked_counter = 0;
                let mut float_counter = 0;
                let mut string_counter = 0;
                let mut uint_counter = 0;

                while type_idx < vars.strtypelist_values.len() {
                    let type_code = vars.strtypelist_values[type_idx];

                    match type_code {
                        0 => {
                            // Bitpacked - output as hex string
                            if data_idx + 4 > record_data.len() { break; }
                            let val_u32 = u32::from_be_bytes(
                                record_data[data_idx..data_idx + 4].try_into().unwrap(),
                            );
                            let hex_val = format!("0x{:08X}", val_u32);
                            record.insert(format!("bitpacked-field_{}", bitpacked_counter), WdbValue::String(hex_val));
                            bitpacked_counter += 1;
                            data_idx += 4;
                            type_idx += 1;
                        },
                        1 => {
                            // Float
                            if data_idx + 4 > record_data.len() { break; }
                            let val_f32 = f32::from_be_bytes(
                                record_data[data_idx..data_idx + 4].try_into().unwrap(),
                            );
                            record.insert(format!("float-field_{}", float_counter), WdbValue::Float(val_f32));
                            float_counter += 1;
                            data_idx += 4;
                            type_idx += 1;
                        },
                        2 => {
                            // String offset
                            if data_idx + 4 > record_data.len() { break; }
                            let offset = u32::from_be_bytes(
                                record_data[data_idx..data_idx + 4].try_into().unwrap(),
                            );
                            let s = derive_string(&vars.strings_data, offset as usize);
                            record.insert(format!("!!string-field_{}", string_counter), WdbValue::String(s));
                            string_counter += 1;
                            data_idx += 4;
                            type_idx += 1;
                        },
                        3 => {
                            // Uint
                            if data_idx + 4 > record_data.len() { break; }
                            let val_u32 = u32::from_be_bytes(
                                record_data[data_idx..data_idx + 4].try_into().unwrap(),
                            );
                            record.insert(format!("uint-field_{}", uint_counter), WdbValue::UInt(val_u32));
                            uint_counter += 1;
                            data_idx += 4;
                            type_idx += 1;
                        },
                        _ => {
                            type_idx += 1;
                        }
                    }
                }

                records.push(record);
                current_header_pos += 32;
                continue;
            }

            // Normal mode with known fields
            let mut f = 0;
            while f < vars.field_count && type_idx < vars.strtypelist_values.len() {
                let type_code = vars.strtypelist_values[type_idx];

                match type_code {
                    0 => {
                        // Bitpacked
                        if data_idx + 4 > record_data.len() {
                            break;
                        }
                        let val_u32 = u32::from_be_bytes(
                            record_data[data_idx..data_idx + 4].try_into().unwrap(),
                        );
                        let mut bit_reader = BitReader::new(val_u32);

                        while bit_reader.bits_remaining > 0 && f < vars.field_count {
                            let field_name = &vars.fields[f];
                            let field_type_char = field_name.chars().next().unwrap_or('?');
                            let field_bits = derive_field_number(field_name);

                            let bits_to_read = if field_bits == 0 { 32 } else { field_bits };

                            if field_bits > 0 && field_bits > bit_reader.bits_remaining {
                                bit_reader.bits_remaining = 0;
                                continue;
                            }

                            let raw_val = bit_reader.read_bits(bits_to_read).unwrap_or(0);

                            // Check if this field should be converted to an enum
                            let val = if let Some(enum_type) =
                                get_enum_type(&vars.wdb_name, field_name)
                            {
                                int_to_enum_value(enum_type, raw_val)
                            } else {
                                match field_type_char {
                                    'i' => WdbValue::Int(super::bit_helpers::sign_extend(
                                        raw_val,
                                        bits_to_read,
                                    )),
                                    'u' => WdbValue::UInt(raw_val),
                                    'f' => WdbValue::Int(super::bit_helpers::sign_extend(
                                        raw_val,
                                        bits_to_read,
                                    )), // Matching C# behavior: float packed as int is extracted as int
                                    's' => {
                                        if let Some(list) = vars.str_array_dict.get(field_name) {
                                            if (raw_val as usize) < list.len() {
                                                WdbValue::String(list[raw_val as usize].clone())
                                            } else {
                                                WdbValue::String(String::new())
                                            }
                                        } else {
                                            WdbValue::String(String::new())
                                        }
                                    }
                                    _ => WdbValue::Int(raw_val as i32),
                                }
                            };

                            record.insert(field_name.clone(), val);
                            f += 1;
                        }

                        data_idx += 4;
                        type_idx += 1;
                    }
                    1 => {
                        // Float
                        if data_idx + 4 > record_data.len() {
                            break;
                        }
                        let val_f32 = f32::from_be_bytes(
                            record_data[data_idx..data_idx + 4].try_into().unwrap(),
                        );
                        if f < vars.fields.len() {
                            record.insert(vars.fields[f].clone(), WdbValue::Float(val_f32));
                            f += 1;
                        }
                        data_idx += 4;
                        type_idx += 1;
                    }
                    2 => {
                        // String Offset
                        if data_idx + 4 > record_data.len() {
                            break;
                        }
                        let offset = u32::from_be_bytes(
                            record_data[data_idx..data_idx + 4].try_into().unwrap(),
                        );

                        let s = derive_string(&vars.strings_data, offset as usize);
                        if f < vars.fields.len() {
                            record.insert(vars.fields[f].clone(), WdbValue::String(s));
                            f += 1;
                        }

                        data_idx += 4;
                        type_idx += 1;
                    }
                    3 => {
                        // Uint
                        if data_idx + 4 > record_data.len() {
                            break;
                        }
                        let val_u32 = u32::from_be_bytes(
                            record_data[data_idx..data_idx + 4].try_into().unwrap(),
                        );
                        if f < vars.fields.len() {
                            let field_name = &vars.fields[f];
                            // Check if this field should be an enum
                            let val = if let Some(enum_type) =
                                get_enum_type(&vars.wdb_name, field_name)
                            {
                                int_to_enum_value(enum_type, val_u32)
                            } else {
                                WdbValue::UInt(val_u32)
                            };
                            record.insert(field_name.clone(), val);
                            f += 1;
                        }
                        data_idx += 4;
                        type_idx += 1;
                    }
                    _ => {
                        log::warn!("Unknown strtypelist value: {}", type_code);
                        type_idx += 1;
                    }
                }
            }

            records.push(record);
            current_header_pos += 32;
        }

        Ok(records)
    }
}

/// Extracts a null-terminated string from the string pool.
///
/// # Arguments
///
/// * `data` - The `!!string` section raw bytes
/// * `offset` - Byte offset into the string pool
///
/// # Returns
///
/// The extracted string, or empty string if offset is invalid.
pub fn derive_string(data: &[u8], offset: usize) -> String {
    if offset >= data.len() {
        return String::new();
    }
    let mut end = offset;
    while end < data.len() && data[end] != 0 {
        end += 1;
    }
    String::from_utf8_lossy(&data[offset..end]).to_string()
}
