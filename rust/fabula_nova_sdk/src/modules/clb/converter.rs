//! # CLB ↔ Java Class Converter
//!
//! This module handles conversion between CLB format (Square Enix's custom
//! bytecode container) and standard Java .class files.
//!
//! ## CLB Format Overview
//!
//! CLB files are essentially modified Java class files with:
//! - Little-endian byte order (vs Java's big-endian)
//! - Custom header structure
//! - Pointer-based constant pool (vs index-based)
//! - Heap storage for variable-length data (strings, code)
//!
//! ## CLB Header Structure
//!
//! ```text
//! Offset │ Size │ Field
//! ───────┼──────┼────────────────────────
//! 0x00   │ 4    │ Unknown / Magic
//! 0x04   │ 2    │ Minor Version
//! 0x06   │ 2    │ Major Version
//! 0x08   │ 2    │ Constant Pool Count
//! 0x0E   │ 2    │ Fields Count
//! 0x18   │ 4    │ Constant Pool Offset
//! 0x1C   │ 4    │ This Class Address
//! 0x24   │ 4    │ Super Class Address
//! 0x2C   │ 4    │ Fields Table Address
//! 0x30   │ 4    │ Methods Table Address
//! 0x34   │ 2    │ Methods Count
//! 0x38   │ 4    │ Attributes Table Address
//! 0x3C   │ 2    │ Attributes Count
//! ```
//!
//! ## Constant Pool Entry (16 bytes each)
//!
//! ```text
//! Offset │ Size │ Field
//! ───────┼──────┼──────────────
//! 0x00   │ 4    │ Tag
//! 0x04   │ 4    │ Padding
//! 0x08   │ 4    │ Data Value
//! 0x0C   │ 4    │ Address/Value
//! ```
//!
//! ## Java Class File (for reference)
//!
//! Standard .class files use big-endian, index-based constant pool,
//! and the well-known CAFEBABE magic.

use std::collections::HashMap;
use std::fs::File;
use std::io::{Cursor, Read, Write};
use std::path::Path;
use byteorder::{BigEndian, LittleEndian, ReadBytesExt, WriteBytesExt};
use thiserror::Error;

/// Error type for CLB conversion operations.
#[derive(Error, Debug)]
pub enum ClbError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Validation error: {0}")]
    Validation(String),
}

/// Result type for CLB operations.
pub type Result<T> = std::result::Result<T, ClbError>;

// Java Constant Pool Tag Constants (JVM Specification)
/// UTF-8 string
const TAG_UTF8: u32 = 1;
/// Integer literal
const TAG_INTEGER: u32 = 3;
/// Float literal
const TAG_FLOAT: u32 = 4;
/// Long literal (occupies 2 CP slots)
const TAG_LONG: u32 = 5;
/// Double literal (occupies 2 CP slots)
const TAG_DOUBLE: u32 = 6;
/// Class reference
const TAG_CLASS: u32 = 7;
/// String literal (reference to UTF8)
const TAG_STRING: u32 = 8;
/// Field reference
const TAG_FIELDREF: u32 = 9;
/// Method reference
const TAG_METHODREF: u32 = 10;
/// Interface method reference
const TAG_INTERFACE_METHODREF: u32 = 11;
/// Name and type descriptor
const TAG_NAME_AND_TYPE: u32 = 12;
/// Method handle (Java 7+)
const TAG_METHOD_HANDLE: u32 = 15;
/// Method type (Java 7+)
const TAG_METHOD_TYPE: u32 = 16;
/// Invoke dynamic (Java 7+)
const TAG_INVOKE_DYNAMIC: u32 = 18;

