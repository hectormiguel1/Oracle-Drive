//! # IMG Data Structures
//!
//! This module defines binary structures for texture files used in FF13 games.
//!
//! ## GTEX Format (Game Texture)
//!
//! GTEX is Square Enix's proprietary texture header format. The header describes
//! image properties while actual pixel data is stored separately in IMGB files.
//!
//! ```text
//! GTEX Header (variable size, minimum 16 bytes):
//! ┌────────────────────────────────────────────────────────────────┐
//! │ Offset │ Size │ Field         │ Description                    │
//! ├────────┼──────┼───────────────┼────────────────────────────────┤
//! │ 0x00   │ 4    │ Magic         │ "GTEX" (0x47544558)            │
//! │ 0x04   │ 2    │ Unknown       │ Flags/version?                 │
//! │ 0x06   │ 1    │ Format        │ Pixel format (see table below) │
//! │ 0x07   │ 1    │ MipCount      │ Number of mipmap levels        │
//! │ 0x08   │ 1    │ Unknown       │ Additional flags               │
//! │ 0x09   │ 1    │ ImageType     │ 2D/3D/Cube texture type        │
//! │ 0x0A   │ 2    │ Width         │ Image width in pixels          │
//! │ 0x0C   │ 2    │ Height        │ Image height in pixels         │
//! │ 0x0E   │ 2    │ Depth         │ Depth (for 3D textures)        │
//! │ 0x10   │ 4    │ MipTableOff   │ Offset to mipmap offset table  │
//! └────────────────────────────────────────────────────────────────┘
//! ```
//!
//! ## Format Codes
//!
//! | Code | Format | Description                        |
//! |------|--------|------------------------------------|
//! | 3-4  | RGBA   | 32-bit uncompressed RGBA           |
//! | 24   | DXT1   | BC1 compression (4:1 ratio)        |
//! | 25   | DXT3   | BC2 compression with alpha         |
//! | 26   | DXT5   | BC3 compression with alpha         |
//!
//! ## DDS Format (DirectDraw Surface)
//!
//! DDS is Microsoft's standard texture format, used as an intermediate format
//! for editing with common image tools (Photoshop, GIMP, Paint.NET).
//!
//! ```text
//! DDS File Structure:
//! ┌────────────────────────────────────────────────────────────────┐
//! │ Magic: "DDS " (4 bytes)                                        │
//! ├────────────────────────────────────────────────────────────────┤
//! │ Header (124 bytes)                                             │
//! │   - Size, flags, dimensions                                    │
//! │   - Pixel format (32 bytes embedded)                           │
//! │   - Caps flags                                                 │
//! ├────────────────────────────────────────────────────────────────┤
//! │ Pixel Data (variable size)                                     │
//! │   - Base mip level                                             │
//! │   - Additional mip levels (if present)                         │
//! └────────────────────────────────────────────────────────────────┘
//! ```

use binrw::binrw;
use serde::{Serialize, Deserialize};

/// GTEX (Game Texture) header from FF13 texture files.
///
/// This header is embedded in `.txbh`, `.xgr`, `.trb` files and describes
/// the texture format. The actual pixel data is stored in a paired `.imgb` file.
///
/// # Endianness
///
/// GTEX headers are stored in big-endian format.
///
/// # Mipmap Table
///
/// Following the header at offset `mip_table_offset` is a table of mipmap
/// entries, each containing:
/// - `offset: u32` - Byte offset into IMGB file
/// - `size: u32` - Size of mip level data in bytes
#[binrw]
#[br(big)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GtexHeader {
    /// Magic bytes "GTEX" - validated by binrw
    #[br(magic = b"GTEX")]
    pub _magic: (),
    /// Unknown field at offset 0x04 (possibly version/flags)
    pub unk_04: u16,
    /// Pixel format code (3-4=RGBA, 24=DXT1, 25=DXT3, 26=DXT5)
    pub format: u8,
    /// Number of mipmap levels (1 = base only, 2+ = with mipmaps)
    pub mip_count: u8,
    /// Unknown field at offset 0x08
    pub unk_08: u8,
    /// Image type (2D, 3D, cubemap, etc.)
    pub img_type: u8,
    /// Texture width in pixels
    pub width: u16,
    /// Texture height in pixels
    pub height: u16,
    /// Texture depth (for 3D/volume textures, usually 0 for 2D)
    pub depth: u16,
}

