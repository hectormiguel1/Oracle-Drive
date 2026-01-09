//! # Event High-Level API
//!
//! This module provides the public API for Event file operations.
//!
//! ## Functions
//!
//! - [`parse_event_metadata`] - Parse event file and extract metadata (in-memory)
//! - [`parse_event_metadata_bytes`] - Parse from raw bytes
//! - [`extract_event`] - Extract event file to directory

use std::fs::File;
use std::io::{BufReader, Cursor};
use std::path::Path;
use anyhow::Result;

use super::reader::EventReader;
use super::structs::{EventMetadata, EventSummary, ExtractedEvent};
use crate::modules::wpd::api as wpd_api;

/// Parses an event file and extracts metadata without writing to disk.
///
/// This is the primary function for quick viewing of event contents.
/// It loads the file into memory, parses the structure, and returns
/// a summary of actors, blocks, resources, and dialogue entries.
///
/// # Arguments
/// * `path` - Path to the event file (`.white.win32.xwb`)
///
/// # Returns
/// [`EventMetadata`] containing all extracted information.
///
/// # Example
/// ```rust,ignore
/// use fabula_nova_sdk::modules::event;
///
/// let meta = event::parse_event_metadata("ev_ddaa_080.white.win32.xwb")?;
/// println!("Actors: {}", meta.actors.len());
/// println!("Blocks: {}", meta.blocks.len());
/// ```
pub fn parse_event_metadata<P: AsRef<Path>>(path: P) -> Result<EventMetadata> {
    let path = path.as_ref();

    let file = File::open(path)?;
    let file_size = file.metadata()?.len();

    let mut reader = EventReader::new(BufReader::new(file));
    let mut meta = reader.read_event()?;

    // Set file info
    meta.source_path = path.to_string_lossy().to_string();
    meta.file_size = file_size;
    meta.name = path.file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("unknown")
        .to_string();

    // Clean up the name (remove .white.win32 suffix if present)
    if let Some(pos) = meta.name.find(".white") {
        meta.name = meta.name[..pos].to_string();
    }

    Ok(meta)
}

/// Parses event metadata from raw bytes.
///
/// Useful when the data is already in memory (e.g., from archive extraction).
///
/// # Arguments
/// * `data` - Raw bytes of the event file
/// * `name` - Optional name for the event
///
/// # Returns
/// [`EventMetadata`] containing all extracted information.
pub fn parse_event_metadata_bytes(data: &[u8], name: Option<&str>) -> Result<EventMetadata> {
    let cursor = Cursor::new(data);
    let mut reader = EventReader::new(cursor);
    let mut meta = reader.read_event()?;

    meta.file_size = data.len() as u64;
    meta.name = name.unwrap_or("unknown").to_string();

    Ok(meta)
}

/// Extracts an event file to a directory and returns metadata.
///
/// This combines WPD extraction with metadata parsing, giving you
/// both the extracted files and the parsed structure.
///
/// # Arguments
/// * `xwb_path` - Path to the event file
/// * `output_dir` - Directory to extract files to
///
/// # Returns
/// [`ExtractedEvent`] containing output directory, metadata, and file list.
///
/// # Example
/// ```rust,ignore
/// use fabula_nova_sdk::modules::event;
///
/// let result = event::extract_event("ev_ddaa_080.white.win32.xwb", "./output")?;
/// println!("Extracted {} files", result.extracted_files.len());
/// ```
pub fn extract_event<P: AsRef<Path>>(xwb_path: P, output_dir: P) -> Result<ExtractedEvent> {
    let xwb_path = xwb_path.as_ref();
    let output_dir = output_dir.as_ref();

    // First, parse metadata
    let metadata = parse_event_metadata(xwb_path)?;

    // Then extract using WPD
    let wpd_data = wpd_api::unpack_wpd(xwb_path, output_dir)?;

    // Build list of extracted files
    let extracted_files: Vec<String> = wpd_data.records.iter()
        .map(|r| {
            let mut name = r.name.clone();
            if !r.extension.is_empty() {
                name.push('.');
                name.push_str(&r.extension);
            }
            output_dir.join(&name).to_string_lossy().to_string()
        })
        .collect();

    Ok(ExtractedEvent {
        output_dir: output_dir.to_string_lossy().to_string(),
        metadata,
        extracted_files,
    })
}

/// Gets a summary of event contents (for quick display).
///
/// # Arguments
/// * `path` - Path to the event file
///
/// # Returns
/// [`EventSummary`] with counts and totals.
pub fn get_event_summary<P: AsRef<Path>>(path: P) -> Result<EventSummary> {
    let meta = parse_event_metadata(path)?;
    Ok(EventSummary::from(&meta))
}

/// Parses event metadata and returns as JSON string.
///
/// Useful for exporting or debugging.
pub fn parse_event_to_json<P: AsRef<Path>>(path: P) -> Result<String> {
    let meta = parse_event_metadata(path)?;
    let json = serde_json::to_string_pretty(&meta)?;
    Ok(json)
}

/// Parses an event from a directory (including DataSet if present).
///
/// This is the preferred method when you have the full event directory
/// structure, as it will also parse the DataSet folder containing
/// motion and camera control blocks.
///
/// # Directory Structure
/// ```text
/// ev_xxxx_xxx/
/// ├── bin/
/// │   └── ev_xxxx_xxx.white.win32.xwb
/// └── DataSet/  (optional)
///     ├── a00.white.win32.bin
///     ├── a01.white.win32.bin
///     └── ...
/// ```
///
/// # Arguments
/// * `dir_path` - Path to the event directory
///
/// # Returns
/// [`EventMetadata`] with `dataset` field populated if DataSet exists.
///
/// # Example
/// ```rust,ignore
/// use fabula_nova_sdk::modules::event;
///
/// let meta = event::parse_event_directory("./ev_yuaa_360")?;
/// if let Some(dataset) = &meta.dataset {
///     println!("Motion blocks: {}", dataset.motion_blocks.len());
///     println!("Camera blocks: {}", dataset.camera_blocks.len());
/// }
/// ```
pub fn parse_event_directory<P: AsRef<Path>>(dir_path: P) -> Result<EventMetadata> {
    super::reader::read_event_directory(dir_path.as_ref().to_str().unwrap_or(""))
}