/// Converts a CLB file to a standard Java .class file.
///
/// This enables using standard Java decompilers (CFR, Fernflower, etc.)
/// to analyze game scripts.
///
/// # Conversion Process
///
/// 1. Read CLB header to get structure offsets
/// 2. **Pass 1**: Parse constant pool to build address→index mapping
/// 3. **Pass 2**: Write Java class file:
///    - Magic (CAFEBABE)
///    - Version numbers
///    - Constant pool (converted to big-endian, index-based)
///    - Class info (access flags, this/super class)
///    - Fields, methods, attributes
///
/// # Key Transformations
///
/// | CLB                  | Java                  |
/// |----------------------|-----------------------|
/// | Little-endian        | Big-endian            |
/// | Pointer addresses    | CP indices            |
/// | 16-byte CP entries   | Variable-size entries |
/// | Heap strings         | Inline strings        |
///
/// # Arguments
///
/// * `input_path` - Path to the CLB file
/// * `output_path` - Path to write the .class file
///
/// # Example
///
/// ```rust,ignore
/// clb_to_java(Path::new("script.clb"), Path::new("Script.class"))?;
/// // Now decompile with: java -jar cfr.jar Script.class
/// ```
pub fn clb_to_java(input_path: &Path, output_path: &Path) -> Result<()> {
    let mut input_file = File::open(input_path)?;
    let file_len = input_file.metadata()?.len();
    let mut buffer = vec![0u8; file_len as usize];
    input_file.read_exact(&mut buffer)?;

    if buffer.len() < 28 {
        return Err(ClbError::Validation("CLB file too small".into()));
    }

    let mut cursor = Cursor::new(&buffer);

    // Read CLB Header
    cursor.set_position(4);
    let minor_version = cursor.read_u16::<LittleEndian>()?;
    let major_version = cursor.read_u16::<LittleEndian>()?;
    let cp_count = cursor.read_u16::<LittleEndian>()?;

    cursor.set_position(0x18);
    let cp_offset = cursor.read_u32::<LittleEndian>()? as u64;
    let this_class_addr = cursor.read_u32::<LittleEndian>()?;
    
    cursor.set_position(0x24);
    let super_class_addr = cursor.read_u32::<LittleEndian>()?;
    
    cursor.set_position(0x2C);
    let fields_table_addr = cursor.read_u32::<LittleEndian>()? as u64;

    log::info!("[CLB] Header: minor={}, major={}, cp_count={}, cp_offset={}, this_class_addr={}, super_class_addr={}, fields_table_addr={}", 
               minor_version, major_version, cp_count, cp_offset, this_class_addr, super_class_addr, fields_table_addr);

    // Pass 1: Parse CP to get Strings (for attribute parsing) AND find heap end AND build address map
    let mut cp_strings = HashMap::new();
    let mut addr_to_index = HashMap::new();
    let mut current_cp_offset = cp_offset;
    let mut max_heap_addr = cp_offset + (cp_count as u64 * 16);

    // Check for dummy entry 0 at the start of the pool
    cursor.set_position(current_cp_offset);
    if let Ok(0) = cursor.read_u32::<LittleEndian>() {
        addr_to_index.insert(current_cp_offset as u32, 0u16);
        current_cp_offset += 16;
    }

    let mut i = 1;
    while i < cp_count {
        addr_to_index.insert(current_cp_offset as u32, i);
        cursor.set_position(current_cp_offset);
        let tag = match cursor.read_u32::<LittleEndian>() {
            Ok(t) => t,
            Err(_) => break,
        };
        let _padding = cursor.read_u32::<LittleEndian>()?;
        let data_val = cursor.read_u32::<LittleEndian>()?;
        let addr_val = cursor.read_u32::<LittleEndian>()?;

        if tag == TAG_UTF8 {
            let length = data_val;
            let str_addr = addr_val;
            
            // Map the string data address itself to this index (Tag 7 pointers)
            addr_to_index.insert(str_addr, i);

            if (str_addr as u64 + length as u64) > max_heap_addr {
                max_heap_addr = str_addr as u64 + length as u64;
            }

            let mut str_cursor = Cursor::new(&buffer);
            str_cursor.set_position(str_addr as u64);
            let mut str_bytes = vec![0u8; length as usize];
            if str_cursor.read_exact(&mut str_bytes).is_ok() {
                if let Ok(s) = String::from_utf8(str_bytes) {
                    cp_strings.insert(i, s);
                }
            }
        } else if tag == TAG_LONG || tag == TAG_DOUBLE {
            i += 1;
        }

        current_cp_offset += 16;
        i += 1;
    }

    // Pass 2: Write Output
    let mut output_file = File::create(output_path)?;
    output_file.write_u32::<BigEndian>(0xCAFEBABE)?;
    output_file.write_u16::<BigEndian>(minor_version)?;
    output_file.write_u16::<BigEndian>(major_version)?;
    output_file.write_u16::<BigEndian>(cp_count)?;

    current_cp_offset = cp_offset;
    // Check for dummy entry 0 again for Pass 2
    cursor.set_position(current_cp_offset);
    if let Ok(0) = cursor.read_u32::<LittleEndian>() {
        current_cp_offset += 16;
    }

    i = 1;
    while i < cp_count {
        cursor.set_position(current_cp_offset);
        let tag = cursor.read_u32::<LittleEndian>()?;
        let _padding = cursor.read_u32::<LittleEndian>()?;
        let data_val = cursor.read_u32::<LittleEndian>()?;
        let addr_val = cursor.read_u32::<LittleEndian>()?;

        output_file.write_u8(tag as u8)?;

        match tag {
            TAG_UTF8 => {
                let length = data_val;
                let str_addr = addr_val;
                output_file.write_u16::<BigEndian>(length as u16)?;
                
                let mut str_cursor = Cursor::new(&buffer);
                str_cursor.set_position(str_addr as u64);
                let mut str_bytes = vec![0u8; length as usize];
                str_cursor.read_exact(&mut str_bytes)?;
                output_file.write_all(&str_bytes)?;
            }
            TAG_INTEGER => output_file.write_i32::<BigEndian>(data_val as i32)?,
            TAG_FLOAT => {
                output_file.write_u32::<BigEndian>(data_val.swap_bytes())?;
            }
            TAG_LONG => {
                cursor.set_position(current_cp_offset + 8);
                let val_i64 = cursor.read_i64::<LittleEndian>()?;
                output_file.write_i64::<BigEndian>(val_i64)?;
                i += 1;
                current_cp_offset += 16;
            }
            TAG_DOUBLE => {
                cursor.set_position(current_cp_offset + 8);
                let val_f64 = cursor.read_f64::<LittleEndian>()?;
                output_file.write_f64::<BigEndian>(val_f64)?;
                i += 1;
                current_cp_offset += 16;
            }
            TAG_CLASS => {
                let name_index = addr_to_index.get(&data_val).copied().unwrap_or(0);
                output_file.write_u16::<BigEndian>(name_index)?;
            }
            TAG_STRING => {
                output_file.write_u16::<BigEndian>(data_val as u16)?;
            }
            TAG_FIELDREF | TAG_METHODREF | TAG_INTERFACE_METHODREF | TAG_NAME_AND_TYPE => {
                output_file.write_u16::<BigEndian>(data_val as u16)?;
                output_file.write_u16::<BigEndian>(addr_val as u16)?;
            }
            TAG_METHOD_HANDLE => {
                let kind = (data_val & 0xFF) as u8;
                let index = ((data_val >> 8) & 0xFFFF) as u16;
                output_file.write_u8(kind)?;
                output_file.write_u16::<BigEndian>(index)?;
            }
            TAG_METHOD_TYPE => output_file.write_u16::<BigEndian>(data_val as u16)?,
            TAG_INVOKE_DYNAMIC => {
                output_file.write_u32::<BigEndian>(data_val.swap_bytes())?;
            }
            _ => return Err(ClbError::Validation(format!("Unknown CP tag: {} at index {}", tag, i))),
        }

        current_cp_offset += 16;
        i += 1;
    }

    // Hardcode headers as per spec
    output_file.write_u16::<BigEndian>(0x0001)?;
    let this_class_idx = addr_to_index.get(&this_class_addr).copied().unwrap_or(0);
    let super_class_idx = addr_to_index.get(&super_class_addr).copied().unwrap_or(0);
    output_file.write_u16::<BigEndian>(this_class_idx)?;
    output_file.write_u16::<BigEndian>(super_class_idx)?;
    output_file.write_u16::<BigEndian>(0)?; // Interfaces Count

    // Fields
    cursor.set_position(0x0E);
    let fields_count = cursor.read_u16::<LittleEndian>()?;
    output_file.write_u16::<BigEndian>(fields_count)?;

    if fields_count > 0 && fields_table_addr > 0 {
        cursor.set_position(fields_table_addr);
        for _ in 0..fields_count {
            let entry_start = cursor.position();
            copy_clb_member_to_java(&mut cursor, &mut output_file, &cp_strings, &addr_to_index)?;
            cursor.set_position(entry_start + 24);
        }
    }

    // Methods
    cursor.set_position(0x30);
    let methods_table_addr = cursor.read_u32::<LittleEndian>()? as u64;
    cursor.set_position(0x34);
    let methods_count = cursor.read_u16::<LittleEndian>()?;
    
    output_file.write_u16::<BigEndian>(methods_count)?;
    if methods_count > 0 && methods_table_addr > 0 {
        cursor.set_position(methods_table_addr);
        for _ in 0..methods_count {
            let entry_start = cursor.position();
            copy_clb_member_to_java(&mut cursor, &mut output_file, &cp_strings, &addr_to_index)?;
            cursor.set_position(entry_start + 24);
        }
    }

    // Attributes
    cursor.set_position(0x38);
    let attr_table_addr = cursor.read_u32::<LittleEndian>()? as u64;
    cursor.set_position(0x3C);
    let attributes_count = cursor.read_u16::<LittleEndian>()?;
    
    output_file.write_u16::<BigEndian>(attributes_count)?;
    if attributes_count > 0 && attr_table_addr > 0 {
        cursor.set_position(attr_table_addr);
        for _ in 0..attributes_count {
            copy_clb_attribute_to_java(&mut cursor, &mut output_file, &cp_strings, &addr_to_index)?;
        }
    }

    Ok(())
}

