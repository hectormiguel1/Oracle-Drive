//! # MCP File Reader
//!
//! Binary parser for MCP (Master Crystal Pattern) files.
//! All values are stored in Big Endian byte order.

use anyhow::{anyhow, Result};
use byteorder::{BigEndian, ReadBytesExt};
use std::collections::HashMap;
use std::io::{Cursor, Read};

use super::structs::{mcp_sizes::*, McpFile, McpPattern, Vec3};

/// Parse an MCP file from a byte slice.
///
/// # Arguments
/// * `data` - Raw MCP file bytes
///
/// # Returns
/// * `Ok(McpFile)` - Parsed MCP data
/// * `Err` - If the file format is invalid
///
/// # Example
/// ```rust,ignore
/// let bytes = std::fs::read("patterns.mcp")?;
/// let mcp = parse_mcp_bytes(&bytes)?;
///
/// if let Some(pattern) = mcp.get_pattern("test3") {
///     println!("Pattern has {} nodes", pattern.count);
/// }
/// ```
pub fn parse_mcp_bytes(data: &[u8]) -> Result<McpFile> {
    if data.len() < HEADER_SIZE {
        return Err(anyhow!(
            "MCP file too small: {} bytes (minimum {})",
            data.len(),
            HEADER_SIZE
        ));
    }

    let mut cursor = Cursor::new(data);

    // Parse header
    let version = cursor.read_u32::<BigEndian>()?;
    let pattern_count = cursor.read_u32::<BigEndian>()?;
    let reserved = cursor.read_u32::<BigEndian>()?;
    let _padding = cursor.read_u32::<BigEndian>()?; // Skip 4 more bytes of reserved

    // Validate size
    let expected_size = HEADER_SIZE + (pattern_count as usize * PATTERN_SIZE);
    if data.len() < expected_size {
        return Err(anyhow!(
            "MCP file too small for {} patterns: {} bytes (expected at least {})",
            pattern_count,
            data.len(),
            expected_size
        ));
    }

    // Parse patterns
    let mut patterns = HashMap::with_capacity(pattern_count as usize);
    for i in 0..pattern_count {
        let pattern = parse_pattern(&mut cursor, i)?;
        patterns.insert(pattern.name.clone(), pattern);
    }

    Ok(McpFile {
        version,
        pattern_count,
        reserved,
        patterns,
    })
}

/// Parse a single pattern from the cursor.
fn parse_pattern(cursor: &mut Cursor<&[u8]>, index: u32) -> Result<McpPattern> {
    // Pattern name (16 bytes, null-terminated ASCII)
    let mut name_bytes = [0u8; NAME_SIZE];
    cursor.read_exact(&mut name_bytes)?;
    let name = parse_null_terminated_string(&name_bytes);
    let name = if name.is_empty() {
        format!("pattern_{}", index)
    } else {
        name
    };

    // Parse nodes (16 slots × 16 bytes each as Vec4)
    let mut nodes = Vec::new();
    for _ in 0..NODES_PER_PATTERN {
        let x = cursor.read_f32::<BigEndian>()?;
        let y = cursor.read_f32::<BigEndian>()?;
        let z = cursor.read_f32::<BigEndian>()?;
        let w = cursor.read_f32::<BigEndian>()?;

        // W = 1.0 indicates a valid node
        if w == 1.0 {
            nodes.push(Vec3::new(x, y, z));
        } else {
            // End of valid nodes for this pattern
            // Still need to read remaining slots to advance cursor
            let remaining = NODES_PER_PATTERN - nodes.len() - 1;
            for _ in 0..remaining {
                cursor.read_f32::<BigEndian>()?;
                cursor.read_f32::<BigEndian>()?;
                cursor.read_f32::<BigEndian>()?;
                cursor.read_f32::<BigEndian>()?;
            }
            break;
        }
    }

    let count = nodes.len();
    Ok(McpPattern { name, nodes, count })
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
        let bytes = [b't', b'e', b's', b't', b'3', 0, 0, 0];
        assert_eq!(parse_null_terminated_string(&bytes), "test3");
    }
}
