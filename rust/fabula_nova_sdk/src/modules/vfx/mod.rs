//! # VFX Module - Visual Effects Handler
//!
//! This module handles VFX (Visual Effects) files (`.xfv`) from the FF13 trilogy.
//! XFV files are WPD containers containing particle effects, 3D meshes, textures,
//! and animation data.
//!
//! ## File Format
//!
//! XFV files use the WPD container format with these record types:
//!
//! | Extension | SEDB Type | Description |
//! |-----------|-----------|-------------|
//! | `vtex` | SEDBvtex | Texture references (GTEX headers) |
//! | `vanm` | SEDBvanm | Vertex animations |
//! | `vmdl` | SEDBvmdl | 3D mesh models with materials |
//! | `veff` | SEDBveff | Effect definitions |
//!
//! ## Record Naming
//!
//! Records use hash-based names with `v` prefix:
//! - `v04fdfc11828acd` → texture
//! - `v089726d05112b5` → animation
//! - `v8691516e1274cb` → model
//! - `ev_loc_thanks` → effect definition (human-readable)
//!
//! ## Usage
//!
//! ```rust,ignore
//! use fabula_nova_sdk::modules::vfx;
//!
//! // Parse VFX file
//! let vfx_data = vfx::parse_vfx("effects.xfv")?;
//!
//! // List effects
//! for effect in &vfx_data.effects {
//!     println!("Effect: {}", effect.name);
//! }
//! ```
//!
//! ## Shader Handling
//!
//! The vmdl records contain compiled D3D9 shaders (ps_3_0) which cannot be
//! directly executed in Flutter. The module extracts material properties
//! (colors, blend modes) for cross-platform rendering instead.

pub mod structs;
pub mod reader;
pub mod api;
pub mod renderer;

// Re-export public items
pub use structs::*;
pub use reader::*;
pub use api::*;
pub use renderer::{VfxPlayer, AnimationState, LoadedModel};

#[cfg(test)]
mod tests {
    use std::path::PathBuf;
    use super::api::parse_vfx;

    #[test]
    fn test_parse_vfx_sample() {
        // Try project root ai_resources first
        let mut path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        path.pop(); // Go up from fabula_nova_sdk
        path.pop(); // Go up from rust
        path.push("ai_resources/vfx/event/ev_comn_055/veffs.us.win32.xfv");

        if !path.exists() {
            eprintln!("Test file not found: {:?}", path);
            return;
        }

        let result = parse_vfx(&path);
        assert!(result.is_ok(), "Failed to parse VFX: {:?}", result.err());

        let vfx = result.unwrap();
        println!("VFX parsed successfully!");
        println!("  Textures: {}", vfx.textures.len());
        println!("  Models: {}", vfx.models.len());
        println!("  Animations: {}", vfx.animations.len());
        println!("  Effects: {}", vfx.effects.len());

        // Print texture details
        for tex in &vfx.textures {
            println!("  - Texture: {} ({}x{}, {})",
                tex.name, tex.width, tex.height, tex.format_name);
        }

        // Print effect details
        for eff in &vfx.effects {
            println!("  - Effect: {} ({} controllers)",
                eff.name, eff.controller_paths.len());
        }

        assert!(vfx.textures.len() > 0, "Should have textures");
    }
}

#[cfg(test)]
mod action_effect_tests {
    use std::path::PathBuf;
    use std::collections::HashSet;
    use super::api::parse_vfx;

    #[test]
    fn test_match_action_effects() {
        // Effect hashes from ActionEffect.json (sample)
        let action_hashes: HashSet<&str> = [
            "v00b1e74a3ee84b", "v03e4716a1b2d19", "v070bc769db4fc7",
            "v0736c14e03a4c1", "v07e451622eb417", "v085012b64dcb26",
        ].into_iter().collect();

        let mut base = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        base.pop(); base.pop();
        base.push("ai_resources/vfx/menu/resident/resident/veffs.us.win32.xfv");

        if !base.exists() { return; }
        let vfx = parse_vfx(&base).unwrap();

        println!("\n=== Checking hash matches ===");
        
        // Check textures
        for tex in &vfx.textures {
            if action_hashes.contains(tex.name.as_str()) {
                println!("TEXTURE match: {}", tex.name);
            }
        }
        
        // Check models
        for model in &vfx.models {
            if action_hashes.contains(model.name.as_str()) {
                println!("MODEL match: {}", model.name);
            }
        }
        
        // Check effects
        for eff in &vfx.effects {
            if action_hashes.contains(eff.name.as_str()) {
                println!("EFFECT match: {} (controllers: {:?})", eff.name, eff.controller_paths);
            }
        }
        
        println!("VFX has {} textures, {} models, {} effects", 
            vfx.textures.len(), vfx.models.len(), vfx.effects.len());
    }
}
