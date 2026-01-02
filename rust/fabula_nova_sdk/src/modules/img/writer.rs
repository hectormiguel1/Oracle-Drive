//! # IMG Binary Writer
//!
//! This module provides DDS file generation from GTEX headers.
//!
//! ## GTEX to DDS Conversion
//!
//! The writer translates Square Enix's GTEX format codes to standard DDS
//! header fields, enabling textures to be edited with common image tools.
//!
//! ## Format Mapping
//!
//! | GTEX Format | DDS Format | Block Size | Description          |
//! |-------------|------------|------------|----------------------|
//! | 3, 4        | RGBA       | 4 bytes    | Uncompressed 32-bit  |
//! | 24          | DXT1       | 8 bytes    | BC1 compressed       |
//! | 25          | DXT3       | 16 bytes   | BC2 compressed       |
//! | 26          | DXT5       | 16 bytes   | BC3 compressed       |
//!
//! ## Pitch Calculation
//!
//! - **Uncompressed**: `pitch = (width * bits_per_pixel + 7) / 8`
//! - **Compressed**: `linear_size = max(1, (w+3)/4) * max(1, (h+3)/4) * block_size`
//!
//! The compressed formula accounts for 4x4 block alignment.

use std::io::{Write, Seek};
use super::structs::{GtexHeader, DdsHeader, DdsPixelFormat};
use anyhow::Result;

/// Binary writer for DDS texture files.
///
/// Generates DDS headers from GTEX metadata, allowing game textures
/// to be exported as standard DDS files.
///
/// # Type Parameter
///
/// `W` - Any type implementing `Write + Seek`, typically `BufWriter<File>`.
///
/// # Example
///
/// ```rust,ignore
/// let file = File::create("output.dds")?;
/// let mut writer = ImgWriter::new(BufWriter::new(file));
///
/// // Write DDS header based on GTEX properties
/// writer.write_dds_header(&gtex_header)?;
///
/// // Then copy pixel data from IMGB file...
/// ```
pub struct ImgWriter<W: Write + Seek> {
    writer: W,
}

impl<W: Write + Seek> ImgWriter<W> {
    /// Creates a new image writer wrapping the given stream.
    pub fn new(writer: W) -> Self {
        Self { writer }
    }

