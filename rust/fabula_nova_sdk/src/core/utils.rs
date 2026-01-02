//! # Utils Module
//!
//! This module provides common utility types and functions used throughout
//! the Fabula Nova SDK. These utilities are foundational and have no dependencies
//! on other SDK modules.
//!
//! ## Contents
//!
//! - [`GameCode`] - Enum identifying which Final Fantasy XIII game is being targeted
//! - [`remove_illegal_chars()`] - Sanitizes strings for use as filenames
//!
//! ## Game Version Support
//!
//! The SDK supports all three Final Fantasy XIII games:
//!
//! | GameCode | Game                                | Notes                        |
//! |----------|-------------------------------------|------------------------------|
//! | FF13_1   | Final Fantasy XIII                  | Original 2010 release        |
//! | FF13_2   | Final Fantasy XIII-2                | 2012 sequel                  |
//! | FF13_3   | Lightning Returns: Final Fantasy XIII | 2014 finale                 |
//!
//! Each game has slightly different file formats, compression dictionaries,
//! and data structures, which is why the game code is passed to most parsing
//! functions.

// =============================================================================
// Game Code Enumeration
// =============================================================================

/// Identifies which Final Fantasy XIII game the files belong to.
///
/// This enum is critical because each game in the XIII trilogy uses slightly
/// different file formats, compression schemes, and data layouts. Passing the
/// correct game code ensures files are parsed and written correctly.
///
/// # Derive Traits
/// - `Debug`, `Clone`, `Copy` - Standard utility traits
/// - `PartialEq`, `Eq`, `Hash` - Enables use as HashMap keys
/// - `Serialize`, `Deserialize` - JSON support for configuration files
///
/// # Usage
///
/// ```rust,ignore
/// use fabula_nova_sdk::core::utils::GameCode;
///
/// // Parse a WDB file from Final Fantasy XIII-2
/// let data = wdb::parse_wdb(&path, GameCode::FF13_2)?;
///
/// // The game code affects:
/// // - Field definitions in WDB files
/// // - Compression dictionaries in ZTR files
/// // - Encryption keys in CLB files
/// ```
///
/// # Version Differences
///
/// ## FF13_1 (Final Fantasy XIII)
/// - Original data structures
/// - Simpler WDB schemas
/// - Specific ZTR compression dictionaries
///
/// ## FF13_2 (Final Fantasy XIII-2)
/// - Extended WDB fields for time travel mechanics
/// - Crystarium growth system changes
/// - Different monster data structures
///
/// ## FF13_3 (Lightning Returns)
/// - Completely different combat system data
/// - New item and equipment schemas
/// - Real-time clock integration data
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum GameCode {
    /// Final Fantasy XIII (2010) - The original game featuring Lightning,
    /// Snow, Hope, Vanille, Sazh, and Fang on their journey through Cocoon
    /// and Gran Pulse. Uses the original Crystarium system.
    FF13_1,

    /// Final Fantasy XIII-2 (2012) - Sequel featuring Serah and Noel
    /// traveling through time. Introduces monster collection, Historia Crux,
    /// and paradox endings. Extended data structures for temporal mechanics.
    FF13_2,

    /// Lightning Returns: Final Fantasy XIII (2014) - Final chapter with
    /// Lightning as the sole protagonist. Features real-time clock system,
    /// action-oriented combat, and schema-based character customization.
    /// Also known as "XIII-3" or "LR".
    FF13_3,
}

// =============================================================================
// String Utilities
// =============================================================================

/// Removes characters that are illegal in Windows/Unix filenames.
///
/// This function filters out characters that cannot be used in file paths
/// on Windows or would cause issues on Unix systems. Use this when creating
/// output filenames from game data (e.g., NPC names, item names).
///
/// # Illegal Characters Removed
///
/// | Char | Name           | Why Illegal                    |
/// |------|----------------|--------------------------------|
/// | `\`  | Backslash      | Path separator (Windows)       |
/// | `/`  | Forward slash  | Path separator (Unix/Windows)  |
/// | `:`  | Colon          | Drive separator (Windows)      |
/// | `*`  | Asterisk       | Wildcard (shells)              |
/// | `?`  | Question mark  | Wildcard (shells)              |
/// | `"`  | Double quote   | Path quoting (Windows)         |
/// | `<`  | Less than      | Redirection (shells)           |
/// | `>`  | Greater than   | Redirection (shells)           |
/// | `\|` | Pipe           | Command piping (shells)        |
///
/// # Arguments
/// * `input` - The string to sanitize
///
/// # Returns
/// A new `String` with all illegal characters removed.
///
/// # Examples
///
/// ```rust,ignore
/// use fabula_nova_sdk::core::utils::remove_illegal_chars;
///
/// // Remove path separators
/// assert_eq!(remove_illegal_chars("Hello/World:"), "HelloWorld");
///
/// // Clean string passes through unchanged
/// assert_eq!(remove_illegal_chars("CleanString"), "CleanString");
///
/// // All illegal chars removed
/// assert_eq!(remove_illegal_chars("<>|*?\""), "");
///
/// // Real-world example: NPC dialogue ID
/// assert_eq!(
///     remove_illegal_chars("npc_001/greeting:01"),
///     "npc_001greeting01"
/// );
/// ```
///
/// # Note
/// This function only removes characters, it does not replace them.
/// If you need to preserve word boundaries, consider replacing with
/// underscores instead.
pub fn remove_illegal_chars(input: &str) -> String {
    // Characters that are illegal in Windows filenames or problematic in shells
    let illegal_chars = ['\\', '/', ':', '*', '?', '"', '<', '>', '|'];

    input
        .chars()
        .filter(|c| !illegal_chars.contains(c))
        .collect()
}

// =============================================================================
// Unit Tests
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    /// Tests that illegal characters are properly removed from strings.
    #[test]
    fn test_remove_illegal_chars() {
        // Path separators are removed
        assert_eq!(remove_illegal_chars("Hello/World:"), "HelloWorld");

        // Clean strings pass through unchanged
        assert_eq!(remove_illegal_chars("CleanString"), "CleanString");

        // All illegal chars are removed
        assert_eq!(remove_illegal_chars("<>|*?\""), "");

        // Empty string handling
        assert_eq!(remove_illegal_chars(""), "");

        // Mixed content
        assert_eq!(
            remove_illegal_chars("file:name/with*illegal?chars"),
            "filenamewithillegalchars"
        );
    }
}
