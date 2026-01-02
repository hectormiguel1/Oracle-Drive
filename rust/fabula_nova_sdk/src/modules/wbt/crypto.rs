//! # WBT Cryptography Module
//!
//! This module implements WhiteBinTools-compatible cryptographic operations
//! for filelist encryption/decryption in FF13-2 and Lightning Returns.
//!
//! ## Algorithm Overview
//!
//! The encryption uses a custom XOR-based block cipher:
//!
//! 1. **XOR Table Generation**: 264-byte table from 8-byte seed
//! 2. **Block Processing**: 8-byte blocks with special key mixing
//! 3. **INTEGERS Lookup**: 256-byte substitution table
//!
//! ## Key Components
//!
//! - [`generate_xor_table`] - Creates XOR lookup table from seed
//! - [`decrypt_blocks`] / [`encrypt_blocks`] - Block cipher operations
//! - [`loop_a_byte`] - Single byte transformation (decrypt)
//! - [`loop_a_byte_reverse`] - Single byte transformation (encrypt)
//!
//! ## INTEGERS Table
//!
//! A 256-byte rotation table where values 120-255 are at indices 0-135,
//! and values 0-119 are at indices 136-255. Used for byte substitution.

use log::{debug, trace};

/// The INTEGERS lookup table used for byte transformations.
/// This is a 256-byte array where values 120-255 are at indices 0-135,
/// and values 0-119 are at indices 136-255.
pub const INTEGERS: [u8; 256] = [
    120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135,
    136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151,
    152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167,
    168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183,
    184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199,
    200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215,
    216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231,
    232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247,
    248, 249, 250, 251, 252, 253, 254, 255, 0, 1, 2, 3, 4, 5, 6, 7,
    8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
    24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
    40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55,
    56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71,
    72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87,
    88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103,
    104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119,
];

/// Block counter state for crypto operations.
///
/// These values are derived from the current block position
/// and used to compute special keys for block transformation.
pub struct BlockCounterState {
    /// Lower 32 bits of the computed block position value
    pub eval: u32,
    /// Upper 32 bits of the computed block position value
    pub fval: u32,
}

