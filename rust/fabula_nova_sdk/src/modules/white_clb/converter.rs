//! # WHITE_CLB Converter
//!
//! Bidirectional converter between CLB (Crystal Logic Bytecode) and Java .class files.
//!
//! ## Overview
//!
//! CLB is Square Enix's custom bytecode format used for game logic in FF13.
//! While similar to Java bytecode, CLB uses different binary layouts:
//!
//! | Aspect              | Java .class            | CLB                    |
//! |---------------------|------------------------|------------------------|
//! | Byte order          | Big-endian             | Little-endian          |
//! | CP references       | Index-based (u16)      | Pointer-based (u32)    |
//! | CP entry size       | Variable               | Fixed 16 bytes         |
//! | Magic number        | `CAFEBABE`             | `TRBT` or none         |
//! | String storage      | Inline in CP           | Separate data section  |
//!
//! ## Conversion Flow
//!
//! ### CLB → Java
//!
//! ```text
//! ┌─────────────────┐
//! │   CLB Header    │──── Extract version, counts, pointers
//! └────────┬────────┘
//!          ▼
//! ┌─────────────────┐
//! │  Constant Pool  │──── Build address→index mapping
//! │  (16-byte fixed)│     Collect UTF-8 string addresses
//! └────────┬────────┘
//!          ▼
//! ┌─────────────────┐
//! │  Fields/Methods │──── Convert pointer refs to indices
//! │   Attributes    │     Copy bytecode directly
//! └────────┬────────┘
//!          ▼
//! ┌─────────────────┐
//! │  Java .class    │──── Write big-endian, variable-size CP
//! └─────────────────┘
//! ```
//!
//! ### Java → CLB
//!
//! ```text
//! ┌─────────────────┐
//! │  Java .class    │──── Parse CP, fields, methods, attributes
//! └────────┬────────┘
//!          ▼
//! ┌─────────────────┐
//! │  Layout Calc    │──── Compute sizes and addresses for each section
//! └────────┬────────┘
//!          ▼
//! ┌─────────────────┐
//! │  CLB Builder    │──── Write header, CP, string pool,
//! │                 │     fields, methods, code, footer
//! └─────────────────┘
//! ```
//!
//! ## CLB File Layout
//!
//! ```text
//! Offset │ Size  │ Field
//! ───────┼───────┼──────────────────────────────
//! 0x00   │ 4     │ Magic ("TRBT" or zeros)
//! 0x04   │ 2     │ Minor version
//! 0x06   │ 2     │ Major version
//! 0x08   │ 2     │ Constant pool count
//! 0x0E   │ 2     │ Field count
//! 0x10   │ 4     │ Method count
//! 0x18   │ 4     │ First CP entry address
//! 0x1C   │ 4     │ This class CP address
//! 0x24   │ 4     │ Super class CP address
//! 0x2C   │ 4     │ Fields table address
//! 0x30   │ 4     │ Methods table address
//! 0x38   │ 4     │ Class attributes address
//! 0x3C   │ 2     │ Class attributes count
//! ```
//!
//! ## Constant Pool Entry (16 bytes)
//!
//! ```text
//! Offset │ Size │ Field
//! ───────┼──────┼─────────────────────────
//! 0      │ 4    │ Tag (1=UTF8, 7=Class, etc.)
//! 4      │ 4    │ Reserved/padding
//! 8      │ 4-8  │ Data (varies by tag)
//! ```
//!
//! ### Tag-Specific Data
//!
//! | Tag | Type             | Data Layout                          |
//! |-----|------------------|--------------------------------------|
//! | 1   | UTF-8            | +8: length, +12: string address      |
//! | 3   | Integer          | +8: value (i32)                      |
//! | 4   | Float            | +8: value (f32)                      |
//! | 5   | Long             | +8: value (i64)                      |
//! | 6   | Double           | +8: value (f64)                      |
//! | 7   | Class            | +8: name string address              |
//! | 8   | String           | +8: UTF-8 index (u16)                |
//! | 9   | Fieldref         | +8: class idx, +10: name_type idx    |
//! | 10  | Methodref        | +8: class idx, +10: name_type idx    |
//! | 11  | InterfaceMethod  | +8: class idx, +10: name_type idx    |
//! | 12  | NameAndType      | +8: name idx, +10: descriptor idx    |

use std::collections::HashMap;
use std::path::Path;
use thiserror::Error;

/// Errors that can occur during CLB/Java conversion.
#[derive(Error, Debug)]
pub enum WhiteClbError {
    /// File I/O operation failed.
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    /// Data validation failed (invalid magic, malformed structure, etc.).
    #[error("Validation error: {0}")]
    Validation(String),
}

/// Result type for WHITE_CLB operations.
pub type Result<T> = std::result::Result<T, WhiteClbError>;

