//! # WBT Archive Repacker
//!
//! This module handles repacking modified files back into WBT archives.
//! Supports three repacking modes to balance speed vs. file size.
//!
//! ## Repacking Modes
//!
//! ### Type A: Full Repack (`repack_all`)
//!
//! Rebuilds the entire archive from an extracted directory.
//! - Pros: Smallest file size, proper sector alignment
//! - Cons: Slowest, requires full extraction
//!
//! ### Type B: Single File Injection (`repack_single`)
//!
//! Injects a single modified file into the existing archive.
//! - In-place: If new file fits in original slot
//! - Appended: If new file is larger, append to end
//!
//! ### Type C: Multiple File Injection (`repack_multiple`)
//!
//! Batch version of Type B for multiple files.
//! Uses parallel compression for performance.
//!
//! ## Sector Alignment
//!
//! Files are aligned to 2048-byte sectors. The path string
//! stores `offset / 2048` rather than raw byte offset.

use std::io::{Write, BufReader, Seek, SeekFrom};
use std::fs::{self, File, OpenOptions};
use std::path::{Path, PathBuf};
use std::collections::HashMap;
use log::{debug, info, trace, warn};
use crate::core::utils::GameCode;
use crate::modules::wbt::filelist::{Filelist, WbtError};
use crate::modules::wbt::crypto;
use flate2::write::ZlibEncoder;
use flate2::Compression;
use binrw::BinWriterExt;
use rayon::prelude::*;

/// WBT archive repacker for modifying game archives.
///
/// Provides methods for injecting modified files into existing
/// WBT archives while preserving the original file structure.
pub struct WbtRepacker {
    game_code: GameCode,
    filelist_path: PathBuf,
    container_path: PathBuf,
}

impl WbtRepacker {
    /// Creates a new repacker for the given archive.
    ///
    /// # Arguments
    ///
    /// * `filelist_path` - Path to the filelist index file
    /// * `container_path` - Path to the container data file
    /// * `game_code` - Target game (affects entry format)
    pub fn new(filelist_path: &str, container_path: &str, game_code: GameCode) -> Self {
        Self {
            game_code,
            filelist_path: PathBuf::from(filelist_path),
            container_path: PathBuf::from(container_path),
        }
    }

    /// Creates a backup of the filelist before modification.
    fn create_filelist_backup(&self) -> Result<(), WbtError> {
        if self.filelist_path.exists() {
            let mut backup_path = self.filelist_path.clone();
            backup_path.set_extension("bin.bak");
            debug!("Creating filelist backup: {:?}", backup_path);
            fs::copy(&self.filelist_path, &backup_path)?;
            trace!("Filelist backup created successfully");
        } else {
            warn!("Filelist does not exist, skipping backup: {:?}", self.filelist_path);
        }
        Ok(())
    }

    /// Creates a backup of the container before modification.
    fn create_container_backup(&self) -> Result<(), WbtError> {
        if self.container_path.exists() {
            let mut backup_path = self.container_path.clone();
            backup_path.set_extension("bin.bak");
            debug!("Creating container backup: {:?}", backup_path);
            fs::copy(&self.container_path, &backup_path)?;
            trace!("Container backup created successfully");
        } else {
            warn!("Container does not exist, skipping backup: {:?}", self.container_path);
        }
        Ok(())
    }

    /// Creates backups of both filelist and container before modification.
    fn create_backups(&self) -> Result<(), WbtError> {
        self.create_filelist_backup()?;
        self.create_container_backup()?;
        Ok(())
    }

