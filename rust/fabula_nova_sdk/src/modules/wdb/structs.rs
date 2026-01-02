//! # WDB Data Structures
//!
//! This module defines all data structures for WDB file parsing, writing,
//! and interoperability.
//!
//! ## Structure Categories
//!
//! 1. **Binary Format Structures** - Direct file format representations
//!    - [`WdbBinaryHeader`] - 16-byte file header
//!    - [`WdbSectionHeader`] - 32-byte section header
//!
//! 2. **High-Level Rust/Dart Structures** - For application use
//!    - [`WdbData`] - Complete parsed WDB file
//!    - [`WdbRecord`] - Single record (HashMap of field names to values)
//!    - [`WdbValue`] - Typed field value (int, float, string, etc.)
//!
//! 3. **C FFI Structures** - For legacy C interop
//!    - [`WDBFileCInternal`], [`WDBRecordCInternal`], etc.
//!
//! ## Value Types
//!
//! WDB fields can contain various types:
//! - `Int(i32)` - Signed 32-bit integer
//! - `UInt(u32)` - Unsigned 32-bit integer
//! - `Float(f32)` - 32-bit floating point
//! - `String(String)` - String value
//! - `Bool(bool)` - Boolean value
//! - `IntArray(Vec<i32>)` - Array of signed integers
//! - `UIntArray(Vec<u32>)` - Array of unsigned integers
//! - `StringArray(Vec<String>)` - Array of strings
//! - `CrystalRole`, `CrystalNodeType` - Enum types for Crystarium

use binrw::BinRead;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// Re-export GameCode for convenience
pub use crate::core::utils::GameCode;
use super::enums::{CrystalNodeType, CrystalRole};

// =============================================================================
// Binary Format Structures
// =============================================================================

/// WDB file header - first 16 bytes of every WDB file.
///
/// # Binary Layout
/// ```text
/// Offset  Size  Field
/// 0x00    4     magic ("WPD" + null)
/// 0x04    4     record_count
/// 0x08    8     padding
/// ```
#[derive(BinRead, Debug, Clone)]
#[br(big)]
pub struct WdbBinaryHeader {
    #[br(count = 4)]
    #[br(map = |bytes: Vec<u8>| String::from_utf8_lossy(&bytes).trim_matches('\0').to_string())]
    pub magic: String, // "WPD"
    pub record_count: u32,
    pub _padding: [u8; 8], // Total 16 bytes
}

#[derive(BinRead, Debug, Clone)]
#[br(big)]
pub struct WdbSectionHeader {
    #[br(count = 16)]
    #[br(map = |bytes: Vec<u8>| String::from_utf8_lossy(&bytes).trim_matches('\0').to_string())]
    pub name: String,
    pub offset: u32,
    pub length: u32,
    pub _padding: [u8; 8],
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(untagged)]
pub enum WdbValue {
    Int(i32),
    UInt(u32),
    Float(f32),
    String(String),
    Bool(bool),
    IntArray(Vec<i32>),
    UIntArray(Vec<u32>),
    StringArray(Vec<String>),
    UInt64(u64),
    // Enum variants for type-safe field values
    CrystalRole(CrystalRole),
    CrystalNodeType(CrystalNodeType),
    Unknown,
}

pub type WdbRecord = HashMap<String, WdbValue>;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WdbData {
    pub header: HashMap<String, WdbValue>,
    pub records: Vec<WdbRecord>,
}

// Legacy C Structs
#[repr(C)]
pub enum WDBValueTypeC {
    Int = 0,
    UInt = 1,
    Float = 2,
    String = 3,
    Bool = 4,
    IntArray = 5,
    UIntArray = 6,
    StringArray = 7,
    Unknown = 8
}

#[repr(C)]
pub struct WDBIntArrayInternal {
    pub items: *mut i32,
    pub count: i32,
}

#[repr(C)]
pub struct WDBUIntArrayInternal {
    pub items: *mut u32, 
    pub count: i32,
}

#[repr(C)]
pub struct WDBStringArrayInternal {
    pub items: *mut *mut std::ffi::c_char,
    pub count: i32,
}

#[repr(C)]
pub union WDBValueDataC {
    pub int_val: i32,
    pub uint_val: u32,
    pub float_val: f32,
    pub string_val: *mut std::ffi::c_char,
    pub bool_val: i32,
    pub int_array_val: std::mem::ManuallyDrop<WDBIntArrayInternal>,
    pub uint_array_val: std::mem::ManuallyDrop<WDBUIntArrayInternal>,
    pub string_array_val: std::mem::ManuallyDrop<WDBStringArrayInternal>,
}

#[repr(C)]
pub struct WDBValueInternal {
    pub type_: WDBValueTypeC,
    pub data: WDBValueDataC,
}

#[repr(C)]
pub struct WDBEntryInternal {
    pub key: *mut std::ffi::c_char,
    pub value: WDBValueInternal,
}

#[repr(C)]
pub struct WDBSectionCInternal {
    pub entries: *mut WDBEntryInternal,
    pub entry_count: i32,
}

#[repr(C)]
pub struct WDBRecordCInternal {
    pub entries: *mut WDBEntryInternal,
    pub entry_count: i32,
}

#[repr(C)]
pub struct WDBFileCInternal {
    pub wdb_name: *mut std::ffi::c_char,
    pub header: WDBSectionCInternal,
    pub records: *mut WDBRecordCInternal,
    pub record_count: i32,
}
