//! # Crystalium Data Structures
//!
//! This module defines all data structures for CGT and MCP file handling.
//!
//! ## Structure Categories
//!
//! 1. **Common Types**
//!    - [`Vec3`] - 3D vector (x, y, z)
//!    - [`Vec4`] - 4D vector/quaternion (x, y, z, w)
//!
//! 2. **CGT Structures**
//!    - [`CgtFile`] - Complete parsed CGT file
//!    - [`CrystariumEntry`] - Pattern entry with position, rotation, nodes
//!    - [`CrystariumNode`] - Individual node with parent connection
//!
//! 3. **MCP Structures**
//!    - [`McpFile`] - Complete parsed MCP file
//!    - [`McpPattern`] - Geometric pattern definition

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// =============================================================================
// Common Types
// =============================================================================

/// 3D vector used for positions.
#[derive(Debug, Clone, Copy, Default, PartialEq, Serialize, Deserialize)]
pub struct Vec3 {
    pub x: f32,
    pub y: f32,
    pub z: f32,
}

impl Vec3 {
    pub fn new(x: f32, y: f32, z: f32) -> Self {
        Self { x, y, z }
    }

    pub fn zero() -> Self {
        Self::default()
    }
}

/// 4D vector used for quaternions and extended positions.
#[derive(Debug, Clone, Copy, Default, PartialEq, Serialize, Deserialize)]
pub struct Vec4 {
    pub x: f32,
    pub y: f32,
    pub z: f32,
    pub w: f32,
}

impl Vec4 {
    pub fn new(x: f32, y: f32, z: f32, w: f32) -> Self {
        Self { x, y, z, w }
    }

    pub fn identity() -> Self {
        Self { x: 0.0, y: 0.0, z: 0.0, w: 1.0 }
    }
}

// =============================================================================
// CGT Structures
// =============================================================================

/// File size constants for CGT format.
pub mod cgt_sizes {
    pub const HEADER_SIZE: usize = 16;
    pub const ENTRY_SIZE: usize = 136;  // 0x88
    pub const NODE_SIZE: usize = 52;     // 0x34
    pub const NAME_SIZE: usize = 16;
    pub const NODE_IDS_COUNT: usize = 16;
}

/// A complete CGT (Crystal Graph Tree) file.
///
/// CGT files define character-specific Crystarium layouts for FF13.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CgtFile {
    /// File version (typically 1 or 2).
    pub version: u32,

    /// Number of entries in the file.
    pub entry_count: u32,

    /// Total number of nodes across all entries.
    pub total_nodes: u32,

    /// Reserved field (usually 0).
    pub reserved: u32,

    /// Pattern entries defining layout sections.
    pub entries: Vec<CrystariumEntry>,

    /// Node records with parent connections.
    pub nodes: Vec<CrystariumNode>,
}

impl CgtFile {
    /// Create a new empty CGT file.
    pub fn new() -> Self {
        Self {
            version: 1,
            entry_count: 0,
            total_nodes: 0,
            reserved: 0,
            entries: Vec::new(),
            nodes: Vec::new(),
        }
    }

    /// Get a node by its index.
    pub fn get_node(&self, index: u32) -> Option<&CrystariumNode> {
        self.nodes.iter().find(|n| n.index == index)
    }

    /// Get a mutable reference to a node by its index.
    pub fn get_node_mut(&mut self, index: u32) -> Option<&mut CrystariumNode> {
        self.nodes.iter_mut().find(|n| n.index == index)
    }

    /// Get an entry by its index.
    pub fn get_entry(&self, index: u32) -> Option<&CrystariumEntry> {
        self.entries.get(index as usize)
    }

    /// Build a map of node ID -> parent index for quick lookups.
    pub fn build_parent_map(&self) -> HashMap<u32, i32> {
        self.nodes.iter()
            .map(|n| (n.index, n.parent_index))
            .collect()
    }

    /// Build a map of parent ID -> child IDs.
    pub fn build_children_map(&self) -> HashMap<u32, Vec<u32>> {
        let mut map: HashMap<u32, Vec<u32>> = HashMap::new();
        for node in &self.nodes {
            if node.parent_index >= 0 {
                map.entry(node.parent_index as u32)
                    .or_default()
                    .push(node.index);
            }
        }
        map
    }
}

impl Default for CgtFile {
    fn default() -> Self {
        Self::new()
    }
}