/// DDS (DirectDraw Surface) file header.
///
/// Standard Microsoft DDS format header (124 bytes after magic).
/// This is an intermediate format used for texture editing.
///
/// # Structure
///
/// The DDS header follows immediately after the 4-byte "DDS " magic.
/// Total file header size is 128 bytes (4 magic + 124 header).
///
/// # Endianness
///
/// DDS files use little-endian byte order.
///
/// # Flags
///
/// Common flag combinations:
/// - `0x100F` - Basic texture (CAPS, HEIGHT, WIDTH, PIXELFORMAT)
/// - `0x2100F` - With mipmaps (adds MIPMAPCOUNT)
/// - `0x81007` - Compressed without mipmaps (adds LINEARSIZE)
/// - `0xA1007` - Compressed with mipmaps
#[binrw]
#[br(little)]
#[bw(little)]
pub struct DdsHeader {
    /// Magic bytes "DDS " - validated by binrw
    #[brw(magic = b"DDS ")]
    pub _magic: (),
    /// Header size (always 124, not including magic)
    pub size: u32,
    /// Flags indicating which fields are valid
    pub flags: u32,
    /// Texture height in pixels
    pub height: u32,
    /// Texture width in pixels
    pub width: u32,
    /// Row pitch (uncompressed) or total size (compressed)
    pub pitch_or_linear_size: u32,
    /// Depth for volume textures (usually 0)
    pub depth: u32,
    /// Number of mipmap levels (0 or 1 means no mipmaps)
    pub mip_map_count: u32,
    /// Reserved space (unused, set to 0)
    pub reserved1: [u32; 11],
    /// Embedded pixel format descriptor
    pub pixel_format: DdsPixelFormat,
    /// Surface complexity flags (TEXTURE, MIPMAP, COMPLEX)
    pub caps: u32,
    /// Additional caps for cubemaps/volumes
    pub caps2: u32,
    /// Reserved caps field
    pub caps3: u32,
    /// Reserved caps field
    pub caps4: u32,
    /// Reserved field
    pub reserved2: u32,
}

/// DDS pixel format descriptor (32 bytes).
///
/// Embedded within the DDS header to describe the pixel data format.
///
/// # Format Types
///
/// There are two main format categories:
///
/// 1. **Compressed (FourCC)**: `flags = 0x04`
///    - `four_cc` contains format code ("DXT1", "DXT3", "DXT5", etc.)
///    - RGB masks are ignored
///
/// 2. **Uncompressed (RGB/RGBA)**: `flags = 0x40` (RGB) or `0x41` (RGBA)
///    - `rgb_bit_count` specifies bits per pixel
///    - Bit masks define channel positions
///
/// # Common Formats
///
/// | FourCC | Description                    |
/// |--------|--------------------------------|
/// | DXT1   | BC1 - RGB with 1-bit alpha     |
/// | DXT3   | BC2 - RGBA with explicit alpha |
/// | DXT5   | BC3 - RGBA with interpolated alpha |
#[binrw]
#[br(little)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DdsPixelFormat {
    /// Structure size (always 32)
    pub size: u32,
    /// Format flags (0x04=FOURCC, 0x40=RGB, 0x41=RGBA)
    pub flags: u32,
    /// Four-character code for compressed formats (e.g., "DXT1")
    pub four_cc: [u8; 4],
    /// Bits per pixel for uncompressed formats (8, 16, 24, 32)
    pub rgb_bit_count: u32,
    /// Red channel bit mask (e.g., 0x00FF0000 for BGRA)
    pub r_bit_mask: u32,
    /// Green channel bit mask (e.g., 0x0000FF00)
    pub g_bit_mask: u32,
    /// Blue channel bit mask (e.g., 0x000000FF)
    pub b_bit_mask: u32,
    /// Alpha channel bit mask (e.g., 0xFF000000)
    pub a_bit_mask: u32,
}

/// Image metadata returned to Flutter after extraction.
///
/// This struct contains texture properties without the actual pixel data,
/// which is typically too large to pass efficiently through FFI.
///
/// # Usage
///
/// Returned by [`extract_img_to_dds`] and [`extract_img_to_memory`] to
/// provide texture information to the Flutter UI.
///
/// # Example
///
/// ```rust,ignore
/// let img_data = extract_img_to_dds(header, imgb, output)?;
/// println!("Texture: {}x{}, {} mips, format: {}",
///     img_data.width, img_data.height,
///     img_data.mip_count, img_data.format);
/// ```
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImgData {
    /// Texture width in pixels
    pub width: u16,
    /// Texture height in pixels
    pub height: u16,
    /// Number of mipmap levels
    pub mip_count: u8,
    /// Format name (debug representation of format code)
    pub format: String,
}