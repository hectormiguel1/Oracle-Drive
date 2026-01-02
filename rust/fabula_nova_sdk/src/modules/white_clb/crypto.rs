//! # WHITE_CLB Cryptographic Primitives
//!
//! This module provides a simplified implementation of CLB encryption
//! based on the WhiteCLBtool specification.
//!
//! ## Differences from CLB Module
//!
//! | Aspect          | CLB Module           | WHITE_CLB Module        |
//! |-----------------|----------------------|-------------------------|
//! | INTEGERS table  | Offset by 120        | Identity (i → i)        |
//! | Operations      | Full block cipher    | Simplified XOR          |
//!
//! ## XOR Table Generation
//!
//! Uses the same algorithm as the CLB module:
//! 1. Reverse seed bytes
//! 2. Rotate halves
//! 3. Generate 33 blocks (264 bytes)
//!
//! ## Byte Transformation
//!
//! The `loop_a_byte` function applies 8 rounds of substitution
//! through the INTEGERS table with XOR table subtraction.

/// Identity substitution table.
///
/// Unlike the CLB module's rotated table, this is a straight identity
/// mapping: INTEGERS[i] = i for all i in 0..255.
pub const INTEGERS: [u8; 256] = {
    let mut arr = [0u8; 256];
    let mut i = 0;
    while i < 256 {
        arr[i] = i as u8;
        i += 1;
    }
    arr
};

/// Generates a 264-byte XOR table from an 8-byte seed.
///
/// Same algorithm as [`crate::modules::clb::crypto::generate_xor_table`].
///
/// # Algorithm
///
/// 1. Reverse seed byte order
/// 2. Split into two 32-bit halves, apply rotations
/// 3. Generate initial block with chained XOR (0x45, 0xD4 magic values)
/// 4. Expand to 33 blocks using multiply-XOR derivation
///
/// # Arguments
///
/// * `seed` - 8-byte seed from CLB file header
///
/// # Returns
///
/// 264-byte table (33 × 8-byte blocks).
pub fn generate_xor_table(seed: &[u8; 8]) -> [u8; 264] {
    let mut table = [0u8; 264];

    // Reverse the seed array
    let mut reversed_seed = *seed;
    reversed_seed.reverse();
    
    // Extract two u32 values
    let val1 = u32::from_le_bytes([reversed_seed[0], reversed_seed[1], reversed_seed[2], reversed_seed[3]]);
    let val2 = u32::from_le_bytes([reversed_seed[4], reversed_seed[5], reversed_seed[6], reversed_seed[7]]);
    
    // Apply bit rotations
    let val1 = val1.rotate_left(8);  // Rotate left 8
    let val2 = val2.rotate_left(16); // Rotate by 16 (swap halves)
    
    // Create initial 8-byte block
    let mut block = [0u8; 8];
    block[0..4].copy_from_slice(&val2.to_le_bytes());
    block[4..8].copy_from_slice(&val1.to_le_bytes());
    
    // Modify first byte
    block[0] = block[0].wrapping_add(0x45); // Add 69
    
    // Generate bytes 1-7 using chained operations
    for i in 1..8 {
        let mut temp = (block[i] as i32).wrapping_add(0xD4); // Add 212
        temp = temp.wrapping_add(block[i - 1] as i32);
        temp ^= (block[i - 1] as i32) << 2;
        temp ^= 0x45; // XOR with 69
        block[i] = temp as u8;
    }
    
    // Copy first block to table
    table[0..8].copy_from_slice(&block);
    
    // Generate remaining 32 blocks (blocks 1-32)
    let mut prev_u64 = u64::from_le_bytes(block);
    let mut table_offset = 8;
    
    for _ in 1..33 {
        let low = (prev_u64 & 0xFFFFFFFF) as u32;
        let high = (prev_u64 >> 32) as u32;
        
        // Multiply by 5
        let mut result = prev_u64.wrapping_mul(5);
        
        // XOR with (high << 32)
        result ^= (high as u64) << 32;
        
        // Extract new values
        let new_low = ((low as u64) ^ result) as u32;
        let new_high_intermediate = (result >> 32) as u32;
        let new_high = new_high_intermediate ^ high;
        
        let new_block_bytes: [u8; 8] = {
            let mut b = [0u8; 8];
            b[0..4].copy_from_slice(&new_low.to_le_bytes());
            b[4..8].copy_from_slice(&new_high.to_le_bytes());
            b
        };
        
        table[table_offset..table_offset + 8].copy_from_slice(&new_block_bytes);
        table_offset += 8;
        prev_u64 = u64::from_le_bytes(new_block_bytes);
    }
    
    table
}

/// Computes the XOR table offset for a given block counter.
///
/// The table offset cycles through 32 8-byte entries (256 bytes),
/// providing variation in the encryption key per block.
///
/// # Arguments
///
/// * `block_counter` - Current block position (0, 8, 16, ...)
///
/// # Returns
///
/// Offset into XOR table (0-248, step 8).
pub fn get_table_offset(block_counter: u32) -> u32 {
    let masked = (block_counter & 0xFFFF) as u16;
    let shifted = masked >> 3;
    let multiplied = shifted << 3;
    (multiplied & 0xF8) as u32
}

/// Transforms a byte through the decryption pipeline.
///
/// Applies 8 rounds of INTEGERS lookup followed by XOR table subtraction.
/// With the identity INTEGERS table, this simplifies to direct subtraction.
///
/// # Arguments
///
/// * `decrypted_byte` - Byte value to transform (0-255)
/// * `xor_table` - 264-byte XOR table
/// * `table_offset` - Starting offset into table
///
/// # Returns
///
/// Transformed byte value.
pub fn loop_a_byte(mut decrypted_byte: u32, xor_table: &[u8], table_offset: u32) -> u32 {
    for i in 0..8 {
        let lookup_val = INTEGERS[decrypted_byte as usize];
        let xor_val = xor_table[(table_offset as usize) + i];
        let temp = (lookup_val as i32) - (xor_val as i32);
        if temp < 0 {
            decrypted_byte = (temp & 0xFF) as u32;
        } else {
            decrypted_byte = temp as u32;
        }
    }
    decrypted_byte
}

/// Computes a simple checksum over data.
///
/// Sums the first byte of each 4-byte chunk with wrapping addition.
///
/// # Arguments
///
/// * `data` - Data to checksum
///
/// # Returns
///
/// 32-bit checksum value.
pub fn compute_checksum(data: &[u8]) -> u32 {
    let mut sum = 0u32;
    let mut pos = 0usize;
    let block_count = data.len() / 4;

    for _ in 0..block_count {
        let byte_val = data[pos] as u32;
        sum = sum.wrapping_add(byte_val);
        pos += 4;
    }

    sum
}

/// Transforms a byte through the encryption pipeline.
///
/// Reverse of [`loop_a_byte`] - adds XOR table values in reverse order.
///
/// # Arguments
///
/// * `val` - Byte value to transform
/// * `xor_table` - 264-byte XOR table
/// * `table_offset` - Starting offset into table
///
/// # Returns
///
/// Encrypted byte value.
pub fn loop_a_byte_reverse(mut val: u32, xor_table: &[u8], table_offset: u32) -> u32 {
    for i in (0..8).rev() {
        let xor_val = xor_table[(table_offset as usize) + i];
        val = ((val as i32).wrapping_add(xor_val as i32) & 0xFF) as u32;
    }
    val
}
