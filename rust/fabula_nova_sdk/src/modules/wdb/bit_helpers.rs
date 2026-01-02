//! # Bit Manipulation Helpers
//!
//! This module provides utilities for reading and writing bitpacked data
//! in WDB files. WDB uses a custom bitpacking scheme where multiple
//! fields are packed into 32-bit words.
//!
//! ## Bitpacking Format
//!
//! Fields are packed LSB-first within a 32-bit word. For example,
//! a 4-bit field followed by a 12-bit field would occupy bits 0-3
//! and 4-15 respectively.
//!
//! ## Field Naming Convention
//!
//! Field names encode type and bit width:
//! - `u4Role` → unsigned, 4 bits
//! - `i16Value` → signed, 16 bits
//! - `s8Index` → string array index, 8 bits
//! - `fFloat` → full 32-bit float (type 1)

/// Reads bits from a 32-bit value in LSB-first order.
///
/// Maintains state about which bits have been consumed.
pub struct BitReader {
    /// The source 32-bit value
    pub value: u32,
    /// Number of bits not yet consumed
    pub bits_remaining: usize,
}

impl BitReader {
    /// Creates a new BitReader for the given 32-bit value.
    pub fn new(value: u32) -> Self {
        Self {
            value,
            bits_remaining: 32,
        }
    }

    /// Reads `count` bits from the current position.
    ///
    /// Returns `None` if not enough bits remain.
    /// Bits are read LSB-first (lowest bits consumed first).
    pub fn read_bits(&mut self, count: usize) -> Option<u32> {
        if count == 0 {
            return Some(0);
        }
        if count > self.bits_remaining {
            return None;
        }

        let _shift = self.bits_remaining - count;
        let mask = if count == 32 { !0 } else { (1 << count) - 1 };
        
        let consumed = 32 - self.bits_remaining;
        let val = (self.value >> consumed) & mask;
        self.bits_remaining -= count;
        
        Some(val)
    }
}

/// Writes bits to a 32-bit value in LSB-first order.
///
/// Used for encoding bitpacked fields during WDB serialization.
pub struct BitWriter {
    /// The accumulated 32-bit value
    pub value: u32,
    /// Number of bits written so far
    pub bits_consumed: usize,
}

impl Default for BitWriter {
    fn default() -> Self {
        Self::new()
    }
}

impl BitWriter {
    /// Creates a new BitWriter with zero value.
    pub fn new() -> Self {
        Self {
            value: 0,
            bits_consumed: 0,
        }
    }

    /// Writes `count` bits of `val` to the output.
    ///
    /// Values are masked to the specified width and shifted
    /// to the next available bit position.
    pub fn write_bits(&mut self, val: u32, count: usize) {
        if count == 0 || count > 32 { return; }
        
        let mask = if count == 32 { !0 } else { (1 << count) - 1 };
        let masked_val = val & mask;
        
        // Write to lowest available bits (LSB packing)
        self.value |= masked_val << self.bits_consumed;
        self.bits_consumed += count;
    }
}

/// Extracts the bit width from a field name.
///
/// Field names follow the pattern `[type][width][name]`:
/// - `u4Role` → 4
/// - `i16Value` → 16
/// - `s8Category` → 8
/// - `fFloat` → 0 (full 32 bits)
///
/// # Returns
///
/// The numeric width, or 0 if no width is specified.
pub fn derive_field_number(field_name: &str) -> usize {
    let chars: Vec<char> = field_name.chars().collect();
    if chars.len() < 2 { return 0; }
    
    let mut num_str = String::new();
    if chars[1].is_ascii_digit() {
        num_str.push(chars[1]);
        if chars.len() > 2 && chars[2].is_ascii_digit() {
            num_str.push(chars[2]);
        }
    }
    
    num_str.parse().unwrap_or(0)
}

/// Sign-extends a value from `bits` width to 32 bits.
///
/// Used when reading signed bitpacked fields (i-prefix).
/// The value is shifted left to place the sign bit at bit 31,
/// then arithmetically shifted right to propagate the sign.
///
/// # Example
///
/// ```rust,ignore
/// // 4-bit value 0b1111 (-1 in 4-bit signed) → -1 as i32
/// assert_eq!(sign_extend(0xF, 4), -1);
/// ```
pub fn sign_extend(val: u32, bits: usize) -> i32 {
    if bits == 0 || bits >= 32 {
        return val as i32;
    }
    let shift = 32 - bits;
    ((val << shift) as i32) >> shift
}