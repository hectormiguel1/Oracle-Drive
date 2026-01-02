//! # WPD Data Structures
//!
//! This module defines the binary structures for WPD (WhiteBin Package) files.
//!
//! ## File Format
//!
//! ```text
//! ┌─────────────────────────────────────────────────────────────┐
//! │ Header (16 bytes)                                           │
//! │   - Magic: "WPD\0" (4 bytes)                                │
//! │   - Record Count: u32 (4 bytes)                             │
//! │   - Padding: 8 bytes                                        │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Record Headers (32 bytes each)                              │
//! │   - Name: 16 bytes (null-padded)                            │
//! │   - Offset: u32 (4 bytes)                                   │
//! │   - Size: u32 (4 bytes)                                     │
//! │   - Extension: 8 bytes (null-padded)                        │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Record Data                                                 │
//! │   - Raw file data at specified offsets                      │
//! │   - 4-byte aligned                                          │
//! └─────────────────────────────────────────────────────────────┘
//! ```

use binrw::BinRead;
use serde::{Serialize, Deserialize};

/// WPD file header (16 bytes).
///
/// Contains the magic string "WPD" and record count.
#[derive(BinRead, Debug, Clone, Serialize, Deserialize)]
#[br(big)]
pub struct WpdBinaryHeader {
    #[br(count = 4)]
    #[br(map = |bytes: Vec<u8>| String::from_utf8_lossy(&bytes).trim_matches('\0').to_string())]
    pub magic: String, // "WPD"
    pub record_count: u32,
    #[br(pad_after = 8)]
    pub _padding: [u8; 8], // Total 16 bytes
}

/// WPD record header (32 bytes).
///
/// Describes a single file within the package.
/// The offset points to where data begins in the file.
#[derive(BinRead, Debug, Clone, Serialize, Deserialize)]
#[br(big)]
pub struct WpdRecordHeader {
    /// File name (max 16 bytes, null-padded)
    #[br(count = 16)]
    #[br(map = |bytes: Vec<u8>| String::from_utf8_lossy(&bytes).trim_matches('\0').to_string())]
    pub name: String,
    /// Byte offset to file data
    pub offset: u32,
    /// Size of file data in bytes
    pub size: u32,
    /// File extension (max 8 bytes, null-padded)
    #[br(count = 8)]
    #[br(map = |bytes: Vec<u8>| String::from_utf8_lossy(&bytes).trim_matches('\0').to_string())]
    pub extension: String,
}

/// Parsed WPD record with loaded data.
///
/// Combines the header metadata with the actual file contents.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WpdRecord {
    /// File name (without extension)
    pub name: String,
    /// File extension (empty string if none)
    pub extension: String,
    /// Raw file data
    pub data: Vec<u8>,
}

/// Container for all records in a WPD file.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WpdData {
    /// All records from the WPD file
    pub records: Vec<WpdRecord>,
}
