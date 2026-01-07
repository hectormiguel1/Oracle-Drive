//! # VFX High-Level API
//!
//! This module provides the public API for VFX file operations.
//!
//! ## Functions
//!
//! - [`parse_vfx`] - Parse a VFX XFV file
//! - [`get_vfx_summary`] - Get quick summary of VFX contents
//! - [`vfx_to_json`] - Export VFX data to JSON

use std::path::Path;
use std::fs::{File, metadata};
use std::io::BufReader;
use anyhow::Result;
use super::reader::VfxReader;
use super::structs::{VfxData, VfxSummary, VfxTexture};

/// Parses a VFX XFV file and returns all effect data.
///
/// # Arguments
///
/// * `path` - Path to the XFV file
///
/// # Returns
///
/// Complete VFX data including textures, models, animations, and effects.
///
/// # Example
///
/// ```rust,ignore
/// let vfx = parse_vfx("effects.xfv")?;
/// println!("Found {} effects", vfx.effects.len());
/// ```
pub fn parse_vfx<P: AsRef<Path>>(path: P) -> Result<VfxData> {
    let path = path.as_ref();
    let file = File::open(path)?;
    let mut reader = VfxReader::new(BufReader::new(file));
    let mut vfx = reader.read_vfx()?;
    vfx.source_path = path.to_string_lossy().to_string();
    Ok(vfx)
}

/// Gets a quick summary of VFX file contents.
///
/// Faster than full parsing when you just need counts and names.
pub fn get_vfx_summary<P: AsRef<Path>>(path: P) -> Result<VfxSummary> {
    let path = path.as_ref();
    let vfx = parse_vfx(path)?;
    let file_size = metadata(path)?.len();

    let mut summary = VfxSummary::from(&vfx);
    summary.total_size = file_size;
    Ok(summary)
}

/// Exports VFX data to JSON string.
pub fn vfx_to_json(data: &VfxData) -> Result<String> {
    Ok(serde_json::to_string_pretty(data)?)
}

/// Exports VFX summary to JSON string.
pub fn vfx_summary_to_json(summary: &VfxSummary) -> Result<String> {
    Ok(serde_json::to_string_pretty(summary)?)
}

/// Lists all effect names in a VFX file.
pub fn list_vfx_effects<P: AsRef<Path>>(path: P) -> Result<Vec<String>> {
    let vfx = parse_vfx(path)?;
    Ok(vfx.effects.iter().map(|e| e.name.clone()).collect())
}

/// Lists all texture references in a VFX file.
pub fn list_vfx_textures<P: AsRef<Path>>(path: P) -> Result<Vec<VfxTexture>> {
    let vfx = parse_vfx(path)?;
    Ok(vfx.textures)
}

/// Extracts textures from VFX to DDS files.
///
/// Requires the paired IMGB file to be present.
///
/// # Arguments
///
/// * `xfv_path` - Path to the XFV file
/// * `output_dir` - Directory to write DDS files
///
/// # Returns
///
/// List of extracted DDS file paths.
pub fn extract_vfx_textures<P: AsRef<Path>>(xfv_path: P, output_dir: P) -> Result<Vec<String>> {
    use std::fs::create_dir_all;

    let xfv_path = xfv_path.as_ref();
    let output_dir = output_dir.as_ref();

    // Parse VFX to get texture info (validates the file is correct)
    let _vfx = parse_vfx(xfv_path)?;

    // Check for paired IMGB
    let imgb_path = xfv_path.with_extension("imgb");
    if !imgb_path.exists() {
        anyhow::bail!("Paired IMGB file not found: {:?}", imgb_path);
    }

    // Create output directory
    if !output_dir.exists() {
        create_dir_all(output_dir)?;
    }

    let mut extracted = Vec::new();

    // Use WPD unpacker which handles vtex → DDS extraction
    // vtex records are WPD-compatible with IMGB pairing
    use crate::modules::wpd::api::unpack_wpd;

    let _unpack_result = unpack_wpd(xfv_path, output_dir)?;

    // Find all DDS files created
    for entry in std::fs::read_dir(output_dir)? {
        let entry = entry?;
        if entry.path().extension().map_or(false, |ext| ext == "dds") {
            extracted.push(entry.path().to_string_lossy().to_string());
        }
    }

    Ok(extracted)
}

/// Gets texture dimensions for a specific texture by name.
pub fn get_vfx_texture_info<P: AsRef<Path>>(xfv_path: P, texture_name: &str) -> Result<Option<VfxTexture>> {
    let vfx = parse_vfx(xfv_path)?;
    Ok(vfx.textures.into_iter().find(|t| t.name == texture_name))
}

/// Extracts a single texture as PNG bytes in memory.
///
/// This function loads only the specified texture without extracting any files to disk.
/// Ideal for on-demand texture preview in the UI.
///
/// # Arguments
///
/// * `xfv_path` - Path to the XFV file
/// * `texture_name` - Name of the texture to extract (e.g., "v04fdfc11828acd")
///
/// # Returns
///
/// A tuple of:
/// - (width, height) - Dimensions of the texture
/// - `Vec<u8>` - PNG file data ready for display
///
/// # Errors
///
/// Returns an error if:
/// - XFV file cannot be read
/// - Paired IMGB file not found
/// - Texture name not found in the VFX
/// - Texture format not supported
pub fn extract_vfx_texture_as_png<P: AsRef<Path>>(
    xfv_path: P,
    texture_name: &str
) -> Result<((u32, u32), Vec<u8>)> {
    use crate::modules::wpd::reader::WpdReader;
    use crate::modules::img::api as img_api;

    let xfv_path = xfv_path.as_ref();

    // Check for paired IMGB
    let imgb_path = xfv_path.with_extension("imgb");
    if !imgb_path.exists() {
        anyhow::bail!("Paired IMGB file not found: {:?}", imgb_path);
    }

    // Read WPD records to find the texture header
    let file = File::open(xfv_path)?;
    let mut reader = WpdReader::new(BufReader::new(file));
    let header = reader.read_header()?;
    let records = reader.read_records(&header)?;

    // Find the texture record by name (vtex extension)
    let texture_record = records.into_iter()
        .find(|r| r.name == texture_name && r.extension == "vtex")
        .ok_or_else(|| anyhow::anyhow!("Texture '{}' not found in VFX", texture_name))?;

    // Extract header to DDS bytes
    let (_img_info, dds_bytes) = img_api::extract_img_to_dds_bytes(&texture_record.data, &imgb_path)?;

    // Convert DDS to PNG
    img_api::convert_dds_bytes_to_png_bytes(&dds_bytes)
}