/// Generates the 264-byte XOR table from an 8-byte seed.
///
/// The algorithm:
/// 1. Reverse the seed bytes
/// 2. Split into two 32-bit halves and rotate
/// 3. Apply initial transformations
/// 4. Generate 32 additional 8-byte blocks through mixing
///
/// # Arguments
///
/// * `seed` - 8-byte seed extracted from file header
///
/// # Returns
///
/// 264-byte XOR table used for block transformations.
pub fn generate_xor_table(mut seed: [u8; 8]) -> [u8; 264] {
    let mut xor_table = [0u8; 264];

    // C#: Array.Reverse(seedArray);
    seed.reverse();

    // C#: var seedHalfA = BitConverter.ToUInt32(seedArray, 0);
    //     var seedHalfB = BitConverter.ToUInt32(seedArray, 4);
    let seed_half_a = u32::from_le_bytes([seed[0], seed[1], seed[2], seed[3]]);
    let seed_half_b = u32::from_le_bytes([seed[4], seed[5], seed[6], seed[7]]);

    // C#: seedHalfA = (seedHalfA << 0x08) | (seedHalfA >> 0x18);
    //     seedHalfB = (seedHalfB >> 0x10) | (seedHalfB << 0x10);
    let seed_half_a = (seed_half_a << 8) | (seed_half_a >> 24);
    let seed_half_b = (seed_half_b >> 16) | (seed_half_b << 16);

    // C#: var xorBlock = BitConverter.GetBytes(seedHalfB).Concat(BitConverter.GetBytes(seedHalfA)).ToArray();
    let mut xor_block = [0u8; 8];
    xor_block[0..4].copy_from_slice(&seed_half_b.to_le_bytes());
    xor_block[4..8].copy_from_slice(&seed_half_a.to_le_bytes());

    // C#: xorBlock[0] += 0x45;
    xor_block[0] = xor_block[0].wrapping_add(0x45);

    // Loop 1: C# while (i < 8)
    for i in 1..8 {
        // C#: var tmp = xorBlock[i] + 0xD4 + xorBlock[i - 1];
        //     tmp ^= (xorBlock[i - 1]) << 2;
        //     tmp ^= 0x45;
        //     xorBlock[i] = (byte)tmp;
        let tmp = (xor_block[i] as i32) + 0xD4 + (xor_block[i - 1] as i32);
        let tmp = tmp ^ ((xor_block[i - 1] as i32) << 2);
        let tmp = tmp ^ 0x45;
        xor_block[i] = tmp as u8;
    }

    // C#: Array.ConstrainedCopy(xorBlock, 0, xorTable, 0, xorBlock.Length);
    xor_table[0..8].copy_from_slice(&xor_block);

    trace!("XOR table block 0: {:02X?}", &xor_block);

    // Loop 2: C# while (i < 0x21)
    let mut previous_xor_block = u64::from_le_bytes(xor_block);
    let mut copy_index = 8;

    for i in 1..33 {
        // C#: var blockHalfA = (uint)(previousXorBlock & 0xFFFFFFFF);
        //     var blockHalfB = (uint)(previousXorBlock >> 32);
        let block_half_a = (previous_xor_block & 0xFFFFFFFF) as u32;
        let block_half_b = (previous_xor_block >> 32) as u32;

        // C#: var a = 5 * previousXorBlock;
        //     a ^= (ulong)blockHalfB << 32;
        let mut a = previous_xor_block.wrapping_mul(5);
        a ^= (block_half_b as u64) << 32;

        // C#: ulong tmpBlockHalfA = (uint)(blockHalfA ^ a);
        //     ulong tmpBlockHalfB = (uint)(a >> 32);
        let tmp_block_half_a = (block_half_a ^ (a as u32)) as u32;
        let mut tmp_block_half_b = (a >> 32) as u32;

        // C#: a = blockHalfA | (a & 0xFFFFFFFF00000000);
        a = (block_half_a as u64) | (a & 0xFFFFFFFF00000000);

        // C#: var xorBlockHalfA = (uint)(a ^ tmpBlockHalfA);
        //     tmpBlockHalfB ^= blockHalfB;
        //     var xorBlockHalfB = (uint)tmpBlockHalfB;
        let xor_block_half_a = (a as u32) ^ tmp_block_half_a;
        tmp_block_half_b ^= block_half_b;
        let xor_block_half_b = tmp_block_half_b;

        // C#: xorBlock = BitConverter.GetBytes(xorBlockHalfA).Concat(BitConverter.GetBytes(xorBlockHalfB)).ToArray();
        let mut current_xor_block = [0u8; 8];
        current_xor_block[0..4].copy_from_slice(&xor_block_half_a.to_le_bytes());
        current_xor_block[4..8].copy_from_slice(&xor_block_half_b.to_le_bytes());

        // C#: Array.ConstrainedCopy(xorBlock, 0, xorTable, copyIndex, xorBlock.Length);
        xor_table[copy_index..copy_index + 8].copy_from_slice(&current_xor_block);

        trace!("XOR table block {}: {:02X?}", i, &current_xor_block);

        // C#: previousXorBlock = BitConverter.ToUInt64(xorBlock, 0);
        previous_xor_block = u64::from_le_bytes(current_xor_block);
        copy_index += 8;
    }

    xor_table
}

