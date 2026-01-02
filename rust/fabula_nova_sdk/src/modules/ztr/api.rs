//! # ZTR High-Level API
//!
//! This module provides convenient, high-level functions for common ZTR
//! operations. These functions handle file I/O, encoding/decoding, and
//! format conversion automatically.
//!
//! ## Common Operations
//!
//! - [`extract_ztr_to_text`] - Export ZTR → human-readable text file
//! - [`pack_text_to_ztr`] - Import text file → ZTR binary
//! - [`parse_ztr`] - Load ZTR into memory as [`ZtrData`]
//! - [`pack_ztr_from_struct`] - Save [`ZtrData`] to ZTR binary
//!
//! ## Text File Format
//!
//! The text format uses ` |:| ` as delimiter between ID and text:
//! ```text
//! txtres_0001 |:| {Color White}Welcome to the game!
//! txtres_0002 |:| Press {Btn A} to start
//! ```
//!
//! Multi-line text is supported by continuation lines (no delimiter).
//!
//! ## Roundtrip Example
//!
//! ```rust,ignore
//! use fabula_nova_sdk::modules::ztr;
//! use fabula_nova_sdk::core::GameCode;
//!
//! // Extract to text for editing
//! ztr::extract_ztr_to_text("input.ztr", "text.txt", GameCode::FF13_1)?;
//!
//! // Edit text.txt in your favorite editor...
//!
//! // Pack back to ZTR
//! ztr::pack_text_to_ztr("text.txt", "output.ztr", GameCode::FF13_1)?;
//! ```

use anyhow::Result;
use std::fs::File;
use std::io::{BufReader, BufWriter, Write};
use std::path::Path;
use walkdir::WalkDir;

use super::key_dicts::GameCode;
use super::reader::ZtrReader;
use super::structs::{
    ZtrData, ZtrDirectoryResult, ZtrEntry, ZtrEntryWithSource, ZtrFileError, ZtrParseProgress,
};
use super::text_decoder::decode_ztr_line;
use super::writer::ZtrWriter;

/// Extracts a ZTR file to a human-readable text file.
///
/// This is the primary function for extracting game text for translation
/// or editing. Control codes are converted to `{Tag}` format.
///
/// # Arguments
/// * `ztr_path` - Path to the input ZTR file
/// * `txt_path` - Path to the output text file
/// * `game_code` - Which FF13 game (affects control code decoding)
///
/// # Output Format
/// Each line: `ID |:| Decoded Text`
///
/// # Errors
/// Returns an error if:
/// - Input file cannot be opened
/// - Output file cannot be created
/// - ZTR parsing fails
pub fn extract_ztr_to_text<P: AsRef<Path>>(
    ztr_path: P,
    txt_path: P,
    game_code: GameCode,
) -> Result<()> {
    let file = File::open(ztr_path)?;
    let mut reader = ZtrReader::new(BufReader::new(file));
    let entries = reader.read()?;

    // Convert to decoded entries
    let mut decoded_entries = Vec::new();
    for (id, data) in entries {
        let text = decode_ztr_line(&data, game_code, "Shift-JIS");
        decoded_entries.push((id, text));
    }

    write_ztr_text_file(&decoded_entries, txt_path)?;

    Ok(())
}

/// Helper to write entries to text file (for FFI dump).
pub fn write_ztr_text_file<P: AsRef<Path>>(
    entries: &[(String, String)],
    txt_path: P,
) -> Result<()> {
    let mut out_file = BufWriter::new(File::create(txt_path)?);
    for (id, text) in entries {
        writeln!(out_file, "{} |:| {}", id, text)?;
    }
    Ok(())
}

/// Helper to pack in-memory entries to ZTR (for FFI pack).
pub fn pack_ztr_from_memory<P: AsRef<Path>>(
    entries: &[(String, String)],
    ztr_path: P,
    game_code: GameCode,
) -> Result<()> {
    let mut out_file = File::create(ztr_path)?;
    let mut writer = ZtrWriter::new(&mut out_file, game_code);
    writer.write(entries)?;
    Ok(())
}

