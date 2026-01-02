//! # CGT File Reader
//!
//! Binary parser for CGT (Crystal Graph Tree) files.
//! All values are stored in Big Endian byte order.

use anyhow::{anyhow, Result};
use byteorder::{BigEndian, ReadBytesExt};
use std::io::{Cursor, Read};

use super::structs::{cgt_sizes::*, CgtFile, CrystariumEntry, CrystariumNode, Vec3};

/// Parse a CGT file from a byte slice.
///
/// # Arguments
/// * `data` - Raw CGT file bytes
///
/// # Returns
/// * `Ok(CgtFile)` - Parsed CGT data
/// * `Err` - If the file format is invalid
///
/// # Example
/// ```rust,ignore
/// let bytes = std::fs::read("lightning.cgt")?;
/// let cgt = parse_cgt_bytes(&bytes)?;
/// ```
pub fn parse_cgt_bytes(data: &[u8]) -> Result<CgtFile> {
    if data.len() < HEADER_SIZE {
        return Err(anyhow!(
            "CGT file too small: {} bytes (minimum {})",
            data.len(),
            HEADER_SIZE
        ));
    }

    let mut cursor = Cursor::new(data);

    // Parse header
    let version = cursor.read_u32::<BigEndian>()?;
    let entry_count = cursor.read_u32::<BigEndian>()?;
    let total_nodes = cursor.read_u32::<BigEndian>()?;
    let reserved = cursor.read_u32::<BigEndian>()?;

    // Validate size
    let entry_section_size = entry_count as usize * ENTRY_SIZE;
    let min_size = HEADER_SIZE + entry_section_size;
    if data.len() < min_size {
        return Err(anyhow!(
            "CGT file too small for {} entries: {} bytes (expected at least {})",
            entry_count,
            data.len(),
            min_size
        ));
    }

    // Parse entries
    let mut entries = Vec::with_capacity(entry_count as usize);
    for i in 0..entry_count {
        let entry = parse_entry(&mut cursor, i)?;
        entries.push(entry);
    }

    // Parse nodes
    let node_array_offset = HEADER_SIZE + entry_section_size;
    let remaining_bytes = data.len() - node_array_offset;
    let node_count = remaining_bytes / NODE_SIZE;

    let mut nodes = Vec::with_capacity(node_count);
    for i in 0..node_count {
        let node = parse_node(&mut cursor, i as u32)?;
        nodes.push(node);
    }

    Ok(CgtFile {
        version,
        entry_count,
        total_nodes,
        reserved,
        entries,
        nodes,
    })
}

/// Parse a single entry from the cursor.
fn parse_entry(cursor: &mut Cursor<&[u8]>, index: u32) -> Result<CrystariumEntry> {
    // Pattern name (16 bytes, null-terminated ASCII)
    let mut name_bytes = [0u8; NAME_SIZE];
    cursor.read_exact(&mut name_bytes)?;
    let pattern_name = parse_null_terminated_string(&name_bytes);

    // Position (3 x f32)
    let pos_x = cursor.read_f32::<BigEndian>()?;
    let pos_y = cursor.read_f32::<BigEndian>()?;
    let pos_z = cursor.read_f32::<BigEndian>()?;
    let position = Vec3::new(pos_x, pos_y, pos_z);

    // Scale (f32)
    let scale = cursor.read_f32::<BigEndian>()?;

    // Rotation quaternion (4 x f32)
    let rot_x = cursor.read_f32::<BigEndian>()?;
    let rot_y = cursor.read_f32::<BigEndian>()?;
    let rot_z = cursor.read_f32::<BigEndian>()?;
    let rotation_w = cursor.read_f32::<BigEndian>()?;
    let rotation = Vec3::new(rot_x, rot_y, rot_z);

    // Node scale (f32)
    let node_scale = cursor.read_f32::<BigEndian>()?;

    // Flags (4 bytes)
    let role_id = cursor.read_u8()?;
    let stage = cursor.read_u8()?;
    let entry_type = cursor.read_u8()?;
    let reserved = cursor.read_u8()?;

    // Node IDs (16 x u32)
    let mut node_ids = Vec::new();
    for _ in 0..NODE_IDS_COUNT {
        let node_id = cursor.read_u32::<BigEndian>()?;
        if node_id > 0 {
            node_ids.push(node_id);
        }
    }

    // Link position (4 x f32)
    let link_x = cursor.read_f32::<BigEndian>()?;
    let link_y = cursor.read_f32::<BigEndian>()?;
    let link_z = cursor.read_f32::<BigEndian>()?;
    let link_w = cursor.read_f32::<BigEndian>()?;
    let link_position = Vec3::new(link_x, link_y, link_z);

    Ok(CrystariumEntry {
        index,
        pattern_name,
        position,
        scale,
        rotation,
        rotation_w,
        node_scale,
        role_id,
        stage,
        entry_type,
        reserved,
        node_ids,
        link_position,
        link_w,
    })
}

/// Parse a single node from the cursor.
fn parse_node(cursor: &mut Cursor<&[u8]>, index: u32) -> Result<CrystariumNode> {
    // Node name (16 bytes, null-terminated ASCII)
    let mut name_bytes = [0u8; NAME_SIZE];
    cursor.read_exact(&mut name_bytes)?;
    let name = parse_null_terminated_string(&name_bytes);

    // Parent index (i32, signed - root has -1)
    let parent_index = cursor.read_i32::<BigEndian>()?;

    // Unknown fields (4 x u32)
    let unknown = [
        cursor.read_u32::<BigEndian>()?,
        cursor.read_u32::<BigEndian>()?,
        cursor.read_u32::<BigEndian>()?,
        cursor.read_u32::<BigEndian>()?,
    ];

    // Scale values (4 x f32)
    let scales = [
        cursor.read_f32::<BigEndian>()?,
        cursor.read_f32::<BigEndian>()?,
        cursor.read_f32::<BigEndian>()?,
        cursor.read_f32::<BigEndian>()?,
    ];

    Ok(CrystariumNode {
        index,
        name,
        parent_index,
        unknown,
        scales,
    })
}

/// Parse a null-terminated string from a fixed-size byte array.
fn parse_null_terminated_string(bytes: &[u8]) -> String {
    let end = bytes.iter().position(|&b| b == 0).unwrap_or(bytes.len());
    String::from_utf8_lossy(&bytes[..end]).to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_null_terminated() {
        let bytes = [b't', b'e', b's', b't', 0, 0, 0, 0];
        assert_eq!(parse_null_terminated_string(&bytes), "test");

        let full = [b'f', b'u', b'l', b'l'];
        assert_eq!(parse_null_terminated_string(&full), "full");
    }
}