/// Sets up block counter state for a given block position.
///
/// Computes the XOR table offset (0-248 in steps of 8) and
/// the BlockCounterState used for special key generation.
///
/// # Returns
///
/// A tuple of (xor_table_offset, BlockCounterState).
pub fn block_counter_setup(block_counter: u32) -> (u32, BlockCounterState) {
    // C#: var blockCounterLowerMost = (ushort)(blockCounter & 0xFFFF);
    //     blockCounterLowerMost >>= 3;
    //     blockCounterLowerMost <<= 3;
    //     xorTableOffset = (uint)blockCounterLowerMost & 0xF8;
    let block_counter_lower_most = (block_counter & 0xFFFF) as u16;
    let tmp = (block_counter_lower_most >> 3) << 3;
    let xor_table_offset = (tmp as u32) & 0xF8;

    // C#: var blockCounterABshiftVal = (long)blockCounter << 10;
    //     var blockCounterCDshiftVal = (long)blockCounter << 20;
    //     var blockCounterEFshiftVal = (long)blockCounter << 30;
    let block_counter_ab_shift_val = (block_counter as i64) << 10;
    let block_counter_cd_shift_val = (block_counter as i64) << 20;
    let block_counter_ef_shift_val = (block_counter as i64) << 30;

    // C#: var blockCounterAval = (uint)(blockCounterABshiftVal & 0xFFFFFFFF);
    //     var blockCounterBval = (uint)(blockCounterABshiftVal >> 32);
    let block_counter_a_val = (block_counter_ab_shift_val & 0xFFFFFFFF) as u32;
    let block_counter_b_val = (block_counter_ab_shift_val >> 32) as u32;

    // C#: var blockCounterCval = (uint)(blockCounterCDshiftVal & 0xFFFFFFFF);
    //     var blockCounterDval = (uint)(blockCounterCDshiftVal >> 32);
    //     blockCounterCval |= blockCounterAval;
    //     blockCounterDval |= blockCounterBval;
    let mut block_counter_c_val = (block_counter_cd_shift_val & 0xFFFFFFFF) as u32;
    let mut block_counter_d_val = (block_counter_cd_shift_val >> 32) as u32;
    block_counter_c_val |= block_counter_a_val;
    block_counter_d_val |= block_counter_b_val;

    // C#: BlockCounterEval = (uint)(blockCounterEFshiftVal & 0xFFFFFFFF);
    //     BlockCounterFval = (uint)(blockCounterEFshiftVal >> 32);
    //     BlockCounterEval |= blockCounter;
    //     BlockCounterFval |= 0;
    //     BlockCounterEval |= blockCounterCval;
    //     BlockCounterFval |= blockCounterDval;
    let mut eval = (block_counter_ef_shift_val & 0xFFFFFFFF) as u32;
    let mut fval = (block_counter_ef_shift_val >> 32) as u32;
    eval |= block_counter;
    fval |= 0;
    eval |= block_counter_c_val;
    fval |= block_counter_d_val;

    (xor_table_offset, BlockCounterState { eval, fval })
}

/// Extracts two 32-bit values from the XOR table at the given offset.
///
/// # Returns
///
/// A tuple of (lower_value, higher_value) read as little-endian u32s.
pub fn xor_block_setup(xor_table: &[u8], table_offset: u32) -> (u32, u32) {
    // C#: xorBlockLowerVal = BitConverter.ToUInt32(currentXoRBlock, 0);
    //     xorBlockHigherVal = BitConverter.ToUInt32(currentXoRBlock, 4);
    let offset = table_offset as usize;
    let xor_block_lower_val = u32::from_le_bytes([
        xor_table[offset],
        xor_table[offset + 1],
        xor_table[offset + 2],
        xor_table[offset + 3],
    ]);
    let xor_block_higher_val = u32::from_le_bytes([
        xor_table[offset + 4],
        xor_table[offset + 5],
        xor_table[offset + 6],
        xor_table[offset + 7],
    ]);
    (xor_block_lower_val, xor_block_higher_val)
}

/// Computes special keys for block transformation.
///
/// These keys are XORed with the block data during encryption/decryption.
///
/// # Returns
///
/// A tuple of (carry_flag, special_key1, special_key2).
pub fn special_key_setup(state: &BlockCounterState) -> (u32, i64, i64) {
    // C#: carryFlag = BlockCounterEval > ~0xA1652347 ? (uint)1 : (uint)0;
    // In C#, ~0xA1652347 computes the bitwise NOT of 0xA1652347 as a 32-bit signed int,
    // which is 0x5E9ADCB8. When comparing with uint, both are treated as uint.
    let not_val = !0xA1652347u32; // = 0x5E9ADCB8
    let carry_flag: u32 = if state.eval > not_val { 1 } else { 0 };

    // C#: specialKey1 = (long)BlockCounterEval + 0xA1652347;
    //     specialKey2 = (long)BlockCounterFval + carryFlag;
    let special_key1 = (state.eval as i64) + (0xA1652347i64);
    let special_key2 = (state.fval as i64) + (carry_flag as i64);

    (carry_flag, special_key1, special_key2)
}

