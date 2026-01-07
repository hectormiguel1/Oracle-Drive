//! # VFX Binary Reader
//!
//! This module provides binary parsing for VFX (Visual Effects) files.
//! XFV files are WPD containers with SEDB-prefixed records.

use std::io::{Read, Seek, Cursor};
use binrw::BinReaderExt;
use anyhow::{Result, Context};
use super::structs::*;
use crate::modules::wpd::reader::WpdReader;
use crate::modules::img::structs::GtexHeader;
use byteorder::{LittleEndian, ReadBytesExt};

/// Binary reader for VFX XFV files.
pub struct VfxReader<R: Read + Seek> {
    reader: R,
}

impl<R: Read + Seek> VfxReader<R> {
    /// Creates a new VFX reader.
    pub fn new(reader: R) -> Self {
        Self { reader }
    }

    /// Reads and parses the entire VFX file.
    pub fn read_vfx(&mut self) -> Result<VfxData> {
        // Read as WPD container first
        let mut wpd_reader = WpdReader::new(&mut self.reader);
        let header = wpd_reader.read_header()
            .context("Failed to read WPD header")?;
        let records = wpd_reader.read_records(&header)
            .context("Failed to read WPD records")?;

        let mut vfx = VfxData::default();

        // Parse each record based on extension
        for record in records {
            match record.extension.as_str() {
                "vtex" => {
                    if let Ok(tex) = self.parse_vtex(&record.name, &record.data) {
                        vfx.textures.push(tex);
                    }
                }
                "vmdl" => {
                    if let Ok(mdl) = self.parse_vmdl(&record.name, &record.data) {
                        vfx.models.push(mdl);
                    }
                }
                "vanm" => {
                    if let Ok(anim) = self.parse_vanm(&record.name, &record.data) {
                        vfx.animations.push(anim);
                    }
                }
                "veff" => {
                    if let Ok(eff) = self.parse_veff(&record.name, &record.data) {
                        vfx.effects.push(eff);
                    }
                }
                _ => {
                    log::debug!("Unknown VFX record type: {}", record.extension);
                }
            }
        }

        Ok(vfx)
    }

    /// Parses a SEDBvtex (texture) record.
    fn parse_vtex(&self, name: &str, data: &[u8]) -> Result<VfxTexture> {
        // Validate SEDB header
        if data.len() < 48 || &data[0..4] != b"SEDB" || &data[4..8] != b"vtex" {
            anyhow::bail!("Invalid SEDBvtex header");
        }

        // Search for GTEX header in the data
        let mut tex = VfxTexture {
            name: name.to_string(),
            width: 0,
            height: 0,
            format: 0,
            format_name: "Unknown".to_string(),
            mip_count: 0,
            image_type: 0,
            depth: 0,
            imgb_offset: 0,
            imgb_size: 0,
        };

        // Find GTEX magic in data
        if let Some(gtex_pos) = find_magic(data, b"GTEX") {
            if gtex_pos + 16 <= data.len() {
                let mut cursor = Cursor::new(&data[gtex_pos..]);
                if let Ok(gtex) = cursor.read_be::<GtexHeader>() {
                    tex.width = gtex.width;
                    tex.height = gtex.height;
                    tex.format = gtex.format;
                    tex.format_name = format_name(gtex.format);
                    tex.mip_count = gtex.mip_count;
                    tex.image_type = gtex.img_type;
                    tex.depth = gtex.depth;
                }
            }
        }

        // Try to extract IMGB offset from the data after GTEX
        // The mipmap table follows the GTEX header
        if let Some(gtex_pos) = find_magic(data, b"GTEX") {
            let mip_table_start = gtex_pos + 16; // After 16-byte GTEX header
            if mip_table_start + 8 <= data.len() {
                // First mip entry: offset (u32 BE), size (u32 BE)
                let offset_bytes = &data[mip_table_start..mip_table_start + 4];
                let size_bytes = &data[mip_table_start + 4..mip_table_start + 8];
                tex.imgb_offset = u32::from_be_bytes([
                    offset_bytes[0], offset_bytes[1], offset_bytes[2], offset_bytes[3]
                ]);
                tex.imgb_size = u32::from_be_bytes([
                    size_bytes[0], size_bytes[1], size_bytes[2], size_bytes[3]
                ]);
            }
        }

        Ok(tex)
    }

