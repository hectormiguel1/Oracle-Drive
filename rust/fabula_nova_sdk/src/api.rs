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

// ============================================================================
// CGT/MCP API - Crystarium Data
// ============================================================================

use crate::modules::crystalium::{
    api as cgt_api,
    structs::{CgtFile, McpFile},
};

/// Parses a CGT (Crystal Graph Tree) file from disk.
///
/// # Arguments
/// * `in_file` - Path to the CGT file
///
/// # Returns
/// * `Ok(CgtFile)` - Parsed CGT data with entries and nodes
pub fn cgt_parse(in_file: String) -> Result<CgtFile> {
    cgt_api::parse_cgt(&in_file)
}

/// Parses a CGT file from memory.
///
/// # Arguments
/// * `data` - Raw CGT file bytes
///
/// # Returns
/// * `Ok(CgtFile)` - Parsed CGT data
pub fn cgt_parse_from_memory(data: Vec<u8>) -> Result<CgtFile> {
    cgt_api::parse_cgt_from_memory(data)
}

/// Writes a CGT file to disk.
///
/// # Arguments
/// * `cgt` - The CGT data to write
/// * `out_file` - Output file path
pub fn cgt_write(cgt: CgtFile, out_file: String) -> Result<()> {
    cgt_api::write_cgt(&cgt, &out_file)
}

/// Writes a CGT file to memory.
///
/// # Arguments
/// * `cgt` - The CGT data to serialize
///
/// # Returns
/// * `Ok(Vec<u8>)` - Serialized CGT bytes
pub fn cgt_write_to_memory(cgt: CgtFile) -> Result<Vec<u8>> {
    cgt_api::write_cgt_to_memory(&cgt)
}

/// Converts a CGT file to JSON string.
pub fn cgt_to_json(cgt: CgtFile) -> Result<String> {
    cgt_api::cgt_to_json(&cgt)
}

/// Parses a CGT file from JSON string.
pub fn cgt_from_json(json: String) -> Result<CgtFile> {
    cgt_api::cgt_from_json(&json)
}

/// Validates a CGT file structure and returns warnings.
///
/// # Returns
/// * `Vec<String>` - List of validation warnings (empty if valid)
pub fn cgt_validate(cgt: CgtFile) -> Vec<String> {
    cgt_api::validate_cgt(&cgt)
}

/// Parses an MCP (Master Crystal Pattern) file from disk.
///
/// # Arguments
/// * `in_file` - Path to the MCP file
///
/// # Returns
/// * `Ok(McpFile)` - Parsed MCP data with patterns
pub fn mcp_parse(in_file: String) -> Result<McpFile> {
    cgt_api::parse_mcp(&in_file)
}

/// Parses an MCP file from memory.
///
/// # Arguments
/// * `data` - Raw MCP file bytes
///
/// # Returns
/// * `Ok(McpFile)` - Parsed MCP data
pub fn mcp_parse_from_memory(data: Vec<u8>) -> Result<McpFile> {
    cgt_api::parse_mcp_from_memory(data)
}

/// Converts an MCP file to JSON string.
pub fn mcp_to_json(mcp: McpFile) -> Result<String> {
    cgt_api::mcp_to_json(&mcp)
}

/// Parses an MCP file from JSON string.
pub fn mcp_from_json(json: String) -> Result<McpFile> {
    cgt_api::mcp_from_json(&json)
}

// ============================================================================
// VFX API - Visual Effects
// ============================================================================

use crate::modules::vfx::{
    api as vfx_api,
    structs::{VfxData, VfxSummary, VfxTexture},
};

/// Parses a VFX XFV file and returns all effect data.
///
/// # Arguments
/// * `in_file` - Path to the XFV file
///
/// # Returns
/// Complete VFX data including textures, models, animations, and effects.
pub fn vfx_parse(in_file: String) -> Result<VfxData> {
    vfx_api::parse_vfx(&in_file)
}

/// Gets a quick summary of VFX file contents.
///
/// # Arguments
/// * `in_file` - Path to the XFV file
///
/// # Returns
/// Summary with counts and effect names.
pub fn vfx_get_summary(in_file: String) -> Result<VfxSummary> {
    vfx_api::get_vfx_summary(&in_file)
}

/// Lists all effect names in a VFX file.
///
/// # Arguments
/// * `in_file` - Path to the XFV file
///
/// # Returns
/// List of effect names.
pub fn vfx_list_effects(in_file: String) -> Result<Vec<String>> {
    vfx_api::list_vfx_effects(&in_file)
}

/// Lists all textures in a VFX file.
///
/// # Arguments
/// * `in_file` - Path to the XFV file
///
/// # Returns
/// List of texture info (name, dimensions, format).
pub fn vfx_list_textures(in_file: String) -> Result<Vec<VfxTexture>> {
    vfx_api::list_vfx_textures(&in_file)
}

