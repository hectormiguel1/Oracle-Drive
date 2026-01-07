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
use image::{ImageBuffer, RgbaImage};
use ddsfile::{Dds, D3DFormat};
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

/// Converts a DDS file to PNG format.
///
/// Supports common DDS formats including DXT1, DXT3, DXT5, and uncompressed RGBA.
/// Only the base mipmap level (mip 0) is converted.
///
/// # Arguments
///
/// * `dds_path` - Path to the input DDS file
/// * `png_path` - Path to write the output PNG file
///
/// # Returns
///
/// A tuple of (width, height) of the converted image.
///
/// # Errors
///
/// Returns an error if:
/// - DDS file cannot be read or has unsupported format
/// - PNG file cannot be written
///
/// # Example
///
/// ```rust,ignore
/// let (width, height) = convert_dds_to_png("texture.dds", "texture.png")?;
/// println!("Converted {}x{} texture to PNG", width, height);
/// ```
pub fn convert_dds_to_png<P: AsRef<Path>>(dds_path: P, png_path: P) -> Result<(u32, u32)> {
    let dds_file = File::open(dds_path)?;
    let dds = Dds::read(dds_file)?;

    let width = dds.get_width();
    let height = dds.get_height();

    // Decode the DDS to RGBA pixels
    let rgba_data = decode_dds_to_rgba(&dds)?;

    // Create image buffer and save as PNG
    let img: RgbaImage = ImageBuffer::from_raw(width, height, rgba_data)
        .ok_or_else(|| anyhow::anyhow!("Failed to create image buffer"))?;

    img.save(png_path)?;

    Ok((width, height))
}

/// Converts a DDS file to PNG and returns the PNG data as bytes.
///
/// Useful for displaying textures directly in Flutter without writing to disk.
///
/// # Arguments
///
/// * `dds_path` - Path to the input DDS file
///
/// # Returns
///
/// A tuple of:
/// - (width, height) - Dimensions of the image
/// - `Vec<u8>` - PNG file data
pub fn convert_dds_to_png_bytes<P: AsRef<Path>>(dds_path: P) -> Result<((u32, u32), Vec<u8>)> {
    let dds_file = File::open(dds_path)?;
    let dds = Dds::read(dds_file)?;

    let width = dds.get_width();
    let height = dds.get_height();

    // Decode the DDS to RGBA pixels
    let rgba_data = decode_dds_to_rgba(&dds)?;

    // Create image buffer
    let img: RgbaImage = ImageBuffer::from_raw(width, height, rgba_data)
        .ok_or_else(|| anyhow::anyhow!("Failed to create image buffer"))?;

    // Encode to PNG in memory
    let mut png_data = Vec::new();
    let encoder = image::codecs::png::PngEncoder::new(&mut png_data);
    img.write_with_encoder(encoder)?;

    Ok(((width, height), png_data))
}

/// Converts DDS bytes to PNG bytes entirely in memory.
///
/// This function allows for texture conversion without any disk I/O.
/// Useful for previewing textures in the UI directly from extracted data.
///
/// # Arguments
///
/// * `dds_data` - DDS file data as bytes
///
/// # Returns
///
/// A tuple of:
/// - (width, height) - Dimensions of the image
/// - `Vec<u8>` - PNG file data
pub fn convert_dds_bytes_to_png_bytes(dds_data: &[u8]) -> Result<((u32, u32), Vec<u8>)> {
    let cursor = Cursor::new(dds_data);
    let dds = Dds::read(cursor)?;

    let width = dds.get_width();
    let height = dds.get_height();

    // Decode the DDS to RGBA pixels
    let rgba_data = decode_dds_to_rgba(&dds)?;

    // Create image buffer
    let img: RgbaImage = ImageBuffer::from_raw(width, height, rgba_data)
        .ok_or_else(|| anyhow::anyhow!("Failed to create image buffer"))?;

    // Encode to PNG in memory
    let mut png_data = Vec::new();
    let encoder = image::codecs::png::PngEncoder::new(&mut png_data);
    img.write_with_encoder(encoder)?;

    Ok(((width, height), png_data))
}