    /// Parses a SEDBvmdl (model) record.
    fn parse_vmdl(&self, name: &str, data: &[u8]) -> Result<VfxModel> {
        // Validate SEDB header
        if data.len() < 48 || &data[0..4] != b"SEDB" || &data[4..8] != b"vmdl" {
            anyhow::bail!("Invalid SEDBvmdl header");
        }

        let mut model = VfxModel {
            name: name.to_string(),
            data_size: data.len() as u32,
            vertex_count: None,
            index_count: None,
            material: VfxMaterial::default(),
            texture_refs: Vec::new(),
            has_shader: false,
            technique_name: None,
            mesh: None,
        };

        // Search for shader signatures
        // D3D9 shaders start with 0xFFFF (version) or contain "ps_3_0"
        if data.windows(4).any(|w| w == [0xFF, 0xFF, 0x03, 0x00]) {
            model.has_shader = true;
        }

        // Look for technique name
        if let Some(pos) = find_string(data, b"TechCgfxShader") {
            model.technique_name = Some(extract_string(data, pos));
        }

        // Extract texture references (look for .dds paths)
        let mut i = 0;
        while i < data.len().saturating_sub(4) {
            // Look for path patterns like "whiteproj\" or ".dds"
            if &data[i..i.min(data.len() - 4) + 4] == b".dds" {
                // Try to extract the full path
                if let Some(path) = extract_path_before(data, i) {
                    if !model.texture_refs.contains(&path) {
                        model.texture_refs.push(path);
                    }
                }
            }
            i += 1;
        }

        // Extract material properties from strings in data
        // These are usually in parameter blocks
        model.material = extract_material_hints(data);

        // Try to parse mesh geometry (only for models without complex shaders)
        if !model.has_shader {
            model.mesh = parse_mesh_geometry(data);
            if let Some(ref mesh) = model.mesh {
                model.vertex_count = Some(mesh.vertices.len() as u32);
                model.index_count = Some(mesh.indices.len() as u32);
            }
        }

        Ok(model)
    }

    /// Parses a SEDBvanm (animation) record.
    fn parse_vanm(&self, name: &str, data: &[u8]) -> Result<VfxAnimation> {
        // Validate SEDB header
        if data.len() < 48 || &data[0..4] != b"SEDB" || &data[4..8] != b"vanm" {
            anyhow::bail!("Invalid SEDBvanm header");
        }

        let anim = VfxAnimation {
            name: name.to_string(),
            data_size: data.len() as u32,
            duration_frames: None,
            keyframe_count: None,
        };

        // Animation data format is complex - return basic info for now
        Ok(anim)
    }

    /// Parses a SEDBveff (effect definition) record.
    fn parse_veff(&self, name: &str, data: &[u8]) -> Result<VfxEffect> {
        // Validate SEDB header
        if data.len() < 48 || &data[0..4] != b"SEDB" || &data[4..8] != b"veff" {
            anyhow::bail!("Invalid SEDBveff header");
        }

        let mut effect = VfxEffect {
            name: name.to_string(),
            data_size: data.len() as u32,
            controller_paths: Vec::new(),
            model_refs: Vec::new(),
            texture_refs: Vec::new(),
        };

        // Extract SQEX controller paths
        let mut i = 0;
        while i < data.len().saturating_sub(10) {
            // Look for "SQEX/" prefix
            if &data[i..i + 5] == b"SQEX/" {
                let path = extract_string(data, i);
                if !effect.controller_paths.contains(&path) {
                    effect.controller_paths.push(path);
                }
            }
            i += 1;
        }

        // Extract model references (v-prefixed hashes)
        i = 0;
        while i < data.len().saturating_sub(16) {
            // Look for 'v' followed by hex characters (model hash)
            if data[i] == b'v' && is_hex_string(&data[i + 1..i.min(data.len() - 16) + 16]) {
                let ref_name = extract_string(data, i);
                if ref_name.len() >= 8 && ref_name.len() <= 20 {
                    if !effect.model_refs.contains(&ref_name) && !effect.texture_refs.contains(&ref_name) {
                        effect.model_refs.push(ref_name);
                    }
                }
            }
            i += 1;
        }

        Ok(effect)
    }
}