/// Converts CLB bytecode to Java .class format.
///
/// This function performs a two-pass conversion:
///
/// ## Pass 1: Index Mapping
///
/// Scans the CLB constant pool to build mappings between:
/// - CLB CP addresses → Java CP indices
/// - CLB CP indices → Java CP indices
/// - UTF-8 string addresses → Java CP indices
///
/// This is necessary because CLB uses 32-bit pointers while Java uses
/// 16-bit indices.
///
/// ## Pass 2: Data Conversion
///
/// Writes the Java .class file with:
/// 1. Magic (`CAFEBABE`) and version info
/// 2. Constant pool (variable-size entries, big-endian)
/// 3. Class metadata (access flags, this/super class)
/// 4. Fields with attributes
/// 5. Methods with Code attributes
/// 6. Class-level attributes
///
/// ## Constant Pool Tag Handling
///
/// | Tag | Java Size | Conversion Notes                          |
/// |-----|-----------|-------------------------------------------|
/// | 1   | 2+N       | UTF-8: length prefix + bytes              |
/// | 3   | 4         | Integer: swap endianness                  |
/// | 4   | 4         | Float: reverse byte order                 |
/// | 5   | 8         | Long: reverse bytes, creates 2 slots      |
/// | 6   | 8         | Double: reverse bytes, creates 2 slots    |
/// | 7   | 2         | Class: resolve string address to index    |
/// | 8   | 2         | String: convert CLB index to Java index   |
/// | 9-12| 4         | Refs: convert both indices                |
///
/// # Arguments
///
/// * `clb_data` - Raw CLB file bytes
///
/// # Returns
///
/// Complete Java .class file as byte vector.
///
/// # Example
///
/// ```rust,ignore
/// let clb_bytes = std::fs::read("script.clb")?;
/// let java_bytes = clb_to_java(&clb_bytes)?;
/// std::fs::write("Script.class", java_bytes)?;
/// ```
pub fn clb_to_java(clb_data: &[u8]) -> Result<Vec<u8>> {
    let first_cp_addr = u32::from_le_bytes([
        clb_data[0x18], clb_data[0x19], clb_data[0x1A], clb_data[0x1B]
    ]) as usize;
    let cp_count = u16::from_le_bytes([clb_data[8], clb_data[9]]);

    let mut cp_strings = HashMap::new();
    let mut addr_to_java_idx: HashMap<u32, u16> = HashMap::new();
    let mut clb_idx_to_java_idx: HashMap<u16, u16> = HashMap::new();
    let mut string_addr_to_java_idx: HashMap<u32, u16> = HashMap::new();

    // Pass 1: Build the CLB-to-Java index mapping
    // Entry 0 is reserved, entries 1 to cp_count-1 are valid
    // CLB index c_idx corresponds to entry at first_cp_addr + c_idx*16
    let mut java_idx = 1u16;
    for c_idx in 1..cp_count {
        let cp_addr = first_cp_addr + (c_idx as usize) * 16;
        let tag = u32::from_le_bytes([clb_data[cp_addr], clb_data[cp_addr+1], clb_data[cp_addr+2], clb_data[cp_addr+3]]);
        if tag > 18 { break; }
        if tag != 0 {
            clb_idx_to_java_idx.insert(c_idx, java_idx);
            addr_to_java_idx.insert(cp_addr as u32, java_idx);

            if tag == 1 { // UTF-8
                let str_addr = u32::from_le_bytes([clb_data[cp_addr+12], clb_data[cp_addr+13], clb_data[cp_addr+14], clb_data[cp_addr+15]]);
                string_addr_to_java_idx.insert(str_addr, java_idx);
            }

            if tag == 5 || tag == 6 { java_idx += 1; }
            java_idx += 1;
        }
    }

    let mut java_data = Vec::new();
    java_data.extend_from_slice(&[0xCA, 0xFE, 0xBA, 0xBE]); // Magic
    java_data.extend_from_slice(&u16::from_le_bytes([clb_data[4], clb_data[5]]).to_be_bytes()); // Minor
    java_data.extend_from_slice(&u16::from_le_bytes([clb_data[6], clb_data[7]]).to_be_bytes()); // Major
    java_data.extend_from_slice(&java_idx.to_be_bytes()); // Java CP Count

    // Pass 2: Write Java CP entries
    let mut current_java_idx = 1u16;
    for c_idx in 1..cp_count {
        let cp_addr = first_cp_addr + (c_idx as usize) * 16;
        let tag = u32::from_le_bytes([clb_data[cp_addr], clb_data[cp_addr+1], clb_data[cp_addr+2], clb_data[cp_addr+3]]);
        if tag > 18 { break; }
        if tag != 0 {
            java_data.push(tag as u8);
            match tag {
                1 => {
                    let str_len = u32::from_le_bytes([clb_data[cp_addr+8], clb_data[cp_addr+9], clb_data[cp_addr+10], clb_data[cp_addr+11]]) as u16;
                    let str_addr = u32::from_le_bytes([clb_data[cp_addr+12], clb_data[cp_addr+13], clb_data[cp_addr+14], clb_data[cp_addr+15]]) as usize;
                    java_data.extend_from_slice(&str_len.to_be_bytes());
                    java_data.extend_from_slice(&clb_data[str_addr..str_addr + str_len as usize]);
                    if let Ok(s) = String::from_utf8(clb_data[str_addr..str_addr + str_len as usize].to_vec()) {
                        cp_strings.insert(current_java_idx, s);
                    }
                }
                3 => java_data.extend_from_slice(&i32::from_le_bytes([clb_data[cp_addr+8], clb_data[cp_addr+9], clb_data[cp_addr+10], clb_data[cp_addr+11]]).to_be_bytes()),
                4 => java_data.extend_from_slice(&[clb_data[cp_addr+11], clb_data[cp_addr+10], clb_data[cp_addr+9], clb_data[cp_addr+8]]),
                5 | 6 => {
                    let mut bytes: [u8; 8] = clb_data[cp_addr + 8..cp_addr + 16].try_into().unwrap();
                    bytes.reverse();
                    java_data.extend_from_slice(&bytes);
                    current_java_idx += 1;
                }
                7 => {
                    // Tag 7 (Class): name pointer at +0x08 points to UTF-8 string data address
                    let name_ptr = u32::from_le_bytes([clb_data[cp_addr+8], clb_data[cp_addr+9], clb_data[cp_addr+10], clb_data[cp_addr+11]]);
                    let name_idx = string_addr_to_java_idx.get(&name_ptr).copied().unwrap_or(0);
                    java_data.extend_from_slice(&name_idx.to_be_bytes());
                }
                8 | 16 => {
                    let old_idx = u16::from_le_bytes([clb_data[cp_addr+8], clb_data[cp_addr+9]]);
                    java_data.extend_from_slice(&clb_idx_to_java_idx.get(&old_idx).copied().unwrap_or(0).to_be_bytes());
                }
                9 | 10 | 11 | 12 => {
                    // Tags 9-12: Both indices are packed at +0x08 as two consecutive u16 LE
                    let old_idx1 = u16::from_le_bytes([clb_data[cp_addr+8], clb_data[cp_addr+9]]);
                    let old_idx2 = u16::from_le_bytes([clb_data[cp_addr+10], clb_data[cp_addr+11]]);
                    java_data.extend_from_slice(&clb_idx_to_java_idx.get(&old_idx1).copied().unwrap_or(0).to_be_bytes());
                    java_data.extend_from_slice(&clb_idx_to_java_idx.get(&old_idx2).copied().unwrap_or(0).to_be_bytes());
                }
                15 => {
                    let mut bytes = [clb_data[cp_addr+8], clb_data[cp_addr+9], clb_data[cp_addr+10]];
                    bytes.reverse();
                    java_data.extend_from_slice(&bytes);
                }
                18 => {
                    let mut bytes: [u8; 4] = clb_data[cp_addr + 8..cp_addr + 12].try_into().unwrap();
                    bytes.reverse();
                    java_data.extend_from_slice(&bytes);
                }
                _ => {}
            }
            current_java_idx += 1;
        }
    }

    // Class Metadata
    java_data.extend_from_slice(&0x0001u16.to_be_bytes()); // ACC_PUBLIC
    let this_ptr = u32::from_le_bytes([clb_data[0x1C], clb_data[0x1D], clb_data[0x1E], clb_data[0x1F]]);
    java_data.extend_from_slice(&addr_to_java_idx.get(&this_ptr).copied().unwrap_or(0).to_be_bytes());
    let super_ptr = u32::from_le_bytes([clb_data[0x24], clb_data[0x25], clb_data[0x26], clb_data[0x27]]);
    java_data.extend_from_slice(&addr_to_java_idx.get(&super_ptr).copied().unwrap_or(0).to_be_bytes());
    java_data.extend_from_slice(&0u16.to_be_bytes()); // interfaces_count

    // STEP 10: Fields
    // Field entry structure (24 bytes):
    //   +0-1: access_flags
    //   +2-3: name_idx
    //   +4-5: desc_idx
    //   +6-7: attr_count
    //   +8-11: attr_table_addr
    let field_count = u16::from_le_bytes([clb_data[0x0E], clb_data[0x0F]]);
    java_data.extend_from_slice(&field_count.to_be_bytes());
    let fields_addr = u32::from_le_bytes([clb_data[0x2C], clb_data[0x2D], clb_data[0x2E], clb_data[0x2F]]) as usize;
    if fields_addr > 0 && field_count > 0 {
        for i in 0..field_count {
            let f_addr = fields_addr + (i as usize) * 24;
            write_field_to_java(clb_data, f_addr, &mut java_data, &cp_strings, &addr_to_java_idx, &string_addr_to_java_idx, &clb_idx_to_java_idx)?;
        }
    }

    // STEP 11: Methods
    // Method entry structure (24 bytes):
    //   +0-1: access_flags
    //   +2-3: name_idx (CLB index)
    //   +4-5: desc_idx (CLB index)
    //   +6-7: attr_count (0 for native, 1+ for methods with Code)
    //   +8-15: unknown/padding
    //   +16-19: hash/padding
    //   +20-23: attr_ptr (pointer to first attribute, if attr_count > 0)
    let methods_count = u32::from_le_bytes([clb_data[0x10], clb_data[0x11], clb_data[0x12], clb_data[0x13]]) as u16;
    java_data.extend_from_slice(&methods_count.to_be_bytes());
    let methods_addr = u32::from_le_bytes([clb_data[0x30], clb_data[0x31], clb_data[0x32], clb_data[0x33]]) as usize;

    if methods_addr > 0 && methods_count > 0 {
        for i in 0..methods_count {
            let m_addr = methods_addr + (i as usize) * 24;
            write_method_to_java(
                clb_data, m_addr, &mut java_data,
                &cp_strings, &clb_idx_to_java_idx
            )?;
        }
    }

    // STEP 12: Class Attributes
    let attributes_count = u16::from_le_bytes([clb_data[0x3C], clb_data[0x3D]]);
    java_data.extend_from_slice(&attributes_count.to_be_bytes());
    let attr_addr = u32::from_le_bytes([clb_data[0x38], clb_data[0x39], clb_data[0x3A], clb_data[0x3B]]) as usize;
    if attr_addr > 0 && attributes_count > 0 {
        for i in 0..attributes_count {
            write_field_attribute_to_java(
                clb_data, attr_addr + (i as usize) * 16, &mut java_data,
                &cp_strings, &addr_to_java_idx, &string_addr_to_java_idx, &clb_idx_to_java_idx
            )?;
        }
    }

    Ok(java_data)
}

