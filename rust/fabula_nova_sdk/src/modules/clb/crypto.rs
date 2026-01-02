//! # CLB Cryptographic Primitives
//!
//! This module implements the encryption algorithm used for CLB files in FF13.
//!
//! ## Encryption Overview
//!
//! CLB uses a custom block cipher with these components:
//!
//! 1. **XOR Table Generation**: 264-byte lookup table from 8-byte seed
//! 2. **Block Cipher**: 8-byte blocks with XOR, rotation, and special keys
//! 3. **Byte Transformation**: Uses INTEGERS lookup table for obfuscation
//!
//! ## XOR Table Generation
//!
//! ```text
//! Seed (8 bytes)
//!     │
//!     ▼ reverse, rotate halves
//! Initial XOR Block (8 bytes)
//!     │
//!     ▼ iterative transformation
//! XOR Table (264 bytes = 33 × 8)
//! ```
//!
//! ## Block Cipher Flow
//!
//! Each 8-byte block is processed with:
//! 1. XOR with block ID and previous byte (chaining)
//! 2. Byte transformation via INTEGERS table
//! 3. Byte rearrangement (swap halves)
//! 4. XOR with table values and special keys
//! 5. Arithmetic operations with carry flags
//!
//! ## The INTEGERS Table
//!
//! A substitution table mapping 0-255 → rotated values starting at 120.
//! Provides a bijective mapping used for byte obfuscation.

/// Substitution table for byte transformation.
///
/// This table provides a rotated mapping: INTEGERS[i] = (i + 120) mod 256.
/// Used in `loop_a_byte` and `loop_a_byte_reverse` for encryption/decryption.
///
/// ```text
/// Index:  0   1   2   ... 135 136 137 ... 255
/// Value: 120 121 122 ... 255   0   1 ... 119
/// ```
pub const INTEGERS: [u8; 256] = [
    120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138,
    139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157,
    158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176,
    177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195,
    196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214,
    215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233,
    234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252,
    253, 254, 255, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
    23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46,
    47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70,
    71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94,
    95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114,
    115, 116, 117, 118, 119,
];

/// Generates the 264-byte XOR table from an 8-byte seed.
///
/// This table is used for all subsequent encryption/decryption operations.
/// The same seed always produces the same table, enabling deterministic
/// encryption.
///
/// # Algorithm
///
/// 1. **Seed Preparation**:
///    - Reverse byte order of seed
///    - Split into two 32-bit halves
///    - Rotate halves (left 8 for A, swap words for B)
///    - Recombine and add 0x45 to first byte
///
/// 2. **Initial Block Derivation** (Loop 1):
///    - For each byte 1-7: XOR with magic values (0xD4, 0x45)
///    - Chain with previous byte (add + left-shift XOR)
///
/// 3. **Table Expansion** (Loop 2):
///    - Generate 32 additional 8-byte blocks
///    - Each block derived from previous via multiply-XOR operations
///    - Total: 33 blocks × 8 bytes = 264 bytes
///
/// # Arguments
///
/// * `seed` - 8-byte seed from the CLB file header
///
/// # Returns
///
/// 264-byte XOR table for encryption operations.
pub fn generate_xor_table(mut seed: [u8; 8]) -> [u8; 264] {
    let mut xor_table = [0u8; 264];

    // Step 1: Prepare seed - reverse and rotate halves
    seed.reverse();

    let seed_half_a = u32::from_le_bytes([seed[0], seed[1], seed[2], seed[3]]);
    let seed_half_b = u32::from_le_bytes([seed[4], seed[5], seed[6], seed[7]]);

    // Rotate: left 8 for A, word swap for B
    let seed_half_a = (seed_half_a << 8) | (seed_half_a >> 24);
    let seed_half_b = (seed_half_b >> 16) | (seed_half_b << 16);

    // Recombine halves (swapped order) and add magic to first byte
    let mut xor_block = [0u8; 8];
    xor_block[0..4].copy_from_slice(&seed_half_b.to_le_bytes());
    xor_block[4..8].copy_from_slice(&seed_half_a.to_le_bytes());
    xor_block[0] = xor_block[0].wrapping_add(0x45);

    // Loop 1: Derive initial block with chained XOR operations
    for i in 1..8 {
        let tmp = (xor_block[i] as i32) + 0xD4 + (xor_block[i - 1] as i32);
        let mut tmp = tmp ^ ((xor_block[i - 1] as i32) << 2);
        tmp ^= 0x45;
        xor_block[i] = tmp as u8;
    }

    xor_table[0..8].copy_from_slice(&xor_block);

    // Loop 2: Expand to full 264-byte table (32 more blocks)
    let mut previous_xor_block = u64::from_le_bytes(xor_block);
    let mut copy_index = 8;

    for _ in 1..33 {
        let block_half_a = (previous_xor_block & 0xFFFFFFFF) as u32;
        let block_half_b = (previous_xor_block >> 32) as u32;

        // Complex derivation: multiply by 5, XOR with halves
        let mut a = previous_xor_block.wrapping_mul(5);
        a ^= (block_half_b as u64) << 32;

        let tmp_block_half_a = (block_half_a ^ (a as u32)) as u32;
        let mut tmp_block_half_b = (a >> 32) as u32;

        a = (block_half_a as u64) | (a & 0xFFFFFFFF00000000);

        let b = tmp_block_half_a;

        let xor_block_half_a = (a as u32) ^ b;
        tmp_block_half_b ^= block_half_b;
        let xor_block_half_b = tmp_block_half_b;

        let mut current_xor_block = [0u8; 8];
        current_xor_block[0..4].copy_from_slice(&xor_block_half_a.to_le_bytes());
        current_xor_block[4..8].copy_from_slice(&xor_block_half_b.to_le_bytes());

        xor_table[copy_index..copy_index + 8].copy_from_slice(&current_xor_block);

        previous_xor_block = u64::from_le_bytes(current_xor_block);
        copy_index += 8;
    }

    xor_table
}

