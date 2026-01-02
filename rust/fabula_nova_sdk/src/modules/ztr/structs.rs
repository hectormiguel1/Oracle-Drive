//! # ZTR Data Structures
//!
//! This module defines all data structures used for ZTR file parsing, writing,
//! and interoperability with Dart/Flutter and C code.
//!
//! ## Structure Categories
//!
//! 1. **Binary Format Structures** - Direct representations of ZTR file format
//!    - [`ZtrFileHeader`] - 20-byte file header
//!    - [`LineInfo`] - 4-byte per-line metadata
//!
//! 2. **High-Level Rust/Dart Structures** - For application use
//!    - [`ZtrData`] - Complete parsed ZTR file
//!    - [`ZtrEntry`] - Single text entry (ID + text)
//!    - [`ZtrMapEntry`] - Key-value mapping for control codes
//!
//! 3. **C FFI Structures** - For legacy C interop
//!    - [`ZtrEntryC`], [`ZtrKeyMappingC`], [`ZtrResultDataC`]

use binrw::binrw;
use serde::{Deserialize, Serialize};

// =============================================================================
// Binary Format Structures
// =============================================================================

/// ZTR file header - first 20 bytes of every ZTR file.
///
/// All fields are stored in big-endian format.
///
/// # Binary Layout
/// ```text
/// Offset  Size  Field
/// 0x00    8     magic (always 0x01 for valid ZTR)
/// 0x08    4     line_count (number of text entries)
/// 0x0C    4     dcmp_ids_size (decompressed size of all IDs)
/// 0x10    4     dict_chunk_offsets_count (number of dictionary chunks + 1)
/// ```
///
/// # Example
/// ```rust,ignore
/// use binrw::BinReaderExt;
/// let header: ZtrFileHeader = file.read_be()?;
/// println!("Contains {} text entries", header.line_count);
/// ```
#[binrw]
#[br(big)]
#[bw(big)]
#[derive(Debug, Clone)]
pub struct ZtrFileHeader {
    /// Magic number, always 0x01 for valid ZTR files.
    /// Used to verify file format.
    pub magic: u64,

    /// Total number of text entries (lines) in the file.
    /// Each entry has an ID and associated text content.
    pub line_count: u32,

    /// Total size of all decompressed string IDs in bytes.
    /// Used to calculate ID chunk boundaries (each chunk max 4096 bytes).
    pub dcmp_ids_size: u32,

    /// Number of entries in the dictionary chunk offset array.
    /// The last offset points to the end of all text data.
    pub dict_chunk_offsets_count: u32,
}

/// Per-line metadata for locating text within compressed chunks.
///
/// Each text entry in the ZTR file has a corresponding LineInfo that
/// describes where to find its content in the compressed data stream.
///
/// # Binary Layout (4 bytes)
/// ```text
/// Offset  Size  Field
/// 0x00    1     dict_chunk_id (which dictionary chunk)
/// 0x01    1     chara_start_in_dict_page (offset within dictionary page)
/// 0x02    2     line_start_pos_in_chunk (offset within decompressed chunk)
/// ```
///
/// # Decompression Algorithm
/// 1. Seek to the dictionary chunk indicated by `dict_chunk_id`
/// 2. Load the chunk's dictionary (byte pair → expanded bytes mapping)
/// 3. Seek to `line_start_pos_in_chunk` within the chunk's data
/// 4. If line starts within a dictionary page, skip `chara_start_in_dict_page` bytes
/// 5. Read and expand bytes until double-null terminator (0x00 0x00)
#[binrw]
#[br(big)]
#[bw(big)]
#[derive(Debug, Clone)]
pub struct LineInfo {
    /// Index of the dictionary chunk containing this line's text.
    /// Dictionary chunks are 4096 bytes of decompressed data each.
    pub dict_chunk_id: u8,

    /// Starting character offset within a dictionary page.
    /// Used when a line starts in the middle of an expanded dictionary entry.
    /// Usually 0 unless the previous line ends mid-expansion.
    pub chara_start_in_dict_page: u8,

    /// Byte offset from the start of the chunk's data section.
    /// Points to where this line's text begins after dictionary expansion.
    pub line_start_pos_in_chunk: u16,
}

// =============================================================================
// Error Types
// =============================================================================