/// Transforms a byte through 8 iterations of INTEGERS lookup and XOR table subtraction.
///
/// This is the core transformation used in decryption:
/// ```text
/// for i in 0..8:
///     byte = INTEGERS[byte] - xor_table[offset + i]
/// ```
pub fn loop_a_byte(mut decrypted_byte: u32, xor_table: &[u8], table_offset: u32) -> u32 {
    // C#: while (byteIterator < 8) { ... byteIterator++; }
    for i in 0..8 {
        // C#: int integerVal = IntegersArray.Integers[(int)decryptedByte];
        let integer_val = INTEGERS[decrypted_byte as usize] as i32;

        // C#: var xorTableByte = xorTable[tableOffset + byteIterator];
        let xor_table_byte = xor_table[(table_offset + i) as usize] as i32;

        // C#: var computedValue = integerVal - xorTableByte;
        let computed_value = integer_val - xor_table_byte;

        // C#: if (computedValue < 0) {
        //         decryptedByte = (uint)computedValue & 0xFF;
        //     } else {
        //         decryptedByte = (uint)computedValue;
        //     }
        if computed_value < 0 {
            decrypted_byte = (computed_value & 0xFF) as u32;
        } else {
            decrypted_byte = computed_value as u32;
        }
    }
    decrypted_byte
}

/// Reverse transformation for encryption.
///
/// Iterates backward through the XOR table, adding values and
/// looking up the result in INTEGERS to find the original index.
pub fn loop_a_byte_reverse(mut byte_to_encrypt: u8, xor_table: &[u8], table_offset: u32) -> u8 {
    // C#: while (byteIterator > -1) { ... byteIterator--; }
    for i in (0..8).rev() {
        // C#: var xorTableByte = xorTable[tableOffset + byteIterator];
        //     var integerValUsed = xorTableByte + byteToEncrypt;
        let xor_table_byte = xor_table[(table_offset + i) as usize];
        let integer_val_used = (xor_table_byte as u32) + (byte_to_encrypt as u32);

        // C#: if (integerValUsed > 255) {
        //         var negativeHexVal = "FFFFFF";
        //         negativeHexVal += byteToEncrypt.ToString("X2");
        //         integerValUsed = Convert.ToInt32(negativeHexVal, 16) + xorTableByte;
        //     }
        let target_val = if integer_val_used > 255 {
            // This creates a negative number: 0xFFFFFF00 | byte_to_encrypt
            let negative_hex_val = 0xFFFFFF00u32 | (byte_to_encrypt as u32);
            (negative_hex_val as i32) + (xor_table_byte as i32)
        } else {
            integer_val_used as i32
        };

        // C#: byteToEncrypt = (byte)IntegersArray.Integers.IndexOf((byte)integerValUsed);
        byte_to_encrypt = INTEGERS
            .iter()
            .position(|&x| x == (target_val as u8))
            .unwrap_or(0) as u8;
    }
    byte_to_encrypt
}

/// Computes checksum for filelist validation.
///
/// Sums every 4th byte starting from `start_pos` for `blocks` iterations.
pub fn compute_checksum(data: &[u8], start_pos: usize, blocks: u32) -> u32 {
    let mut total_chksum: u32 = 0;
    let mut read_pos = start_pos;

    // C#: for (var i = 0; i < blocks; i++) {
    //         readerName.BaseStream.Position = readPos;
    //         var currentVal = readerName.ReadByte();
    //         totalChkSum = chkSumVal + currentVal;
    //         chkSumVal = totalChkSum;
    //         readPos += 4;
    //     }
    for _ in 0..blocks {
        if read_pos < data.len() {
            total_chksum = total_chksum.wrapping_add(data[read_pos] as u32);
        }
        read_pos += 4;
    }
    total_chksum
}

