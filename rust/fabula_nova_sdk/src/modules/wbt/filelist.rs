//! # WBT Filelist Parser
//!
//! This module parses the filelist index for WBT (WhiteBin) archives.
//! The filelist maps file paths to their locations in the container file.
//!
//! ## Filelist Structure
//!
//! ```text
//! ┌─────────────────────────────────────────────────────────────┐
//! │ Header (12 bytes)                                           │
//! │   - chunk_info_offset (u32)                                 │
//! │   - chunk_data_offset (u32)                                 │
//! │   - total_files (u32)                                       │
//! ├─────────────────────────────────────────────────────────────┤
//! │ File Entries (8 bytes each)                                 │
//! │   FF13-1: file_code(4), chunk(2), path_pos(2)               │
//! │   FF13-2/LR: file_code(4), path_pos(2), chunk(1), type(1)   │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Chunk Info (12 bytes each)                                  │
//! │   - unknown (u32)                                           │
//! │   - compressed_size (u32)                                   │
//! │   - start_offset (u32)                                      │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Chunk Data (ZLIB compressed)                                │
//! │   Contains path strings in format:                          │
//! │   "OFFSET:UNCOMP:COMP:path/to/file.ext\0"                   │
//! └─────────────────────────────────────────────────────────────┘
//! ```
//!
//! ## Encryption (FF13-2/LR)
//!
//! FF13-2 and Lightning Returns use encrypted filelists with a 32-byte
//! header. The encryption uses a custom XOR-based block cipher.

use binrw::{binread, BinRead, BinReaderExt};
use std::io::{Cursor, Read, Seek, SeekFrom};
use thiserror::Error;
use log::{debug, trace, warn, info};
use crate::core::utils::GameCode;
use crate::modules::wbt::crypto;
use flate2::read::ZlibDecoder;