    /// Repacks all files from a directory into a new archive (Type A).
    ///
    /// Completely rebuilds the container and filelist from extracted files.
    /// This is the slowest mode but produces optimal file layout.
    ///
    /// # Arguments
    ///
    /// * `extracted_dir` - Directory containing extracted files with original paths
    pub fn repack_all(&self, extracted_dir: &str) -> Result<(), WbtError> {
        info!("Repacking all files from directory: {}", extracted_dir);
        let extracted_path = Path::new(extracted_dir);

        debug!("Reading existing filelist: {:?}", self.filelist_path);
        let mut filelist = {
            let file = File::open(&self.filelist_path)?;
            let mut reader = BufReader::new(file);
            Filelist::read(&mut reader, self.game_code)?
        };
        info!("Processing {} entries for full repack", filelist.entries.len());

        self.create_backups()?;

        debug!("Compressing files in parallel...");
        let mut entries_with_data: Vec<_> = filelist.entries.par_iter().enumerate().map(|(i, entry)| {
            let metadata = filelist.get_metadata(i).map_err(|e| e.to_string())?;
            let file_to_pack = extracted_path.join(&metadata.path);

            let file_data = if file_to_pack.exists() {
                fs::read(&file_to_pack).map_err(|e| e.to_string())?
            } else {
                Vec::new()
            };

            let uncompressed_size = file_data.len() as u32;
            let is_compressed = metadata.uncompressed_size != metadata.compressed_size;

            let (packed_data, compressed_size) = if is_compressed && !file_data.is_empty() {
                let mut encoder = ZlibEncoder::new(Vec::new(), Compression::default());
                encoder.write_all(&file_data).map_err(|e| e.to_string())?;
                let data = encoder.finish().map_err(|e| e.to_string())?;
                let size = data.len() as u32;
                (data, size)
            } else {
                (file_data, uncompressed_size)
            };

            Ok((i, metadata.path, uncompressed_size, compressed_size, packed_data, entry.chunk_number))
        }).collect::<Result<Vec<_>, String>>().map_err(WbtError::Zlib)?;

        // CRITICAL: Sort by entry index to ensure path strings are added in correct order
        // Parallel iteration does not guarantee order, but path strings within each chunk
        // must be in entry order for path_string_pos to be correct
        entries_with_data.sort_by_key(|(i, _, _, _, _, _)| *i);

        debug!("Compressed {} files, writing new container", entries_with_data.len());

        let mut new_container = File::create(&self.container_path)?;
        let mut new_chunks_dict: HashMap<u32, Vec<u8>> = HashMap::new();
        for i in 0..filelist.chunks.len() {
            new_chunks_dict.insert(i as u32, Vec::new());
        }

        let mut current_offset: u64 = 0;
        let mut total_written: u64 = 0;
        let mut files_written = 0;

        for (_i, path, uncompressed_size, compressed_size, packed_data, chunk_number) in entries_with_data {
            if !current_offset.is_multiple_of(2048) {
                let pad = 2048 - (current_offset % 2048);
                new_container.write_all(&vec![0u8; pad as usize])?;
                current_offset += pad;
            }

            let start_pos_in_2048 = (current_offset / 2048) as u32;
            new_container.write_all(&packed_data)?;
            current_offset += packed_data.len() as u64;
            total_written += packed_data.len() as u64;
            files_written += 1;

            trace!(
                "Wrote [{}/{}]: {} ({} bytes at sector {})",
                files_written,
                filelist.entries.len(),
                path,
                packed_data.len(),
                start_pos_in_2048
            );

            let path_in_chunk = path.replace(std::path::MAIN_SEPARATOR, "/");
            let path_string = format!("{:x}:{:x}:{:x}:{}\0", start_pos_in_2048, uncompressed_size, compressed_size, path_in_chunk);

            new_chunks_dict.get_mut(&chunk_number).unwrap().extend_from_slice(path_string.as_bytes());
        }

        if let Some(last_entry) = filelist.entries.last() {
            new_chunks_dict.get_mut(&last_entry.chunk_number).unwrap().extend_from_slice(b"end\0");
        }

        info!(
            "Container written: {} files, {} bytes total",
            files_written, total_written
        );

        self.build_filelist(&mut filelist, new_chunks_dict)
    }