/// Exports VFX data to JSON string.
///
/// # Arguments
/// * `in_file` - Path to the XFV file
///
/// # Returns
/// JSON string representation of VFX data.
pub fn vfx_export_json(in_file: String) -> Result<String> {
    let data = vfx_api::parse_vfx(&in_file)?;
    vfx_api::vfx_to_json(&data)
}

/// Extracts VFX textures to DDS files.
///
/// Requires the paired IMGB file to be present.
///
/// # Arguments
/// * `xfv_path` - Path to the XFV file
/// * `output_dir` - Directory to write DDS files
///
/// # Returns
/// List of extracted DDS file paths.
pub fn vfx_extract_textures(xfv_path: String, output_dir: String) -> Result<Vec<String>> {
    vfx_api::extract_vfx_textures(&xfv_path, &output_dir)
}

/// Extracts a single VFX texture as PNG bytes in memory.
///
/// This function loads only the specified texture without writing to disk.
/// Ideal for on-demand texture preview in the UI.
///
/// # Arguments
/// * `xfv_path` - Path to the XFV file
/// * `texture_name` - Name of the texture (e.g., "v04fdfc11828acd")
///
/// # Returns
/// Tuple of ((width, height), png_bytes).
pub fn vfx_extract_texture_as_png(xfv_path: String, texture_name: String) -> Result<((u32, u32), Vec<u8>)> {
    vfx_api::extract_vfx_texture_as_png(&xfv_path, &texture_name)
}

// ============================================================
// DDS to PNG Conversion
// ============================================================

/// Converts a DDS file to PNG format.
///
/// Supports DXT1, DXT3, DXT5, and uncompressed RGBA formats.
///
/// # Arguments
/// * `dds_path` - Path to input DDS file
/// * `png_path` - Path to output PNG file
///
/// # Returns
/// Tuple of (width, height) of the converted image.
pub fn convert_dds_to_png(dds_path: String, png_path: String) -> Result<(u32, u32)> {
    img_api::convert_dds_to_png(&dds_path, &png_path)
}

/// Converts a DDS file to PNG and returns the PNG data as bytes.
///
/// Useful for displaying textures directly in Flutter.
///
/// # Arguments
/// * `dds_path` - Path to input DDS file
///
/// # Returns
/// Tuple of ((width, height), png_bytes).
pub fn convert_dds_to_png_bytes(dds_path: String) -> Result<((u32, u32), Vec<u8>)> {
    img_api::convert_dds_to_png_bytes(&dds_path)
}

// ============================================================
// VFX Player API
// ============================================================
//
// GPU-based VFX effect player for real-time rendering.
// Uses wgpu for headless rendering and streams frames to Flutter.

use crate::modules::vfx::renderer::VfxPlayer;
use std::sync::Mutex;
use once_cell::sync::Lazy;

/// Global VFX player instance (single player at a time)
static VFX_PLAYER: Lazy<Mutex<Option<VfxPlayer>>> = Lazy::new(|| Mutex::new(None));

/// Initializes the VFX player with specified render dimensions.
///
/// Must be called before loading models or rendering frames.
///
/// # Arguments
/// * `width` - Render width in pixels
/// * `height` - Render height in pixels
///
/// # Returns
/// Ok(()) on success.
pub fn vfx_player_init(width: u32, height: u32) -> Result<()> {
    let player = VfxPlayer::new(width, height)?;
    *VFX_PLAYER.lock().unwrap() = Some(player);
    log::info!("VFX Player initialized: {}x{}", width, height);
    Ok(())
}

/// Loads a test quad with specified color for debugging.
///
/// # Arguments
/// * `r`, `g`, `b`, `a` - RGBA color (0.0 to 1.0)
///
/// # Returns
/// Ok(()) on success.
pub fn vfx_player_load_test(r: f32, g: f32, b: f32, a: f32) -> Result<()> {
    let mut player_guard = VFX_PLAYER.lock().unwrap();
    let player = player_guard
        .as_mut()
        .ok_or_else(|| anyhow::anyhow!("VFX Player not initialized"))?;
    player.load_test_quad([r, g, b, a])
}

