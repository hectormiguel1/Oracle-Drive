//! # IMG Module - Image Data Handler
//!
//! This module handles IMGB (Image Binary) files, which contain texture data
//! for the Final Fantasy XIII games. IMGB files are paired with header files
//! (XGR/TXBH) that describe the image format.
//!
//! ## File Pair Structure
//!
//! Image data is split across two files:
//! 1. **Header File** (`.xgr`, `.txbh`, `.trb`) - Image metadata
//! 2. **Image File** (`.imgb`) - Raw pixel data
//!
//! ```text
//! Header File (.txbh):
//! ┌─────────────────────────────────────────────────────────────┐
//! │ Texture Header                                               │
//! │   - Width, Height                                            │
//! │   - Format (DXT1, DXT5, etc.)                                │
//! │   - Mipmap count                                             │
//! │   - Offset into IMGB                                         │
//! └─────────────────────────────────────────────────────────────┘
//!
//! Image File (.imgb):
//! ┌─────────────────────────────────────────────────────────────┐
//! │ Raw pixel data in specified format                           │
//! │ (Multiple images concatenated)                               │
//! └─────────────────────────────────────────────────────────────┘
//! ```
//!
//! ## DDS Conversion
//!
//! Images are extracted as DDS (DirectDraw Surface) files, which can be
//! edited with standard image tools and then repacked.
//!
//! ## Submodules
//!
//! - [`structs`] - Image data structures
//! - [`reader`] - Binary image parser
//! - [`writer`] - Binary image generator
//! - [`api`] - High-level public API
//!
//! ## Usage Example
//!
//! ```rust,ignore
//! use fabula_nova_sdk::modules::img;
//!
//! // Extract to DDS
//! img::extract_img_to_dds("texture.txbh", "data.imgb", "texture.dds")?;
//!
//! // Repack DDS back (strict mode - must match original size)
//! img::repack_img_strict("texture.txbh", "data.imgb", "modified.dds")?;
//! ```

pub mod structs;
pub mod reader;
pub mod writer;
pub mod api;

// Re-export all public items
pub use structs::*;
pub use reader::*;
pub use writer::*;
pub use api::*;

#[cfg(test)]
mod tests {
    use std::path::PathBuf;
    use super::api::{extract_img_to_dds, repack_img_strict};

    #[test]
    fn test_img_roundtrip() {
        let mut xgr_path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        xgr_path.push("ai_resources/WPD.Lib/example_files/crystal.win32.xgr");
        
        let mut imgb_path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        imgb_path.push("ai_resources/WPD.Lib/example_files/crystal.win32.imgb");

        let mut out_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        out_dir.push("target/test_img_setup_dir");
        
        if !xgr_path.exists() || !imgb_path.exists() {
            return;
        }

        if out_dir.exists() {
            let _ = std::fs::remove_dir_all(&out_dir);
        }
        std::fs::create_dir_all(&out_dir).unwrap();

        // 0. Setup: Unpack WPD (XGR) to get the .txbh header
        crate::modules::wpd::api::unpack_wpd(&xgr_path, &out_dir).unwrap();
        
        let header_path = out_dir.join("cs_line00.txbh");
        assert!(header_path.exists(), "Setup failed: cs_line00.txbh not found in unpacked XGR");
        
        let mut dds_path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        dds_path.push("target/test_cs_line00.dds");
        
        let mut imgb_repack_path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        imgb_repack_path.push("target/test_cs_line00_repacked.imgb");

        // 1. Extract
        extract_img_to_dds(&header_path, &imgb_path, &dds_path).unwrap();
        assert!(dds_path.exists());

        // 2. Repack
        // We'll copy the original IMGB to a temp file then overwrite it during repack
        std::fs::copy(&imgb_path, &imgb_repack_path).unwrap();
        repack_img_strict(&header_path, &imgb_repack_path, &dds_path).unwrap();
        
        assert!(imgb_repack_path.exists());
        // In strict mode, if we didn't change DDS, IMGB should remain same size.
        assert_eq!(
            std::fs::metadata(&imgb_path).unwrap().len(),
            std::fs::metadata(&imgb_repack_path).unwrap().len()
        );
    }
}