    /// Repacks a single file into an existing archive (Type B).
    ///
    /// Injects a modified file, either in-place or appended.
    ///
    /// # Arguments
    ///
    /// * `target_path_in_archive` - Virtual path of file to replace
    /// * `file_to_inject` - Local path to the new file data
    pub fn repack_single(&self, target_path_in_archive: &str, file_to_inject: &str) -> Result<(), WbtError> {
        debug!(
            "Single file repack: {} -> {}",
            file_to_inject, target_path_in_archive
        );
        self.repack_multiple(&[(target_path_in_archive.to_string(), file_to_inject.to_string())])
    }

    /// Repacks multiple files into an existing archive (Type C).
    ///
    /// Batch version of `repack_single`. Uses parallel compression.
    ///
    /// # Arguments
    ///
    /// * `files_to_patch` - Pairs of (archive_path, local_path)
    pub fn repack_multiple(&self, files_to_patch: &[(String, String)]) -> Result<(), WbtError> {
        info!("Repacking {} files into existing archive", files_to_patch.len());

        debug!("Reading existing filelist: {:?}", self.filelist_path);
        let mut filelist = {
            let file = File::open(&self.filelist_path)?;
            let mut reader = BufReader::new(file);
            Filelist::read(&mut reader, self.game_code)?
        };
        debug!("Filelist contains {} entries", filelist.entries.len());

        self.create_backups()?;

        let patch_map: HashMap<String, String> = files_to_patch.iter()
            .map(|(k, v)| (k.replace("\\", "/"), v.clone()))
            .collect();

        for (target, source) in &patch_map {
            trace!("Patch mapping: {} <- {}", target, source);
        }

        debug!("Processing entries in parallel...");
        let mut processed_entries: Vec<_> = (0..filelist.entries.len()).into_par_iter().map(|i| {
            let metadata = filelist.get_metadata(i).map_err(|e| e.to_string())?;
            let normalized_path = metadata.path.replace(std::path::MAIN_SEPARATOR, "/");
            let entry = &filelist.entries[i];

            if let Some(local_path) = patch_map.get(&normalized_path) {
                let file_data = fs::read(local_path).map_err(|e| {
                    if e.kind() == std::io::ErrorKind::NotFound {
                        format!("File not found: {} - ensure previous workflow steps have completed", local_path)
                    } else {
                        format!("Failed to read {}: {}", local_path, e)
                    }
                })?;
                let uncompressed_size = file_data.len() as u32;

                let (final_data, compressed_size) = if metadata.uncompressed_size != metadata.compressed_size {
                    let mut encoder = ZlibEncoder::new(Vec::new(), Compression::default());
                    encoder.write_all(&file_data).map_err(|e| e.to_string())?;
                    let data = encoder.finish().map_err(|e| e.to_string())?;
                    let size = data.len() as u32;
                    (data, size)
                } else {
                    (file_data, uncompressed_size)
                };

                Ok((i, normalized_path, Some((final_data, uncompressed_size, compressed_size)), metadata, entry.chunk_number))
            } else {
                Ok((i, normalized_path, None, metadata, entry.chunk_number))
            }
        }).collect::<Result<Vec<_>, String>>().map_err(WbtError::Repack)?;

        // CRITICAL: Sort by entry index to ensure path strings are added in correct order
        // Parallel iteration does not guarantee order, but path strings within each chunk
        // must be in entry order for path_string_pos to be correct
        processed_entries.sort_by_key(|(i, _, _, _, _)| *i);

        let mut new_chunks_dict: HashMap<u32, Vec<u8>> = HashMap::new();
        for i in 0..filelist.chunks.len() {
            new_chunks_dict.insert(i as u32, Vec::new());
        }

        debug!("Opening container for patching: {:?}", self.container_path);
        let mut container = OpenOptions::new()
            .read(true)
            .write(true)
            .open(&self.container_path)?;

        let mut patched_in_place = 0;
        let mut patched_appended = 0;
        let mut unchanged = 0;

        for (_i, normalized_path, patch, metadata, chunk_number) in processed_entries {
            let path_string = if let Some((final_data, uncompressed_size, compressed_size)) = patch {
                if compressed_size <= metadata.compressed_size {
                    // File fits in original location - zero out old data first (like C# CleanOldFile)
                    container.seek(SeekFrom::Start(metadata.offset))?;
                    container.write_all(&vec![0u8; metadata.compressed_size as usize])?;

                    // Now write the new data
                    container.seek(SeekFrom::Start(metadata.offset))?;
                    container.write_all(&final_data)?;
                    patched_in_place += 1;

                    let new_path_string = format!("{:x}:{:x}:{:x}:{}",
                        (metadata.offset / 2048) as u32, uncompressed_size, compressed_size, normalized_path);

                    info!(
                        "PATCHED IN-PLACE: entry {} '{}' at offset 0x{:X} ({} bytes -> {} bytes)",
                        _i, normalized_path, metadata.offset, metadata.compressed_size, final_data.len()
                    );
                    info!("  Original path string: '{}'", metadata.original_path_string);
                    info!("  New path string:      '{}'", new_path_string);

                    format!("{}\0", new_path_string)
                } else {
                    // File is larger, append to end - zero out old location first
                    container.seek(SeekFrom::Start(metadata.offset))?;
                    container.write_all(&vec![0u8; metadata.compressed_size as usize])?;

                    // Append to end with sector alignment
                    let mut end_pos = container.seek(SeekFrom::End(0))?;
                    if end_pos % 2048 != 0 {
                        let pad = 2048 - (end_pos % 2048);
                        container.write_all(&vec![0u8; pad as usize])?;
                        end_pos += pad;
                    }
                    container.seek(SeekFrom::Start(end_pos))?;
                    container.write_all(&final_data)?;
                    patched_appended += 1;

                    let new_path_string = format!("{:x}:{:x}:{:x}:{}",
                        (end_pos / 2048) as u32, uncompressed_size, compressed_size, normalized_path);

                    info!(
                        "PATCHED APPENDED: entry {} '{}' moved from 0x{:X} to 0x{:X} ({} bytes -> {} bytes)",
                        _i, normalized_path, metadata.offset, end_pos, metadata.compressed_size, final_data.len()
                    );
                    info!("  Original path string: '{}'", metadata.original_path_string);
                    info!("  New path string:      '{}'", new_path_string);

                    format!("{}\0", new_path_string)
                }
            } else {
                // CRITICAL: For unchanged files, use the ORIGINAL path string
                // This preserves exact hex formatting (e.g., "0a" stays "0a", not "a")
                // which is essential for correct path_string_pos calculations
                unchanged += 1;
                format!("{}\0", metadata.original_path_string)
            };

            // Log first few entries for debugging
            if _i < 5 {
                debug!(
                    "Adding path to chunk {}: entry {} -> '{}'",
                    chunk_number,
                    _i,
                    path_string.trim_end_matches('\0')
                );
            }

            new_chunks_dict.get_mut(&chunk_number).unwrap().extend_from_slice(path_string.as_bytes());
        }

        if let Some(last_entry) = filelist.entries.last() {
            debug!("Adding 'end' marker to chunk {}", last_entry.chunk_number);
            new_chunks_dict.get_mut(&last_entry.chunk_number).unwrap().extend_from_slice(b"end\0");
        }

        info!(
            "Patch complete: {} in-place, {} appended, {} unchanged",
            patched_in_place, patched_appended, unchanged
        );

        self.build_filelist(&mut filelist, new_chunks_dict)
    }

