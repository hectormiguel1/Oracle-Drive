//! # WBT High-Level API
//!
//! This module provides the public API for WBT archive operations.
//! These functions are the primary interface for Flutter/Dart code.
//!
//! ## Extraction Functions
//!
//! - [`extract_wbt`] - Extract entire archive
//! - [`extract_single_file`] - Extract one file by path
//! - [`extract_file_by_index`] - Extract one file by index
//! - [`extract_directory`] - Extract files matching directory prefix
//! - [`extract_files_by_indices`] - Extract multiple files by index
//!
//! ## Repacking Functions
//!
//! - [`repack_wbt`] - Full repack from directory
//! - [`repack_wbt_single`] - Inject single file
//! - [`repack_wbt_multiple`] - Inject multiple files
//!
//! ## Query Functions
//!
//! - [`get_file_list`] - List all files in archive

use std::fs::{self, File};
use std::io::BufReader;
use std::path::Path;
use log::{debug, info, trace};
use crate::core::utils::GameCode;
use crate::modules::wbt::{Filelist, WbtContainer, WbtError, WbtRepacker, WbtFileMetadata};

/// Extracts all files from a WBT archive to a directory.
///
/// Creates subdirectories as needed to preserve the archive structure.
///
/// # Arguments
///
/// * `filelist_path` - Path to the filelist index file
/// * `container_path` - Path to the container data file
/// * `output_dir` - Directory to extract files to
/// * `game_code` - Target game (FF13_1, FF13_2, FF13_3)
pub fn extract_wbt(
    filelist_path: &str,
    container_path: &str,
    output_dir: &str,
    game_code: GameCode,
) -> Result<(), WbtError> {
    info!("Starting WBT extraction for game {:?}", game_code);
    debug!("Filelist: {}", filelist_path);
    debug!("Container: {}", container_path);
    debug!("Output directory: {}", output_dir);

    trace!("Opening filelist file");
    let filelist_file = File::open(filelist_path)?;
    let mut filelist_reader = BufReader::new(filelist_file);
    let filelist = Filelist::read(&mut filelist_reader, game_code)?;

    trace!("Opening container file");
    let container_file = File::open(container_path)?;
    let container_reader = BufReader::new(container_file);
    let mut container = WbtContainer::new(container_reader, filelist);

    let total_files = container.total_files();
    info!("Found {} files to extract", total_files);

    let output_path = Path::new(output_dir);
    if !output_path.exists() {
        debug!("Creating output directory: {}", output_dir);
        fs::create_dir_all(output_path)?;
    }

    for i in 0..total_files {
        let (path, data) = container.extract_file(i)?;
        let full_path = output_path.join(&path);

        if let Some(parent) = full_path.parent() {
            fs::create_dir_all(parent)?;
        }

        trace!("Extracted [{}/{}]: {} ({} bytes)", i + 1, total_files, path, data.len());
        fs::write(full_path, data)?;
    }

    info!("WBT extraction completed successfully ({} files)", total_files);
    Ok(())
}

/// Repacks an entire directory back into a WBT archive.
///
/// This is a full repack that rebuilds the container and filelist.
/// Slower but produces optimal file layout.
pub fn repack_wbt(
    filelist_path: &str,
    container_path: &str,
    extracted_dir: &str,
    game_code: GameCode,
) -> Result<(), WbtError> {
    info!("Starting WBT full repack for game {:?}", game_code);
    debug!("Filelist: {}", filelist_path);
    debug!("Container: {}", container_path);
    debug!("Source directory: {}", extracted_dir);

    let repacker = WbtRepacker::new(filelist_path, container_path, game_code);
    let result = repacker.repack_all(extracted_dir);

    match &result {
        Ok(_) => info!("WBT full repack completed successfully"),
        Err(e) => log::error!("WBT full repack failed: {}", e),
    }
    result
}