pub fn pack_ztr_from_struct<P: AsRef<Path>>(
    data: &ZtrData,
    ztr_path: P,
    game_code: GameCode,
) -> Result<()> {
    let entries: Vec<(String, String)> = data
        .entries
        .iter()
        .map(|e| (e.id.clone(), e.text.clone()))
        .collect();
    pack_ztr_from_memory(&entries, ztr_path, game_code)
}

/// High-level API to pack text file to ZTR.
pub fn pack_text_to_ztr<P: AsRef<Path>>(
    txt_path: P,
    ztr_path: P,
    game_code: GameCode,
) -> Result<()> {
    let file = File::open(txt_path)?;
    let reader = std::io::BufReader::new(file);
    use std::io::BufRead;

    let mut entries = Vec::new();
    let separator = " |:| ";

    let mut current_id = String::new();
    let mut current_text = String::new();

    for line in reader.lines() {
        let line = line?;
        if let Some((id, text)) = line.split_once(separator) {
            if !current_id.is_empty() {
                entries.push((current_id, current_text));
            }
            current_id = id.to_string();
            current_text = text.to_string();
        } else {
            // Continuation of previous text
            if !current_id.is_empty() {
                current_text.push('\n');
                current_text.push_str(&line);
            }
        }
    }
    if !current_id.is_empty() {
        entries.push((current_id, current_text));
    }

    pack_ztr_from_memory(&entries, ztr_path, game_code)
}

/// Parse ZTR file and return structured data (for Flutter).
pub fn parse_ztr<P: AsRef<Path>>(ztr_path: P, game_code: GameCode) -> Result<ZtrData> {
    let file = File::open(ztr_path)?;
    let mut reader = ZtrReader::new(BufReader::new(file));
    let raw_entries = reader.read()?;

    let mut entries = Vec::with_capacity(raw_entries.len());

    for (id, data) in raw_entries {
        let text = decode_ztr_line(&data, game_code, "Shift-JIS");
        entries.push(ZtrEntry { id, text });
    }

    // Mappings: Currently Reader does not extract "LastUsedDict" explicitly in a way that matches C# "Mappings" output.
    // In C#, `LastUsedDict` is populated during `Finalize` in `DecoderBase`.
    // My `decode_ztr_line` does the decoding but doesn't expose the dictionary state used.
    // However, the dictionaries are static in my implementation (`key_dicts.rs`).
    // The C# code returns the `LastUsedDict` which seems to be the mapping of keys it encountered/used?
    // Actually `ParsedZtr` has `Mappings`.
    // In `ZTRExtract.cs`: `result.Mappings = new Dictionary<string, string>(DecoderBase.LastUsedDict);`
    // `DecoderBase` populates it.

    // For now, I'll return an empty mapping list or populate it if I track used keys.
    // Since my decoder is stateless (uses static dicts), the "Mappings" would just be the static dict entries that were used?
    // Or all of them?
    // C# seems to accumulate them.
    // Since I don't track usage yet, I'll return empty. This should be sufficient for viewing text.

    Ok(ZtrData {
        entries,
        mappings: Vec::new(),
    })
}

pub fn parse_ztr_from_memory(data: &[u8], game_code: GameCode) -> Result<ZtrData> {
    let mut reader = ZtrReader::new(std::io::Cursor::new(data));
    let raw_entries = reader.read()?;

    let mut entries = Vec::with_capacity(raw_entries.len());
    for (id, data) in raw_entries {
        let text = decode_ztr_line(&data, game_code, "Shift-JIS");
        entries.push(ZtrEntry { id, text });
    }

    Ok(ZtrData {
        entries,
        mappings: Vec::new(),
    })
}

