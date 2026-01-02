//! # WDB Enum Field Registry
//!
//! This module provides a registry mapping WDB field names to their
//! corresponding enum types. When parsing WDB files, certain integer
//! fields should be converted to strongly-typed enums for better
//! usability.
//!
//! ## How It Works
//!
//! 1. During parsing, [`get_enum_type`] checks if a field should be an enum
//! 2. If matched, [`int_to_enum_value`] converts the raw integer to a [`WdbValue`] variant
//! 3. The enum variant is serialized as a named string in JSON output
//!
//! ## Extensibility
//!
//! To add new enum mappings:
//! 1. Define the enum in [`super::enums`]
//! 2. Add a variant to [`EnumType`]
//! 3. Register the (sheet_name, field_name) → EnumType mapping in [`ENUM_FIELDS`]
//! 4. Handle the conversion in [`int_to_enum_value`]

use super::enums::{CrystalNodeType, CrystalRole};
use super::structs::WdbValue;
use once_cell::sync::Lazy;
use std::collections::HashMap;

/// Identifies which enum type a field should be converted to.
///
/// Add new variants here as more WDB enum fields are discovered.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EnumType {
    CrystalRole,
    CrystalNodeType,
    // Add more enum types here as needed
}

/// Registry mapping (sheet_name, field_name) → EnumType.
///
/// This static registry tells the parser which integer fields should
/// be converted to typed enums during parsing.
///
/// Both lowercase and capitalized sheet names are registered to handle
/// variations in WDB file naming.
pub static ENUM_FIELDS: Lazy<HashMap<(&'static str, &'static str), EnumType>> = Lazy::new(|| {
    let mut m = HashMap::new();

    // Crystal sheet (Crystarium progression data)
    m.insert(("crystal", "u4Role"), EnumType::CrystalRole);
    m.insert(("crystal", "u8NodeType"), EnumType::CrystalNodeType);

    // Also support capitalized variants (WDB names can vary)
    m.insert(("Crystal", "u4Role"), EnumType::CrystalRole);
    m.insert(("Crystal", "u8NodeType"), EnumType::CrystalNodeType);

    // Add more enum fields here as discovered in other WDB sheets
    // Example:
    // m.insert(("BattleAbility", "uElementType"), EnumType::ElementType);

    m
});

/// Converts a raw integer to the appropriate enum WdbValue variant.
///
/// # Arguments
///
/// * `enum_type` - The target enum type from the registry
/// * `raw` - The raw integer value from the WDB file
///
/// # Returns
///
/// A WdbValue variant containing the typed enum.
pub fn int_to_enum_value(enum_type: EnumType, raw: u32) -> WdbValue {
    match enum_type {
        EnumType::CrystalRole => WdbValue::CrystalRole(CrystalRole::from_u32(raw)),
        EnumType::CrystalNodeType => WdbValue::CrystalNodeType(CrystalNodeType::from_u32(raw)),
    }
}

/// Looks up whether a field should be converted to an enum.
///
/// Performs case-insensitive matching on the sheet name to handle
/// variations in WDB file naming conventions.
///
/// # Arguments
///
/// * `sheet_name` - The WDB record type (from `!structitem` or filename)
/// * `field_name` - The field name being parsed
///
/// # Returns
///
/// `Some(EnumType)` if the field should be an enum, `None` otherwise.
pub fn get_enum_type(sheet_name: &str, field_name: &str) -> Option<EnumType> {
    log::debug!(
        "Looking up enum type for sheet: '{}', field: '{}'",
        sheet_name,
        field_name
    );
    let res = ENUM_FIELDS
        .get(&(sheet_name, field_name))
        .copied()
        .or_else(|| {
            // Try lowercase sheet name as fallback
            let lower_sheet = sheet_name.to_lowercase();
            ENUM_FIELDS
                .iter()
                .find(|((s, f), _)| s.to_lowercase() == lower_sheet && *f == field_name)
                .map(|(_, et)| *et)
        });

    if let Some(enum_type) = res {
        log::debug!("Found enum type: {:?}", enum_type);
    } else {
        log::debug!("No enum type found for given sheet and field.");
    }
    res
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_enum_registry_lookup() {
        assert_eq!(
            get_enum_type("crystal", "u4Role"),
            Some(EnumType::CrystalRole)
        );
        assert_eq!(
            get_enum_type("Crystal", "u4Role"),
            Some(EnumType::CrystalRole)
        );
        assert_eq!(
            get_enum_type("crystal", "u8NodeType"),
            Some(EnumType::CrystalNodeType)
        );
        assert_eq!(get_enum_type("crystal", "unknown"), None);
        assert_eq!(get_enum_type("unknown_sheet", "u4Role"), None);
    }

    #[test]
    fn test_int_to_enum_value() {
        let val = int_to_enum_value(EnumType::CrystalRole, 2);
        assert_eq!(val, WdbValue::CrystalRole(CrystalRole::Attacker));

        let val = int_to_enum_value(EnumType::CrystalNodeType, 6);
        assert_eq!(val, WdbValue::CrystalNodeType(CrystalNodeType::Ability));
    }
}
