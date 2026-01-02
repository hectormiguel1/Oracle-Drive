//! # Fabula Nova SDK - Public API
//!
//! This module provides the public API surface for the Flutter/Dart frontend.
//! All functions in this module are designed to be called via Flutter Rust Bridge.
//!
//! ## Module Overview
//!
//! The API is organized by game file format:
//!
//! | API Section | Format | Description                          |
//! |-------------|--------|--------------------------------------|
//! | Logging     | -      | Log streaming and level control      |
//! | ZTR         | `.ztr` | Text resource extraction/packing     |
//! | WBT         | `.bin` | WhiteBin archive operations          |
//! | WPD         | `.wpd` | Package data extraction/repacking    |
//! | WCT         | `.clb` | Encryption/decryption                |
//! | IMG         | `.imgb`| Texture extraction/repacking         |
//! | WDB         | `.wdb` | Database parsing/writing             |
//!
//! ## Game Codes
//!
//! Most functions accept a `game_code` parameter:
//!
//! | Code | Game                        |
//! |------|-----------------------------|
//! | 0    | Final Fantasy XIII          |
//! | 1    | Final Fantasy XIII-2        |
//! | 2    | Lightning Returns: FF XIII  |
//!
//! ## Error Handling
//!
//! Functions return `Result<T>` using `anyhow` for error handling.
//! Errors are propagated to Dart as exceptions.
//!
//! ## Example Usage (from Dart)
//!
//! ```dart
//! // Initialize the SDK
//! await api.initApp();
//!
//! // Extract a ZTR file
//! await api.ztrExtractToText(
//!   inFile: 'strings.ztr',
//!   outFile: 'strings.txt',
//!   gameCode: 0, // FF13
//! );
//! ```

use crate::core::utils::GameCode;
use crate::core::logging;
use crate::modules::img::{api as img_api, structs::ImgData};
use crate::modules::wbt::api as wbt_api;
use crate::modules::wct::{self, Action, TargetType};
use crate::modules::wdb::{api as wdb_api, structs::WdbData};
use crate::modules::wpd::{api as wpd_api, structs::WpdData};
use crate::modules::ztr::{
    api as ztr_api,
    structs::{ZtrData, ZtrDirectoryResult, ZtrParseProgress},
};
use anyhow::Result;
use std::path::Path;
use crate::frb_generated::StreamSink;

// ============================================================================
// LOGGING API
// ============================================================================
//
// Two log delivery mechanisms are provided:
// 1. Stream-based (create_log_stream): Real-time but breaks on hot restart
// 2. Polling-based (fetch_logs): Survives hot restart, recommended for dev

/// Creates a log stream using StreamSink (original pattern).
/// NOTE: This may not work well with hot restart. Prefer using fetch_logs() instead.
pub fn create_log_stream(sink: StreamSink<String>) -> Result<()> {
    logging::set_log_callback(move |msg| {
        if let Err(e) = sink.add(msg) {
            eprintln!("Rust: Failed to send log to stream: {:?}", e);
        }
    });
    Ok(())
}

pub fn init_app() {
    let _ = logging::init_logger();
    flutter_rust_bridge::setup_default_user_utils();
    log::info!("Rust SDK initialized.");
}

/// Sets the log level for the Rust logger.
///
/// # Arguments
/// * `level` - Log level (0=Off, 1=Error, 2=Warn, 3=Info, 4=Debug, 5=Trace)
pub fn set_log_level(level: i32) {
    let log_level = logging::LogLevel::from(level);
    logging::set_log_level(log_level);
}

/// Gets the current log level.
///
/// # Returns
/// Log level as integer (0=Off, 1=Error, 2=Warn, 3=Info, 4=Debug, 5=Trace)
pub fn get_log_level() -> i32 {
    logging::get_log_level() as i32
}

pub fn test_log(message: String) {
    log::info!("Test log from Dart: {}", message);
    log::warn!("Test warning from Rust");
    log::error!("Test error from Rust");
}

/// Clears the log callback to prevent dangling references on hot reload.
/// Call this before reinitializing the Dart side.
pub fn clear_log_callback() {
    logging::clear_log_callback();
}

// --- POLLING-BASED LOG API (Hot Restart Safe) ---