/// Decrypts 8-byte blocks in place.
///
/// For each block:
/// 1. Apply byte transformations via `loop_a_byte`
/// 2. Rearrange bytes (swap first 4 with last 4)
/// 3. Apply XOR and special key operations
/// 4. Handle carry flag for borrow propagation
pub fn decrypt_blocks(
    data: &mut [u8],
    xor_table: &[u8],
    block_count: u32,
    start_pos: usize,
) {
    let mut block_counter: u32 = 0;
    let mut read_pos = start_pos;
    let mut write_pos = start_pos;

    debug!("Decrypting {} blocks starting at position {}", block_count, start_pos);

    for block_idx in 0..block_count {
        if read_pos + 8 > data.len() {
            debug!("Block {}: reached end of data at pos {}", block_idx, read_pos);
            break;
        }

        // C#: var currentBlockId = blockCounter >> 3;
        let current_block_id = block_counter >> 3;

        // Read 8 bytes to decrypt
        let current_bytes: [u8; 8] = data[read_pos..read_pos + 8].try_into().unwrap();

        // Setup BlockCounter variables
        let (table_offset, state) = block_counter_setup(block_counter);

        // Decrypt each byte
        // C#: var decryptedByte1 = ((currentBlockId ^ 69) & 255) ^ currentBytes[0];
        //     decryptedByte1 = decryptedByte1.LoopAByte(xorTable, tableOffset);
        let decrypted_byte1 = loop_a_byte(
            ((current_block_id ^ 69) & 255) ^ (current_bytes[0] as u32),
            xor_table,
            table_offset,
        );

        // C#: var decryptedByte2 = (uint)currentBytes[0] ^ currentBytes[1];
        //     decryptedByte2 = decryptedByte2.LoopAByte(xorTable, tableOffset);
        let decrypted_byte2 = loop_a_byte(
            (current_bytes[0] as u32) ^ (current_bytes[1] as u32),
            xor_table,
            table_offset,
        );

        let decrypted_byte3 = loop_a_byte(
            (current_bytes[1] as u32) ^ (current_bytes[2] as u32),
            xor_table,
            table_offset,
        );

        let decrypted_byte4 = loop_a_byte(
            (current_bytes[2] as u32) ^ (current_bytes[3] as u32),
            xor_table,
            table_offset,
        );

        let decrypted_byte5 = loop_a_byte(
            (current_bytes[3] as u32) ^ (current_bytes[4] as u32),
            xor_table,
            table_offset,
        );

        let decrypted_byte6 = loop_a_byte(
            (current_bytes[4] as u32) ^ (current_bytes[5] as u32),
            xor_table,
            table_offset,
        );

        let decrypted_byte7 = loop_a_byte(
            (current_bytes[5] as u32) ^ (current_bytes[6] as u32),
            xor_table,
            table_offset,
        );

        let decrypted_byte8 = loop_a_byte(
            (current_bytes[6] as u32) ^ (current_bytes[7] as u32),
            xor_table,
            table_offset,
        );

        // C#: byte[] decryptedBytesArray = [
        //         (byte)decryptedByte5, (byte)decryptedByte6, (byte)decryptedByte7,
        //         (byte)decryptedByte8, (byte)decryptedByte1, (byte)decryptedByte2,
        //         (byte)decryptedByte3, (byte)decryptedByte4
        //     ];
        let decrypted_bytes_array: [u8; 8] = [
            decrypted_byte5 as u8,
            decrypted_byte6 as u8,
            decrypted_byte7 as u8,
            decrypted_byte8 as u8,
            decrypted_byte1 as u8,
            decrypted_byte2 as u8,
            decrypted_byte3 as u8,
            decrypted_byte4 as u8,
        ];

        // C#: var decryptedBytesHigherVal = BitConverter.ToUInt32(decryptedBytesArray, 0);
        //     var decryptedBytesLowerVal = BitConverter.ToUInt32(decryptedBytesArray, 4);
        let decrypted_bytes_higher_val = u32::from_le_bytes([
            decrypted_bytes_array[0],
            decrypted_bytes_array[1],
            decrypted_bytes_array[2],
            decrypted_bytes_array[3],
        ]);
        let decrypted_bytes_lower_val = u32::from_le_bytes([
            decrypted_bytes_array[4],
            decrypted_bytes_array[5],
            decrypted_bytes_array[6],
            decrypted_bytes_array[7],
        ]);

        // Setup XOR block values
        let (xor_block_lower_val, xor_block_higher_val) = xor_block_setup(xor_table, table_offset);

        // Setup SpecialKey variables
        let (_, special_key1, special_key2) = special_key_setup(&state);

        // C#: carryFlag = decryptedBytesLongLowerVal < xorBlockLowerVal ? 1 : (uint)0;
        let carry_flag: i64 = if decrypted_bytes_lower_val < xor_block_lower_val {
            1
        } else {
            0
        };

        // C#: decryptedBytesLongLowerVal -= xorBlockLowerVal;
        //     decryptedBytesLongHigherVal -= xorBlockHigherVal;
        //     decryptedBytesLongHigherVal -= carryFlag;
        let mut decrypted_bytes_long_lower_val =
            (decrypted_bytes_lower_val as i64) - (xor_block_lower_val as i64);
        let mut decrypted_bytes_long_higher_val =
            (decrypted_bytes_higher_val as i64) - (xor_block_higher_val as i64) - carry_flag;

        // C#: decryptedBytesLongLowerVal ^= specialKey1;
        //     decryptedBytesLongHigherVal ^= specialKey2;
        decrypted_bytes_long_lower_val ^= special_key1;
        decrypted_bytes_long_higher_val ^= special_key2;

        // C#: decryptedBytesLongLowerVal ^= xorBlockLowerVal;
        //     decryptedBytesLongHigherVal ^= xorBlockHigherVal;
        decrypted_bytes_long_lower_val ^= xor_block_lower_val as i64;
        decrypted_bytes_long_higher_val ^= xor_block_higher_val as i64;

        // C#: var decryptedByteLowerArray = BitConverter.GetBytes((uint)decryptedBytesLongLowerVal);
        //     var decryptedByteHigherArray = BitConverter.GetBytes((uint)decryptedBytesLongHigherVal);
        let decrypted_byte_lower_array = (decrypted_bytes_long_lower_val as u32).to_le_bytes();
        let decrypted_byte_higher_array = (decrypted_bytes_long_higher_val as u32).to_le_bytes();

        // C#: decryptedStreamBinWriter.Write(decryptedByteHigherArray);  // at writePos
        //     decryptedStreamBinWriter.Write(decryptedByteLowerArray);   // at writePos + 4
        data[write_pos..write_pos + 4].copy_from_slice(&decrypted_byte_higher_array);
        data[write_pos + 4..write_pos + 8].copy_from_slice(&decrypted_byte_lower_array);

        if block_idx < 3 {
            trace!(
                "Block {}: enc={:02X?} -> dec higher={:02X?} lower={:02X?}",
                block_idx,
                current_bytes,
                decrypted_byte_higher_array,
                decrypted_byte_lower_array
            );
        }

        // Move to next block
        block_counter += 8;
        read_pos += 8;
        write_pos += 8;
    }

    debug!("Decryption complete: {} blocks processed", block_count);
}