/// Injects a single modified file into an existing archive.
///
/// Fast injection - file is placed in-place if it fits, or appended.
pub fn repack_wbt_single(
    filelist_path: &str,
    container_path: &str,
    target_path_in_archive: &str,
    file_to_inject: &str,
    game_code: GameCode,
) -> Result<(), WbtError> {
    info!("Starting WBT single file injection for game {:?}", game_code);
    debug!("Filelist: {}", filelist_path);
    debug!("Container: {}", container_path);
    debug!("Target in archive: {}", target_path_in_archive);
    debug!("File to inject: {}", file_to_inject);

    let repacker = WbtRepacker::new(filelist_path, container_path, game_code);
    let result = repacker.repack_single(target_path_in_archive, file_to_inject);

    match &result {
        Ok(_) => info!("WBT single file injection completed successfully"),
        Err(e) => log::error!("WBT single file injection failed: {}", e),
    }
    result
}

/// Injects multiple modified files into an existing archive.
///
/// Batch version of `repack_wbt_single`. Uses parallel compression.
pub fn repack_wbt_multiple(
    filelist_path: &str,
    container_path: &str,
    files_to_patch: &[(String, String)],
    game_code: GameCode,
) -> Result<(), WbtError> {
    info!("Starting WBT multiple file injection for game {:?}", game_code);
    debug!("Filelist: {}", filelist_path);
    debug!("Container: {}", container_path);
    info!("Files to patch: {}", files_to_patch.len());

    let repacker = WbtRepacker::new(filelist_path, container_path, game_code);
    let result = repacker.repack_multiple(files_to_patch);

    match &result {
        Ok(_) => info!("WBT multiple file injection completed successfully ({} files)", files_to_patch.len()),
        Err(e) => log::error!("WBT multiple file injection failed: {}", e),
    }
    result
}

/// Returns metadata for all files in a WBT archive.
///
/// This allows Flutter to display a file tree without extracting files.
/// Each entry includes path, offset, and size information.
pub fn get_file_list(
    filelist_path: &str,
    game_code: GameCode,
) -> Result<Vec<WbtFileMetadata>, WbtError> {
    info!("Reading WBT file list for game {:?}", game_code);
    debug!("Filelist: {}", filelist_path);

    let filelist_file = File::open(filelist_path)?;
    let mut filelist_reader = BufReader::new(filelist_file);
    let filelist = Filelist::read(&mut filelist_reader, game_code)?;

    let metadata = filelist.get_all_metadata()?;
    info!("Retrieved {} file entries from archive", metadata.len());

    Ok(metadata)
}

/// Extracts a single file from the WBT archive by its virtual path.
///
/// # Arguments
///
/// * `virtual_path` - Archive path (e.g., "db/item.wdb")
/// * `output_path` - Local path to write the file
pub fn extract_single_file(
    filelist_path: &str,
    container_path: &str,
    virtual_path: &str,
    output_path: &str,
    game_code: GameCode,
) -> Result<(), WbtError> {
    info!("Extracting single file: {} -> {}", virtual_path, output_path);

    let filelist_file = File::open(filelist_path)?;
    let mut filelist_reader = BufReader::new(filelist_file);
    let filelist = Filelist::read(&mut filelist_reader, game_code)?;

    // Find the file by path
    let metadata = filelist.find_by_path(virtual_path)?
        .ok_or_else(|| WbtError::Io(std::io::Error::new(
            std::io::ErrorKind::NotFound,
            format!("File not found in archive: {}", virtual_path),
        )))?;

    // Extract the file
    let container_file = File::open(container_path)?;
    let container_reader = BufReader::new(container_file);
    let mut container = WbtContainer::new(container_reader, filelist);

    let (_, data) = container.extract_file(metadata.index)?;

    // Ensure parent directory exists
    let output = Path::new(output_path);
    if let Some(parent) = output.parent() {
        fs::create_dir_all(parent)?;
    }

    fs::write(output_path, data)?;
    info!("Single file extracted successfully: {} bytes", metadata.uncompressed_size);

    Ok(())
}