/// Fetches all new logs since the last fetch.
/// This is safe to call after hot restart - the Rust log buffer survives.
/// Returns an empty vector if no new logs are available.
pub fn fetch_logs() -> Vec<String> {
    logging::fetch_logs()
}

/// Gets all logs currently in the buffer.
/// Use this on initialization to get historical logs.
pub fn get_all_buffered_logs() -> Vec<String> {
    logging::get_all_buffered_logs()
}

/// Resets the log read index so the next fetch_logs() returns all buffered logs.
/// Call this after hot restart to ensure you don't miss logs.
pub fn reset_log_read_index() {
    logging::reset_log_read_index();
}

// ============================================================================
// ZTR API - Text Resources
// ============================================================================

/// Extracts ZTR file to a text file.
///
/// # Arguments
/// * `in_file` - Path to the source .ztr file.
/// * `out_file` - Path to the destination .txt file.
/// * `game_code` - Game version (0: FF13, 1: FF13-2, 2: LR).
pub fn ztr_extract_to_text(in_file: String, out_file: String, game_code: i32) -> Result<()> {
    let gc = map_game_code(game_code);
    ztr_api::extract_ztr_to_text(Path::new(&in_file), Path::new(&out_file), gc)
}

/// Parses ZTR file into memory structure.
pub fn ztr_parse(in_file: String, game_code: i32) -> Result<ZtrData> {
    let gc = map_game_code(game_code);
    ztr_api::parse_ztr(&in_file, gc)
}

/// Parses ZTR from memory buffer into memory structure.
pub fn ztr_parse_from_memory(data: Vec<u8>, game_code: i32) -> Result<ZtrData> {
    let gc = map_game_code(game_code);
    ztr_api::parse_ztr_from_memory(&data, gc)
}

/// Packs in-memory entries (ID, Text) into a ZTR file.
pub fn ztr_pack_from_data(
    entries: Vec<(String, String)>,
    out_file: String,
    game_code: i32,
) -> Result<()> {
    let gc = map_game_code(game_code);
    ztr_api::pack_ztr_from_memory(&entries, &out_file, gc)
}

/// Packs ZtrData structure into a ZTR file.
pub fn ztr_pack_from_struct(data: ZtrData, out_file: String, game_code: i32) -> Result<()> {
    let gc = map_game_code(game_code);
    ztr_api::pack_ztr_from_struct(&data, &out_file, gc)
}

/// Converts memory structure to formatted text string.
pub fn ztr_to_text_string(data: ZtrData) -> String {
    ztr_api::decode_ztr_to_text_string(&data)
}

/// Parses all ZTR files in a directory recursively with progress streaming.
///
/// # Arguments
/// * `dir_path` - Path to the directory to scan recursively.
/// * `game_code` - Game version (0: FF13, 1: FF13-2, 2: LR).
/// * `progress_sink` - StreamSink for progress updates.
///
/// # Returns
/// A `ZtrDirectoryResult` containing all parsed entries and error information.
pub fn ztr_parse_directory(
    dir_path: String,
    game_code: i32,
    progress_sink: StreamSink<ZtrParseProgress>,
) -> ZtrDirectoryResult {
    let gc = map_game_code(game_code);
    ztr_api::parse_ztr_directory(&dir_path, gc, Some(|progress: ZtrParseProgress| {
        let _ = progress_sink.add(progress);
    }))
}

/// Parses all ZTR files in a directory recursively (simple version without progress).
///
/// # Arguments
/// * `dir_path` - Path to the directory to scan recursively.
/// * `game_code` - Game version (0: FF13, 1: FF13-2, 2: LR).
///
/// # Returns
/// A `ZtrDirectoryResult` containing all parsed entries and error information.
pub fn ztr_parse_directory_simple(dir_path: String, game_code: i32) -> ZtrDirectoryResult {
    let gc = map_game_code(game_code);
    ztr_api::parse_ztr_directory_simple(&dir_path, gc)
}

// ============================================================================
// WBT API - WhiteBin Archives
// ============================================================================