/// Writes a CLB field entry to Java format.
///
/// ## CLB Field Structure (24 bytes)
///
/// ```text
/// Offset │ Size │ Field
/// ───────┼──────┼─────────────────
/// 0      │ 2    │ access_flags
/// 2      │ 2    │ name_idx (CLB)
/// 4      │ 2    │ descriptor_idx
/// 6      │ 2    │ attributes_count
/// 8      │ 4    │ attributes_addr
/// 12     │ 12   │ padding
/// ```
///
/// ## Java Field Structure
///
/// ```text
/// access_flags (u16 BE)
/// name_index (u16 BE) ─────┐
/// descriptor_index (u16 BE)│ Converted from CLB indices
/// attributes_count (u16 BE)│
/// attributes[]             │
/// ```
fn write_field_to_java(
    clb_data: &[u8],
    f_addr: usize,
    java_data: &mut Vec<u8>,
    cp_strings: &HashMap<u16, String>,
    addr_to_java_idx: &HashMap<u32, u16>,
    string_addr_to_java_idx: &HashMap<u32, u16>,
    clb_idx_to_java_idx: &HashMap<u16, u16>,
) -> Result<()> {
    let access = u16::from_le_bytes([clb_data[f_addr], clb_data[f_addr + 1]]);
    let old_name_idx = u16::from_le_bytes([clb_data[f_addr + 2], clb_data[f_addr + 3]]);
    let old_desc_idx = u16::from_le_bytes([clb_data[f_addr + 4], clb_data[f_addr + 5]]);
    let attr_count = u16::from_le_bytes([clb_data[f_addr + 6], clb_data[f_addr + 7]]);
    let attr_table_addr = u32::from_le_bytes([clb_data[f_addr + 8], clb_data[f_addr + 9], clb_data[f_addr + 10], clb_data[f_addr + 11]]) as usize;

    java_data.extend_from_slice(&access.to_be_bytes());
    java_data.extend_from_slice(&clb_idx_to_java_idx.get(&old_name_idx).copied().unwrap_or(0).to_be_bytes());
    java_data.extend_from_slice(&clb_idx_to_java_idx.get(&old_desc_idx).copied().unwrap_or(0).to_be_bytes());
    java_data.extend_from_slice(&attr_count.to_be_bytes());

    if attr_count > 0 && attr_table_addr > 0 {
        for i in 0..attr_count {
            write_field_attribute_to_java(
                clb_data, attr_table_addr + (i as usize) * 16, java_data,
                cp_strings, addr_to_java_idx, string_addr_to_java_idx, clb_idx_to_java_idx
            )?;
        }
    }
    Ok(())
}

/// Writes a CLB field attribute to Java format.
///
/// ## CLB Attribute Structure (16 bytes)
///
/// ```text
/// Offset │ Size │ Field
/// ───────┼──────┼───────────────────────────
/// 0      │ 4    │ name_ptr (CP entry address)
/// 4      │ 4    │ data_ptr (value address)
/// 8      │ 8    │ unused/padding
/// ```
///
/// ## Supported Attributes
///
/// - **ConstantValue**: Writes 2-byte CP index for the constant value.
/// - Other attributes are written with length 0 (not supported yet).
fn write_field_attribute_to_java(
    clb_data: &[u8],
    a_addr: usize,
    java_data: &mut Vec<u8>,
    cp_strings: &HashMap<u16, String>,
    addr_to_java_idx: &HashMap<u32, u16>,
    _string_addr_to_java_idx: &HashMap<u32, u16>,
    _clb_idx_to_java_idx: &HashMap<u16, u16>,
) -> Result<()> {
    let name_ptr = u32::from_le_bytes([clb_data[a_addr], clb_data[a_addr + 1], clb_data[a_addr + 2], clb_data[a_addr + 3]]);
    let data_ptr = u32::from_le_bytes([clb_data[a_addr + 4], clb_data[a_addr + 5], clb_data[a_addr + 6], clb_data[a_addr + 7]]);

    // Resolve name_ptr to Java CP index
    let name_idx = addr_to_java_idx.get(&name_ptr).copied().unwrap_or(0);
    java_data.extend_from_slice(&name_idx.to_be_bytes());

    if let Some(name) = cp_strings.get(&name_idx) {
        if name == "ConstantValue" {
            // ConstantValue points to a CP entry for the value
            let val_idx = addr_to_java_idx.get(&data_ptr).copied().unwrap_or(0);
            java_data.extend_from_slice(&2u32.to_be_bytes()); // attribute_length = 2
            java_data.extend_from_slice(&val_idx.to_be_bytes());
            return Ok(());
        }
        // Other attributes - write empty (length 0)
    }

    java_data.extend_from_slice(&0u32.to_be_bytes());
    Ok(())
}