pub fn decode_ztr_to_text_string(data: &ZtrData) -> String {
    let mut out = String::new();
    for entry in &data.entries {
        out.push_str(&format!("{} |:| {}\n", entry.id, entry.text));
    }
    out
}

// =============================================================================
// Directory/Batch Parsing API
// =============================================================================

/// Recursively scans a directory for ZTR files and parses all of them.
///
/// This function:
/// 1. Recursively walks the directory tree
/// 2. Finds all files with `.ztr` extension (case-insensitive)
/// 3. Parses each file and collects entries with source file tracking
/// 4. Reports progress via callback
///
/// # Arguments
/// * `dir_path` - Path to the directory to scan
/// * `game_code` - Game version for decoding
/// * `progress_callback` - Optional callback for progress updates
///
/// # Returns
/// A `ZtrDirectoryResult` containing all parsed entries and error information.
pub fn parse_ztr_directory<P, F>(
    dir_path: P,
    game_code: GameCode,
    mut progress_callback: Option<F>,
) -> ZtrDirectoryResult
where
    P: AsRef<Path>,
    F: FnMut(ZtrParseProgress),
{
    let base_path = dir_path.as_ref();

    // Phase 1: Scan for ZTR files
    let mut ztr_files: Vec<std::path::PathBuf> = Vec::new();

    if let Some(ref mut cb) = progress_callback {
        cb(ZtrParseProgress {
            total_files: 0,
            processed_files: 0,
            success_count: 0,
            error_count: 0,
            current_file: String::new(),
            stage: "scanning".to_string(),
        });
    }

    for entry in WalkDir::new(base_path)
        .follow_links(true)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let path = entry.path();
        if path.is_file() {
            if let Some(ext) = path.extension() {
                if ext.to_string_lossy().to_lowercase() == "ztr" {
                    ztr_files.push(path.to_path_buf());
                }
            }
        }
    }

    let total_files = ztr_files.len();
    let mut entries: Vec<ZtrEntryWithSource> = Vec::new();
    let mut parsed_files: Vec<String> = Vec::new();
    let mut failed_files: Vec<ZtrFileError> = Vec::new();

    // Phase 2: Parse each file
    for (index, file_path) in ztr_files.iter().enumerate() {
        // Calculate relative path from base directory
        let relative_path = file_path
            .strip_prefix(base_path)
            .unwrap_or(file_path)
            .to_string_lossy()
            .to_string();

        if let Some(ref mut cb) = progress_callback {
            cb(ZtrParseProgress {
                total_files,
                processed_files: index,
                success_count: parsed_files.len(),
                error_count: failed_files.len(),
                current_file: relative_path.clone(),
                stage: "parsing".to_string(),
            });
        }

        // Try to parse the file
        match parse_ztr(file_path, game_code) {
            Ok(data) => {
                // Add entries with source file tracking
                for entry in data.entries {
                    entries.push(ZtrEntryWithSource {
                        id: entry.id,
                        text: entry.text,
                        source_file: relative_path.clone(),
                    });
                }
                parsed_files.push(relative_path);
            }
            Err(e) => {
                failed_files.push(ZtrFileError {
                    file_path: relative_path,
                    error: e.to_string(),
                });
            }
        }
    }

    // Phase 3: Complete
    if let Some(ref mut cb) = progress_callback {
        cb(ZtrParseProgress {
            total_files,
            processed_files: total_files,
            success_count: parsed_files.len(),
            error_count: failed_files.len(),
            current_file: String::new(),
            stage: "complete".to_string(),
        });
    }

    ZtrDirectoryResult {
        entries,
        parsed_files,
        failed_files,
        total_files,
    }
}

/// Simplified version without progress callback for direct use.
pub fn parse_ztr_directory_simple<P: AsRef<Path>>(
    dir_path: P,
    game_code: GameCode,
) -> ZtrDirectoryResult {
    parse_ztr_directory(dir_path, game_code, None::<fn(ZtrParseProgress)>)
}