/// Find a magic byte sequence in data.
fn find_magic(data: &[u8], magic: &[u8]) -> Option<usize> {
    data.windows(magic.len())
        .position(|window| window == magic)
}

/// Find a string pattern in data.
fn find_string(data: &[u8], pattern: &[u8]) -> Option<usize> {
    data.windows(pattern.len())
        .position(|window| window == pattern)
}

/// Extract a null-terminated string starting at position.
fn extract_string(data: &[u8], start: usize) -> String {
    let mut end = start;
    while end < data.len() && data[end] != 0 && data[end].is_ascii_graphic() {
        end += 1;
    }
    String::from_utf8_lossy(&data[start..end]).to_string()
}

/// Extract a path before a given position (for .dds references).
fn extract_path_before(data: &[u8], end_pos: usize) -> Option<String> {
    if end_pos < 4 {
        return None;
    }

    // Find the start of the path (look for non-path characters going backwards)
    let mut start = end_pos;
    while start > 0 {
        let c = data[start - 1];
        if c.is_ascii_alphanumeric() || c == b'\\' || c == b'/' || c == b'_' || c == b'.' {
            start -= 1;
        } else {
            break;
        }
    }

    if start < end_pos {
        let path_bytes = &data[start..end_pos + 4]; // Include ".dds"
        let path = String::from_utf8_lossy(path_bytes).to_string();
        if path.len() >= 5 {
            return Some(path);
        }
    }

    None
}

/// Check if bytes form a hex string.
fn is_hex_string(data: &[u8]) -> bool {
    if data.is_empty() {
        return false;
    }
    let check_len = data.len().min(14);
    data[..check_len].iter().all(|&b|
        (b >= b'0' && b <= b'9') || (b >= b'a' && b <= b'f') || (b >= b'A' && b <= b'F')
    )
}

/// Get format name from GTEX format code.
fn format_name(format: u8) -> String {
    match format {
        3 | 4 => "RGBA".to_string(),
        24 => "DXT1".to_string(),
        25 => "DXT3".to_string(),
        26 => "DXT5".to_string(),
        _ => format!("Unknown({})", format),
    }
}

/// Extract material hints from data.
fn extract_material_hints(data: &[u8]) -> VfxMaterial {
    let mut mat = VfxMaterial::default();

    // Look for known material property strings and set flags
    if find_string(data, b"isEnabledBlend").is_some() ||
       find_string(data, b"BlendMode").is_some() {
        mat.blend_enabled = true;
    }

    if find_string(data, b"isEnabledAlphaTest").is_some() ||
       find_string(data, b"AlphaTest").is_some() {
        mat.alpha_test_enabled = true;
    }

    if find_string(data, b"isEnabledBackFaceCulling").is_some() {
        mat.back_face_culling = true;
    }

    if find_string(data, b"isEnabledDepthMask").is_some() {
        mat.depth_mask_enabled = true;
    }

    if find_string(data, b"isEnabledLighting").is_some() {
        mat.lighting_enabled = true;
    }

    // Default sensible values for rendering
    mat.diffuse_color = [1.0, 1.0, 1.0, 1.0];
    mat.ambient_color = [0.2, 0.2, 0.2, 1.0];
    mat.specular_color = [0.5, 0.5, 0.5, 1.0];
    mat.shininess = 32.0;

    mat
}

