//! # WDB Game Enumerations
//!
//! This module defines strongly-typed enums for WDB field values.
//! These replace raw integer values with meaningful names for
//! better modding ergonomics.
//!
//! ## Crystarium System (FF13)
//!
//! The Crystarium is the character progression system in FF13.
//! Each character has six roles (jobs) arranged on a crystal grid.
//!
//! ### Roles
//!
//! - **Commando (Attacker)**: Physical damage dealer
//! - **Ravager (Blaster)**: Builds stagger gauge
//! - **Sentinel (Defender)**: Tank, draws enemy attacks
//! - **Synergist (Enhancer)**: Buffs party members
//! - **Saboteur (Jammer)**: Debuffs enemies
//! - **Medic (Healer)**: Heals party members
//!
//! ### Node Types
//!
//! Crystal nodes provide various bonuses when unlocked:
//! - HP, Strength, Magic stat increases
//! - New abilities
//! - ATB segment extensions
//! - Accessory slot unlocks

use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};

/// Crystal role enum (u4Role field in crystal.wdb).
///
/// Each node in the Crystarium belongs to one of six roles.
/// This determines which role level increases when unlocking nodes.
///
/// # Values
///
/// | Value | Role      | Japanese | Description              |
/// |-------|-----------|----------|--------------------------|
/// | 0     | None      | -        | Not assigned to a role   |
/// | 1     | Defender  | 聖騎士   | Sentinel                 |
/// | 2     | Attacker  | アタッカー | Commando               |
/// | 3     | Blaster   | ブラスター | Ravager                |
/// | 4     | Enhancer  | エンハンサー | Synergist            |
/// | 5     | Jammer    | ジャマー | Saboteur                 |
/// | 6     | Healer    | ヒーラー | Medic                    |
#[frb]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[repr(u8)]
pub enum CrystalRole {
    #[default]
    None = 0,
    Defender = 1,
    Attacker = 2,
    Blaster = 3,
    Enhancer = 4,
    Jammer = 5,
    Healer = 6,
}

/// Crystal node type enum (u8NodeType field in crystal.wdb).
///
/// Defines what bonus a Crystarium node provides when unlocked.
/// The `u16NodeVal` field specifies the magnitude of the bonus.
///
/// # Values
///
/// | Value | Type       | NodeVal Meaning                    |
/// |-------|------------|-----------------------------------|
/// | 0     | None       | -                                 |
/// | 1     | Hp         | HP increase amount                |
/// | 2     | Strength   | Strength stat increase            |
/// | 3     | Magic      | Magic stat increase               |
/// | 4     | Accessory  | Accessory slot index              |
/// | 5     | AtbSegment | ATB gauge segment unlock          |
/// | 6     | Ability    | Ability ID reference              |
/// | 7     | Role       | Role level unlock                 |
#[frb]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[repr(u8)]
pub enum CrystalNodeType {
    #[default]
    None = 0,
    Hp = 1,
    Strength = 2,
    Magic = 3,
    Accessory = 4,
    AtbSegment = 5,
    Ability = 6,
    Role = 7,
}

impl CrystalRole {
    /// Convert raw integer value to CrystalRole enum
    pub fn from_u32(v: u32) -> Self {
        match v {
            1 => Self::Defender,
            2 => Self::Attacker,
            3 => Self::Blaster,
            4 => Self::Enhancer,
            5 => Self::Jammer,
            6 => Self::Healer,
            _ => Self::None,
        }
    }

    /// Convert to integer representation
    pub fn to_u32(self) -> u32 {
        self as u32
    }
}

impl CrystalNodeType {
    /// Convert raw integer value to CrystalNodeType enum
    pub fn from_u32(v: u32) -> Self {
        match v {
            1 => Self::Hp,
            2 => Self::Strength,
            3 => Self::Magic,
            4 => Self::Accessory,
            5 => Self::AtbSegment,
            6 => Self::Ability,
            7 => Self::Role,
            _ => Self::None,
        }
    }

    /// Convert to integer representation
    pub fn to_u32(self) -> u32 {
        self as u32
    }
}

impl From<u32> for CrystalRole {
    fn from(v: u32) -> Self {
        Self::from_u32(v)
    }
}

impl From<CrystalRole> for u32 {
    fn from(v: CrystalRole) -> Self {
        v.to_u32()
    }
}

impl From<u32> for CrystalNodeType {
    fn from(v: u32) -> Self {
        Self::from_u32(v)
    }
}

impl From<CrystalNodeType> for u32 {
    fn from(v: CrystalNodeType) -> Self {
        v.to_u32()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_crystal_role_from_u32() {
        assert_eq!(CrystalRole::from_u32(0), CrystalRole::None);
        assert_eq!(CrystalRole::from_u32(1), CrystalRole::Defender);
        assert_eq!(CrystalRole::from_u32(2), CrystalRole::Attacker);
        assert_eq!(CrystalRole::from_u32(3), CrystalRole::Blaster);
        assert_eq!(CrystalRole::from_u32(4), CrystalRole::Enhancer);
        assert_eq!(CrystalRole::from_u32(5), CrystalRole::Jammer);
        assert_eq!(CrystalRole::from_u32(6), CrystalRole::Healer);
        assert_eq!(CrystalRole::from_u32(99), CrystalRole::None); // Unknown maps to None
    }

    #[test]
    fn test_crystal_node_type_from_u32() {
        assert_eq!(CrystalNodeType::from_u32(0), CrystalNodeType::None);
        assert_eq!(CrystalNodeType::from_u32(1), CrystalNodeType::Hp);
        assert_eq!(CrystalNodeType::from_u32(2), CrystalNodeType::Strength);
        assert_eq!(CrystalNodeType::from_u32(3), CrystalNodeType::Magic);
        assert_eq!(CrystalNodeType::from_u32(4), CrystalNodeType::Accessory);
        assert_eq!(CrystalNodeType::from_u32(5), CrystalNodeType::AtbSegment);
        assert_eq!(CrystalNodeType::from_u32(6), CrystalNodeType::Ability);
        assert_eq!(CrystalNodeType::from_u32(7), CrystalNodeType::Role);
        assert_eq!(CrystalNodeType::from_u32(99), CrystalNodeType::None);
    }

    #[test]
    fn test_crystal_role_roundtrip() {
        for v in 0..=6 {
            let role = CrystalRole::from_u32(v);
            assert_eq!(role.to_u32(), v);
        }
    }

    #[test]
    fn test_crystal_node_type_roundtrip() {
        for v in 0..=7 {
            let node_type = CrystalNodeType::from_u32(v);
            assert_eq!(node_type.to_u32(), v);
        }
    }
}