/// Errors that can occur during ZTR file operations.
///
/// This enum covers all error conditions from parsing, writing, and encoding
/// ZTR files.
#[derive(Debug, thiserror::Error)]
pub enum ZtrError {
    /// Standard I/O error (file not found, permission denied, etc.)
    #[error("IO Error: {0}")]
    Io(#[from] std::io::Error),

    /// Binary parsing/writing error from binrw library
    #[error("BinRw Error: {0}")]
    BinRw(#[from] binrw::Error),

    /// UTF-8 decoding error when converting IDs to strings
    #[error("Utf8 Error: {0}")]
    Utf8(#[from] std::string::FromUtf8Error),
}

// =============================================================================
// High-Level Structures for Flutter/Dart Interop
// =============================================================================

/// A single text entry from a ZTR file.
///
/// Each entry consists of a unique string ID and its associated text content.
/// The text may contain control codes represented as `{Tag}` placeholders.
///
/// # Example
/// ```rust,ignore
/// let entry = ZtrEntry {
///     id: "txtres_0001".to_string(),
///     text: "{Color White}Hello, traveler!".to_string(),
/// };
/// ```
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZtrEntry {
    /// Unique identifier for this text entry.
    /// Used by the game engine to look up specific strings.
    /// Examples: "txtres_0001", "btl_001_001", "menu_save_confirm"
    pub id: String,

    /// The decoded text content with control codes as `{Tag}` placeholders.
    /// Examples:
    /// - "{Color Gold}Lightning{Color White} joined the party!"
    /// - "Press {Btn A} to continue"
    /// - "HP restored by {Counter Type 1} points"
    pub text: String,
}

/// Key-value mapping for control code dictionaries.
///
/// Used to export the mapping between tag names and their meanings.
/// Primarily for debugging and documentation purposes.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZtrMapEntry {
    /// The tag name as it appears in decoded text (e.g., "{Color White}")
    pub key: String,

    /// Description or hex representation of the control code
    pub value: String,
}

/// Complete parsed ZTR file data.
///
/// This structure represents a fully parsed ZTR file, ready for viewing,
/// editing, or repacking. It's the primary interface for ZTR operations.
///
/// # Usage
/// ```rust,ignore
/// // Parse a ZTR file
/// let data = parse_ztr("dialogue.ztr", GameCode::FF13_1)?;
///
/// // Modify entries
/// data.entries[0].text = "Modified text".to_string();
///
/// // Save changes
/// pack_ztr_from_struct(&data, "dialogue_mod.ztr", GameCode::FF13_1)?;
/// ```
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZtrData {
    /// All text entries in the file, in order.
    pub entries: Vec<ZtrEntry>,

    /// Control code mappings used during decoding.
    /// Currently empty; reserved for future use.
    pub mappings: Vec<ZtrMapEntry>,
}

// =============================================================================
// Batch/Directory Loading Structures
// =============================================================================

/// A text entry with its source file path for batch loading.
///
/// Used when loading multiple ZTR files from a directory, allowing
/// tracking of which file each entry came from.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZtrEntryWithSource {
    /// Unique identifier for this text entry.
    pub id: String,

    /// The decoded text content.
    pub text: String,

    /// Relative path to the source ZTR file (relative to the scanned directory).
    pub source_file: String,
}

/// Result of parsing all ZTR files in a directory.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZtrDirectoryResult {
    /// All entries from all parsed files.
    pub entries: Vec<ZtrEntryWithSource>,

    /// List of files that were successfully parsed.
    pub parsed_files: Vec<String>,

    /// List of files that failed to parse, with error messages.
    pub failed_files: Vec<ZtrFileError>,

    /// Total number of ZTR files found.
    pub total_files: usize,
}

/// Error information for a failed ZTR file parse.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZtrFileError {
    /// Path to the file that failed.
    pub file_path: String,

    /// Error message describing what went wrong.
    pub error: String,
}

/// Progress update during directory parsing.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZtrParseProgress {
    /// Total number of ZTR files found.
    pub total_files: usize,

    /// Number of files processed so far.
    pub processed_files: usize,

    /// Number of successfully parsed files.
    pub success_count: usize,

    /// Number of failed files.
    pub error_count: usize,

    /// Path to the file currently being processed.
    pub current_file: String,

    /// Current stage: "scanning", "parsing", "complete".
    pub stage: String,
}

// =============================================================================
// Legacy C-Interop Structures (Manual Memory Layout)
// =============================================================================

use std::ffi::c_char;

/// C-compatible text entry for legacy FFI.
///
/// # Memory Management
/// Both `id` and `text` are heap-allocated C strings.
/// The caller must free them when done.
#[repr(C)]
pub struct ZtrEntryC {
    /// Null-terminated C string for the entry ID
    pub id: *mut c_char,
    /// Null-terminated C string for the decoded text
    pub text: *mut c_char,
}

/// C-compatible key-value pair for control code mappings.
#[repr(C)]
pub struct ZtrKeyMappingC {
    /// Null-terminated C string for the key (tag name)
    pub key: *mut c_char,
    /// Null-terminated C string for the value (description)
    pub value: *mut c_char,
}

/// C-compatible result structure for ZTR parsing.
///
/// Contains arrays of entries and mappings with their counts.
/// All pointers are heap-allocated and must be freed by the caller.
#[repr(C)]
pub struct ZtrResultDataC {
    /// Array of ZtrEntryC structures
    pub entries: *mut ZtrEntryC,
    /// Number of entries in the array
    pub entry_count: i32,
    /// Array of ZtrKeyMappingC structures
    pub mappings: *mut ZtrKeyMappingC,
    /// Number of mappings in the array
    pub mapping_count: i32,
}