/// Extracts a single file from the WBT archive by its index.
///
/// The file is written to `output_path/<archive_path>`.
pub fn extract_file_by_index(
    filelist_path: &str,
    container_path: &str,
    file_index: usize,
    output_path: &str,
    game_code: GameCode,
) -> Result<(), WbtError> {
    info!("Extracting file at index {} -> {}", file_index, output_path);

    let filelist_file = File::open(filelist_path)?;
    let mut filelist_reader = BufReader::new(filelist_file);
    let filelist = Filelist::read(&mut filelist_reader, game_code)?;

    let container_file = File::open(container_path)?;
    let container_reader = BufReader::new(container_file);
    let mut container = WbtContainer::new(container_reader, filelist);

    let (path, data) = container.extract_file(file_index)?;

    // Use the output_path as the base directory and preserve the virtual path
    let output_base = Path::new(output_path);
    let full_path = output_base.join(&path);

    if let Some(parent) = full_path.parent() {
        fs::create_dir_all(parent)?;
    }

    fs::write(&full_path, &data)?;
    info!("File extracted: {} ({} bytes)", path, data.len());

    Ok(())
}

/// Extracts all files matching a virtual directory prefix.
///
/// # Returns
///
/// The number of files extracted.
pub fn extract_directory(
    filelist_path: &str,
    container_path: &str,
    dir_prefix: &str,
    output_dir: &str,
    game_code: GameCode,
) -> Result<usize, WbtError> {
    info!("Extracting directory: {} -> {}", dir_prefix, output_dir);

    let filelist_file = File::open(filelist_path)?;
    let mut filelist_reader = BufReader::new(filelist_file);
    let filelist = Filelist::read(&mut filelist_reader, game_code)?;

    // Find all files matching the directory prefix
    let matching_files = filelist.find_by_directory(dir_prefix)?;
    info!("Found {} files matching directory prefix '{}'", matching_files.len(), dir_prefix);

    if matching_files.is_empty() {
        return Ok(0);
    }

    // Extract each matching file
    let container_file = File::open(container_path)?;
    let container_reader = BufReader::new(container_file);
    let mut container = WbtContainer::new(container_reader, filelist);

    let output_path = Path::new(output_dir);
    let mut extracted_count = 0;

    for metadata in &matching_files {
        let (path, data) = container.extract_file(metadata.index)?;
        let full_path = output_path.join(&path);

        if let Some(parent) = full_path.parent() {
            fs::create_dir_all(parent)?;
        }

        trace!("Extracted [{}/{}]: {} ({} bytes)",
            extracted_count + 1, matching_files.len(), path, data.len());
        fs::write(full_path, data)?;
        extracted_count += 1;
    }

    info!("Directory extraction complete: {} files extracted", extracted_count);
    Ok(extracted_count)
}

/// Extracts multiple files by their indices.
///
/// Skips invalid indices with a warning.
pub fn extract_files_by_indices(
    filelist_path: &str,
    container_path: &str,
    indices: &[usize],
    output_dir: &str,
    game_code: GameCode,
) -> Result<usize, WbtError> {
    info!("Extracting {} selected files", indices.len());

    let filelist_file = File::open(filelist_path)?;
    let mut filelist_reader = BufReader::new(filelist_file);
    let filelist = Filelist::read(&mut filelist_reader, game_code)?;

    let container_file = File::open(container_path)?;
    let container_reader = BufReader::new(container_file);
    let mut container = WbtContainer::new(container_reader, filelist);

    let output_path = Path::new(output_dir);
    let mut extracted_count = 0;

    for &index in indices {
        if index >= container.total_files() {
            log::warn!("Skipping invalid index: {}", index);
            continue;
        }

        let (path, data) = container.extract_file(index)?;
        let full_path = output_path.join(&path);

        if let Some(parent) = full_path.parent() {
            fs::create_dir_all(parent)?;
        }

        trace!("Extracted [{}/{}]: {} ({} bytes)",
            extracted_count + 1, indices.len(), path, data.len());
        fs::write(full_path, data)?;
        extracted_count += 1;
    }

    info!("Selected files extraction complete: {} files extracted", extracted_count);
    Ok(extracted_count)
}


