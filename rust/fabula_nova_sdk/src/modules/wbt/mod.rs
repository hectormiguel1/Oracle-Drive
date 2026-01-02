//! # WBT Module - WhiteBin Archive Handler
//!
//! This module handles WBT (WhiteBin Archive) files, which are the primary
//! container format for game resources in Final Fantasy XIII. WBT archives
//! can contain thousands of files including textures, models, scripts, and data.
//!
//! ## Archive Structure
//!
//! WBT archives consist of two parts:
//! 1. **Filelist** (`.bin` file) - Encrypted index of all files in the archive
//! 2. **Container** (`.bin/.white_img` file) - Compressed file data
//!
//! ```text
//! ┌─────────────────────────────────────────────────────────────┐
//! │                      Filelist Structure                      │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Encrypted metadata containing:                               │
//! │   - File paths (relative to game root)                       │
//! │   - Offsets into container file                              │
//! │   - Compressed and uncompressed sizes                        │
//! └─────────────────────────────────────────────────────────────┘
//!
//! ┌─────────────────────────────────────────────────────────────┐
//! │                    Container Structure                       │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Compressed file data (ZLIB)                                  │
//! │ Files stored at offsets specified in filelist                │
//! └─────────────────────────────────────────────────────────────┘
//! ```
//!
//! ## Submodules
//!
//! - [`filelist`] - Parses encrypted filelist index
//! - [`container`] - Handles file extraction from container
//! - [`repack`] - Repacks modified files into archives
//! - [`api`] - High-level public API functions
//! - [`crypto`] - Filelist encryption/decryption
//!
//! ## Usage Example
//!
//! ```rust,ignore
//! use fabula_nova_sdk::modules::wbt;
//!
//! // Extract entire archive
//! wbt::extract_wbt("white_img.bin", "filelist.bin", "output_dir/")?;
//!
//! // Extract single file
//! wbt::wbt_extract_single_file("white_img.bin", "filelist.bin", "db/item.wdb", "item.wdb")?;
//!
//! // Repack with modifications
//! wbt::repack_wbt_single("white_img.bin", "filelist.bin", "db/item.wdb", "item_modified.wdb")?;
//! ```

pub mod filelist;
pub mod container;
pub mod repack;
pub mod api;
pub mod crypto;
mod tests;

// Re-export main types
pub use filelist::{Filelist, WbtError, WbtFileMetadata};
pub use container::WbtContainer;
pub use repack::WbtRepacker;