fn copy_clb_member_to_java(
    cursor: &mut Cursor<&Vec<u8>>,
    output: &mut File,
    cp_strings: &HashMap<u16, String>,
    addr_to_index: &HashMap<u32, u16>,
) -> Result<()> {
    let access = cursor.read_u16::<LittleEndian>()?;
    let name_index = cursor.read_u16::<LittleEndian>()?;
    let desc_index = cursor.read_u16::<LittleEndian>()?;
    let attr_count = cursor.read_u16::<LittleEndian>()?;
    let attr_table_addr = cursor.read_u32::<LittleEndian>()? as u64;

    output.write_u16::<BigEndian>(access)?;
    output.write_u16::<BigEndian>(name_index)?;
    output.write_u16::<BigEndian>(desc_index)?;
    output.write_u16::<BigEndian>(attr_count)?;

    if attr_count > 0 && attr_table_addr > 0 {
        let saved_pos = cursor.position();
        cursor.set_position(attr_table_addr);
        for _ in 0..attr_count {
            copy_clb_attribute_to_java(cursor, output, cp_strings, addr_to_index)?;
        }
        cursor.set_position(saved_pos);
    }
    
    Ok(())
}

fn copy_clb_attribute_to_java(
    cursor: &mut Cursor<&Vec<u8>>,
    output: &mut File,
    cp_strings: &HashMap<u16, String>,
    addr_to_index: &HashMap<u32, u16>,
) -> Result<()> {
    let name_addr = cursor.read_u32::<LittleEndian>()?;
    let data_addr = cursor.read_u32::<LittleEndian>()?;
    
    let name_index = addr_to_index.get(&name_addr).copied().unwrap_or(0);
    output.write_u16::<BigEndian>(name_index)?;
    
    if let Some(name) = cp_strings.get(&name_index) {
        if name == "ConstantValue" {
            let val_index = addr_to_index.get(&data_addr).copied().unwrap_or(0);
            output.write_u32::<BigEndian>(2)?;
            output.write_u16::<BigEndian>(val_index)?;
            return Ok(());
        }
    }
    output.write_u32::<BigEndian>(0)?;
    Ok(())
}