/// Parse mesh geometry from vmdl data.
///
/// VFX models are typically billboard quads with:
/// - Vertex format: position (3 floats) + UV (2 floats) = 20 bytes per vertex
/// - Index format: u16 triangle indices
fn parse_mesh_geometry(data: &[u8]) -> Option<VfxMesh> {
    // Search for vertex buffer in the 0x400-0x600 range
    // VFX billboards typically have 4 vertices forming a quad

    for vb_start in (0x400..0x600.min(data.len().saturating_sub(100))).step_by(4) {
        let mut vertices = Vec::new();
        let mut valid_count = 0;

        // Try to read up to 8 vertices with stride 20
        for v in 0..8 {
            let start = vb_start + v * 20;
            if start + 20 > data.len() {
                break;
            }

            let mut cursor = Cursor::new(&data[start..start + 20]);
            let px = cursor.read_f32::<LittleEndian>().ok()?;
            let py = cursor.read_f32::<LittleEndian>().ok()?;
            let pz = cursor.read_f32::<LittleEndian>().ok()?;
            let u = cursor.read_f32::<LittleEndian>().ok()?;
            let uv_v = cursor.read_f32::<LittleEndian>().ok()?;

            // Validate vertex data
            if !px.is_finite() || !py.is_finite() || !pz.is_finite() {
                break;
            }
            if !u.is_finite() || !uv_v.is_finite() {
                break;
            }

            // Check reasonable bounds
            if px.abs() > 100.0 || py.abs() > 100.0 || pz.abs() > 100.0 {
                break;
            }
            if u.abs() > 10.0 || uv_v.abs() > 10.0 {
                break;
            }

            // Count non-zero vertices
            if px.abs() > 0.001 || py.abs() > 0.001 || pz.abs() > 0.001 {
                valid_count += 1;
            }

            vertices.push(VfxVertex {
                position: [px, py, pz],
                uv: [u, uv_v],
            });
        }

        // We need at least 3 non-zero vertices for a triangle
        if valid_count >= 3 && vertices.len() >= 3 {
            // Look for index buffer after vertices
            let indices = find_index_buffer(data, vb_start + vertices.len() * 20, vertices.len());

            // If no indices found, generate default quad indices
            let indices = indices.unwrap_or_else(|| {
                if vertices.len() >= 4 {
                    // Quad: two triangles
                    vec![0, 1, 2, 2, 3, 0]
                } else if vertices.len() == 3 {
                    vec![0, 1, 2]
                } else {
                    vec![]
                }
            });

            if !indices.is_empty() {
                return Some(VfxMesh {
                    vertices,
                    indices,
                    primitive_type: VfxPrimitiveType::TriangleList,
                });
            }
        }
    }

    // If no mesh found, create a default billboard quad
    Some(create_default_billboard())
}

/// Search for u16 index buffer starting at given offset.
fn find_index_buffer(data: &[u8], start_offset: usize, max_vertex_index: usize) -> Option<Vec<u16>> {
    for search_start in (start_offset..start_offset + 200.min(data.len().saturating_sub(24))).step_by(2) {
        let mut indices = Vec::new();
        let mut valid = true;

        // Try to read triangle indices (multiples of 3)
        for i in 0..12 {
            if search_start + i * 2 + 2 > data.len() {
                break;
            }

            let mut cursor = Cursor::new(&data[search_start + i * 2..]);
            let idx = cursor.read_u16::<LittleEndian>().ok()?;

            // Check if this looks like a valid index
            if idx as usize >= max_vertex_index + 10 {
                valid = false;
                break;
            }

            indices.push(idx);
        }

        // Check for valid triangle pattern
        if valid && indices.len() >= 3 {
            // First triangle should have different indices
            if indices.len() >= 3 && indices[0] != indices[1] && indices[1] != indices[2] {
                // Trim to multiple of 3
                let len = (indices.len() / 3) * 3;
                indices.truncate(len);
                if !indices.is_empty() {
                    return Some(indices);
                }
            }
        }
    }

    None
}

/// Create a default billboard quad mesh for models without parseable geometry.
fn create_default_billboard() -> VfxMesh {
    VfxMesh {
        vertices: vec![
            VfxVertex { position: [-0.5, -0.5, 0.0], uv: [0.0, 1.0] },
            VfxVertex { position: [ 0.5, -0.5, 0.0], uv: [1.0, 1.0] },
            VfxVertex { position: [ 0.5,  0.5, 0.0], uv: [1.0, 0.0] },
            VfxVertex { position: [-0.5,  0.5, 0.0], uv: [0.0, 0.0] },
        ],
        indices: vec![0, 1, 2, 2, 3, 0],
        primitive_type: VfxPrimitiveType::TriangleList,
    }
}