/// Writes a CLB method entry to Java format.
///
/// ## CLB Method Structure (24 bytes)
///
/// ```text
/// Offset │ Size │ Field
/// ───────┼──────┼───────────────────────────────
/// 0      │ 2    │ access_flags
/// 2      │ 2    │ name_idx (CLB CP index)
/// 4      │ 2    │ descriptor_idx (CLB CP index)
/// 6      │ 2    │ attr_count (0=native, 1+=Code)
/// 8      │ 8    │ unknown/padding
/// 16     │ 4    │ hash/identifier
/// 20     │ 4    │ attr_ptr (first attribute addr)
/// ```
///
/// ## Java Method Structure
///
/// Methods are written with their Code attributes, which contain
/// the actual bytecode. The bytecode is copied directly since both
/// CLB and Java use the same JVM instruction set.
fn write_method_to_java(
    clb_data: &[u8],
    m_addr: usize,
    java_data: &mut Vec<u8>,
    cp_strings: &HashMap<u16, String>,
    clb_idx_to_java_idx: &HashMap<u16, u16>,
) -> Result<()> {
    let access = u16::from_le_bytes([clb_data[m_addr], clb_data[m_addr + 1]]);
    let old_name_idx = u16::from_le_bytes([clb_data[m_addr + 2], clb_data[m_addr + 3]]);
    let old_desc_idx = u16::from_le_bytes([clb_data[m_addr + 4], clb_data[m_addr + 5]]);
    let attr_count = u16::from_le_bytes([clb_data[m_addr + 6], clb_data[m_addr + 7]]);
    let attr_ptr = u32::from_le_bytes([clb_data[m_addr + 20], clb_data[m_addr + 21], clb_data[m_addr + 22], clb_data[m_addr + 23]]) as usize;

    java_data.extend_from_slice(&access.to_be_bytes());
    java_data.extend_from_slice(&clb_idx_to_java_idx.get(&old_name_idx).copied().unwrap_or(0).to_be_bytes());
    java_data.extend_from_slice(&clb_idx_to_java_idx.get(&old_desc_idx).copied().unwrap_or(0).to_be_bytes());
    java_data.extend_from_slice(&attr_count.to_be_bytes());

    // Process method attributes at attr_ptr
    let mut current_attr_addr = attr_ptr;
    for _ in 0..attr_count {
        current_attr_addr = write_method_attribute_to_java(
            clb_data, current_attr_addr, java_data,
            cp_strings, clb_idx_to_java_idx
        )?;
    }

    Ok(())
}

/// Writes a CLB method attribute (typically Code) to Java format.
///
/// ## CLB Code Attribute Structure (16 bytes)
///
/// ```text
/// Offset │ Size │ Field
/// ───────┼──────┼─────────────────────────────
/// 0      │ 2    │ name_idx ("Code" CP index)
/// 2      │ 2    │ max_stack
/// 4      │ 2    │ max_locals
/// 6      │ 2    │ reserved (0)
/// 8      │ 4    │ code_length
/// 12     │ 4    │ code_ptr (bytecode address)
/// ```
///
/// ## Java Code Attribute Structure
///
/// ```text
/// attribute_name_index (u16)
/// attribute_length (u32)
/// max_stack (u16)
/// max_locals (u16)
/// code_length (u32)
/// code[code_length]
/// exception_table_length (u16) = 0
/// attributes_count (u16) = 0
/// ```
///
/// # Returns
///
/// Address of the next attribute in CLB data.
fn write_method_attribute_to_java(
    clb_data: &[u8],
    a_addr: usize,
    java_data: &mut Vec<u8>,
    cp_strings: &HashMap<u16, String>,
    clb_idx_to_java_idx: &HashMap<u16, u16>,
) -> Result<usize> {
    let name_idx_clb = u16::from_le_bytes([clb_data[a_addr], clb_data[a_addr + 1]]);
    let name_idx = clb_idx_to_java_idx.get(&name_idx_clb).copied().unwrap_or(0);

    java_data.extend_from_slice(&name_idx.to_be_bytes());

    // Check attribute type
    if let Some(name) = cp_strings.get(&name_idx) {
        if name == "Code" {
            let max_stack = u16::from_le_bytes([clb_data[a_addr + 2], clb_data[a_addr + 3]]);
            let max_locals = u16::from_le_bytes([clb_data[a_addr + 4], clb_data[a_addr + 5]]);
            let code_length = u32::from_le_bytes([clb_data[a_addr + 8], clb_data[a_addr + 9], clb_data[a_addr + 10], clb_data[a_addr + 11]]);
            let code_ptr = u32::from_le_bytes([clb_data[a_addr + 12], clb_data[a_addr + 13], clb_data[a_addr + 14], clb_data[a_addr + 15]]) as usize;

            // Read bytecode
            let code_bytes = &clb_data[code_ptr..code_ptr + code_length as usize];

            // Code attribute length: 2 (max_stack) + 2 (max_locals) + 4 (code_length) + code + 2 (exception_table_length) + 2 (attributes_count)
            let attr_length = 2 + 2 + 4 + code_length + 2 + 2;

            java_data.extend_from_slice(&attr_length.to_be_bytes());
            java_data.extend_from_slice(&max_stack.to_be_bytes());
            java_data.extend_from_slice(&max_locals.to_be_bytes());
            java_data.extend_from_slice(&code_length.to_be_bytes());
            java_data.extend_from_slice(code_bytes);
            java_data.extend_from_slice(&0u16.to_be_bytes()); // exception_table_length
            java_data.extend_from_slice(&0u16.to_be_bytes()); // attributes_count

            return Ok(a_addr + 16);
        }
    }

    // Unknown attribute - write empty
    java_data.extend_from_slice(&0u32.to_be_bytes());
    Ok(a_addr + 16)
}

/// Parsed constant pool entry from a Java .class file.
///
/// Each variant corresponds to a JVM constant pool tag.
/// Long and Double entries use two slots; the second slot
/// is represented by `Placeholder`.
#[derive(Debug, Clone)]
enum JavaCPEntry {
    Utf8 { length: u16, bytes: Vec<u8> },
    Integer(i32),
    Float(f32),
    Long(i64),
    Double(f64),
    Class(u16),           // name_index
    String(u16),          // utf8_index
    Fieldref { class_idx: u16, nat_idx: u16 },
    Methodref { class_idx: u16, nat_idx: u16 },
    InterfaceMethodref { class_idx: u16, nat_idx: u16 },
    NameAndType { name_idx: u16, desc_idx: u16 },
    MethodHandle([u8; 3]),
    MethodType(u16),
    InvokeDynamic([u8; 4]),
    Placeholder,  // For Long/Double second slot
}

/// Parsed field from a Java .class file.
#[derive(Debug)]
struct JavaField {
    /// Access modifiers (public, private, static, final, etc.)
    access_flags: u16,
    /// CP index of field name (UTF-8 entry)
    name_index: u16,
    /// CP index of field type descriptor
    descriptor_index: u16,
    /// Field attributes (ConstantValue, etc.)
    attributes: Vec<JavaAttribute>,
}

/// Parsed method from a Java .class file.
#[derive(Debug)]
struct JavaMethod {
    /// Access modifiers (public, private, static, native, etc.)
    access_flags: u16,
    /// CP index of method name (UTF-8 entry)
    name_index: u16,
    /// CP index of method type descriptor
    descriptor_index: u16,
    /// Method attributes (Code, Exceptions, etc.)
    attributes: Vec<JavaAttribute>,
}

/// Parsed attribute from a Java .class file.
#[derive(Debug)]
struct JavaAttribute {
    /// CP index of attribute name (UTF-8 entry)
    name_index: u16,
    /// Raw attribute data (interpretation depends on name)
    data: Vec<u8>,
}