// ============================================================================
// Java-To-CLB Converter
// ============================================================================

/// Parsed Java constant pool entry for conversion.
#[derive(Debug, Clone)]
struct JavaCpEntry {
    /// Constant pool tag (1=UTF8, 3=Integer, etc.)
    tag: u8,
    /// Raw data bytes (format depends on tag)
    data: Vec<u8>,
}

/// Converts a Java .class file to CLB format.
///
/// This is the reverse of [`clb_to_java`], allowing modified/custom scripts
/// to be packed back into game format.
///
/// # Conversion Process
///
/// 1. Read Java class file (verify CAFEBABE magic)
/// 2. Parse constant pool entries
/// 3. Build CLB structures:
///    - Convert CP entries to 16-byte format
///    - Move strings to heap area
///    - Convert indices to pointers
///    - Write fields, methods, attributes
///
/// # Key Transformations
///
/// | Java                  | CLB                   |
/// |-----------------------|-----------------------|
/// | Big-endian            | Little-endian         |
/// | CP indices            | Pointer addresses     |
/// | Variable-size CP      | 16-byte fixed entries |
/// | Inline strings        | Heap strings          |
///
/// # Arguments
///
/// * `input_path` - Path to the Java .class file
/// * `output_path` - Path to write the CLB file
///
/// # Example
///
/// ```rust,ignore
/// // After modifying decompiled Java source and recompiling:
/// java_to_clb(Path::new("Script.class"), Path::new("script.clb"))?;
/// ```
pub fn java_to_clb(input_path: &Path, output_path: &Path) -> Result<()> {
    let mut input_file = File::open(input_path)?;
    let mut buffer = Vec::new();
    input_file.read_to_end(&mut buffer)?;

    let mut cursor = Cursor::new(&buffer);
    if cursor.read_u32::<BigEndian>()? != 0xCAFEBABE {
        return Err(ClbError::Validation("Invalid Java Class Magic".into()));
    }

    let minor_version = cursor.read_u16::<BigEndian>()?;
    let major_version = cursor.read_u16::<BigEndian>()?;
    let cp_count = cursor.read_u16::<BigEndian>()?;

    let mut java_cp = Vec::new();
    java_cp.push(JavaCpEntry { tag: 0, data: vec![] });

    let mut i = 1;
    while i < cp_count {
        let tag = cursor.read_u8()?;
        let mut entry = JavaCpEntry { tag, data: vec![] };
        match tag as u32 {
            TAG_UTF8 => {
                let len = cursor.read_u16::<BigEndian>()?;
                let mut str_bytes = vec![0u8; len as usize];
                cursor.read_exact(&mut str_bytes)?;
                entry.data = str_bytes;
            },
            TAG_INTEGER | TAG_FLOAT => {
                let mut bytes = vec![0u8; 4];
                cursor.read_exact(&mut bytes)?;
                entry.data = bytes;
            },
            TAG_LONG | TAG_DOUBLE => {
                let mut bytes = vec![0u8; 8];
                cursor.read_exact(&mut bytes)?;
                entry.data = bytes;
                java_cp.push(entry.clone());
                entry = JavaCpEntry { tag: 0, data: vec![] };
                i += 1;
            },
            TAG_CLASS | TAG_STRING | TAG_METHOD_TYPE => {
                let mut bytes = vec![0u8; 2];
                cursor.read_exact(&mut bytes)?;
                entry.data = bytes;
            },
            TAG_FIELDREF | TAG_METHODREF | TAG_INTERFACE_METHODREF | TAG_NAME_AND_TYPE | TAG_INVOKE_DYNAMIC => {
                let mut bytes = vec![0u8; 4];
                cursor.read_exact(&mut bytes)?;
                entry.data = bytes;
            },
            TAG_METHOD_HANDLE => {
                let mut bytes = vec![0u8; 3];
                cursor.read_exact(&mut bytes)?;
                entry.data = bytes;
            },
            _ => return Err(ClbError::Validation(format!("Unknown Java CP tag: {}", tag))),
        }
        java_cp.push(entry);
        i += 1;
    }

    let mut clb_cp_bytes = Vec::new();
    let mut heap_bytes = Vec::new();
    let cp_array_offset = 56u32;
    let cp_entries_size = (cp_count as u32) * 16;
    let mut current_heap_offset = cp_array_offset + cp_entries_size;

    clb_cp_bytes.write_all(&[0u8; 16])?;

    for entry in java_cp.iter().skip(1) {
        let mut clb_entry = vec![0u8; 16];
        let mut cursor_entry = Cursor::new(&mut clb_entry);
        cursor_entry.write_u32::<LittleEndian>(entry.tag as u32)?;
        cursor_entry.write_u32::<LittleEndian>(0)?;

        match entry.tag as u32 {
            TAG_UTF8 => {
                let len = entry.data.len() as u32;
                cursor_entry.write_u32::<LittleEndian>(len)?;
                cursor_entry.write_u32::<LittleEndian>(current_heap_offset)?;
                heap_bytes.write_all(&entry.data)?;
                current_heap_offset += len;
            },
            TAG_INTEGER | TAG_FLOAT => {
                let val = u32::from_be_bytes([entry.data[0], entry.data[1], entry.data[2], entry.data[3]]);
                cursor_entry.write_u32::<LittleEndian>(val)?;
            },
            TAG_LONG | TAG_DOUBLE => {
                let val = u64::from_be_bytes([
                    entry.data[0], entry.data[1], entry.data[2], entry.data[3],
                    entry.data[4], entry.data[5], entry.data[6], entry.data[7]
                ]);
                cursor_entry.write_u64::<LittleEndian>(val)?;
            },
            TAG_CLASS => {
                let name_idx = u16::from_be_bytes([entry.data[0], entry.data[1]]);
                let name_addr = cp_array_offset + (name_idx as u32 * 16);
                cursor_entry.write_u32::<LittleEndian>(name_addr)?;
            },
            TAG_STRING | TAG_METHOD_TYPE => {
                let val = u16::from_be_bytes([entry.data[0], entry.data[1]]);
                cursor_entry.write_u32::<LittleEndian>(val as u32)?;
            },
            TAG_FIELDREF | TAG_METHODREF | TAG_INTERFACE_METHODREF | TAG_NAME_AND_TYPE => {
                 let val1 = u16::from_be_bytes([entry.data[0], entry.data[1]]);
                 let val2 = u16::from_be_bytes([entry.data[2], entry.data[3]]);
                 cursor_entry.write_u32::<LittleEndian>(val1 as u32)?;
                 cursor_entry.write_u32::<LittleEndian>(val2 as u32)?;
            },
            TAG_METHOD_HANDLE => {
                let kind = entry.data[0];
                let index = u16::from_be_bytes([entry.data[1], entry.data[2]]);
                cursor_entry.write_u32::<LittleEndian>((kind as u32) | ((index as u32) << 8))?;
            },
            TAG_INVOKE_DYNAMIC => {
                 let val = u32::from_be_bytes([entry.data[0], entry.data[1], entry.data[2], entry.data[3]]);
                 cursor_entry.write_u32::<LittleEndian>(val.swap_bytes())?;
            },
            _ => {}
        }
        clb_cp_bytes.write_all(&clb_entry)?;
    }
    
    let mut clb_body_bytes = Vec::new();
    let mut clb_body = Cursor::new(&mut clb_body_bytes);
    let access_flags = cursor.read_u16::<BigEndian>()?;
    let this_class_idx = cursor.read_u16::<BigEndian>()?;
    let super_class_idx = cursor.read_u16::<BigEndian>()?;
    clb_body.write_u16::<LittleEndian>(access_flags)?;
    clb_body.write_u16::<LittleEndian>(this_class_idx)?;
    clb_body.write_u16::<LittleEndian>(super_class_idx)?;

    let this_class_addr = cp_array_offset + (this_class_idx as u32 * 16);
    let super_class_addr = cp_array_offset + (super_class_idx as u32 * 16);
    
    let interfaces_count = cursor.read_u16::<BigEndian>()?;
    clb_body.write_u16::<LittleEndian>(interfaces_count)?;
    for _ in 0..interfaces_count {
        clb_body.write_u16::<LittleEndian>(cursor.read_u16::<BigEndian>()?)?;
    }
    
    let fields_count = cursor.read_u16::<BigEndian>()?;
    clb_body.write_u16::<LittleEndian>(fields_count)?;
    let mut attr_heap = Vec::new();
    let mut current_attr_ptr = cp_array_offset + cp_entries_size + heap_bytes.len() as u32 + 2000; // Speculative
    
    for _ in 0..fields_count {
        copy_java_member_to_clb(&mut cursor, &mut clb_body, &java_cp, cp_array_offset, &mut current_attr_ptr, &mut attr_heap)?;
    }
    
    let methods_count = cursor.read_u16::<BigEndian>()?;
    clb_body.write_u16::<LittleEndian>(methods_count)?;
    for _ in 0..methods_count {
        copy_java_member_to_clb(&mut cursor, &mut clb_body, &java_cp, cp_array_offset, &mut current_attr_ptr, &mut attr_heap)?;
    }
    
    let attributes_count = cursor.read_u16::<BigEndian>()?;
    clb_body.write_u16::<LittleEndian>(attributes_count)?;

    let mut output_file = File::create(output_path)?;
    output_file.write_u32::<LittleEndian>(0)?; 
    output_file.write_u16::<LittleEndian>(minor_version)?;
    output_file.write_u16::<LittleEndian>(major_version)?;
    output_file.write_u16::<LittleEndian>(cp_count)?;
    output_file.write_all(&[0u8; 10])?;
    output_file.write_u16::<LittleEndian>(fields_count)?;
    output_file.write_all(&[0u8; 8])?;
    output_file.write_u32::<LittleEndian>(cp_array_offset)?;
    output_file.write_u32::<LittleEndian>(this_class_addr)?;
    output_file.write_u32::<LittleEndian>(0)?;
    output_file.write_u32::<LittleEndian>(super_class_addr)?;
    output_file.write_u32::<LittleEndian>(0)?;
    output_file.write_u32::<LittleEndian>(56 + clb_cp_bytes.len() as u32 + heap_bytes.len() as u32 + 8)?;
    for _ in 0..8 { output_file.write_u8(0)?; }
    output_file.write_all(&clb_cp_bytes)?;
    output_file.write_all(&heap_bytes)?;
    output_file.write_all(&clb_body_bytes)?;
    output_file.write_all(&attr_heap)?;
    Ok(())
}