/// Loads a VFX model for rendering.
///
/// The model must exist in the VFX file, and a texture must be provided as RGBA bytes.
///
/// # Arguments
/// * `xfv_path` - Path to the XFV file
/// * `model_name` - Name of the model to load
/// * `texture_name` - Name of the texture to use (or empty for first texture)
///
/// # Returns
/// Ok(()) on success.
pub fn vfx_player_load_model(xfv_path: String, model_name: String, texture_name: String) -> Result<()> {
    // Parse VFX file
    let vfx_data = vfx_api::parse_vfx(&xfv_path)?;

    // Find the model
    let model = vfx_data
        .models
        .iter()
        .find(|m| m.name == model_name)
        .ok_or_else(|| anyhow::anyhow!("Model '{}' not found", model_name))?;

    // Determine which texture to use
    // Note: model.texture_refs contains original file paths (e.g., "whiteproj\tex\fm02_jp.dds")
    // but VFX textures are stored with hash-based names (e.g., "v04fdfc11828acd")
    // So we need to use the hash-based texture names from vfx_data.textures
    let tex_name = if !texture_name.is_empty() {
        // User specified a texture name - use it directly
        texture_name.clone()
    } else {
        // Try to find a texture that matches the model's texture ref by looking for partial matches
        // or fall back to the first available texture
        let tex = if let Some(tex_ref) = model.texture_refs.first() {
            // Extract just the filename from path (e.g., "fm02_jp.dds" from "whiteproj\tex\fm02_jp.dds")
            let filename = tex_ref.split(&['\\', '/'][..]).last().unwrap_or(tex_ref);
            let basename = filename.split('.').next().unwrap_or(filename).to_lowercase();

            log::debug!("Looking for texture matching '{}' (basename: '{}')", tex_ref, basename);

            // Try to find a texture whose name contains the basename (unlikely but worth trying)
            // If not found, use the first available texture
            vfx_data.textures.first()
                .map(|t| t.name.clone())
        } else {
            // No texture refs - use first available
            vfx_data.textures.first()
                .map(|t| t.name.clone())
        };

        tex.ok_or_else(|| anyhow::anyhow!("No textures available in VFX file"))?
    };

    log::info!("Using texture '{}' for model '{}'", tex_name, model_name);
    if !model.texture_refs.is_empty() {
        log::debug!("Model references textures: {:?}", model.texture_refs);
    }

    // Extract texture as PNG bytes (then convert to RGBA)
    let ((tex_width, tex_height), png_bytes) = vfx_api::extract_vfx_texture_as_png(&xfv_path, &tex_name)?;

    // Decode PNG to RGBA
    let img = image::load_from_memory(&png_bytes)?;
    let rgba = img.to_rgba8();
    let rgba_bytes = rgba.into_raw();

    // Load into player
    let mut player_guard = VFX_PLAYER.lock().unwrap();
    let player = player_guard
        .as_mut()
        .ok_or_else(|| anyhow::anyhow!("VFX Player not initialized"))?;

    player.load_model(model, &rgba_bytes, tex_width, tex_height)?;

    log::info!("Loaded model '{}' with texture '{}' ({}x{})", model_name, tex_name, tex_width, tex_height);
    Ok(())
}

/// Renders a single frame and returns RGBA pixel data.
///
/// # Arguments
/// * `delta_time` - Time elapsed since last frame (in seconds)
///
/// # Returns
/// RGBA pixel data (width * height * 4 bytes).
pub fn vfx_player_render_frame(delta_time: f32) -> Result<Vec<u8>> {
    let mut player_guard = VFX_PLAYER.lock().unwrap();
    let player = player_guard
        .as_mut()
        .ok_or_else(|| anyhow::anyhow!("VFX Player not initialized"))?;

    player.render_frame(delta_time)
}

/// Gets the current animation time.
///
/// # Returns
/// Current animation time in seconds.
pub fn vfx_player_get_time() -> Result<f32> {
    let player_guard = VFX_PLAYER.lock().unwrap();
    let player = player_guard
        .as_ref()
        .ok_or_else(|| anyhow::anyhow!("VFX Player not initialized"))?;

    Ok(player.animation.time)
}

/// Resets the animation to the beginning.
pub fn vfx_player_reset() -> Result<()> {
    let mut player_guard = VFX_PLAYER.lock().unwrap();
    let player = player_guard
        .as_mut()
        .ok_or_else(|| anyhow::anyhow!("VFX Player not initialized"))?;

    player.animation.reset();
    Ok(())
}

/// Disposes of the VFX player and releases GPU resources.
pub fn vfx_player_dispose() {
    let mut player_guard = VFX_PLAYER.lock().unwrap();
    if player_guard.take().is_some() {
        log::info!("VFX Player disposed");
    }
}

/// Checks if the VFX player is initialized.
///
/// # Returns
/// True if initialized, false otherwise.
pub fn vfx_player_is_initialized() -> bool {
    VFX_PLAYER.lock().unwrap().is_some()
}

/// Gets the render dimensions.
///
/// # Returns
/// Tuple of (width, height) in pixels.
pub fn vfx_player_get_dimensions() -> Result<(u32, u32)> {
    let player_guard = VFX_PLAYER.lock().unwrap();
    let player = player_guard
        .as_ref()
        .ok_or_else(|| anyhow::anyhow!("VFX Player not initialized"))?;

    Ok((player.frame_buffer.width, player.frame_buffer.height))
}