/// Encrypts 8-byte blocks in place.
///
/// Reverses the decryption process:
/// 1. Rearrange bytes
/// 2. Apply XOR and special key operations
/// 3. Handle carry flag for overflow
/// 4. Apply reverse byte transformations via `loop_a_byte_reverse`
pub fn encrypt_blocks(
    data: &mut [u8],
    xor_table: &[u8],
    block_count: u32,
    start_pos: usize,
) {
    let mut block_counter: u32 = 0;
    let mut read_pos = start_pos;
    let mut write_pos = start_pos;

    debug!("Encrypting {} blocks starting at position {}", block_count, start_pos);

    for block_idx in 0..block_count {
        if read_pos + 8 > data.len() {
            debug!("Block {}: reached end of data at pos {}", block_idx, read_pos);
            break;
        }

        // C#: var currentBlockId = blockCounter >> 3;
        let current_block_id = block_counter >> 3;

        // Read 8 bytes to encrypt
        let bytes_to_encrypt: [u8; 8] = data[read_pos..read_pos + 8].try_into().unwrap();

        // C#: byte[] bytesToEncryptLowerArray = [bytesToEncrypt[7], bytesToEncrypt[6], bytesToEncrypt[5], bytesToEncrypt[4]];
        //     byte[] bytesToEncryptHigherArray = [bytesToEncrypt[3], bytesToEncrypt[2], bytesToEncrypt[1], bytesToEncrypt[0]];
        let bytes_to_encrypt_lower_array: [u8; 4] = [
            bytes_to_encrypt[7],
            bytes_to_encrypt[6],
            bytes_to_encrypt[5],
            bytes_to_encrypt[4],
        ];
        let bytes_to_encrypt_higher_array: [u8; 4] = [
            bytes_to_encrypt[3],
            bytes_to_encrypt[2],
            bytes_to_encrypt[1],
            bytes_to_encrypt[0],
        ];

        // C#: var bytesToEncryptLowerVal = bytesToEncryptLowerArray.ArrayToFfNum();
        //     var bytesToEncryptHigherVal = bytesToEncryptHigherArray.ArrayToFfNum();
        let mut bytes_to_encrypt_lower_val = array_to_ff_num(&bytes_to_encrypt_lower_array);
        let mut bytes_to_encrypt_higher_val = array_to_ff_num(&bytes_to_encrypt_higher_array);

        // Setup BlockCounter variables
        let (table_offset, state) = block_counter_setup(block_counter);

        // Setup XOR block values
        let (xor_block_lower_val, xor_block_higher_val) = xor_block_setup(xor_table, table_offset);

        // Setup SpecialKey variables
        let (_, special_key1, special_key2) = special_key_setup(&state);

        // C#: bytesToEncryptLowerVal ^= xorBlockLowerVal;
        //     bytesToEncryptHigherVal ^= xorBlockHigherVal;
        bytes_to_encrypt_lower_val ^= xor_block_lower_val as i64;
        bytes_to_encrypt_higher_val ^= xor_block_higher_val as i64;

        // C#: bytesToEncryptLowerVal ^= specialKey1;
        //     bytesToEncryptHigherVal ^= specialKey2;
        bytes_to_encrypt_lower_val ^= special_key1;
        bytes_to_encrypt_higher_val ^= special_key2;

        // C#: bytesToEncryptLowerVal += xorBlockLowerVal;
        //     bytesToEncryptHigherVal += xorBlockHigherVal;
        bytes_to_encrypt_lower_val += xor_block_lower_val as i64;
        bytes_to_encrypt_higher_val += xor_block_higher_val as i64;

        // C#: var bytesToEncryptLowerValFixed = bytesToEncryptLowerVal & 0xFFFFFFFF;
        //     carryFlag = bytesToEncryptLowerValFixed < xorBlockLowerVal ? 1 : (uint)0;
        //     bytesToEncryptHigherVal += carryFlag;
        let bytes_to_encrypt_lower_val_fixed = (bytes_to_encrypt_lower_val & 0xFFFFFFFF) as u64;
        let carry_flag: i64 = if bytes_to_encrypt_lower_val_fixed < (xor_block_lower_val as u64) {
            1
        } else {
            0
        };
        bytes_to_encrypt_higher_val += carry_flag;

        // C#: var bytesToEncryptHigherValUInt = (uint)bytesToEncryptHigherVal & 0xFFFFFFFF;
        //     var bytesToEncryptLowerValUInt = (uint)bytesToEncryptLowerVal & 0xFFFFFFFF;
        let bytes_to_encrypt_higher_val_uint = (bytes_to_encrypt_higher_val as u32) & 0xFFFFFFFF;
        let bytes_to_encrypt_lower_val_uint = (bytes_to_encrypt_lower_val as u32) & 0xFFFFFFFF;

        // C#: var computedBytesArray = new byte[8];
        //     Array.ConstrainedCopy(BitConverter.GetBytes(bytesToEncryptLowerValUInt), 0, computedBytesArray, 0, 4);
        //     Array.ConstrainedCopy(BitConverter.GetBytes(bytesToEncryptHigherValUInt), 0, computedBytesArray, 4, 4);
        let mut computed_bytes_array = [0u8; 8];
        computed_bytes_array[0..4].copy_from_slice(&bytes_to_encrypt_lower_val_uint.to_le_bytes());
        computed_bytes_array[4..8].copy_from_slice(&bytes_to_encrypt_higher_val_uint.to_le_bytes());

        // Encrypt each byte
        // C#: var encryptedByte1 = computedBytesArray[0].LoopAByteReverse(xorTable, tableOffset);
        //     encryptedByte1 = ((currentBlockId ^ 69) & 255) ^ encryptedByte1;
        let mut encrypted_byte1 =
            loop_a_byte_reverse(computed_bytes_array[0], xor_table, table_offset) as u32;
        encrypted_byte1 = ((current_block_id ^ 69) & 255) ^ encrypted_byte1;

        let mut encrypted_byte2 =
            loop_a_byte_reverse(computed_bytes_array[1], xor_table, table_offset) as u32;
        encrypted_byte2 = encrypted_byte1 ^ encrypted_byte2;

        let mut encrypted_byte3 =
            loop_a_byte_reverse(computed_bytes_array[2], xor_table, table_offset) as u32;
        encrypted_byte3 = encrypted_byte2 ^ encrypted_byte3;

        let mut encrypted_byte4 =
            loop_a_byte_reverse(computed_bytes_array[3], xor_table, table_offset) as u32;
        encrypted_byte4 = encrypted_byte3 ^ encrypted_byte4;

        let mut encrypted_byte5 =
            loop_a_byte_reverse(computed_bytes_array[4], xor_table, table_offset) as u32;
        encrypted_byte5 = encrypted_byte4 ^ encrypted_byte5;

        let mut encrypted_byte6 =
            loop_a_byte_reverse(computed_bytes_array[5], xor_table, table_offset) as u32;
        encrypted_byte6 = encrypted_byte5 ^ encrypted_byte6;

        let mut encrypted_byte7 =
            loop_a_byte_reverse(computed_bytes_array[6], xor_table, table_offset) as u32;
        encrypted_byte7 = encrypted_byte6 ^ encrypted_byte7;

        let mut encrypted_byte8 =
            loop_a_byte_reverse(computed_bytes_array[7], xor_table, table_offset) as u32;
        encrypted_byte8 = encrypted_byte7 ^ encrypted_byte8;

        // C#: byte[] encryptedByteArray = [
        //         (byte)encryptedByte1, (byte)encryptedByte2, (byte)encryptedByte3,
        //         (byte)encryptedByte4, (byte)encryptedByte5, (byte)encryptedByte6,
        //         (byte)encryptedByte7, (byte)encryptedByte8
        //     ];
        let encrypted_byte_array: [u8; 8] = [
            encrypted_byte1 as u8,
            encrypted_byte2 as u8,
            encrypted_byte3 as u8,
            encrypted_byte4 as u8,
            encrypted_byte5 as u8,
            encrypted_byte6 as u8,
            encrypted_byte7 as u8,
            encrypted_byte8 as u8,
        ];

        // Write encrypted bytes
        data[write_pos..write_pos + 8].copy_from_slice(&encrypted_byte_array);

        if block_idx < 3 {
            trace!(
                "Block {}: plain={:02X?} -> enc={:02X?}",
                block_idx,
                bytes_to_encrypt,
                encrypted_byte_array
            );
        }

        // Move to next block
        read_pos += 8;
        block_counter += 8;
        write_pos += 8;
    }

    debug!("Encryption complete: {} blocks processed", block_count);
}