fn copy_java_member_to_clb(
    cursor: &mut Cursor<&Vec<u8>>,
    output: &mut Cursor<&mut Vec<u8>>,
    cp: &[JavaCpEntry],
    cp_array_offset: u32,
    current_attr_ptr: &mut u32,
    attr_heap: &mut Vec<u8>,
) -> Result<()> {
    let access = cursor.read_u16::<BigEndian>()?;
    let name = cursor.read_u16::<BigEndian>()?;
    let desc = cursor.read_u16::<BigEndian>()?;
    let attr_count = cursor.read_u16::<BigEndian>()?;
    output.write_u16::<LittleEndian>(access)?;
    output.write_u16::<LittleEndian>(name)?;
    output.write_u16::<LittleEndian>(desc)?;
    output.write_u16::<LittleEndian>(attr_count)?;
    
    if attr_count > 0 {
        output.write_u32::<LittleEndian>(*current_attr_ptr)?;
        for _ in 0..attr_count {
            copy_java_attribute_to_clb(cursor, cp, cp_array_offset, attr_heap)?;
            *current_attr_ptr += 16;
        }
    } else {
        output.write_u32::<LittleEndian>(0)?;
    }
    for _ in 0..12 { output.write_u8(0)?; }
    Ok(())
}

fn copy_java_attribute_to_clb(
    cursor: &mut Cursor<&Vec<u8>>,
    cp: &[JavaCpEntry],
    cp_array_offset: u32,
    attr_heap: &mut Vec<u8>,
) -> Result<()> {
    let name_idx = cursor.read_u16::<BigEndian>()?;
    let len = cursor.read_u32::<BigEndian>()?;
    let mut attr_data = vec![0u8; len as usize];
    cursor.read_exact(&mut attr_data)?;
    let name_addr = cp_array_offset + (name_idx as u32 * 16);
    attr_heap.write_u32::<LittleEndian>(name_addr)?;
    let mut is_const = false;
    if let Some(entry) = cp.get(name_idx as usize) {
        if entry.tag == TAG_UTF8 as u8 {
            if let Ok(name) = String::from_utf8(entry.data.clone()) {
                if name == "ConstantValue" { is_const = true; }
            }
        }
    }
    if is_const {
        let val_idx = u16::from_be_bytes([attr_data[0], attr_data[1]]);
        attr_heap.write_u32::<LittleEndian>(cp_array_offset + (val_idx as u32 * 16))?;
    } else {
        attr_heap.write_u32::<LittleEndian>(0)?;
    }
    attr_heap.write_u32::<LittleEndian>(0)?;
    attr_heap.write_u32::<LittleEndian>(0)?;
    Ok(())
}