/// State derived from block counter for key generation.
///
/// These values are used to compute special keys for each block's
/// encryption/decryption operations.
pub struct BlockCounterState {
    /// Combined value from multiple shifted block counters
    pub eval: u32,
    /// Overflow/carry component
    pub fval: u32,
}

/// Computes XOR table offset and block state from block counter.
///
/// Each 8-byte block in the file has a sequential counter (0, 8, 16, ...).
/// This function determines:
/// 1. Which 8-byte segment of the XOR table to use
/// 2. State values for special key generation
///
/// # Arguments
///
/// * `block_counter` - Current block position (multiple of 8)
///
/// # Returns
///
/// Tuple of (table_offset, state) where:
/// - `table_offset` - Index into XOR table (0-248, step 8)
/// - `state` - Values for `special_key_setup`
pub fn block_counter_setup(block_counter: u32) -> (u32, BlockCounterState) {
    // Calculate XOR table offset (cycles through 32 entries = 256 bytes)
    let block_counter_lower_most = (block_counter & 0xFFFF) as u16;
    let tmp = (block_counter_lower_most >> 3) << 3;
    let xor_table_offset = (tmp as u32) & 0xF8;

    // Derive state from shifted block counter values
    let block_counter_ab_shift_val = (block_counter as i64) << 10;
    let block_counter_cd_shift_val = (block_counter as i64) << 20;
    let block_counter_ef_shift_val = (block_counter as i64) << 30;

    let block_counter_a_val = (block_counter_ab_shift_val & 0xFFFFFFFF) as u32;
    let block_counter_b_val = (block_counter_ab_shift_val >> 32) as u32;

    let mut block_counter_c_val = (block_counter_cd_shift_val & 0xFFFFFFFF) as u32;
    let mut block_counter_d_val = (block_counter_cd_shift_val >> 32) as u32;

    block_counter_c_val |= block_counter_a_val;
    block_counter_d_val |= block_counter_b_val;

    let mut eval = (block_counter_ef_shift_val & 0xFFFFFFFF) as u32;
    let mut fval = (block_counter_ef_shift_val >> 32) as u32;

    eval |= block_counter;
    fval |= 0;

    eval |= block_counter_c_val;
    fval |= block_counter_d_val;

    (xor_table_offset, BlockCounterState { eval, fval })
}

/// Generates special keys for block encryption/decryption.
///
/// These keys are derived from the block counter state and a magic constant
/// (0xA1652347). They're XORed with block data during processing.
///
/// # Arguments
///
/// * `state` - Block counter state from `block_counter_setup`
///
/// # Returns
///
/// Tuple of (carry_flag, special_key1, special_key2)
pub fn special_key_setup(state: &BlockCounterState) -> (u32, i64, i64) {
    // Check for arithmetic overflow (carry)
    let carry_flag = if state.eval > !0xA1652347 { 1 } else { 0 };

    // Compute keys with magic constant
    let special_key1 = (state.eval as i64).wrapping_add(0xA1652347u32 as i64);
    let special_key2 = (state.fval as i64).wrapping_add(carry_flag as i64);

    (carry_flag, special_key1, special_key2)
}