/// Extracts all files from a WhiteBinTools archive.
///
/// # Arguments
/// * `filelist_path` - Path to the filelistu.win32.bin file.
/// * `container_path` - Path to the white_imgu.win32.bin file.
/// * `out_dir` - Directory where files will be extracted.
/// * `game_code` - Game version (0: FF13, 1: FF13-2, 2: LR).
pub fn wbt_extract(
    filelist_path: String,
    container_path: String,
    out_dir: String,
    game_code: i32,
) -> Result<()> {
    let gc = map_game_code(game_code);
    wbt_api::extract_wbt(&filelist_path, &container_path, &out_dir, gc)
        .map_err(|e| anyhow::anyhow!(e))
}

/// Repacks files from a directory into a WhiteBinTools archive.
pub fn wbt_repack(
    filelist_path: String,
    container_path: String,
    extracted_dir: String,
    game_code: i32,
) -> Result<()> {
    let gc = map_game_code(game_code);
    wbt_api::repack_wbt(&filelist_path, &container_path, &extracted_dir, gc)
        .map_err(|e| anyhow::anyhow!(e))
}

/// Repacks a single file into a WhiteBinTools archive.
pub fn wbt_repack_single(
    filelist_path: String,
    container_path: String,
    target_path_in_archive: String,
    file_to_inject: String,
    game_code: i32,
) -> Result<()> {
    let gc = map_game_code(game_code);
    wbt_api::repack_wbt_single(
        &filelist_path,
        &container_path,
        &target_path_in_archive,
        &file_to_inject,
        gc,
    )
    .map_err(|e| anyhow::anyhow!(e))
}

/// Repacks multiple files into a WhiteBinTools archive.
pub fn wbt_repack_multiple(
    filelist_path: String,
    container_path: String,
    files_to_patch: Vec<(String, String)>,
    game_code: i32,
) -> Result<()> {
    let gc = map_game_code(game_code);
    wbt_api::repack_wbt_multiple(&filelist_path, &container_path, &files_to_patch, gc)
        .map_err(|e| anyhow::anyhow!(e))
}

/// File metadata for a single entry in a WBT archive.
/// Mirrors the Rust struct for flutter_rust_bridge serialization.
pub struct WbtFileEntry {
    /// File index in the archive (0-based)
    pub index: usize,
    /// Byte offset in the container file
    pub offset: u64,
    /// Original uncompressed file size
    pub uncompressed_size: u32,
    /// Compressed file size
    pub compressed_size: u32,
    /// Virtual path within the archive
    pub path: String,
}

/// Returns the file list metadata from a WBT archive.
/// Use this to display a file tree in Flutter without extracting files.
pub fn wbt_get_file_list(
    filelist_path: String,
    game_code: i32,
) -> Result<Vec<WbtFileEntry>> {
    let gc = map_game_code(game_code);
    let metadata_list = wbt_api::get_file_list(&filelist_path, gc)
        .map_err(|e| anyhow::anyhow!(e))?;

    Ok(metadata_list
        .into_iter()
        .map(|m| WbtFileEntry {
            index: m.index,
            offset: m.offset,
            uncompressed_size: m.uncompressed_size,
            compressed_size: m.compressed_size,
            path: m.path,
        })
        .collect())
}

/// Extracts a single file from the WBT archive by its virtual path.
pub fn wbt_extract_single_file(
    filelist_path: String,
    container_path: String,
    virtual_path: String,
    output_path: String,
    game_code: i32,
) -> Result<()> {
    let gc = map_game_code(game_code);
    wbt_api::extract_single_file(&filelist_path, &container_path, &virtual_path, &output_path, gc)
        .map_err(|e| anyhow::anyhow!(e))
}

/// Extracts a single file from the WBT archive by its index.
pub fn wbt_extract_file_by_index(
    filelist_path: String,
    container_path: String,
    file_index: usize,
    output_dir: String,
    game_code: i32,
) -> Result<()> {
    let gc = map_game_code(game_code);
    wbt_api::extract_file_by_index(&filelist_path, &container_path, file_index, &output_dir, gc)
        .map_err(|e| anyhow::anyhow!(e))
}

/// Extracts all files matching a virtual directory prefix.
/// Returns the number of files extracted.
pub fn wbt_extract_directory(
    filelist_path: String,
    container_path: String,
    dir_prefix: String,
    output_dir: String,
    game_code: i32,
) -> Result<usize> {
    let gc = map_game_code(game_code);
    wbt_api::extract_directory(&filelist_path, &container_path, &dir_prefix, &output_dir, gc)
        .map_err(|e| anyhow::anyhow!(e))
}

