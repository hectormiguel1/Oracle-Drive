//! # VFX Data Structures
//!
//! This module defines the data structures for VFX (Visual Effects) files.
//!
//! ## SEDB Block Format
//!
//! All VFX record types share a common SEDB header:
//!
//! ```text
//! Offset  Size  Field
//! 0x00    4     Magic: "SEDB"
//! 0x04    4     Type: "vtex", "vmdl", "vanm", "veff"
//! 0x08    4     Version/flags
//! 0x0C    4     Unknown
//! 0x10    4     Header size (typically 0x30)
//! 0x14    4     Data size
//! 0x18    24    Reserved/padding
//! 0x30+   ...   Type-specific data
//! ```

use binrw::BinRead;
use serde::{Serialize, Deserialize};

/// Common SEDB header for all VFX block types.
///
/// This 48-byte header appears at the start of vtex, vmdl, vanm, and veff records.
#[derive(BinRead, Debug, Clone, Serialize, Deserialize)]
#[br(big)]
pub struct SedbHeader {
    /// Magic bytes "SEDB"
    #[br(count = 4)]
    #[br(map = |b: Vec<u8>| String::from_utf8_lossy(&b).trim_matches('\0').to_string())]
    pub magic: String,
    /// Block type: "vtex", "vmdl", "vanm", "veff"
    #[br(count = 4)]
    #[br(map = |b: Vec<u8>| String::from_utf8_lossy(&b).trim_matches('\0').to_string())]
    pub block_type: String,
    /// Version or flags
    pub version: u32,
    /// Unknown field
    pub unknown: u32,
    /// Header size (usually 0x30 = 48)
    pub header_size: u32,
    /// Data size following header
    pub data_size: u32,
    /// Reserved padding
    #[br(count = 24)]
    pub reserved: Vec<u8>,
}

/// Parsed VFX file containing all effects data.
///
/// This is the main output structure returned by [`parse_vfx`].
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VfxData {
    /// Source file path
    pub source_path: String,
    /// All texture references in the VFX
    pub textures: Vec<VfxTexture>,
    /// All 3D models in the VFX
    pub models: Vec<VfxModel>,
    /// All vertex animations
    pub animations: Vec<VfxAnimation>,
    /// All effect definitions
    pub effects: Vec<VfxEffect>,
}

impl Default for VfxData {
    fn default() -> Self {
        Self {
            source_path: String::new(),
            textures: Vec::new(),
            models: Vec::new(),
            animations: Vec::new(),
            effects: Vec::new(),
        }
    }
}

/// Texture reference from SEDBvtex block.
///
/// Contains GTEX header metadata. Actual pixel data is in paired IMGB file.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VfxTexture {
    /// Record name (hash-based, e.g., "v04fdfc11828acd")
    pub name: String,
    /// Texture width in pixels
    pub width: u16,
    /// Texture height in pixels
    pub height: u16,
    /// Pixel format code (24=DXT1, 25=DXT3, 26=DXT5, 3-4=RGBA)
    pub format: u8,
    /// Format name for display
    pub format_name: String,
    /// Number of mipmap levels
    pub mip_count: u8,
    /// Image type (2D, 3D, cube)
    pub image_type: u8,
    /// Depth (for 3D textures)
    pub depth: u16,
    /// Offset in IMGB file
    pub imgb_offset: u32,
    /// Size in IMGB file
    pub imgb_size: u32,
}

/// 3D mesh model from SEDBvmdl block.
///
/// Contains mesh geometry and material properties.
/// Shader bytecode is D3D9 (ps_3_0) and cannot be directly executed.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VfxModel {
    /// Record name (hash-based)
    pub name: String,
    /// Total data size
    pub data_size: u32,
    /// Vertex count (if parseable)
    pub vertex_count: Option<u32>,
    /// Index count (if parseable)
    pub index_count: Option<u32>,
    /// Material properties
    pub material: VfxMaterial,
    /// Texture references found in shader
    pub texture_refs: Vec<String>,
    /// Whether compiled shader is present
    pub has_shader: bool,
    /// Shader technique name (if found)
    pub technique_name: Option<String>,
    /// Mesh geometry (vertices and indices)
    pub mesh: Option<VfxMesh>,
}