    /// Builds a new filelist from modified chunk data.
    ///
    /// Compresses path chunks with ZLIB and writes the complete
    /// filelist structure. Handles encryption for FF13-2/LR.
    fn build_filelist(&self, filelist: &mut Filelist, new_chunks_dict: HashMap<u32, Vec<u8>>) -> Result<(), WbtError> {
        debug!("Building new filelist with {} chunks", filelist.chunks.len());

        trace!("Compressing chunks in parallel...");
        let mut compressed_chunks: Vec<_> = (0..filelist.chunks.len() as u32).into_par_iter().map(|c| {
            let chunk_uncmp = new_chunks_dict.get(&c).unwrap();
            let mut encoder = ZlibEncoder::new(Vec::new(), Compression::default());
            encoder.write_all(chunk_uncmp).map_err(|e| e.to_string())?;
            let chunk_cmp = encoder.finish().map_err(|e| e.to_string())?;
            Ok((c, chunk_uncmp.len() as u32, chunk_cmp))
        }).collect::<Result<Vec<_>, String>>().map_err(WbtError::Zlib)?;

        // CRITICAL: Sort by chunk index to ensure chunk_info is written in correct order
        // Parallel iteration does not guarantee order, but chunk_info[n] must correspond to chunk n
        compressed_chunks.sort_by_key(|(c, _, _)| *c);

        let mut chunk_info_stream = std::io::Cursor::new(Vec::new());
        let mut chunk_data_stream = Vec::new();

        let mut total_uncompressed: usize = 0;
        let mut total_compressed: usize = 0;

        for (c, uncmp_len, chunk_cmp) in &compressed_chunks {
            let chunk_start = chunk_data_stream.len() as u32;
            chunk_data_stream.extend_from_slice(chunk_cmp);

            chunk_info_stream.write_le(uncmp_len)?;
            chunk_info_stream.write_le(&(chunk_cmp.len() as u32))?;
            chunk_info_stream.write_le(&chunk_start)?;

            total_uncompressed += *uncmp_len as usize;
            total_compressed += chunk_cmp.len();

            trace!(
                "Chunk {}: {} -> {} bytes",
                c,
                uncmp_len,
                chunk_cmp.len()
            );
        }

        debug!(
            "Chunks compressed: {} -> {} bytes (ratio: {:.1}x)",
            total_uncompressed,
            total_compressed,
            if total_compressed > 0 {
                total_uncompressed as f64 / total_compressed as f64
            } else {
                0.0
            }
        );

        let total_files = filelist.entries.len() as u32;
        let entries_size = total_files * 8;

        let chunk_info_offset = 12 + entries_size;
        let chunk_data_offset = chunk_info_offset + chunk_info_stream.get_ref().len() as u32;

        debug!(
            "Filelist structure: {} entries, chunk_info @ 0x{:X}, chunk_data @ 0x{:X}",
            total_files, chunk_info_offset, chunk_data_offset
        );

        // Update path_string_pos for each entry
        // This must match the order that paths were added to new_chunks_dict
        let mut total_entries_processed = 0;
        for c in 0..filelist.chunks.len() as u32 {
            let chunk_data = new_chunks_dict.get(&c).unwrap();
            let mut current_pos = 0;
            let mut entries_in_chunk = 0;

            for (entry_idx, entry) in filelist.entries.iter_mut().enumerate().filter(|(_, e)| e.chunk_number == c) {
                let old_pos = entry.path_string_pos;
                entry.path_string_pos = current_pos as u32;

                // Log first few entries, and always log if position changed significantly
                let pos_changed = old_pos != current_pos as u32;
                if total_entries_processed < 5 || pos_changed {
                    debug!(
                        "path_string_pos: entry {} in chunk {}, pos {} -> {} (entry_in_chunk: {})",
                        entry_idx, c, old_pos, current_pos, entries_in_chunk
                    );
                }

                while current_pos < chunk_data.len() && chunk_data[current_pos] != 0 {
                    current_pos += 1;
                }
                current_pos += 1;
                entries_in_chunk += 1;
                total_entries_processed += 1;
            }

            if entries_in_chunk > 0 {
                trace!(
                    "Chunk {}: {} entries, {} bytes of path data",
                    c, entries_in_chunk, chunk_data.len()
                );
            }
        }

        // Check if we need to encrypt (FF13-2/LR with encryption header)
        if let Some(encryption_header) = &filelist.encryption_header {
            self.build_encrypted_filelist(
                filelist,
                encryption_header,
                chunk_info_offset,
                chunk_data_offset,
                total_files,
                chunk_info_stream.get_ref(),
                &chunk_data_stream,
            )
        } else {
            self.build_unencrypted_filelist(
                filelist,
                chunk_info_offset,
                chunk_data_offset,
                total_files,
                chunk_info_stream.get_ref(),
                &chunk_data_stream,
            )
        }
    }