/// Converts a Java .class file to CLB format.
///
/// This is the reverse operation of [`clb_to_java`]. It reads a standard
/// Java class file and produces a CLB file compatible with FF13's runtime.
///
/// # File Format Conversion
///
/// The conversion process:
///
/// 1. **Parse Java**: Read big-endian .class file structure
/// 2. **Calculate Layout**: Determine CLB section sizes and addresses
/// 3. **Build CLB**: Write little-endian CLB with pointer-based references
///
/// ## Layout Calculation
///
/// ```text
/// Section          │ Size Calculation
/// ─────────────────┼─────────────────────────────────
/// Header           │ 0x38 bytes (fixed)
/// Constant Pool    │ (count + 1) × 16 bytes
/// String Data      │ Sum of all UTF-8 string lengths
/// Fields Table     │ field_count × 24 bytes
/// Field Attributes │ attr_count × 16 bytes
/// Methods Table    │ method_count × 24 bytes
/// Method Attrs     │ code_attr_count × 16 bytes
/// Code Data        │ Sum of all bytecode lengths
/// Class Attrs      │ attr_count × 16 bytes
/// Footer           │ 8 bytes
/// ```
///
/// # Arguments
///
/// * `java_path` - Path to input Java .class file
/// * `output_path` - Path to write CLB file
///
/// # Example
///
/// ```rust,ignore
/// java_to_clb(
///     Path::new("QuestController.class"),
///     Path::new("r_quest_ctrl.clb")
/// )?;
/// ```
pub fn java_to_clb(java_path: &Path, output_path: &Path) -> Result<()> {
    let java_data = std::fs::read(java_path).map_err(WhiteClbError::Io)?;
    let clb_data = java_bytes_to_clb(&java_data)?;
    std::fs::write(output_path, clb_data).map_err(WhiteClbError::Io)?;
    Ok(())
}

/// Converts raw Java .class bytes to CLB format.
///
/// This is the internal implementation called by [`java_to_clb`].
/// It handles all parsing and conversion logic.
fn java_bytes_to_clb(java_data: &[u8]) -> Result<Vec<u8>> {
    let mut pos = 0usize;

    // Verify magic
    if java_data[0..4] != [0xCA, 0xFE, 0xBA, 0xBE] {
        return Err(WhiteClbError::Validation("Invalid Java class magic".into()));
    }
    pos += 4;

    // Read versions
    let minor = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
    pos += 2;
    let major = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
    pos += 2;
    let cp_count = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
    pos += 2;

    // Parse constant pool
    let mut cp_entries: Vec<JavaCPEntry> = vec![JavaCPEntry::Placeholder]; // Index 0 is unused
    let mut java_idx = 1u16;

    while java_idx < cp_count {
        let tag = java_data[pos];
        pos += 1;

        let entry = match tag {
            1 => { // UTF-8
                let len = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
                pos += 2;
                let bytes = java_data[pos..pos + len as usize].to_vec();
                pos += len as usize;
                JavaCPEntry::Utf8 { length: len, bytes }
            }
            3 => { // Integer
                let val = i32::from_be_bytes([java_data[pos], java_data[pos+1], java_data[pos+2], java_data[pos+3]]);
                pos += 4;
                JavaCPEntry::Integer(val)
            }
            4 => { // Float
                let bits = u32::from_be_bytes([java_data[pos], java_data[pos+1], java_data[pos+2], java_data[pos+3]]);
                pos += 4;
                JavaCPEntry::Float(f32::from_bits(bits))
            }
            5 => { // Long (uses 2 slots)
                let val = i64::from_be_bytes([
                    java_data[pos], java_data[pos+1], java_data[pos+2], java_data[pos+3],
                    java_data[pos+4], java_data[pos+5], java_data[pos+6], java_data[pos+7]
                ]);
                pos += 8;
                cp_entries.push(JavaCPEntry::Long(val));
                cp_entries.push(JavaCPEntry::Placeholder);
                java_idx += 2;
                continue;
            }
            6 => { // Double (uses 2 slots)
                let bits = u64::from_be_bytes([
                    java_data[pos], java_data[pos+1], java_data[pos+2], java_data[pos+3],
                    java_data[pos+4], java_data[pos+5], java_data[pos+6], java_data[pos+7]
                ]);
                pos += 8;
                cp_entries.push(JavaCPEntry::Double(f64::from_bits(bits)));
                cp_entries.push(JavaCPEntry::Placeholder);
                java_idx += 2;
                continue;
            }
            7 => { // Class
                let name_idx = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
                pos += 2;
                JavaCPEntry::Class(name_idx)
            }
            8 => { // String
                let str_idx = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
                pos += 2;
                JavaCPEntry::String(str_idx)
            }
            9 => { // Fieldref
                let class_idx = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
                pos += 2;
                let nat_idx = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
                pos += 2;
                JavaCPEntry::Fieldref { class_idx, nat_idx }
            }
            10 => { // Methodref
                let class_idx = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
                pos += 2;
                let nat_idx = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
                pos += 2;
                JavaCPEntry::Methodref { class_idx, nat_idx }
            }
            11 => { // InterfaceMethodref
                let class_idx = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
                pos += 2;
                let nat_idx = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
                pos += 2;
                JavaCPEntry::InterfaceMethodref { class_idx, nat_idx }
            }
            12 => { // NameAndType
                let name_idx = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
                pos += 2;
                let desc_idx = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
                pos += 2;
                JavaCPEntry::NameAndType { name_idx, desc_idx }
            }
            15 => { // MethodHandle
                let bytes = [java_data[pos], java_data[pos+1], java_data[pos+2]];
                pos += 3;
                JavaCPEntry::MethodHandle(bytes)
            }
            16 => { // MethodType
                let desc_idx = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
                pos += 2;
                JavaCPEntry::MethodType(desc_idx)
            }
            18 => { // InvokeDynamic
                let bytes = [java_data[pos], java_data[pos+1], java_data[pos+2], java_data[pos+3]];
                pos += 4;
                JavaCPEntry::InvokeDynamic(bytes)
            }
            _ => {
                return Err(WhiteClbError::Validation(format!("Unknown CP tag: {}", tag)));
            }
        };

        cp_entries.push(entry);
        java_idx += 1;
    }

    // Parse class metadata
    let access_flags = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
    pos += 2;
    let this_class = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
    pos += 2;
    let super_class = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
    pos += 2;
    let interfaces_count = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
    pos += 2;
    pos += interfaces_count as usize * 2; // Skip interfaces

    // Parse fields
    let fields_count = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
    pos += 2;
    let mut fields: Vec<JavaField> = Vec::new();
    for _ in 0..fields_count {
        let (field, new_pos) = parse_java_field(&java_data, pos)?;
        fields.push(field);
        pos = new_pos;
    }

    // Parse methods
    let methods_count = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
    pos += 2;
    let mut methods: Vec<JavaMethod> = Vec::new();
    for _ in 0..methods_count {
        let (method, new_pos) = parse_java_method(&java_data, pos)?;
        methods.push(method);
        pos = new_pos;
    }

    // Parse class attributes
    let class_attr_count = u16::from_be_bytes([java_data[pos], java_data[pos + 1]]);
    pos += 2;
    let mut class_attributes: Vec<JavaAttribute> = Vec::new();
    for _ in 0..class_attr_count {
        let (attr, new_pos) = parse_java_attribute(&java_data, pos)?;
        class_attributes.push(attr);
        pos = new_pos;
    }

    // Now build CLB data
    build_clb_from_parsed(
        minor, major, &cp_entries, access_flags, this_class, super_class,
        &fields, &methods, &class_attributes
    )
}