/// Extracts multiple files by their indices.
/// Returns the number of files extracted.
pub fn wbt_extract_files_by_indices(
    filelist_path: String,
    container_path: String,
    indices: Vec<usize>,
    output_dir: String,
    game_code: i32,
) -> Result<usize> {
    let gc = map_game_code(game_code);
    wbt_api::extract_files_by_indices(&filelist_path, &container_path, &indices, &output_dir, gc)
        .map_err(|e| anyhow::anyhow!(e))
}

// ============================================================================
// WPD API - Package Data
// ============================================================================

/// Unpacks WPD archive to a directory. Returns the WpdData structure.
pub fn wpd_unpack(in_file: String, out_dir: String) -> Result<WpdData> {
    wpd_api::unpack_wpd(in_file, out_dir)
}

/// Repacks directory into a WPD archive.
pub fn wpd_repack(in_dir: String, out_file: String) -> Result<()> {
    wpd_api::repack_wpd(in_dir, out_file)
}

// ============================================================================
// WCT API - Encryption/Decryption
// ============================================================================

/// Performs encryption/decryption on supported files (FileList or CLB).
///
/// # Arguments
/// * `target` - Target file type (0: FileList, 1: CLB).
/// * `action` - Crypt action (0: Decrypt, 1: Encrypt).
/// * `input_file` - Path to the file to process.
pub fn wct_process(target: TargetType, action: Action, input_file: String) -> Result<()> {
    wct::process_file(target, action, Path::new(&input_file)).map_err(|e| anyhow::anyhow!(e))
}

// ============================================================================
// IMG API - Textures
// ============================================================================

/// Unpacks IMGB to a DDS file using XGR/IMG header.
pub fn img_unpack(header_file: String, imgb_file: String, out_dds: String) -> Result<ImgData> {
    img_api::extract_img_to_dds(header_file, imgb_file, out_dds)
}

/// Unpacks IMGB to memory using XGR/IMG header.
pub fn img_unpack_to_memory(header_file: String, imgb_file: String) -> Result<(ImgData, Vec<u8>)> {
    img_api::extract_img_to_memory(header_file, imgb_file)
}

/// Repacks DDS back to IMGB (strict size parity).
pub fn img_repack_strict(header_file: String, imgb_file: String, in_dds: String) -> Result<()> {
    img_api::repack_img_strict(header_file, imgb_file, in_dds)
}

// ============================================================================
// WDB API - Game Databases
// ============================================================================

/// Parses WDB file into memory structure.
pub fn wdb_parse(in_file: String, game_code: i32) -> Result<WdbData> {
    let gc = map_game_code(game_code);
    wdb_api::parse_wdb(in_file, gc)
}

/// Packs memory structure into a WDB file.
pub fn wdb_repack(data: WdbData, out_file: String) -> Result<()> {
    let game_code = determine_wdb_game_code(&data);
    wdb_api::pack_wdb(&data, out_file, game_code)
}

/// Converts WDB memory structure to JSON string.
pub fn wdb_to_json(data: WdbData) -> Result<String> {
    wdb_api::wdb_to_json_string(&data)
}

/// Parses JSON string into WDB memory structure.
pub fn wdb_from_json(json: String) -> Result<WdbData> {
    wdb_api::wdb_from_json_string(&json)
}

// ============================================================================
// INTERNAL HELPERS
// ============================================================================

/// Maps integer game code to GameCode enum.
fn map_game_code(code: i32) -> GameCode {
    match code {
        0 => GameCode::FF13_1,
        1 => GameCode::FF13_2,
        2 => GameCode::FF13_3,
        _ => GameCode::FF13_1,
    }
}

fn determine_wdb_game_code(data: &WdbData) -> GameCode {
    if let Some(crate::modules::wdb::structs::WdbValue::String(s)) = data.header.get("gameCode") {
        match s.as_str() {
            "FF13_2" => GameCode::FF13_2,
            "LR" | "FF13_3" => GameCode::FF13_3,
            _ => GameCode::FF13_1,
        }
    } else {
        GameCode::FF13_1
    }
}