/// Mesh geometry data for VFX models.
///
/// VFX models are typically billboard quads (4 vertices) or simple shapes.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VfxMesh {
    /// Vertex positions and UVs
    pub vertices: Vec<VfxVertex>,
    /// Triangle indices (3 per triangle)
    pub indices: Vec<u16>,
    /// Primitive type
    pub primitive_type: VfxPrimitiveType,
}

/// Single vertex with position and UV coordinates.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VfxVertex {
    /// Position (x, y, z)
    pub position: [f32; 3],
    /// Texture coordinates (u, v)
    pub uv: [f32; 2],
}

/// Type of primitive for rendering.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub enum VfxPrimitiveType {
    /// Triangle list (3 indices per triangle)
    #[default]
    TriangleList,
    /// Triangle strip
    TriangleStrip,
    /// Point sprites/billboards
    PointSprite,
}

/// Material properties extracted from vmdl block.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct VfxMaterial {
    /// Ambient color (RGBA)
    pub ambient_color: [f32; 4],
    /// Diffuse color (RGBA)
    pub diffuse_color: [f32; 4],
    /// Specular color (RGBA)
    pub specular_color: [f32; 4],
    /// Shininess/specular power
    pub shininess: f32,
    /// Fog parameters
    pub fog_param: [f32; 4],
    /// Fog color
    pub fog_color: [f32; 4],
    /// Alpha test threshold
    pub alpha_threshold: f32,
    /// Blend mode enabled
    pub blend_enabled: bool,
    /// Alpha test enabled
    pub alpha_test_enabled: bool,
    /// Back-face culling enabled
    pub back_face_culling: bool,
    /// Depth mask enabled
    pub depth_mask_enabled: bool,
    /// Lighting enabled
    pub lighting_enabled: bool,
}

/// Vertex animation from SEDBvanm block.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VfxAnimation {
    /// Record name (hash-based)
    pub name: String,
    /// Total data size
    pub data_size: u32,
    /// Duration in frames (if parseable)
    pub duration_frames: Option<u32>,
    /// Number of keyframes (if parseable)
    pub keyframe_count: Option<u32>,
}

/// Effect definition from SEDBveff block.
///
/// Main controller defining how particles/meshes behave.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VfxEffect {
    /// Effect name (human-readable, e.g., "ev_loc_thanks")
    pub name: String,
    /// Total data size
    pub data_size: u32,
    /// Controller paths found (SQEX/CDev/Engine/Vfx/...)
    pub controller_paths: Vec<String>,
    /// Model references (vmdl hashes)
    pub model_refs: Vec<String>,
    /// Texture references (vtex hashes)
    pub texture_refs: Vec<String>,
}

/// Summary of VFX file contents for quick display.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VfxSummary {
    /// Source file path
    pub source_path: String,
    /// Number of textures
    pub texture_count: usize,
    /// Number of models
    pub model_count: usize,
    /// Number of animations
    pub animation_count: usize,
    /// Number of effects
    pub effect_count: usize,
    /// Total file size
    pub total_size: u64,
    /// Effect names (human-readable)
    pub effect_names: Vec<String>,
}

impl From<&VfxData> for VfxSummary {
    fn from(data: &VfxData) -> Self {
        Self {
            source_path: data.source_path.clone(),
            texture_count: data.textures.len(),
            model_count: data.models.len(),
            animation_count: data.animations.len(),
            effect_count: data.effects.len(),
            total_size: 0, // Will be set by caller
            effect_names: data.effects.iter().map(|e| e.name.clone()).collect(),
        }
    }
}