/// Errors that can occur during WBT operations.
#[derive(Debug, Error)]
pub enum WbtError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("BinRead error: {0}")]
    BinRead(#[from] binrw::Error),
    #[error("Zlib decompression error: {0}")]
    Zlib(String),
    #[error("Repack error: {0}")]
    Repack(String),
    #[error("Invalid path string format")]
    InvalidPathString,
    #[error("Utf8 error: {0}")]
    Utf8(#[from] std::string::FromUtf8Error),
}

/// Filelist file header.
///
/// Contains offsets and counts for parsing the rest of the file.
#[binread]
#[derive(Debug)]
#[br(little)]
pub struct FilelistHeader {
    /// Byte offset to chunk info section
    pub chunk_info_offset: u32,
    /// Byte offset to compressed chunk data
    pub chunk_data_offset: u32,
    /// Number of files in the archive
    pub total_files: u32,
}

/// Single file entry in the filelist.
///
/// Each entry points to a path string in a chunk which contains
/// the file's offset and size information.
#[derive(Debug)]
pub struct FileEntry {
    /// Unique file identifier (hash of path)
    pub file_code: u32,
    /// Chunk number containing this file's path string.
    /// For FF13-1: direct chunk number.
    /// For FF13-2/LR: resolved from path_string_pos flags.
    pub chunk_number: u32,
    /// Byte offset into chunk where path string starts.
    /// For FF13-2/LR: adjusted (32768 flag removed).
    pub path_string_pos: u32,
    /// File type identifier (FF13-2/LR only)
    pub file_type_id: Option<u8>,
    /// For FF13-2/LR: true if original path_string_pos was > 32767.
    /// When writing, this flag indicates that 32768 should be added
    /// to the new path_string_pos value to preserve the chunk transition marker.
    pub has_continuation_flag: bool,
}

/// Chunk metadata from the chunk info section.
///
/// Each chunk contains multiple path strings that are ZLIB compressed.
#[binread]
#[derive(Debug)]
#[br(little)]
pub struct ChunkInfo {
    /// Reserved/unknown field (usually uncompressed size)
    pub unknown: u32,
    /// Compressed size of this chunk
    pub compressed_size: u32,
    /// Offset from chunk_data_offset to this chunk's data
    pub start_offset: u32,
}

/// File metadata for a single entry in the WBT archive.
/// This struct is serializable via flutter_rust_bridge for use in Flutter.
#[derive(Debug, Clone)]
pub struct WbtFileMetadata {
    /// File index in the archive (0-based)
    pub index: usize,
    /// Byte offset in the container file
    pub offset: u64,
    /// Original uncompressed file size
    pub uncompressed_size: u32,
    /// Compressed file size (same as uncompressed if not compressed)
    pub compressed_size: u32,
    /// Virtual path within the archive (e.g., "chr/pc/c000/model.trb")
    pub path: String,
    /// Original path string from the chunk (preserves exact hex formatting)
    /// Format: "OFFSET:UNCOMPRESSED:COMPRESSED:path"
    pub original_path_string: String,
}

/// Parsed filelist containing all file entries and decompressed path chunks.
///
/// This struct holds all the information needed to locate files in the
/// container archive. The chunks contain null-terminated path strings
/// in the format: `OFFSET:UNCOMPRESSED:COMPRESSED:path/to/file.ext`
pub struct Filelist {
    /// All file entries from the filelist
    pub entries: Vec<FileEntry>,
    /// Decompressed path string chunks
    pub chunks: Vec<Vec<u8>>,
    /// Target game (affects parsing)
    pub game_code: GameCode,
    /// Original encryption header for re-encryption (FF13-2/LR only)
    pub encryption_header: Option<[u8; 32]>,
}

/// Checks if an encrypted filelist is already decrypted.
///
/// After decryption, a marker value is written at a specific offset.
/// If `stored_value == (crypt_body_size - 8)`, the file is decrypted.
fn is_already_decrypted(data: &[u8]) -> bool {
    if data.len() < 48 {
        return false;
    }

    // Get crypt body size from position 16 (big-endian u32)
    let crypt_body_size_bytes = [data[16], data[17], data[18], data[19]];
    let mut crypt_body_size = u32::from_be_bytes(crypt_body_size_bytes);
    crypt_body_size += 8;

    // Check position: 32 + cryptBodySize - 8 = 24 + cryptBodySize
    let check_pos = (24 + crypt_body_size) as usize;
    if check_pos + 4 > data.len() {
        return false;
    }

    // Read u32 at check position (little-endian)
    let stored_value = u32::from_le_bytes([
        data[check_pos],
        data[check_pos + 1],
        data[check_pos + 2],
        data[check_pos + 3],
    ]);

    // If stored_value equals (cryptBodySize - 8), file is already decrypted
    let expected = crypt_body_size - 8;
    let result = stored_value == expected;

    debug!(
        "wasDecrypted check: pos={}, stored=0x{:08X}, expected=0x{:08X}, result={}",
        check_pos, stored_value, expected, result
    );

    result
}

/// Decrypts an encrypted filelist in place.
///
/// Uses the WhiteBinTools crypto algorithm:
/// 1. Extract 4-byte seed from positions [9, 12, 2, 0] of the header
/// 2. Generate 264-byte XOR table from seed
/// 3. Decrypt 8-byte blocks starting at position 32
///
/// # Seed Extraction
///
/// ```text
/// seed = (header[9] << 24) | (header[12] << 16) | (header[2] << 8) | header[0]
/// ```
fn decrypt_filelist(data: &mut [u8]) -> Result<(), WbtError> {
    if data.len() < 48 {
        return Err(WbtError::Io(std::io::Error::new(
            std::io::ErrorKind::InvalidData,
            "File too small for encrypted filelist",
        )));
    }

    // Check if already decrypted (C# wasDecrypted check)
    if is_already_decrypted(data) {
        info!("Filelist is already decrypted, skipping decryption");
        return Ok(());
    }

    // Extract seed from first 16 bytes using C# algorithm:
    // seedArray8Bytes = (ulong)((baseSeedArray[9] << 24) | (baseSeedArray[12] << 16) | (baseSeedArray[2] << 8) | (baseSeedArray[0]))
    // IMPORTANT: In C#, the shifts are done on signed int, and when cast to ulong, negative values are sign-extended!
    let base_seed = &data[0..16];

    // C# computes this as signed int first
    let seed_i32: i32 = ((base_seed[9] as i32) << 24)
        | ((base_seed[12] as i32) << 16)
        | ((base_seed[2] as i32) << 8)
        | (base_seed[0] as i32);

    // Then casts to ulong (sign-extends if negative)
    let seed_u64: u64 = seed_i32 as i64 as u64;
    let seed: [u8; 8] = seed_u64.to_le_bytes();

    debug!("Filelist decryption: seed_i32=0x{:08X}, seed_u64=0x{:016X}, seed bytes = {:02X?}",
           seed_i32 as u32, seed_u64, seed);

    // Generate XOR table using WBT crypto
    let xor_table = crypto::generate_xor_table(seed);

    // Get crypt body size from position 16 (big-endian u32)
    let crypt_body_size_bytes = [data[16], data[17], data[18], data[19]];
    let mut crypt_body_size = u32::from_be_bytes(crypt_body_size_bytes);
    crypt_body_size += 8; // As per C# code

    debug!("Filelist decryption: crypt_body_size = {} bytes, block_count = {}", crypt_body_size, crypt_body_size / 8);

    // Use the crypto module's decrypt_blocks function
    crypto::decrypt_blocks(data, &xor_table, crypt_body_size / 8, 32);

    info!("Filelist decryption complete: {} blocks decrypted", crypt_body_size / 8);
    Ok(())
}

impl Filelist {
    pub fn read<R: Read + Seek>(mut reader: R, game_code: GameCode) -> Result<Self, WbtError> {
        debug!("Reading filelist for game {:?}", game_code);

        // Read entire file into memory for potential decryption
        reader.seek(SeekFrom::Start(0))?;
        let mut file_data = Vec::new();
        reader.read_to_end(&mut file_data)?;
        debug!("Read {} bytes from filelist file", file_data.len());

        if file_data.len() < 48 {
            return Err(WbtError::Io(std::io::Error::new(
                std::io::ErrorKind::InvalidData,
                "Filelist file too small",
            )));
        }

        // Diagnostic: dump first 48 bytes of file
        debug!(
            "First 48 bytes (before decryption): {:02X?}",
            &file_data[0..48]
        );

        // Check for encryption by reading magic value at position 20
        // Magic value 501232760 (0x1DE03478) indicates encrypted filelist
        let is_encrypted = match game_code {
            GameCode::FF13_1 => false, // FF13-1 never has encrypted filelists
            _ => {
                // FF13-2 and FF13-LR can have encrypted filelists
                let enc_header_number = u32::from_le_bytes([
                    file_data[20], file_data[21], file_data[22], file_data[23]
                ]);
                let encrypted = enc_header_number == 501232760; // 0x1DE03478
                debug!(
                    "Encryption check: value at pos 20 = 0x{:08X}, encrypted = {}",
                    enc_header_number, encrypted
                );
                encrypted
            }
        };

        // Preserve encryption header for later repacking
        let encryption_header: Option<[u8; 32]> = if is_encrypted {
            let mut header = [0u8; 32];
            header.copy_from_slice(&file_data[0..32]);
            Some(header)
        } else {
            None
        };

        // If encrypted, decrypt the file data
        if is_encrypted {
            info!("Decrypting encrypted filelist...");
            decrypt_filelist(&mut file_data)?;
            debug!(
                "First 48 bytes (after decryption): {:02X?}",
                &file_data[0..48]
            );
        }

        // Now parse from the (potentially decrypted) data
        // Header is at position 32 for encrypted files, position 0 for unencrypted
        let (header_offset, adjust_offset): (usize, u32) = if is_encrypted {
            debug!("Using encrypted mode: header at pos 32, adjusting offsets by 32");
            (32, 32)
        } else {
            debug!("Using unencrypted mode: header at pos 0");
            (0, 0)
        };

        // Parse header from the data
        let header = FilelistHeader {
            chunk_info_offset: u32::from_le_bytes([
                file_data[header_offset],
                file_data[header_offset + 1],
                file_data[header_offset + 2],
                file_data[header_offset + 3],
            ]) + adjust_offset,
            chunk_data_offset: u32::from_le_bytes([
                file_data[header_offset + 4],
                file_data[header_offset + 5],
                file_data[header_offset + 6],
                file_data[header_offset + 7],
            ]) + adjust_offset,
            total_files: u32::from_le_bytes([
                file_data[header_offset + 8],
                file_data[header_offset + 9],
                file_data[header_offset + 10],
                file_data[header_offset + 11],
            ]),
        };

        debug!(
            "Filelist header: total_files={}, chunk_info_offset=0x{:X}, chunk_data_offset=0x{:X}",
            header.total_files, header.chunk_info_offset, header.chunk_data_offset
        );

        // Create a cursor to read from the (possibly decrypted) data
        let mut cursor = Cursor::new(&file_data);

        // Position cursor after header (header is 12 bytes: 3 x u32)
        cursor.seek(SeekFrom::Start((header_offset + 12) as u64))?;

        trace!("Reading {} file entries", header.total_files);
        let mut entries = Vec::with_capacity(header.total_files as usize);

        // For FF13-2/LR, CurrentChunkNumber starts at -1 (as per C# reference)
        // We use i32 to handle the -1 start value
        let mut current_chunk_number: i32 = match game_code {
            GameCode::FF13_1 => 0,  // Not used for FF13-1, but initialize anyway
            _ => -1,  // FF13-2/LR: starts at -1, first increment brings it to 0
        };

        for entry_idx in 0..header.total_files {
            let file_code = cursor.read_le::<u32>()?;
            match game_code {
                GameCode::FF13_1 => {
                    let chunk_number = cursor.read_le::<u16>()? as u32;
                    let path_string_pos = cursor.read_le::<u16>()? as u32;
                    entries.push(FileEntry {
                        file_code,
                        chunk_number,
                        path_string_pos,
                        file_type_id: None,
                        has_continuation_flag: false, // FF13-1 doesn't use this flag
                    });
                }
                _ => {
                    // FF13_2 or FF13_3 (LR)
                    // These games use a different chunk numbering scheme:
                    // - path_string_pos == 0: increment current chunk number
                    // - path_string_pos == 32768: increment current chunk number, subtract 32768
                    // - path_string_pos > 32768: subtract 32768
                    let raw_path_string_pos = cursor.read_le::<u16>()? as u32;
                    let raw_chunk_number = cursor.read_le::<u8>()?;
                    let file_type_id = cursor.read_le::<u8>()?;

                    let mut path_string_pos = raw_path_string_pos;

                    // Track if the original value had the 32768 flag (for repacking)
                    // This is true when raw_path_string_pos > 32767 (i.e., >= 32768)
                    let has_continuation_flag = raw_path_string_pos > 32767;

                    // Handle special path_string_pos values
                    match raw_path_string_pos {
                        0 => {
                            current_chunk_number += 1;
                        }
                        32768 => {
                            current_chunk_number += 1;
                            path_string_pos = 0; // 32768 - 32768 = 0
                        }
                        pos if pos > 32768 => {
                            path_string_pos = pos - 32768;
                        }
                        _ => {
                            // Normal case, no adjustment needed
                        }
                    }

                    // Validate chunk number is non-negative
                    if current_chunk_number < 0 {
                        return Err(WbtError::Io(std::io::Error::new(
                            std::io::ErrorKind::InvalidData,
                            format!(
                                "Entry {} has negative chunk number {} (first entry must have path_string_pos 0 or >= 32768)",
                                entry_idx, current_chunk_number
                            ),
                        )));
                    }

                    // Debug first 10 entries to understand the pattern
                    if entry_idx < 10 {
                        debug!(
                            "Entry {}: file_code=0x{:08X}, raw_path_pos={}, raw_chunk={}, resolved_chunk={}, resolved_pos={}, type_id={}, has_flag={}",
                            entry_idx, file_code, raw_path_string_pos, raw_chunk_number,
                            current_chunk_number, path_string_pos, file_type_id, has_continuation_flag
                        );
                    }

                    entries.push(FileEntry {
                        file_code,
                        chunk_number: current_chunk_number as u32,
                        path_string_pos,
                        file_type_id: Some(file_type_id),
                        has_continuation_flag,
                    });
                }
            }
        }
        debug!("Parsed {} file entries", entries.len());

        // Read ChunkInfo
        cursor.seek(SeekFrom::Start(header.chunk_info_offset as u64))?;
        let total_chunks = (header.chunk_data_offset - header.chunk_info_offset) / 12;
        debug!("Reading {} chunk info entries", total_chunks);

        let mut chunk_infos = Vec::with_capacity(total_chunks as usize);
        for _ in 0..total_chunks {
            chunk_infos.push(ChunkInfo::read(&mut cursor)?);
        }

        // Read and decompress Chunks
        trace!("Decompressing {} chunks", total_chunks);
        let mut chunks = Vec::with_capacity(total_chunks as usize);
        let mut total_compressed: usize = 0;
        let mut total_decompressed: usize = 0;

        for (idx, info) in chunk_infos.iter().enumerate() {
            cursor.seek(SeekFrom::Start(
                (header.chunk_data_offset + info.start_offset) as u64,
            ))?;
            let mut compressed_data = vec![0u8; info.compressed_size as usize];
            cursor.read_exact(&mut compressed_data)?;

            let mut decoder = ZlibDecoder::new(&compressed_data[..]);
            let mut decompressed_data = Vec::new();
            decoder
                .read_to_end(&mut decompressed_data)
                .map_err(|e| WbtError::Zlib(e.to_string()))?;

            trace!(
                "Chunk {}: {} bytes compressed -> {} bytes decompressed",
                idx,
                compressed_data.len(),
                decompressed_data.len()
            );
            total_compressed += compressed_data.len();
            total_decompressed += decompressed_data.len();

            chunks.push(decompressed_data);
        }

        debug!(
            "Chunk decompression complete: {} bytes -> {} bytes (ratio: {:.1}x)",
            total_compressed,
            total_decompressed,
            if total_compressed > 0 {
                total_decompressed as f64 / total_compressed as f64
            } else {
                0.0
            }
        );

        // Debug: dump first 100 bytes of first 3 chunks to understand the format
        for (idx, chunk) in chunks.iter().take(3).enumerate() {
            let preview_len = std::cmp::min(100, chunk.len());
            debug!(
                "Chunk {} preview (len={}): {:?}",
                idx,
                chunk.len(),
                &chunk[..preview_len]
            );
            // Also show as string if it looks like text
            if let Ok(s) = std::str::from_utf8(&chunk[..preview_len]) {
                debug!("Chunk {} as text: '{}'", idx, s);
            }
        }

        debug!(
            "Filelist loaded: {} entries, {} chunks",
            entries.len(),
            chunks.len()
        );

        Ok(Self {
            entries,
            chunks,
            game_code,
            encryption_header,
        })
    }

    pub fn get_metadata(&self, entry_index: usize) -> Result<WbtFileMetadata, WbtError> {
        let entry = &self.entries[entry_index];

        // Bounds check for chunk number
        if entry.chunk_number as usize >= self.chunks.len() {
            return Err(WbtError::Io(std::io::Error::new(
                std::io::ErrorKind::InvalidData,
                format!(
                    "Entry {} has invalid chunk number {} (max: {})",
                    entry_index,
                    entry.chunk_number,
                    self.chunks.len().saturating_sub(1)
                ),
            )));
        }

        let chunk = &self.chunks[entry.chunk_number as usize];
        let start = entry.path_string_pos as usize;

        // Bounds check for path string position
        if start >= chunk.len() {
            return Err(WbtError::Io(std::io::Error::new(
                std::io::ErrorKind::InvalidData,
                format!(
                    "Entry {} has invalid path_string_pos {} (chunk {} len: {})",
                    entry_index,
                    start,
                    entry.chunk_number,
                    chunk.len()
                ),
            )));
        }

        let mut end = start;
        while end < chunk.len() && chunk[end] != 0 {
            end += 1;
        }

        let path_string = String::from_utf8(chunk[start..end].to_vec())?;

        // Debug: show the first 20 bytes at the read position for problematic entries
        if entry_index < 5 {
            let preview_end = std::cmp::min(start + 50, chunk.len());
            let preview = &chunk[start..preview_end];
            debug!(
                "Entry {} path preview: chunk={}, pos={}, bytes={:?}, string='{}'",
                entry_index, entry.chunk_number, start, preview, path_string
            );
        }

        // Parse "HEX_OFFSET:HEX_UNCOMPRESSED_SIZE:HEX_COMPRESSED_SIZE:PATH"
        let parts: Vec<&str> = path_string.split(':').collect();
        if parts.len() < 4 {
            warn!(
                "Invalid path string format at entry {}: '{}'",
                entry_index, path_string
            );
            return Err(WbtError::InvalidPathString);
        }

        let offset =
            u64::from_str_radix(parts[0], 16).map_err(|_| WbtError::InvalidPathString)? * 2048;
        let uncompressed_size =
            u32::from_str_radix(parts[1], 16).map_err(|_| WbtError::InvalidPathString)?;
        let compressed_size =
            u32::from_str_radix(parts[2], 16).map_err(|_| WbtError::InvalidPathString)?;
        // Keep forward slashes as-is - the archive format uses forward slashes
        // Converting to platform separator causes .wdb/.bin files to look like directories
        let path = parts[3..].join(":");

        trace!(
            "Metadata[{}]: offset=0x{:X}, size={}/{} bytes, path={}",
            entry_index,
            offset,
            compressed_size,
            uncompressed_size,
            path
        );

        Ok(WbtFileMetadata {
            index: entry_index,
            offset,
            uncompressed_size,
            compressed_size,
            path,
            original_path_string: path_string,
        })
    }

    /// Returns metadata for all files in the archive.
    pub fn get_all_metadata(&self) -> Result<Vec<WbtFileMetadata>, WbtError> {
        let mut metadata_list = Vec::with_capacity(self.entries.len());
        for i in 0..self.entries.len() {
            metadata_list.push(self.get_metadata(i)?);
        }
        Ok(metadata_list)
    }

    /// Finds a file by its virtual path (case-insensitive on path separators).
    pub fn find_by_path(&self, target_path: &str) -> Result<Option<WbtFileMetadata>, WbtError> {
        // Normalize the target path to use forward slashes for comparison
        let normalized_target = target_path.replace('\\', "/").to_lowercase();

        for i in 0..self.entries.len() {
            let metadata = self.get_metadata(i)?;
            let normalized_path = metadata.path.replace('\\', "/").to_lowercase();
            if normalized_path == normalized_target {
                return Ok(Some(metadata));
            }
        }
        Ok(None)
    }

    /// Returns all files that match a directory prefix.
    pub fn find_by_directory(&self, dir_prefix: &str) -> Result<Vec<WbtFileMetadata>, WbtError> {
        // Normalize the directory prefix
        let normalized_prefix = dir_prefix.replace('\\', "/").to_lowercase();
        let prefix_with_slash = if normalized_prefix.ends_with('/') {
            normalized_prefix
        } else {
            format!("{}/", normalized_prefix)
        };

        let mut matches = Vec::new();
        for i in 0..self.entries.len() {
            let metadata = self.get_metadata(i)?;
            let normalized_path = metadata.path.replace('\\', "/").to_lowercase();
            if normalized_path.starts_with(&prefix_with_slash) {
                matches.push(metadata);
            }
        }
        Ok(matches)
    }
}
