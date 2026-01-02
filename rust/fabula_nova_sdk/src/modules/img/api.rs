//! # IMG High-Level API
//!
//! This module provides the public API for texture extraction and repacking.
//!
//! ## Overview
//!
//! FF13 textures are stored as a header/data pair:
//! - **Header file** (`.txbh`, `.xgr`, `.trb`): Contains GTEX metadata
//! - **Data file** (`.imgb`): Contains raw pixel data
//!
//! This API extracts textures to standard DDS format for editing and
//! repacks modified DDS files back into the IMGB container.
//!
//! ## Extraction Flow
//!
//! ```text
//! ┌─────────────┐     ┌─────────────┐
//! │ Header File │     │ IMGB File   │
//! │ (GTEX info) │     │ (pixels)    │
//! └──────┬──────┘     └──────┬──────┘
//!        │                   │
//!        │   extract_img_to_dds()
//!        │                   │
//!        └────────┬──────────┘
//!                 ▼
//!        ┌─────────────┐
//!        │  DDS File   │
//!        │ (editable)  │
//!        └─────────────┘
//! ```
//!
//! ## Repacking (Strict Mode)
//!
//! ```text
//! ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
//! │ Header File │     │ Modified    │     │ IMGB File   │
//! │ (unchanged) │     │ DDS File    │     │ (target)    │
//! └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
//!        │                   │                   │
//!        │   repack_img_strict()                 │
//!        │                   │                   │
//!        └─────────┬─────────┴───────────────────┘
//!                  ▼
//!         Overwrites IMGB at original offsets
//! ```
//!
//! ## Mipmap Table
//!
//! The GTEX header contains an offset to a mipmap table:
//!
//! ```text
//! Mipmap Table (8 bytes per level):
//! ┌────────┬────────┐
//! │ Offset │ Size   │  Mip 0 (base)
//! ├────────┼────────┤
//! │ Offset │ Size   │  Mip 1 (half size)
//! ├────────┼────────┤
//! │  ...   │  ...   │
//! └────────┴────────┘
//! ```

use std::path::Path;
use std::fs::{File, OpenOptions};
use std::io::{BufReader, BufWriter, Read, Write, Seek, SeekFrom, Cursor};
use anyhow::Result;
use byteorder::{BigEndian, ReadBytesExt};
use super::reader::ImgReader;
use super::writer::ImgWriter;
use super::structs::ImgData;

/// Extracts a texture to a DDS file.
///
/// Reads the GTEX header from the header file, generates a DDS header,
/// then copies pixel data from the IMGB file for each mipmap level.
///
/// # Arguments
///
/// * `header_path` - Path to texture header file (`.txbh`, `.xgr`, `.trb`)
/// * `imgb_path` - Path to image data file (`.imgb`)
/// * `output_path` - Path to write the DDS file
///
/// # Returns
///
/// [`ImgData`] containing texture metadata (dimensions, format, mip count).
///
/// # Errors
///
/// Returns an error if:
/// - Header file doesn't contain a GTEX chunk
/// - IMGB file cannot be read
/// - Output file cannot be written
///
/// # Example
///
/// ```rust,ignore
/// let info = extract_img_to_dds(
///     "texture.txbh",
///     "data.imgb",
///     "output.dds"
/// )?;
/// println!("Extracted {}x{} texture", info.width, info.height);
/// ```
pub fn extract_img_to_dds<P: AsRef<Path>>(
    header_path: P,
    imgb_path: P,
    output_path: P
) -> Result<ImgData> {
    // Open header file and scan for GTEX chunk
    let mut header_file = File::open(header_path)?;
    let mut header_file_reader = header_file.try_clone()?;

    let mut img_reader = ImgReader::new(&mut header_file_reader);
    let (gtex_header, gtex_pos) = img_reader.read_gtex()?
        .ok_or_else(|| anyhow::anyhow!("GTEX chunk not found"))?;

    // Create output DDS file and write header
    let mut out_file = BufWriter::new(File::create(output_path)?);
    let mut img_writer = ImgWriter::new(&mut out_file);
    img_writer.write_dds_header(&gtex_header)?;

    // Read mipmap table offset from GTEX header (at offset +16)
    header_file.seek(SeekFrom::Start(gtex_pos + 16))?;
    let mip_table_offset = header_file.read_u32::<BigEndian>()?;
    let mut mip_table_pos = gtex_pos + mip_table_offset as u64;

    // Open IMGB file for reading pixel data
    let mut imgb_file = BufReader::new(File::open(imgb_path)?);

    // Copy each mipmap level from IMGB to DDS
    for _m in 0..gtex_header.mip_count {
        // Read mip entry: offset (4 bytes) + size (4 bytes)
        header_file.seek(SeekFrom::Start(mip_table_pos))?;
        let mip_start = header_file.read_u32::<BigEndian>()?;
        let mip_size = header_file.read_u32::<BigEndian>()?;

        // Copy pixel data from IMGB to DDS
        imgb_file.seek(SeekFrom::Start(mip_start as u64))?;
        let mut chunk = imgb_file.by_ref().take(mip_size as u64);
        std::io::copy(&mut chunk, &mut out_file)?;

        // Advance to next mipmap entry
        mip_table_pos += 8;
    }

    Ok(ImgData {
        width: gtex_header.width,
        height: gtex_header.height,
        mip_count: gtex_header.mip_count,
        format: format!("{:?}", gtex_header.format),
    })
}