/// Parses a field entry from Java .class data.
///
/// Returns the parsed field and the new position after the field.
fn parse_java_field(data: &[u8], mut pos: usize) -> Result<(JavaField, usize)> {
    let access_flags = u16::from_be_bytes([data[pos], data[pos + 1]]);
    pos += 2;
    let name_index = u16::from_be_bytes([data[pos], data[pos + 1]]);
    pos += 2;
    let descriptor_index = u16::from_be_bytes([data[pos], data[pos + 1]]);
    pos += 2;
    let attr_count = u16::from_be_bytes([data[pos], data[pos + 1]]);
    pos += 2;

    let mut attributes = Vec::new();
    for _ in 0..attr_count {
        let (attr, new_pos) = parse_java_attribute(data, pos)?;
        attributes.push(attr);
        pos = new_pos;
    }

    Ok((JavaField { access_flags, name_index, descriptor_index, attributes }, pos))
}

/// Parses a method entry from Java .class data.
///
/// Returns the parsed method and the new position after the method.
fn parse_java_method(data: &[u8], mut pos: usize) -> Result<(JavaMethod, usize)> {
    let access_flags = u16::from_be_bytes([data[pos], data[pos + 1]]);
    pos += 2;
    let name_index = u16::from_be_bytes([data[pos], data[pos + 1]]);
    pos += 2;
    let descriptor_index = u16::from_be_bytes([data[pos], data[pos + 1]]);
    pos += 2;
    let attr_count = u16::from_be_bytes([data[pos], data[pos + 1]]);
    pos += 2;

    let mut attributes = Vec::new();
    for _ in 0..attr_count {
        let (attr, new_pos) = parse_java_attribute(data, pos)?;
        attributes.push(attr);
        pos = new_pos;
    }

    Ok((JavaMethod { access_flags, name_index, descriptor_index, attributes }, pos))
}

/// Parses an attribute entry from Java .class data.
///
/// Attributes have a variable-length data section, so this function
/// reads the length field and consumes the appropriate number of bytes.
///
/// Returns the parsed attribute and the new position after the attribute.
fn parse_java_attribute(data: &[u8], mut pos: usize) -> Result<(JavaAttribute, usize)> {
    let name_index = u16::from_be_bytes([data[pos], data[pos + 1]]);
    pos += 2;
    let length = u32::from_be_bytes([data[pos], data[pos + 1], data[pos + 2], data[pos + 3]]) as usize;
    pos += 4;
    let attr_data = data[pos..pos + length].to_vec();
    pos += length;

    Ok((JavaAttribute { name_index, data: attr_data }, pos))
}