    /// Writes a DDS header based on GTEX properties.
    ///
    /// Translates GTEX format codes and dimensions to a complete DDS header.
    /// After calling this, the caller should copy pixel data from the IMGB file.
    ///
    /// # Format Translation
    ///
    /// | GTEX | DDS       | Flags  | Notes                              |
    /// |------|-----------|--------|----------------------------------- |
    /// | 3-4  | RGBA      | 0x41   | 32-bit uncompressed, BGRA order    |
    /// | 24   | DXT1      | 0x04   | BC1, 8 bytes per 4x4 block         |
    /// | 25   | DXT3      | 0x04   | BC2, 16 bytes per 4x4 block        |
    /// | 26   | DXT5      | 0x04   | BC3, 16 bytes per 4x4 block        |
    ///
    /// # Caps Flags
    ///
    /// - Single level: `0x1000` (TEXTURE)
    /// - With mipmaps: `0x401008` (TEXTURE | MIPMAP | COMPLEX)
    ///
    /// # Header Flags
    ///
    /// The flags field indicates which header fields are valid:
    /// - `0x100F` - Basic uncompressed (CAPS, HEIGHT, WIDTH, PIXELFORMAT)
    /// - `0x2100F` - Uncompressed with mipmaps (adds MIPMAPCOUNT)
    /// - `0x81007` - Compressed (adds LINEARSIZE)
    /// - `0xA1007` - Compressed with mipmaps
    ///
    /// # Implementation Notes
    ///
    /// Based on C# DDSMethods.cs / SharedMethods.cs logic.
    pub fn write_dds_header(&mut self, gtex: &GtexHeader) -> Result<()> {
        // Initialize DDS header with default values
        let mut dds = DdsHeader {
            _magic: (),
            size: 124,  // Fixed DDS header size (excluding magic)
            flags: 0,
            height: gtex.height as u32,
            width: gtex.width as u32,
            pitch_or_linear_size: 0,
            depth: 0,
            mip_map_count: gtex.mip_count as u32,
            reserved1: [0; 11],
            pixel_format: DdsPixelFormat {
                size: 32,  // Fixed pixel format size
                flags: 0,
                four_cc: [0; 4],
                rgb_bit_count: 0,
                r_bit_mask: 0,
                g_bit_mask: 0,
                b_bit_mask: 0,
                a_bit_mask: 0,
            },
            caps: 0,
            caps2: 0,
            caps3: 0,
            caps4: 0,
            reserved2: 0,
        };

        // Set caps based on mipmap presence
        // TEXTURE (0x1000) for single level
        // TEXTURE | MIPMAP | COMPLEX (0x401008) for mipmapped
        dds.caps = if gtex.mip_count > 1 { 0x401008 } else { 0x1000 };

        let width = gtex.width as u32;
        let height = gtex.height as u32;

        // Configure pixel format based on GTEX format code
        match gtex.format {
            // Uncompressed RGBA (formats 3, 4)
            3 | 4 => {
                // Pitch = bytes per row = (width * bits + 7) / 8
                dds.pitch_or_linear_size = (width * 32).div_ceil(8);

                // RGB | ALPHA flags for uncompressed RGBA
                dds.pixel_format.flags = 0x41;
                dds.pixel_format.rgb_bit_count = 32;

                // BGRA channel masks (standard for DDS)
                dds.pixel_format.r_bit_mask = 0x00FF0000;
                dds.pixel_format.g_bit_mask = 0x0000FF00;
                dds.pixel_format.b_bit_mask = 0x000000FF;
                dds.pixel_format.a_bit_mask = 0xFF000000;

                // Header flags: basic or with mipmaps
                dds.flags = if gtex.mip_count > 1 { 0x2100F } else { 0x100F };
            },

            // DXT1 / BC1 (format 24) - 4:1 compression, 1-bit alpha
            24 => {
                let block_size = 8;  // 8 bytes per 4x4 block
                // Linear size = number of blocks * block size
                dds.pitch_or_linear_size = std::cmp::max(1, width.div_ceil(4))
                    * std::cmp::max(1, height.div_ceil(4))
                    * block_size;

                dds.pixel_format.flags = 0x04;  // FOURCC flag
                dds.pixel_format.four_cc = *b"DXT1";

                dds.flags = if gtex.mip_count > 1 { 0xA1007 } else { 0x81007 };
            },

            // DXT3 / BC2 (format 25) - explicit alpha
            25 => {
                let block_size = 16;  // 16 bytes per 4x4 block
                dds.pitch_or_linear_size = std::cmp::max(1, width.div_ceil(4))
                    * std::cmp::max(1, height.div_ceil(4))
                    * block_size;

                dds.pixel_format.flags = 0x04;
                dds.pixel_format.four_cc = *b"DXT3";
                dds.flags = if gtex.mip_count > 1 { 0xA1007 } else { 0x81007 };
            },

            // DXT5 / BC3 (format 26) - interpolated alpha
            26 => {
                let block_size = 16;  // 16 bytes per 4x4 block
                dds.pitch_or_linear_size = std::cmp::max(1, width.div_ceil(4))
                    * std::cmp::max(1, height.div_ceil(4))
                    * block_size;

                dds.pixel_format.flags = 0x04;
                dds.pixel_format.four_cc = *b"DXT5";
                dds.flags = if gtex.mip_count > 1 { 0xA1007 } else { 0x81007 };
            },

            // Unknown format - log warning but continue
            _ => {
                log::warn!("Unknown GTEX format: {}", gtex.format);
            }
        }

        // Write header in little-endian format
        use binrw::BinWrite;
        dds.write_le(&mut self.writer)?;

        Ok(())
    }
}
