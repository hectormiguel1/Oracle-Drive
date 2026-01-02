//! # CGT File Writer
//!
//! Binary serializer for CGT (Crystal Graph Tree) files.
//! All values are stored in Big Endian byte order.

use anyhow::Result;
use byteorder::{BigEndian, WriteBytesExt};
use std::io::{Cursor, Write};

use super::structs::{cgt_sizes::*, CgtFile, CrystariumEntry, CrystariumNode};

/// Write a CGT file to bytes.
///
/// # Arguments
/// * `cgt` - The CGT data to serialize
///
/// # Returns
/// * `Ok(Vec<u8>)` - Serialized CGT file bytes
/// * `Err` - If serialization fails
///
/// # Example
/// ```rust,ignore
/// let bytes = write_cgt_bytes(&cgt)?;
/// std::fs::write("output.cgt", bytes)?;
/// ```
pub fn write_cgt_bytes(cgt: &CgtFile) -> Result<Vec<u8>> {
    let entry_count = cgt.entries.len();
    let node_count = cgt.nodes.len();
    let total_size = HEADER_SIZE + (entry_count * ENTRY_SIZE) + (node_count * NODE_SIZE);

    let mut buffer = Vec::with_capacity(total_size);
    let mut cursor = Cursor::new(&mut buffer);

    // Write header
    cursor.write_u32::<BigEndian>(cgt.version)?;
    cursor.write_u32::<BigEndian>(entry_count as u32)?;
    cursor.write_u32::<BigEndian>(node_count as u32)?;
    cursor.write_u32::<BigEndian>(cgt.reserved)?;

    // Write entries
    for entry in &cgt.entries {
        write_entry(&mut cursor, entry)?;
    }

    // Write nodes
    for node in &cgt.nodes {
        write_node(&mut cursor, node)?;
    }

    Ok(buffer)
}

/// Write a single entry to the cursor.
fn write_entry<W: Write>(cursor: &mut W, entry: &CrystariumEntry) -> Result<()> {
    // Pattern name (16 bytes, null-padded)
    let name_bytes = string_to_bytes(&entry.pattern_name, NAME_SIZE);
    cursor.write_all(&name_bytes)?;

    // Position (3 x f32)
    cursor.write_f32::<BigEndian>(entry.position.x)?;
    cursor.write_f32::<BigEndian>(entry.position.y)?;
    cursor.write_f32::<BigEndian>(entry.position.z)?;

    // Scale (f32)
    cursor.write_f32::<BigEndian>(entry.scale)?;

    // Rotation quaternion (4 x f32)
    cursor.write_f32::<BigEndian>(entry.rotation.x)?;
    cursor.write_f32::<BigEndian>(entry.rotation.y)?;
    cursor.write_f32::<BigEndian>(entry.rotation.z)?;
    cursor.write_f32::<BigEndian>(entry.rotation_w)?;

    // Node scale (f32)
    cursor.write_f32::<BigEndian>(entry.node_scale)?;

    // Flags (4 bytes)
    cursor.write_u8(entry.role_id)?;
    cursor.write_u8(entry.stage)?;
    cursor.write_u8(entry.entry_type)?;
    cursor.write_u8(entry.reserved)?;

    // Node IDs (16 x u32, zero-padded)
    for i in 0..NODE_IDS_COUNT {
        let node_id = entry.node_ids.get(i).copied().unwrap_or(0);
        cursor.write_u32::<BigEndian>(node_id)?;
    }

    // Link position (4 x f32)
    cursor.write_f32::<BigEndian>(entry.link_position.x)?;
    cursor.write_f32::<BigEndian>(entry.link_position.y)?;
    cursor.write_f32::<BigEndian>(entry.link_position.z)?;
    cursor.write_f32::<BigEndian>(entry.link_w)?;

    Ok(())
}

/// Write a single node to the cursor.
fn write_node<W: Write>(cursor: &mut W, node: &CrystariumNode) -> Result<()> {
    // Node name (16 bytes, null-padded)
    let name_bytes = string_to_bytes(&node.name, NAME_SIZE);
    cursor.write_all(&name_bytes)?;

    // Parent index (i32, signed)
    cursor.write_i32::<BigEndian>(node.parent_index)?;

    // Unknown fields (4 x u32)
    for &val in &node.unknown {
        cursor.write_u32::<BigEndian>(val)?;
    }

    // Scale values (4 x f32)
    for &val in &node.scales {
        cursor.write_f32::<BigEndian>(val)?;
    }

    Ok(())
}

/// Convert a string to a fixed-size null-padded byte array.
fn string_to_bytes(s: &str, size: usize) -> Vec<u8> {
    let mut bytes = vec![0u8; size];
    let s_bytes = s.as_bytes();
    let copy_len = s_bytes.len().min(size);
    bytes[..copy_len].copy_from_slice(&s_bytes[..copy_len]);
    bytes
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_string_to_bytes() {
        let result = string_to_bytes("test", 8);
        assert_eq!(result, vec![b't', b'e', b's', b't', 0, 0, 0, 0]);

        let long = string_to_bytes("this is too long", 4);
        assert_eq!(long, vec![b't', b'h', b'i', b's']);
    }

    #[test]
    fn test_roundtrip_empty() {
        use super::super::reader::parse_cgt_bytes;

        let cgt = CgtFile::new();
        let bytes = write_cgt_bytes(&cgt).unwrap();
        let parsed = parse_cgt_bytes(&bytes).unwrap();

        assert_eq!(parsed.version, cgt.version);
        assert_eq!(parsed.entries.len(), 0);
        assert_eq!(parsed.nodes.len(), 0);
    }
}