/// Converts a 4-byte array to an i64 with 0xFFFFFFFF prefix.
///
/// Used during encryption to create sign-extended values:
/// `0xFFFFFFFF_XX_XX_XX_XX` where XX are the input bytes.
fn array_to_ff_num(bytes: &[u8; 4]) -> i64 {
    // C#: var hexValue = "FFFFFFFF";
    //     hexValue += byteArray[0].ToString("X2") + byteArray[1].ToString("X2") + ...
    //     return Convert.ToInt64(hexValue, 16);
    let mut val = 0xFFFFFFFF00000000u64;
    val |= (bytes[0] as u64) << 24;
    val |= (bytes[1] as u64) << 16;
    val |= (bytes[2] as u64) << 8;
    val |= bytes[3] as u64;
    val as i64
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_integers_array() {
        // Verify the INTEGERS array matches the C# version
        assert_eq!(INTEGERS[0], 120);
        assert_eq!(INTEGERS[89], 209);
        assert_eq!(INTEGERS[136], 0);
        assert_eq!(INTEGERS[162], 26);
        assert_eq!(INTEGERS[169], 33);
        assert_eq!(INTEGERS[255], 119);
    }

    #[test]
    fn test_xor_table_generation() {
        // Test with a known seed
        let seed: [u8; 8] = [0x85, 0xEA, 0x6B, 0xB4, 0x00, 0x00, 0x00, 0x00];
        let xor_table = generate_xor_table(seed);

        // Expected first 8 bytes based on C# implementation
        assert_eq!(
            &xor_table[0..8],
            &[0x2F, 0x71, 0x78, 0x12, 0xEB, 0x56, 0x37, 0x92]
        );
    }

    #[test]
    fn test_loop_a_byte() {
        let seed: [u8; 8] = [0x85, 0xEA, 0x6B, 0xB4, 0x00, 0x00, 0x00, 0x00];
        let xor_table = generate_xor_table(seed);

        // Input: (69 ^ 0x1C) = 89
        let result = loop_a_byte(89, &xor_table, 0);
        assert_eq!(result, 229); // 0xE5
    }

    #[test]
    fn test_block_counter_setup() {
        let (offset, state) = block_counter_setup(0);
        assert_eq!(offset, 0);
        assert_eq!(state.eval, 0);
        assert_eq!(state.fval, 0);

        let (offset, _state) = block_counter_setup(8);
        assert_eq!(offset, 8);
    }

    #[test]
    fn test_special_key_setup() {
        let state = BlockCounterState { eval: 0, fval: 0 };
        let (carry, key1, key2) = special_key_setup(&state);
        assert_eq!(carry, 0);
        assert_eq!(key1, 0xA1652347);
        assert_eq!(key2, 0);
    }
}
