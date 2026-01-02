//! # Crystalium Public API
//!
//! High-level API functions for CGT and MCP file operations.
//! These functions are designed for use via FFI (Flutter Rust Bridge).

use anyhow::Result;
use std::fs;
use std::path::Path;

use super::reader::parse_cgt_bytes;
use super::writer::write_cgt_bytes;
use super::mcp_reader::parse_mcp_bytes;
use super::structs::{CgtFile, McpFile};

// =============================================================================
// CGT File Operations
// =============================================================================

/// Parse a CGT file from disk.
///
/// # Arguments
/// * `path` - Path to the CGT file
///
/// # Returns
/// * `Ok(CgtFile)` - Parsed CGT data
/// * `Err` - If the file cannot be read or parsed
///
/// # Example
/// ```rust,ignore
/// let cgt = parse_cgt("path/to/lightning.cgt")?;
/// println!("Loaded {} entries and {} nodes", cgt.entries.len(), cgt.nodes.len());
/// ```
pub fn parse_cgt(path: &str) -> Result<CgtFile> {
    let data = fs::read(path)?;
    parse_cgt_bytes(&data)
}

/// Parse a CGT file from memory.
///
/// # Arguments
/// * `data` - Raw CGT file bytes
///
/// # Returns
/// * `Ok(CgtFile)` - Parsed CGT data
/// * `Err` - If the data format is invalid
pub fn parse_cgt_from_memory(data: Vec<u8>) -> Result<CgtFile> {
    parse_cgt_bytes(&data)
}

/// Write a CGT file to disk.
///
/// # Arguments
/// * `cgt` - The CGT data to write
/// * `path` - Output file path
///
/// # Returns
/// * `Ok(())` - Success
/// * `Err` - If the file cannot be written
pub fn write_cgt(cgt: &CgtFile, path: &str) -> Result<()> {
    let bytes = write_cgt_bytes(cgt)?;

    // Create parent directories if needed
    if let Some(parent) = Path::new(path).parent() {
        if !parent.exists() {
            fs::create_dir_all(parent)?;
        }
    }

    fs::write(path, bytes)?;
    Ok(())
}

/// Write a CGT file to memory.
///
/// # Arguments
/// * `cgt` - The CGT data to serialize
///
/// # Returns
/// * `Ok(Vec<u8>)` - Serialized CGT bytes
/// * `Err` - If serialization fails
pub fn write_cgt_to_memory(cgt: &CgtFile) -> Result<Vec<u8>> {
    write_cgt_bytes(cgt)
}

/// Convert a CGT file to JSON string.
///
/// # Arguments
/// * `cgt` - The CGT data to convert
///
/// # Returns
/// * `Ok(String)` - JSON representation
/// * `Err` - If serialization fails
pub fn cgt_to_json(cgt: &CgtFile) -> Result<String> {
    Ok(serde_json::to_string_pretty(cgt)?)
}

/// Parse a CGT file from JSON string.
///
/// # Arguments
/// * `json` - JSON representation of a CGT file
///
/// # Returns
/// * `Ok(CgtFile)` - Parsed CGT data
/// * `Err` - If parsing fails
pub fn cgt_from_json(json: &str) -> Result<CgtFile> {
    Ok(serde_json::from_str(json)?)
}

// =============================================================================
// MCP File Operations
// =============================================================================

/// Parse an MCP file from disk.
///
/// # Arguments
/// * `path` - Path to the MCP file
///
/// # Returns
/// * `Ok(McpFile)` - Parsed MCP data
/// * `Err` - If the file cannot be read or parsed
pub fn parse_mcp(path: &str) -> Result<McpFile> {
    let data = fs::read(path)?;
    parse_mcp_bytes(&data)
}

/// Parse an MCP file from memory.
///
/// # Arguments
/// * `data` - Raw MCP file bytes
///
/// # Returns
/// * `Ok(McpFile)` - Parsed MCP data
/// * `Err` - If the data format is invalid
pub fn parse_mcp_from_memory(data: Vec<u8>) -> Result<McpFile> {
    parse_mcp_bytes(&data)
}

/// Convert an MCP file to JSON string.
///
/// # Arguments
/// * `mcp` - The MCP data to convert
///
/// # Returns
/// * `Ok(String)` - JSON representation
/// * `Err` - If serialization fails
pub fn mcp_to_json(mcp: &McpFile) -> Result<String> {
    Ok(serde_json::to_string_pretty(mcp)?)
}

/// Parse an MCP file from JSON string.
///
/// # Arguments
/// * `json` - JSON representation of an MCP file
///
/// # Returns
/// * `Ok(McpFile)` - Parsed MCP data
/// * `Err` - If parsing fails
pub fn mcp_from_json(json: &str) -> Result<McpFile> {
    Ok(serde_json::from_str(json)?)
}

// =============================================================================
// Utility Functions
// =============================================================================

/// Validate a CGT file structure.
///
/// Checks for:
/// - Valid parent references
/// - No orphaned nodes
/// - Consistent node counts
///
/// # Returns
/// * `Ok(Vec<String>)` - List of validation warnings (empty if valid)
/// * `Err` - If validation cannot be performed
pub fn validate_cgt(cgt: &CgtFile) -> Vec<String> {
    let mut warnings = Vec::new();

    // Build set of valid node indices
    let node_indices: std::collections::HashSet<u32> =
        cgt.nodes.iter().map(|n| n.index).collect();

    // Check parent references
    for node in &cgt.nodes {
        if node.parent_index >= 0 {
            let parent_id = node.parent_index as u32;
            if !node_indices.contains(&parent_id) && parent_id != 0 {
                warnings.push(format!(
                    "Node {} references non-existent parent {}",
                    node.index, node.parent_index
                ));
            }
        }
    }

    // Check entry node IDs
    for entry in &cgt.entries {
        for &node_id in &entry.node_ids {
            if node_id > 0 && !node_indices.contains(&node_id) {
                warnings.push(format!(
                    "Entry {} references non-existent node {}",
                    entry.index, node_id
                ));
            }
        }
    }

    // Check for orphaned nodes (no path to root)
    let mut reachable = std::collections::HashSet::new();
    reachable.insert(0u32);

    let mut changed = true;
    while changed {
        changed = false;
        for node in &cgt.nodes {
            if !reachable.contains(&node.index) &&
               node.parent_index >= 0 &&
               reachable.contains(&(node.parent_index as u32)) {
                reachable.insert(node.index);
                changed = true;
            }
        }
    }

    for node in &cgt.nodes {
        if !reachable.contains(&node.index) {
            warnings.push(format!("Node {} is not connected to root", node.index));
        }
    }

    warnings
}