/// Builds CLB binary data from parsed Java structures.
///
/// This is the core CLB generation logic. It performs:
///
/// 1. **Index Mapping**: Maps Java CP indices to CLB indices
///    (skipping Placeholder entries for Long/Double)
///
/// 2. **Address Calculation**: Computes absolute addresses for all sections:
///    - Header at 0x00
///    - Constant pool at 0x38
///    - String data after CP
///    - Fields, methods, attributes in order
///    - Footer at the end
///
/// 3. **Binary Generation**: Writes all sections with little-endian encoding
///    and pointer-based references.
///
/// ## CLB vs Java Index Mapping
///
/// Java uses 1-based indices directly into CP. CLB uses:
/// - Entry 0: unused
/// - Entry 1: empty (tag=0)
/// - Entries 2+: actual data
///
/// Long and Double entries in Java take 2 slots but only 1 in CLB.
fn build_clb_from_parsed(
    minor: u16,
    major: u16,
    cp_entries: &[JavaCPEntry],
    _access_flags: u16,
    this_class: u16,
    super_class: u16,
    fields: &[JavaField],
    methods: &[JavaMethod],
    class_attributes: &[JavaAttribute],
) -> Result<Vec<u8>> {
    // Build Java-to-CLB index mapping (skip Placeholder entries)
    // CLB entry 1 is empty (tag=0), real entries start at CLB index 2
    let mut java_to_clb_idx: HashMap<u16, u16> = HashMap::new();
    let mut clb_idx = 2u16; // Start at 2 because entry 1 is empty
    for (java_idx, entry) in cp_entries.iter().enumerate() {
        if java_idx == 0 { continue; }
        if !matches!(entry, JavaCPEntry::Placeholder) {
            java_to_clb_idx.insert(java_idx as u16, clb_idx);
            clb_idx += 1;
        }
    }
    let clb_cp_count = clb_idx; // This includes the empty entry 1

    // Calculate CLB layout
    // Header: 0x38 bytes (56 bytes) - matches original CLB files
    let header_size = 0x38u32;
    let first_cp_addr = header_size;

    // CP entries: clb_cp_count * 16 bytes
    // Entry 1 is empty (Tag 0), entries 2+ are real entries
    // So we need clb_cp_count entries total (including empty entry 1)
    let cp_entries_size = clb_cp_count as u32 * 16;
    let string_data_start = first_cp_addr + cp_entries_size;

    // Collect all UTF-8 strings and calculate their addresses
    let mut string_data: Vec<u8> = Vec::new();
    let mut utf8_addresses: Vec<u32> = Vec::new();

    for entry in cp_entries.iter() {
        if let JavaCPEntry::Utf8 { bytes, .. } = entry {
            utf8_addresses.push(string_data_start + string_data.len() as u32);
            string_data.extend_from_slice(bytes);
        }
    }

    // Calculate addresses after string data
    let after_strings = string_data_start + string_data.len() as u32;

    // Fields: fields.len() * 24 bytes
    let fields_addr = if fields.is_empty() { 0 } else { after_strings };
    let fields_size = fields.len() as u32 * 24;

    // Field attributes (for ConstantValue)
    let field_attrs_addr = if fields.is_empty() { after_strings } else { fields_addr + fields_size };
    let mut field_attrs_size = 0u32;
    for field in fields {
        field_attrs_size += field.attributes.len() as u32 * 16;
    }

    // Methods: methods.len() * 24 bytes
    let methods_addr = if methods.is_empty() { 0 } else { field_attrs_addr + field_attrs_size };
    let methods_size = methods.len() as u32 * 24;

    // Method attributes (Code)
    let method_attrs_addr = methods_addr + methods_size;
    let mut method_code_data: Vec<u8> = Vec::new();
    let mut method_attr_entries: Vec<(u16, u16, u16, u32, u32)> = Vec::new(); // (name_idx, max_stack, max_locals, code_len, code_offset)

    for method in methods {
        for attr in &method.attributes {
            // Check if this is a Code attribute
            if let Some(JavaCPEntry::Utf8 { bytes, .. }) = cp_entries.get(attr.name_index as usize) {
                if bytes == b"Code" && attr.data.len() >= 8 {
                    let max_stack = u16::from_be_bytes([attr.data[0], attr.data[1]]);
                    let max_locals = u16::from_be_bytes([attr.data[2], attr.data[3]]);
                    let code_length = u32::from_be_bytes([attr.data[4], attr.data[5], attr.data[6], attr.data[7]]);
                    let code_offset = method_code_data.len() as u32;
                    method_code_data.extend_from_slice(&attr.data[8..8 + code_length as usize]);
                    method_attr_entries.push((
                        java_to_clb_idx.get(&attr.name_index).copied().unwrap_or(0),
                        max_stack,
                        max_locals,
                        code_length,
                        code_offset,
                    ));
                }
            }
        }
    }

    let method_attrs_count = method_attr_entries.len() as u32;
    let method_attrs_size = method_attrs_count * 16;

    // Code data
    let code_data_addr = method_attrs_addr + method_attrs_size;

    // Class attributes
    let class_attrs_addr = code_data_addr + method_code_data.len() as u32;
    let class_attrs_size = class_attributes.len() as u32 * 16;

    // Footer (8 bytes)
    let footer_addr = class_attrs_addr + class_attrs_size;
    let total_size = footer_addr + 8;

    // Build index-to-address map for CP entries
    // Entry 0 at first_cp_addr is unused, entry 1 at +16 is empty (tag=0)
    // Real entries start at entry 2 (first_cp_addr + 32)
    let mut idx_to_addr: HashMap<u16, u32> = HashMap::new();
    let mut addr = first_cp_addr + 32; // Skip entry 0 (unused) and entry 1 (empty)
    for (java_idx, entry) in cp_entries.iter().enumerate() {
        if java_idx == 0 { continue; }
        if !matches!(entry, JavaCPEntry::Placeholder) {
            if let Some(&clb_idx) = java_to_clb_idx.get(&(java_idx as u16)) {
                idx_to_addr.insert(clb_idx, addr);
            }
            addr += 16;
        }
    }

    // Find this_class and super_class CP entry addresses
    let this_class_clb_idx = java_to_clb_idx.get(&this_class).copied().unwrap_or(0);
    let super_class_clb_idx = java_to_clb_idx.get(&super_class).copied().unwrap_or(0);
    let this_class_addr = idx_to_addr.get(&this_class_clb_idx).copied().unwrap_or(0);
    let super_class_addr = idx_to_addr.get(&super_class_clb_idx).copied().unwrap_or(0);

    // Now build the CLB data
    let mut clb_data = vec![0u8; total_size as usize];

    // Write header
    // 0x00-0x03: "TRBT" magic or zeros
    clb_data[0..4].copy_from_slice(b"TRBT");
    // 0x04-0x05: minor version
    clb_data[4..6].copy_from_slice(&minor.to_le_bytes());
    // 0x06-0x07: major version
    clb_data[6..8].copy_from_slice(&major.to_le_bytes());
    // 0x08-0x09: cp_count
    clb_data[8..10].copy_from_slice(&clb_cp_count.to_le_bytes());
    // 0x0E-0x0F: field_count
    clb_data[0x0E..0x10].copy_from_slice(&(fields.len() as u16).to_le_bytes());
    // 0x10-0x13: methods_count
    clb_data[0x10..0x14].copy_from_slice(&(methods.len() as u32).to_le_bytes());
    // 0x18-0x1B: first_cp_addr
    clb_data[0x18..0x1C].copy_from_slice(&first_cp_addr.to_le_bytes());
    // 0x1C-0x1F: this_class_addr
    clb_data[0x1C..0x20].copy_from_slice(&this_class_addr.to_le_bytes());
    // 0x24-0x27: super_class_addr
    clb_data[0x24..0x28].copy_from_slice(&super_class_addr.to_le_bytes());
    // 0x2C-0x2F: fields_addr
    clb_data[0x2C..0x30].copy_from_slice(&fields_addr.to_le_bytes());
    // 0x30-0x33: methods_addr
    clb_data[0x30..0x34].copy_from_slice(&methods_addr.to_le_bytes());
    // 0x38-0x3B: class_attrs_addr
    clb_data[0x38..0x3C].copy_from_slice(&class_attrs_addr.to_le_bytes());
    // 0x3C-0x3D: class_attrs_count
    clb_data[0x3C..0x3E].copy_from_slice(&(class_attributes.len() as u16).to_le_bytes());

    // Write CP entries
    // Entry 0 (first_cp_addr) is unused, entry 1 (+16) is empty (tag=0)
    // Real entries start at entry 2 (+32), already zeroed in the vec
    let mut utf8_idx = 0usize;
    let mut cp_offset = first_cp_addr as usize + 32; // Skip entry 0 (unused) and entry 1 (empty)

    for (java_idx, entry) in cp_entries.iter().enumerate() {
        if java_idx == 0 { continue; }
        if matches!(entry, JavaCPEntry::Placeholder) { continue; }

        match entry {
            JavaCPEntry::Utf8 { length, .. } => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&1u32.to_le_bytes());
                clb_data[cp_offset+8..cp_offset+12].copy_from_slice(&(*length as u32).to_le_bytes());
                clb_data[cp_offset+12..cp_offset+16].copy_from_slice(&utf8_addresses[utf8_idx].to_le_bytes());
                utf8_idx += 1;
            }
            JavaCPEntry::Integer(val) => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&3u32.to_le_bytes());
                clb_data[cp_offset+8..cp_offset+12].copy_from_slice(&val.to_le_bytes());
            }
            JavaCPEntry::Float(val) => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&4u32.to_le_bytes());
                clb_data[cp_offset+8..cp_offset+12].copy_from_slice(&val.to_le_bytes());
            }
            JavaCPEntry::Long(val) => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&5u32.to_le_bytes());
                clb_data[cp_offset+8..cp_offset+16].copy_from_slice(&val.to_le_bytes());
            }
            JavaCPEntry::Double(val) => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&6u32.to_le_bytes());
                clb_data[cp_offset+8..cp_offset+16].copy_from_slice(&val.to_bits().to_le_bytes());
            }
            JavaCPEntry::Class(name_idx) => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&7u32.to_le_bytes());
                // Store string data address for the class name
                let clb_name_idx = java_to_clb_idx.get(name_idx).copied().unwrap_or(0);
                // Find the UTF-8 entry and get its string address
                let mut str_addr = 0u32;
                let mut utf8_count = 0usize;
                for (j, e) in cp_entries.iter().enumerate() {
                    if j == 0 { continue; }
                    if let JavaCPEntry::Utf8 { .. } = e {
                        if let Some(&idx) = java_to_clb_idx.get(&(j as u16)) {
                            if idx == clb_name_idx {
                                str_addr = utf8_addresses[utf8_count];
                                break;
                            }
                        }
                        utf8_count += 1;
                    }
                }
                clb_data[cp_offset+8..cp_offset+12].copy_from_slice(&str_addr.to_le_bytes());
            }
            JavaCPEntry::String(str_idx) => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&8u32.to_le_bytes());
                let clb_idx = java_to_clb_idx.get(str_idx).copied().unwrap_or(0);
                clb_data[cp_offset+8..cp_offset+10].copy_from_slice(&clb_idx.to_le_bytes());
            }
            JavaCPEntry::Fieldref { class_idx, nat_idx } => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&9u32.to_le_bytes());
                let c_idx = java_to_clb_idx.get(class_idx).copied().unwrap_or(0);
                let n_idx = java_to_clb_idx.get(nat_idx).copied().unwrap_or(0);
                clb_data[cp_offset+8..cp_offset+10].copy_from_slice(&c_idx.to_le_bytes());
                clb_data[cp_offset+10..cp_offset+12].copy_from_slice(&n_idx.to_le_bytes());
            }
            JavaCPEntry::Methodref { class_idx, nat_idx } => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&10u32.to_le_bytes());
                let c_idx = java_to_clb_idx.get(class_idx).copied().unwrap_or(0);
                let n_idx = java_to_clb_idx.get(nat_idx).copied().unwrap_or(0);
                clb_data[cp_offset+8..cp_offset+10].copy_from_slice(&c_idx.to_le_bytes());
                clb_data[cp_offset+10..cp_offset+12].copy_from_slice(&n_idx.to_le_bytes());
            }
            JavaCPEntry::InterfaceMethodref { class_idx, nat_idx } => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&11u32.to_le_bytes());
                let c_idx = java_to_clb_idx.get(class_idx).copied().unwrap_or(0);
                let n_idx = java_to_clb_idx.get(nat_idx).copied().unwrap_or(0);
                clb_data[cp_offset+8..cp_offset+10].copy_from_slice(&c_idx.to_le_bytes());
                clb_data[cp_offset+10..cp_offset+12].copy_from_slice(&n_idx.to_le_bytes());
            }
            JavaCPEntry::NameAndType { name_idx, desc_idx } => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&12u32.to_le_bytes());
                let n_idx = java_to_clb_idx.get(name_idx).copied().unwrap_or(0);
                let d_idx = java_to_clb_idx.get(desc_idx).copied().unwrap_or(0);
                clb_data[cp_offset+8..cp_offset+10].copy_from_slice(&n_idx.to_le_bytes());
                clb_data[cp_offset+10..cp_offset+12].copy_from_slice(&d_idx.to_le_bytes());
            }
            JavaCPEntry::MethodHandle(bytes) => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&15u32.to_le_bytes());
                // Reverse the 3 bytes
                clb_data[cp_offset+8] = bytes[2];
                clb_data[cp_offset+9] = bytes[1];
                clb_data[cp_offset+10] = bytes[0];
            }
            JavaCPEntry::MethodType(desc_idx) => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&16u32.to_le_bytes());
                let d_idx = java_to_clb_idx.get(desc_idx).copied().unwrap_or(0);
                clb_data[cp_offset+8..cp_offset+10].copy_from_slice(&d_idx.to_le_bytes());
            }
            JavaCPEntry::InvokeDynamic(bytes) => {
                clb_data[cp_offset..cp_offset+4].copy_from_slice(&18u32.to_le_bytes());
                // Reverse the 4 bytes
                clb_data[cp_offset+8] = bytes[3];
                clb_data[cp_offset+9] = bytes[2];
                clb_data[cp_offset+10] = bytes[1];
                clb_data[cp_offset+11] = bytes[0];
            }
            JavaCPEntry::Placeholder => {}
        }
        cp_offset += 16;
    }

    // Write string data
    clb_data[string_data_start as usize..string_data_start as usize + string_data.len()]
        .copy_from_slice(&string_data);

    // Write fields (24 bytes each)
    let mut field_offset = fields_addr as usize;
    let mut field_attr_offset = field_attrs_addr as usize;
    for field in fields {
        clb_data[field_offset..field_offset+2].copy_from_slice(&field.access_flags.to_le_bytes());
        let name_idx = java_to_clb_idx.get(&field.name_index).copied().unwrap_or(0);
        let desc_idx = java_to_clb_idx.get(&field.descriptor_index).copied().unwrap_or(0);
        clb_data[field_offset+2..field_offset+4].copy_from_slice(&name_idx.to_le_bytes());
        clb_data[field_offset+4..field_offset+6].copy_from_slice(&desc_idx.to_le_bytes());
        clb_data[field_offset+6..field_offset+8].copy_from_slice(&(field.attributes.len() as u16).to_le_bytes());
        if !field.attributes.is_empty() {
            clb_data[field_offset+8..field_offset+12].copy_from_slice(&(field_attr_offset as u32).to_le_bytes());
        }

        // Write field attributes
        for attr in &field.attributes {
            let attr_name_idx = java_to_clb_idx.get(&attr.name_index).copied().unwrap_or(0);
            let attr_name_addr = idx_to_addr.get(&attr_name_idx).copied().unwrap_or(0);
            clb_data[field_attr_offset..field_attr_offset+4].copy_from_slice(&attr_name_addr.to_le_bytes());
            // For ConstantValue, data is 2 bytes (CP index)
            if attr.data.len() >= 2 {
                let val_java_idx = u16::from_be_bytes([attr.data[0], attr.data[1]]);
                let val_clb_idx = java_to_clb_idx.get(&val_java_idx).copied().unwrap_or(0);
                let val_addr = idx_to_addr.get(&val_clb_idx).copied().unwrap_or(0);
                clb_data[field_attr_offset+4..field_attr_offset+8].copy_from_slice(&val_addr.to_le_bytes());
            }
            field_attr_offset += 16;
        }

        field_offset += 24;
    }

    // Write methods (24 bytes each)
    let mut method_offset = methods_addr as usize;
    let mut method_attr_idx = 0usize;
    for method in methods {
        clb_data[method_offset..method_offset+2].copy_from_slice(&method.access_flags.to_le_bytes());
        let name_idx = java_to_clb_idx.get(&method.name_index).copied().unwrap_or(0);
        let desc_idx = java_to_clb_idx.get(&method.descriptor_index).copied().unwrap_or(0);
        clb_data[method_offset+2..method_offset+4].copy_from_slice(&name_idx.to_le_bytes());
        clb_data[method_offset+4..method_offset+6].copy_from_slice(&desc_idx.to_le_bytes());

        // Count Code attributes for this method
        let code_attr_count = method.attributes.iter().filter(|a| {
            if let Some(JavaCPEntry::Utf8 { bytes, .. }) = cp_entries.get(a.name_index as usize) {
                bytes == b"Code"
            } else {
                false
            }
        }).count() as u16;

        clb_data[method_offset+6..method_offset+8].copy_from_slice(&code_attr_count.to_le_bytes());

        if code_attr_count > 0 {
            let attr_ptr = method_attrs_addr + (method_attr_idx as u32) * 16;
            clb_data[method_offset+20..method_offset+24].copy_from_slice(&attr_ptr.to_le_bytes());
            method_attr_idx += code_attr_count as usize;
        }

        method_offset += 24;
    }

    // Write method attributes (Code)
    let mut attr_offset = method_attrs_addr as usize;
    for (name_idx, max_stack, max_locals, code_len, code_offset) in &method_attr_entries {
        clb_data[attr_offset..attr_offset+2].copy_from_slice(&name_idx.to_le_bytes());
        clb_data[attr_offset+2..attr_offset+4].copy_from_slice(&max_stack.to_le_bytes());
        clb_data[attr_offset+4..attr_offset+6].copy_from_slice(&max_locals.to_le_bytes());
        clb_data[attr_offset+8..attr_offset+12].copy_from_slice(&code_len.to_le_bytes());
        let code_ptr = code_data_addr + code_offset;
        clb_data[attr_offset+12..attr_offset+16].copy_from_slice(&code_ptr.to_le_bytes());
        attr_offset += 16;
    }

    // Write code data
    clb_data[code_data_addr as usize..code_data_addr as usize + method_code_data.len()]
        .copy_from_slice(&method_code_data);

    // Write footer (checksum + size indicator)
    let body_size = (total_size - 16) as u32;
    clb_data[footer_addr as usize..footer_addr as usize + 4].copy_from_slice(&body_size.to_le_bytes());
    // The last 4 bytes are often zeros or a secondary checksum

    Ok(clb_data)
}