/// Transforms a byte through the decryption pipeline.
///
/// Applies 8 rounds of substitution and subtraction using the INTEGERS
/// lookup table and XOR table values.
///
/// # Algorithm
///
/// For each of 8 iterations:
/// 1. Look up byte in INTEGERS table
/// 2. Subtract corresponding XOR table byte
/// 3. Handle negative results with masking
///
/// # Arguments
///
/// * `decrypted_byte` - Input byte value (0-255)
/// * `xor_table` - The 264-byte XOR table
/// * `table_offset` - Starting offset into XOR table
///
/// # Returns
///
/// Transformed byte value.
pub fn loop_a_byte(mut decrypted_byte: u32, xor_table: &[u8], table_offset: u32) -> u32 {
    for i in 0..8 {
        // Substitute through INTEGERS table
        let integer_val = INTEGERS[decrypted_byte as usize] as i32;
        let xor_table_byte = xor_table[(table_offset + i) as usize] as i32;

        // Subtract XOR table value (may go negative)
        let computed_value = integer_val - xor_table_byte;

        // Handle wraparound for negative values
        if computed_value < 0 {
            decrypted_byte = (computed_value & 0xFF) as u32;
        } else {
            decrypted_byte = computed_value as u32;
        }
    }
    decrypted_byte
}

/// Transforms a byte through the encryption pipeline (reverse of `loop_a_byte`).
///
/// Applies 8 rounds in reverse order, inverting the substitution and
/// subtraction operations.
///
/// # Algorithm
///
/// For each of 8 iterations (reverse order):
/// 1. Add XOR table byte value
/// 2. Handle overflow for values > 255
/// 3. Reverse-lookup in INTEGERS table
///
/// # Arguments
///
/// * `byte_to_encrypt` - Input byte value
/// * `xor_table` - The 264-byte XOR table
/// * `table_offset` - Starting offset into XOR table
///
/// # Returns
///
/// Encrypted byte value.
pub fn loop_a_byte_reverse(mut byte_to_encrypt: u8, xor_table: &[u8], table_offset: u32) -> u8 {
    // Process in reverse order (7 down to 0)
    for i in (0..8).rev() {
        let xor_table_byte = xor_table[(table_offset + i) as usize];
        let integer_val_used = (xor_table_byte as u32) + (byte_to_encrypt as u32);

        // Handle overflow case
        let target_val = if integer_val_used > 255 {
            let negative_hex_val = 0xFFFFFF00 | (byte_to_encrypt as u32);
            (negative_hex_val as i32) + (xor_table_byte as i32)
        } else {
            integer_val_used as i32
        };

        // Reverse lookup: find index where INTEGERS[index] == target_val
        byte_to_encrypt = INTEGERS
            .iter()
            .position(|&x| x == (target_val as u8))
            .unwrap_or(0) as u8;
    }
    byte_to_encrypt
}

/// Converts a 4-byte array to a sign-extended i64.
///
/// Creates a value with the upper 32 bits set to 0xFFFFFFFF and the
/// lower 32 bits containing the big-endian interpretation of the bytes.
///
/// # Arguments
///
/// * `bytes` - 4-byte array in big-endian order
///
/// # Returns
///
/// Sign-extended 64-bit value.
pub fn array_to_ff_num(bytes: &[u8; 4]) -> i64 {
    let mut val = 0xFFFFFFFF00000000u64;
    val |= (bytes[0] as u64) << 24;
    val |= (bytes[1] as u64) << 16;
    val |= (bytes[2] as u64) << 8;
    val |= bytes[3] as u64;
    val as i64
}

/// Computes a simple checksum for CLB data integrity.
///
/// Sums the first byte of each 4-byte chunk. This checksum is
/// appended to encrypted CLB files.
///
/// # Arguments
///
/// * `data` - Data bytes to checksum
///
/// # Returns
///
/// 32-bit checksum value.
pub fn compute_checksum(data: &[u8]) -> u32 {
    let mut total_chksum: u32 = 0;
    for chunk in data.chunks_exact(4) {
        total_chksum = total_chksum.wrapping_add(chunk[0] as u32);
    }
    total_chksum
}