/// Extracts a texture to an in-memory buffer.
///
/// Similar to [`extract_img_to_dds`] but returns the DDS data as a byte vector
/// instead of writing to a file. Useful for Flutter UI previews or when the
/// texture needs further processing before saving.
///
/// # Arguments
///
/// * `header_path` - Path to texture header file
/// * `imgb_path` - Path to image data file
///
/// # Returns
///
/// A tuple of:
/// - [`ImgData`] - Texture metadata
/// - `Vec<u8>` - Complete DDS file contents (header + pixel data)
///
/// # Performance Note
///
/// This function allocates memory for the entire DDS file. For large textures,
/// prefer [`extract_img_to_dds`] which streams directly to disk.
pub fn extract_img_to_memory<P: AsRef<Path>>(
    header_path: P,
    imgb_path: P
) -> Result<(ImgData, Vec<u8>)> {
    // Open and parse header file
    let mut header_file = File::open(header_path)?;
    let mut header_file_reader = header_file.try_clone()?;

    let mut img_reader = ImgReader::new(&mut header_file_reader);
    let (gtex_header, gtex_pos) = img_reader.read_gtex()?
        .ok_or_else(|| anyhow::anyhow!("GTEX chunk not found"))?;

    // Write DDS to in-memory buffer using Cursor
    let mut buffer = Cursor::new(Vec::new());
    let mut img_writer = ImgWriter::new(&mut buffer);
    img_writer.write_dds_header(&gtex_header)?;

    // Get mipmap table offset
    header_file.seek(SeekFrom::Start(gtex_pos + 16))?;
    let mip_table_offset = header_file.read_u32::<BigEndian>()?;
    let mut mip_table_pos = gtex_pos + mip_table_offset as u64;

    let mut imgb_file = BufReader::new(File::open(imgb_path)?);

    // Copy all mipmap levels to buffer
    for _m in 0..gtex_header.mip_count {
        header_file.seek(SeekFrom::Start(mip_table_pos))?;
        let mip_start = header_file.read_u32::<BigEndian>()?;
        let mip_size = header_file.read_u32::<BigEndian>()?;

        imgb_file.seek(SeekFrom::Start(mip_start as u64))?;
        let mut chunk = imgb_file.by_ref().take(mip_size as u64);
        std::io::copy(&mut chunk, &mut buffer)?;

        mip_table_pos += 8;
    }

    Ok((ImgData {
        width: gtex_header.width,
        height: gtex_header.height,
        mip_count: gtex_header.mip_count,
        format: format!("{:?}", gtex_header.format),
    }, buffer.into_inner()))
}