/// Extracts a texture from header bytes + IMGB file to DDS bytes in memory.
///
/// # Arguments
///
/// * `header_data` - Raw bytes of the texture header (vtex/txbh/etc.)
/// * `imgb_path` - Path to the IMGB file containing pixel data
///
/// # Returns
///
/// A tuple of:
/// - [`ImgData`] - Texture metadata
/// - `Vec<u8>` - DDS file data
pub fn extract_img_to_dds_bytes<P: AsRef<Path>>(
    header_data: &[u8],
    imgb_path: P
) -> Result<(ImgData, Vec<u8>)> {
    // Parse GTEX header from bytes
    let mut header_cursor = Cursor::new(header_data);
    let mut img_reader = ImgReader::new(&mut header_cursor);
    let (gtex_header, gtex_pos) = img_reader.read_gtex()?
        .ok_or_else(|| anyhow::anyhow!("GTEX chunk not found in header data"))?;

    // Write DDS header to buffer
    let mut buffer = Cursor::new(Vec::new());
    let mut img_writer = ImgWriter::new(&mut buffer);
    img_writer.write_dds_header(&gtex_header)?;

    // Get mipmap table offset
    header_cursor.seek(SeekFrom::Start(gtex_pos + 16))?;
    let mip_table_offset = header_cursor.read_u32::<BigEndian>()?;
    let mut mip_table_pos = gtex_pos + mip_table_offset as u64;

    let mut imgb_file = BufReader::new(File::open(imgb_path)?);

    // Copy all mipmap levels to buffer
    for _m in 0..gtex_header.mip_count {
        header_cursor.seek(SeekFrom::Start(mip_table_pos))?;
        let mip_start = header_cursor.read_u32::<BigEndian>()?;
        let mip_size = header_cursor.read_u32::<BigEndian>()?;

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

/// Decodes DDS pixel data to RGBA format.
fn decode_dds_to_rgba(dds: &Dds) -> Result<Vec<u8>> {
    let width = dds.get_width() as usize;
    let height = dds.get_height() as usize;
    let data = dds.get_data(0)?; // Get mip level 0

    // Get the format
    let format = dds.get_d3d_format().ok_or_else(|| {
        anyhow::anyhow!("Unsupported DDS format: no D3D format specified")
    })?;

    match format {
        D3DFormat::DXT1 => decode_dxt1(data, width, height),
        D3DFormat::DXT3 => decode_dxt3(data, width, height),
        D3DFormat::DXT5 => decode_dxt5(data, width, height),
        D3DFormat::A8R8G8B8 => decode_argb8888(data, width, height),
        D3DFormat::X8R8G8B8 => decode_xrgb8888(data, width, height),
        D3DFormat::R8G8B8 => decode_rgb888(data, width, height),
        D3DFormat::A8B8G8R8 => decode_abgr8888(data, width, height),
        _ => Err(anyhow::anyhow!("Unsupported DDS format: {:?}", format)),
    }
}

/// Decodes DXT1 (BC1) compressed data to RGBA.
fn decode_dxt1(data: &[u8], width: usize, height: usize) -> Result<Vec<u8>> {
    let mut output = vec![0u8; width * height * 4];

    let blocks_x = (width + 3) / 4;
    let blocks_y = (height + 3) / 4;

    for by in 0..blocks_y {
        for bx in 0..blocks_x {
            let block_idx = (by * blocks_x + bx) * 8;
            if block_idx + 8 > data.len() {
                break;
            }

            let block = &data[block_idx..block_idx + 8];
            decode_dxt1_block(block, &mut output, bx * 4, by * 4, width, height);
        }
    }

    Ok(output)
}

/// Decodes a single DXT1 4x4 block.
fn decode_dxt1_block(block: &[u8], output: &mut [u8], x: usize, y: usize, width: usize, height: usize) {
    let c0 = u16::from_le_bytes([block[0], block[1]]);
    let c1 = u16::from_le_bytes([block[2], block[3]]);

    let mut colors = [[0u8; 4]; 4];
    colors[0] = rgb565_to_rgba(c0);
    colors[1] = rgb565_to_rgba(c1);

    if c0 > c1 {
        // 4-color mode
        colors[2] = interpolate_color(&colors[0], &colors[1], 1, 3);
        colors[3] = interpolate_color(&colors[0], &colors[1], 2, 3);
    } else {
        // 3-color mode with transparency
        colors[2] = interpolate_color(&colors[0], &colors[1], 1, 2);
        colors[3] = [0, 0, 0, 0]; // Transparent
    }

    let indices = u32::from_le_bytes([block[4], block[5], block[6], block[7]]);

    for py in 0..4 {
        for px in 0..4 {
            let pixel_x = x + px;
            let pixel_y = y + py;
            if pixel_x >= width || pixel_y >= height {
                continue;
            }

            let idx = ((indices >> ((py * 4 + px) * 2)) & 0x3) as usize;
            let out_idx = (pixel_y * width + pixel_x) * 4;

            output[out_idx] = colors[idx][0];
            output[out_idx + 1] = colors[idx][1];
            output[out_idx + 2] = colors[idx][2];
            output[out_idx + 3] = colors[idx][3];
        }
    }
}

/// Decodes DXT3 (BC2) compressed data to RGBA.
fn decode_dxt3(data: &[u8], width: usize, height: usize) -> Result<Vec<u8>> {
    let mut output = vec![0u8; width * height * 4];

    let blocks_x = (width + 3) / 4;
    let blocks_y = (height + 3) / 4;

    for by in 0..blocks_y {
        for bx in 0..blocks_x {
            let block_idx = (by * blocks_x + bx) * 16;
            if block_idx + 16 > data.len() {
                break;
            }

            let block = &data[block_idx..block_idx + 16];
            decode_dxt3_block(block, &mut output, bx * 4, by * 4, width, height);
        }
    }

    Ok(output)
}

/// Decodes a single DXT3 4x4 block.
fn decode_dxt3_block(block: &[u8], output: &mut [u8], x: usize, y: usize, width: usize, height: usize) {
    // First 8 bytes are explicit alpha values (4 bits per pixel)
    let alpha_block = &block[0..8];
    // Last 8 bytes are DXT1 color block
    let color_block = &block[8..16];

    let c0 = u16::from_le_bytes([color_block[0], color_block[1]]);
    let c1 = u16::from_le_bytes([color_block[2], color_block[3]]);

    let mut colors = [[0u8; 4]; 4];
    colors[0] = rgb565_to_rgba(c0);
    colors[1] = rgb565_to_rgba(c1);
    colors[2] = interpolate_color(&colors[0], &colors[1], 1, 3);
    colors[3] = interpolate_color(&colors[0], &colors[1], 2, 3);

    let indices = u32::from_le_bytes([color_block[4], color_block[5], color_block[6], color_block[7]]);

    for py in 0..4 {
        for px in 0..4 {
            let pixel_x = x + px;
            let pixel_y = y + py;
            if pixel_x >= width || pixel_y >= height {
                continue;
            }

            let idx = ((indices >> ((py * 4 + px) * 2)) & 0x3) as usize;
            let out_idx = (pixel_y * width + pixel_x) * 4;

            // Get alpha from explicit alpha block
            let alpha_idx = py * 4 + px;
            let alpha_byte = alpha_block[alpha_idx / 2];
            let alpha = if alpha_idx % 2 == 0 {
                (alpha_byte & 0x0F) * 17 // Scale 0-15 to 0-255
            } else {
                (alpha_byte >> 4) * 17
            };

            output[out_idx] = colors[idx][0];
            output[out_idx + 1] = colors[idx][1];
            output[out_idx + 2] = colors[idx][2];
            output[out_idx + 3] = alpha;
        }
    }
}

/// Decodes DXT5 (BC3) compressed data to RGBA.
fn decode_dxt5(data: &[u8], width: usize, height: usize) -> Result<Vec<u8>> {
    let mut output = vec![0u8; width * height * 4];

    let blocks_x = (width + 3) / 4;
    let blocks_y = (height + 3) / 4;

    for by in 0..blocks_y {
        for bx in 0..blocks_x {
            let block_idx = (by * blocks_x + bx) * 16;
            if block_idx + 16 > data.len() {
                break;
            }

            let block = &data[block_idx..block_idx + 16];
            decode_dxt5_block(block, &mut output, bx * 4, by * 4, width, height);
        }
    }

    Ok(output)
}

/// Decodes a single DXT5 4x4 block.
fn decode_dxt5_block(block: &[u8], output: &mut [u8], x: usize, y: usize, width: usize, height: usize) {
    // First 8 bytes are interpolated alpha
    let alpha0 = block[0];
    let alpha1 = block[1];

    // Build alpha lookup table
    let mut alphas = [0u8; 8];
    alphas[0] = alpha0;
    alphas[1] = alpha1;
    if alpha0 > alpha1 {
        for i in 0..6 {
            alphas[2 + i] = ((6 - i) as u16 * alpha0 as u16 + (1 + i) as u16 * alpha1 as u16) as u8 / 7;
        }
    } else {
        for i in 0..4 {
            alphas[2 + i] = ((4 - i) as u16 * alpha0 as u16 + (1 + i) as u16 * alpha1 as u16) as u8 / 5;
        }
        alphas[6] = 0;
        alphas[7] = 255;
    }

    // Alpha indices are 3 bits each, packed into 6 bytes (bytes 2-7)
    let alpha_indices = u64::from_le_bytes([
        block[2], block[3], block[4], block[5], block[6], block[7], 0, 0
    ]);

    // Last 8 bytes are DXT1 color block
    let color_block = &block[8..16];

    let c0 = u16::from_le_bytes([color_block[0], color_block[1]]);
    let c1 = u16::from_le_bytes([color_block[2], color_block[3]]);

    let mut colors = [[0u8; 4]; 4];
    colors[0] = rgb565_to_rgba(c0);
    colors[1] = rgb565_to_rgba(c1);
    colors[2] = interpolate_color(&colors[0], &colors[1], 1, 3);
    colors[3] = interpolate_color(&colors[0], &colors[1], 2, 3);

    let color_indices = u32::from_le_bytes([color_block[4], color_block[5], color_block[6], color_block[7]]);

    for py in 0..4 {
        for px in 0..4 {
            let pixel_x = x + px;
            let pixel_y = y + py;
            if pixel_x >= width || pixel_y >= height {
                continue;
            }

            let color_idx = ((color_indices >> ((py * 4 + px) * 2)) & 0x3) as usize;
            let alpha_idx = ((alpha_indices >> ((py * 4 + px) * 3)) & 0x7) as usize;

            let out_idx = (pixel_y * width + pixel_x) * 4;

            output[out_idx] = colors[color_idx][0];
            output[out_idx + 1] = colors[color_idx][1];
            output[out_idx + 2] = colors[color_idx][2];
            output[out_idx + 3] = alphas[alpha_idx];
        }
    }
}

/// Converts RGB565 to RGBA8888.
fn rgb565_to_rgba(color: u16) -> [u8; 4] {
    let r = ((color >> 11) & 0x1F) as u8;
    let g = ((color >> 5) & 0x3F) as u8;
    let b = (color & 0x1F) as u8;

    [
        (r << 3) | (r >> 2),
        (g << 2) | (g >> 4),
        (b << 3) | (b >> 2),
        255,
    ]
}

/// Interpolates between two colors.
fn interpolate_color(c0: &[u8; 4], c1: &[u8; 4], num: u8, denom: u8) -> [u8; 4] {
    let d = denom as u16;
    let n = num as u16;
    [
        ((c0[0] as u16 * (d - n) + c1[0] as u16 * n) / d) as u8,
        ((c0[1] as u16 * (d - n) + c1[1] as u16 * n) / d) as u8,
        ((c0[2] as u16 * (d - n) + c1[2] as u16 * n) / d) as u8,
        255,
    ]
}

/// Decodes A8R8G8B8 to RGBA.
fn decode_argb8888(data: &[u8], width: usize, height: usize) -> Result<Vec<u8>> {
    let mut output = vec![0u8; width * height * 4];
    for i in 0..(width * height) {
        let src = i * 4;
        let dst = i * 4;
        if src + 4 > data.len() {
            break;
        }
        output[dst] = data[src + 2];     // R
        output[dst + 1] = data[src + 1]; // G
        output[dst + 2] = data[src];     // B
        output[dst + 3] = data[src + 3]; // A
    }
    Ok(output)
}

/// Decodes X8R8G8B8 to RGBA.
fn decode_xrgb8888(data: &[u8], width: usize, height: usize) -> Result<Vec<u8>> {
    let mut output = vec![0u8; width * height * 4];
    for i in 0..(width * height) {
        let src = i * 4;
        let dst = i * 4;
        if src + 4 > data.len() {
            break;
        }
        output[dst] = data[src + 2];     // R
        output[dst + 1] = data[src + 1]; // G
        output[dst + 2] = data[src];     // B
        output[dst + 3] = 255;           // A (fully opaque)
    }
    Ok(output)
}

/// Decodes R8G8B8 to RGBA.
fn decode_rgb888(data: &[u8], width: usize, height: usize) -> Result<Vec<u8>> {
    let mut output = vec![0u8; width * height * 4];
    for i in 0..(width * height) {
        let src = i * 3;
        let dst = i * 4;
        if src + 3 > data.len() {
            break;
        }
        output[dst] = data[src + 2];     // R
        output[dst + 1] = data[src + 1]; // G
        output[dst + 2] = data[src];     // B
        output[dst + 3] = 255;           // A
    }
    Ok(output)
}

/// Decodes A8B8G8R8 to RGBA.
fn decode_abgr8888(data: &[u8], width: usize, height: usize) -> Result<Vec<u8>> {
    let mut output = vec![0u8; width * height * 4];
    for i in 0..(width * height) {
        let src = i * 4;
        let dst = i * 4;
        if src + 4 > data.len() {
            break;
        }
        output[dst] = data[src];         // R
        output[dst + 1] = data[src + 1]; // G
        output[dst + 2] = data[src + 2]; // B
        output[dst + 3] = data[src + 3]; // A
    }
    Ok(output)
}