    /// Writes an unencrypted filelist (FF13-1 format).
    ///
    /// IMPORTANT: This follows the C# approach:
    /// 1. Write header (chunk_info_offset, chunk_data_offset, total_files)
    /// 2. Write entries with file_code, chunk_number, and the pre-calculated path_string_pos
    /// 3. Write chunk info and chunk data
    fn build_unencrypted_filelist(
        &self,
        filelist: &Filelist,
        chunk_info_offset: u32,
        chunk_data_offset: u32,
        total_files: u32,
        chunk_info_data: &[u8],
        chunk_data: &[u8],
    ) -> Result<(), WbtError> {
        trace!("Writing unencrypted filelist: {:?}", self.filelist_path);
        let mut new_filelist = File::create(&self.filelist_path)?;

        // Step 1: Write header
        new_filelist.write_le(&chunk_info_offset)?;
        new_filelist.write_le(&chunk_data_offset)?;
        new_filelist.write_le(&total_files)?;

        // Step 2: Write entries with file_code, chunk_number, and path_string_pos
        // The path_string_pos values were already calculated in build_filelist
        for (i, entry) in filelist.entries.iter().enumerate() {
            new_filelist.write_le(&entry.file_code)?;
            match self.game_code {
                GameCode::FF13_1 => {
                    new_filelist.write_le(&(entry.chunk_number as u16))?;
                    new_filelist.write_le(&(entry.path_string_pos as u16))?;

                    if i < 5 {
                        trace!(
                            "Entry {}: file_code=0x{:08X}, chunk={}, path_pos={}",
                            i, entry.file_code, entry.chunk_number, entry.path_string_pos
                        );
                    }
                }
                _ => {
                    // For FF13-2/LR: if the original entry had the 32768 flag,
                    // we need to add 32768 back to the new path_string_pos
                    let final_path_string_pos = if entry.has_continuation_flag {
                        entry.path_string_pos as u16 + 32768
                    } else {
                        entry.path_string_pos as u16
                    };
                    new_filelist.write_le(&final_path_string_pos)?;
                    new_filelist.write_le(&(entry.chunk_number as u8))?;
                    new_filelist.write_le(&entry.file_type_id.unwrap_or(0))?;
                }
            }
        }

        // Step 3: Write chunk info and data
        new_filelist.write_all(chunk_info_data)?;
        new_filelist.write_all(chunk_data)?;

        let entries_size = total_files * 8;
        let filelist_size = 12 + entries_size as usize + chunk_info_data.len() + chunk_data.len();
        info!(
            "Unencrypted filelist written: {} entries, {} bytes total",
            total_files, filelist_size
        );

        Ok(())
    }