/// A Crystarium entry representing a pattern instance.
///
/// Each entry places a geometric pattern at a specific position with
/// associated nodes belonging to a particular role and stage.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrystariumEntry {
    /// Entry index in the file.
    pub index: u32,

    /// Name of the MCP pattern to use (e.g., "test3", "test7").
    pub pattern_name: String,

    /// World position of the entry center.
    pub position: Vec3,

    /// Overall scale factor.
    pub scale: f32,

    /// Rotation quaternion (XYZ components).
    pub rotation: Vec3,

    /// Rotation quaternion W component.
    pub rotation_w: f32,

    /// Scale for individual nodes.
    pub node_scale: f32,

    /// Role ID (0=SYN, 1=COM, 2=RAV, 3=SAB, 4=SEN, 5=MED).
    pub role_id: u8,

    /// Stage number (1-10).
    pub stage: u8,

    /// Entry type (0=Hub with multiple nodes, 255=Leaf with single node).
    pub entry_type: u8,

    /// Reserved byte (usually 0).
    pub reserved: u8,

    /// Node IDs belonging to this entry.
    pub node_ids: Vec<u32>,

    /// Link position (for connecting to parent).
    pub link_position: Vec3,

    /// Link position W component.
    pub link_w: f32,
}

impl CrystariumEntry {
    /// Create a new empty entry.
    pub fn new(index: u32) -> Self {
        Self {
            index,
            pattern_name: String::new(),
            position: Vec3::zero(),
            scale: 1.0,
            rotation: Vec3::zero(),
            rotation_w: 0.0,
            node_scale: 10.0,
            role_id: 0,
            stage: 1,
            entry_type: 0,
            reserved: 0,
            node_ids: Vec::new(),
            link_position: Vec3::zero(),
            link_w: 0.0,
        }
    }

    /// Check if this is a leaf entry (single node).
    pub fn is_leaf(&self) -> bool {
        self.entry_type == 255 || self.node_ids.len() == 1
    }

    /// Get the first (center) node ID if any.
    pub fn center_node(&self) -> Option<u32> {
        self.node_ids.first().copied()
    }
}

/// A Crystarium node representing a single point in the tree.
///
/// Nodes form a tree structure via parent_index references.
/// The root node has parent_index = -1.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrystariumNode {
    /// Unique node index.
    pub index: u32,

    /// Node name (up to 16 characters, null-padded).
    /// Format: "cr_XXatYYZZZZ0000" where XX=char, YY=stage, ZZZZ=id.
    pub name: String,

    /// Parent node index (-1 for root node).
    pub parent_index: i32,

    /// Unknown fields (4 x u32, typically all zeros).
    pub unknown: [u32; 4],

    /// Scale values (4 x f32, typically all 1.0).
    pub scales: [f32; 4],
}

impl CrystariumNode {
    /// Create a new node with default values.
    pub fn new(index: u32, name: String, parent_index: i32) -> Self {
        Self {
            index,
            name,
            parent_index,
            unknown: [0; 4],
            scales: [1.0; 4],
        }
    }

    /// Check if this is the root node.
    pub fn is_root(&self) -> bool {
        self.parent_index < 0
    }

    /// Extract character code from the node name if it follows the standard format.
    pub fn character_code(&self) -> Option<&str> {
        if self.name.starts_with("cr_") && self.name.len() >= 5 {
            Some(&self.name[3..5])
        } else {
            None
        }
    }
}

// =============================================================================
// MCP Structures
// =============================================================================

/// File size constants for MCP format.
pub mod mcp_sizes {
    pub const HEADER_SIZE: usize = 16;
    pub const PATTERN_SIZE: usize = 272;
    pub const NAME_SIZE: usize = 16;
    pub const NODE_SIZE: usize = 16;  // Vec4
    pub const NODES_PER_PATTERN: usize = 16;
}

/// A complete MCP (Master Crystal Pattern) file.
///
/// MCP files define geometric patterns that CGT entries reference.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpFile {
    /// File version.
    pub version: u32,

    /// Number of patterns in the file.
    pub pattern_count: u32,

    /// Reserved field.
    pub reserved: u32,

    /// Patterns indexed by name for quick lookup.
    pub patterns: HashMap<String, McpPattern>,
}

impl McpFile {
    /// Create a new empty MCP file.
    pub fn new() -> Self {
        Self {
            version: 1,
            pattern_count: 0,
            reserved: 0,
            patterns: HashMap::new(),
        }
    }

    /// Get a pattern by name.
    pub fn get_pattern(&self, name: &str) -> Option<&McpPattern> {
        self.patterns.get(name)
    }

    /// Get all pattern names.
    pub fn pattern_names(&self) -> Vec<&str> {
        self.patterns.keys().map(|s| s.as_str()).collect()
    }
}

impl Default for McpFile {
    fn default() -> Self {
        Self::new()
    }
}

/// A geometric pattern used by Crystarium entries.
///
/// Patterns define relative node positions that get transformed
/// by the entry's position, rotation, and scale.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpPattern {
    /// Pattern name (e.g., "test3", "test7").
    pub name: String,

    /// Relative node positions (up to 16).
    pub nodes: Vec<Vec3>,

    /// Number of valid nodes in the pattern.
    pub count: usize,
}

impl McpPattern {
    /// Create a new pattern.
    pub fn new(name: String, nodes: Vec<Vec3>) -> Self {
        let count = nodes.len();
        Self { name, nodes, count }
    }
}