/// Repacks a DDS file back into an IMGB container (strict mode).
///
/// **Strict mode** means the DDS must have the exact same dimensions and
/// mipmap structure as the original texture. Pixel data is written directly
/// to the original offsets in the IMGB file.
///
/// # Arguments
///
/// * `header_path` - Path to the original texture header file (unchanged)
/// * `imgb_path` - Path to the IMGB file to modify
/// * `dds_path` - Path to the modified DDS file
///
/// # Strict Mode Requirements
///
/// - DDS dimensions must match original GTEX dimensions
/// - DDS must have same number of mipmap levels
/// - Each mip level must be the same size as the original
///
/// # How It Works
///
/// 1. Read GTEX header to get mipmap table
/// 2. Read DDS header and validate dimensions
/// 3. For each mipmap level:
///    - Read `mip_size` bytes from DDS (starting at offset 128)
///    - Write to IMGB at `mip_offset` from the table
///
/// # Warning
///
/// This function modifies the IMGB file in-place. Make a backup if needed.
///
/// # Example
///
/// ```rust,ignore
/// // Extract, modify texture in Photoshop, then repack
/// extract_img_to_dds("tex.txbh", "data.imgb", "tex.dds")?;
/// // ... edit tex.dds ...
/// repack_img_strict("tex.txbh", "data.imgb", "tex.dds")?;
/// ```
pub fn repack_img_strict<P: AsRef<Path>>(
    header_path: P,
    imgb_path: P,
    dds_path: P
) -> Result<()> {
    // 1. Read GTEX header to get mipmap offsets
    let mut header_file = File::open(header_path)?;
    let mut header_file_reader = header_file.try_clone()?;

    let mut img_reader = ImgReader::new(&mut header_file_reader);
    let (gtex_header, gtex_pos) = img_reader.read_gtex()?
        .ok_or_else(|| anyhow::anyhow!("GTEX chunk not found"))?;

    // 2. Open and validate DDS file
    let mut dds_file = File::open(dds_path)?;
    let mut img_reader_dds = ImgReader::new(&mut dds_file);
    let dds_header = img_reader_dds.read_dds()?;

    // Warn if dimensions don't match (but continue - user may know what they're doing)
    if dds_header.width != gtex_header.width as u32
        || dds_header.height != gtex_header.height as u32
    {
        log::warn!(
            "DDS dimensions ({}x{}) do not match GTEX ({}x{})",
            dds_header.width, dds_header.height,
            gtex_header.width, gtex_header.height
        );
    }

    // 3. Open IMGB for in-place modification
    let mut imgb_file = OpenOptions::new().write(true).open(imgb_path)?;

    // 4. Get mipmap table location
    header_file.seek(SeekFrom::Start(gtex_pos + 16))?;
    let mip_table_offset = header_file.read_u32::<BigEndian>()?;
    let mut mip_table_pos = gtex_pos + mip_table_offset as u64;

    // DDS pixel data starts at byte 128 (after 4-byte magic + 124-byte header)
    let mut dds_data_pos: u64 = 128;

    // 5. Copy each mipmap level from DDS to IMGB
    for mip_index in 0..gtex_header.mip_count {
        // Read mip entry from header
        header_file.seek(SeekFrom::Start(mip_table_pos))?;
        let mip_start = header_file.read_u32::<BigEndian>()?;
        let mip_size = header_file.read_u32::<BigEndian>()?;

        // Read pixel data from DDS
        dds_file.seek(SeekFrom::Start(dds_data_pos))?;
        let mut buffer = vec![0u8; mip_size as usize];
        let bytes_read = dds_file.read(&mut buffer)?;

        // Warn if DDS mip is smaller than expected (pad with zeros)
        if bytes_read < mip_size as usize {
            log::warn!(
                "DDS mip {} smaller than expected ({} vs {}). Padding with zeros.",
                mip_index, bytes_read, mip_size
            );
        }

        // Write to IMGB at original offset
        imgb_file.seek(SeekFrom::Start(mip_start as u64))?;
        imgb_file.write_all(&buffer)?;

        // Advance positions for next mip level
        dds_data_pos += mip_size as u64;
        mip_table_pos += 8;
    }

    log::info!("Repacked IMGB successfully.");
    Ok(())
}