    /// Writes an encrypted filelist (FF13-2/LR format).
    ///
    /// Re-encrypts the filelist using the original encryption header
    /// to preserve the same seed.
    #[allow(clippy::too_many_arguments)]
    fn build_encrypted_filelist(
        &self,
        filelist: &Filelist,
        encryption_header: &[u8; 32],
        chunk_info_offset: u32,
        chunk_data_offset: u32,
        total_files: u32,
        chunk_info_data: &[u8],
        chunk_data: &[u8],
    ) -> Result<(), WbtError> {
        trace!("Building encrypted filelist: {:?}", self.filelist_path);

        // Build the filelist body (starting at position 32)
        let mut body = Vec::new();

        // Write header (offsets and file count)
        body.extend_from_slice(&chunk_info_offset.to_le_bytes());
        body.extend_from_slice(&chunk_data_offset.to_le_bytes());
        body.extend_from_slice(&total_files.to_le_bytes());

        // Write entries
        for entry in &filelist.entries {
            body.extend_from_slice(&entry.file_code.to_le_bytes());
            match self.game_code {
                GameCode::FF13_1 => {
                    body.extend_from_slice(&(entry.chunk_number as u16).to_le_bytes());
                    body.extend_from_slice(&(entry.path_string_pos as u16).to_le_bytes());
                }
                _ => {
                    // For FF13-2/LR: if the original entry had the 32768 flag,
                    // we need to add 32768 back to the new path_string_pos
                    let final_path_string_pos = if entry.has_continuation_flag {
                        entry.path_string_pos as u16 + 32768
                    } else {
                        entry.path_string_pos as u16
                    };
                    body.extend_from_slice(&final_path_string_pos.to_le_bytes());
                    body.push(entry.chunk_number as u8);
                    body.push(entry.file_type_id.unwrap_or(0));
                }
            }
        }

        // Write chunk info and data
        body.extend_from_slice(chunk_info_data);
        body.extend_from_slice(chunk_data);

        // Pad to 8-byte boundary
        let padding_needed = (8 - (body.len() % 8)) % 8;
        body.extend(vec![0u8; padding_needed]);

        // Add 16 bytes for size and hash fields
        let filelist_data_size = body.len() as u32;
        body.extend_from_slice(&filelist_data_size.to_le_bytes()); // Size field

        // Compute checksum
        let checksum = crypto::compute_checksum(&body, 0, filelist_data_size / 4);
        body.extend_from_slice(&checksum.to_le_bytes()); // Hash field
        body.extend(vec![0u8; 8]); // Additional padding

        debug!(
            "Encrypted body: {} bytes (data: {}, padding: {}, footer: 16)",
            body.len(), filelist_data_size, padding_needed
        );

        // Extract seed from header and generate XOR table
        let seed_i32: i32 = ((encryption_header[9] as i32) << 24)
            | ((encryption_header[12] as i32) << 16)
            | ((encryption_header[2] as i32) << 8)
            | (encryption_header[0] as i32);
        let seed_u64: u64 = seed_i32 as i64 as u64;
        let seed: [u8; 8] = seed_u64.to_le_bytes();
        let xor_table = crypto::generate_xor_table(seed);

        // cryptBodySize is the body size + 8 (for the two 4-byte fields we just added)
        let crypt_body_size = filelist_data_size + 8;
        let block_count = crypt_body_size / 8;

        debug!(
            "Encrypting {} blocks (crypt_body_size: {})",
            block_count, crypt_body_size
        );

        // Encrypt the body
        crypto::encrypt_blocks(&mut body, &xor_table, block_count, 0);

        // Build final file
        let mut final_data = Vec::new();

        // Copy first 16 bytes of original header (seed)
        final_data.extend_from_slice(&encryption_header[0..16]);

        // Write cryptBodySize at position 16 (big-endian)
        final_data.extend_from_slice(&filelist_data_size.to_be_bytes());

        // Write encryption marker at position 20
        final_data.extend_from_slice(&501232760u32.to_le_bytes()); // 0x1DE03478

        // Write 8 zero bytes (positions 24-31)
        final_data.extend(vec![0u8; 8]);

        // Write encrypted body
        final_data.extend_from_slice(&body);

        // Write to file
        let mut new_filelist = File::create(&self.filelist_path)?;
        new_filelist.write_all(&final_data)?;

        info!(
            "Encrypted filelist written: {} entries, {} bytes total",
            total_files, final_data.len()
        );

        Ok(())
    }
}