//! # Crystalium Module - CGT/MCP File Handler
//!
//! This module handles CGT (Crystal Graph Tree) and MCP (Master Crystal Pattern) files
//! used by the Final Fantasy XIII Crystarium system.
//!
//! ## CGT File Format Overview
//!
//! CGT files define character-specific Crystarium layouts including:
//! - Entry positions and rotations (quaternion)
//! - Node IDs and parent connections
//! - Stage and role assignments
//!
//! ```text
//! ┌─────────────────────────────────────────────────────────────┐
//! │                      CGT File Structure                      │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Header (16 bytes)                                            │
//! │   - version: u32                                             │
//! │   - entry_count: u32                                         │
//! │   - total_nodes: u32                                         │
//! │   - reserved: u32                                            │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Entries (136 bytes each)                                     │
//! │   - pattern_name: 16 bytes (null-terminated ASCII)           │
//! │   - position: Vec3 (3x f32)                                  │
//! │   - scale: f32                                               │
//! │   - rotation: Vec4 (quaternion XYZW)                         │
//! │   - node_scale: f32                                          │
//! │   - flags: role_id u8, stage u8, entry_type u8, reserved u8  │
//! │   - node_ids: 16x u32                                        │
//! │   - link_position: Vec4 (XYZW)                               │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Nodes (52 bytes each)                                        │
//! │   - name: 16 bytes (null-terminated ASCII)                   │
//! │   - parent_index: i32 (signed, -1 for root)                  │
//! │   - unknown: 4x u32                                          │
//! │   - scales: 4x f32                                           │
//! └─────────────────────────────────────────────────────────────┘
//! ```
//!
//! ## MCP File Format Overview
//!
//! MCP files define geometric patterns used by the Crystarium system.
//!
//! ```text
//! ┌─────────────────────────────────────────────────────────────┐
//! │                      MCP File Structure                      │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Header (16 bytes)                                            │
//! │   - version: u32                                             │
//! │   - pattern_count: u32                                       │
//! │   - reserved: 8 bytes                                        │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Patterns (272 bytes each)                                    │
//! │   - name: 16 bytes (null-terminated ASCII)                   │
//! │   - nodes: 16 slots × Vec4 (W=1.0 marks valid node)          │
//! └─────────────────────────────────────────────────────────────┘
//! ```
//!
//! ## Byte Order
//!
//! Both CGT and MCP files use **Big Endian** byte order.
//!
//! ## Submodules
//!
//! - [`structs`] - Data structures for CGT/MCP files
//! - [`reader`] - CGT binary parser
//! - [`writer`] - CGT binary generator
//! - [`mcp_reader`] - MCP binary parser
//! - [`api`] - High-level public API functions
//!
//! ## Usage Example
//!
//! ```rust,ignore
//! use fabula_nova_sdk::modules::crystalium;
//!
//! // Parse a CGT file
//! let cgt = crystalium::parse_cgt("lightning.cgt")?;
//!
//! // Access entries and nodes
//! for entry in &cgt.entries {
//!     println!("Entry: {} at stage {}", entry.pattern_name, entry.stage);
//! }
//!
//! // Parse an MCP file
//! let mcp = crystalium::parse_mcp("patterns.mcp")?;
//!
//! // Access patterns
//! if let Some(pattern) = mcp.get_pattern("test3") {
//!     println!("Pattern {} has {} nodes", pattern.name, pattern.count);
//! }
//!
//! // Write CGT file
//! crystalium::write_cgt(&cgt, "modified.cgt")?;
//! ```

pub mod structs;
pub mod reader;
pub mod writer;
pub mod mcp_reader;
pub mod api;

// Re-export all public items
pub use structs::*;
pub use reader::*;
pub use writer::*;
pub use mcp_reader::*;
pub use api::*;
