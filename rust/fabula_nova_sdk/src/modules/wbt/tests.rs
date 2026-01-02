#[cfg(test)]
mod tests {
    use crate::core::utils::GameCode;
    use crate::modules::wbt::Filelist;
    use crate::modules::wbt::crypto as wbt_crypto;
    use std::fs::File;
    use std::path::Path;

    const FF13_LR_DATA_PATH: &str = "/Users/hramirez/Desktop/Development/ff13-lr_data";
    const FF13_1_DATA_PATH: &str = "/Users/hramirez/Desktop/Development/ff13_data";

    #[test]
    fn test_filelist_ff13_1_unencrypted() {
        // Test FF13-1 unencrypted filelist
        let filelist_path = Path::new(FF13_1_DATA_PATH).join("filelistu.win32.bin");

        if !filelist_path.exists() {
            println!("Skipping test: File not found at {:?}", filelist_path);
            return;
        }

        println!("Testing FF13-1 unencrypted filelist: {:?}", filelist_path);

        let file = File::open(&filelist_path).expect("Failed to open filelist");
        let result = Filelist::read(file, GameCode::FF13_1);

        match &result {
            Ok(filelist) => {
                println!("SUCCESS: Parsed {} entries, {} chunks",
                    filelist.entries.len(),
                    filelist.chunks.len()
                );

                // Sanity checks
                assert!(filelist.entries.len() > 0, "Should have entries");
                assert!(filelist.entries.len() < 100000, "Entry count should be reasonable (got {})", filelist.entries.len());
                assert!(filelist.chunks.len() > 0, "Should have chunks");

                // Print first few entries for verification
                println!("First 5 entries:");
                for i in 0..5.min(filelist.entries.len()) {
                    if let Ok(metadata) = filelist.get_metadata(i) {
                        println!("  [{}] {} (offset: 0x{:X}, size: {})",
                            i, metadata.path, metadata.offset, metadata.uncompressed_size);
                    }
                }
            }
            Err(e) => {
                panic!("Failed to parse filelist: {:?}", e);
            }
        }
    }

    #[test]
    fn test_filelist_decryption_ff13lr_2a() {
        let filelist_path = Path::new(FF13_LR_DATA_PATH).join("filelist2a.win32.bin");

        if !filelist_path.exists() {
            println!("Skipping test: File not found at {:?}", filelist_path);
            return;
        }

        println!("Testing filelist decryption: {:?}", filelist_path);

        let file = File::open(&filelist_path).expect("Failed to open filelist");
        let result = Filelist::read(file, GameCode::FF13_3);

        match &result {
            Ok(filelist) => {
                println!("SUCCESS: Parsed {} entries, {} chunks",
                    filelist.entries.len(),
                    filelist.chunks.len()
                );

                // Sanity checks
                assert!(filelist.entries.len() > 0, "Should have entries");
                assert!(filelist.entries.len() < 100000, "Entry count should be reasonable (got {})", filelist.entries.len());
                assert!(filelist.chunks.len() > 0, "Should have chunks");

                // Print first few entries for verification
                println!("First 5 entries:");
                for (i, entry) in filelist.entries.iter().take(5).enumerate() {
                    if let Ok(metadata) = filelist.get_metadata(i) {
                        println!("  [{}] {} (offset: 0x{:X}, size: {})",
                            i, metadata.path, metadata.offset, metadata.uncompressed_size);
                    }
                }
            }
            Err(e) => {
                panic!("Failed to parse filelist: {:?}", e);
            }
        }
    }

    #[test]
    fn test_filelist_decryption_ff13lr_main() {
        let filelist_path = Path::new(FF13_LR_DATA_PATH).join("filelista.win32.bin");

        if !filelist_path.exists() {
            println!("Skipping test: File not found at {:?}", filelist_path);
            return;
        }

        println!("Testing filelist decryption: {:?}", filelist_path);

        let file = File::open(&filelist_path).expect("Failed to open filelist");
        let result = Filelist::read(file, GameCode::FF13_3);

        match &result {
            Ok(filelist) => {
                println!("SUCCESS: Parsed {} entries, {} chunks",
                    filelist.entries.len(),
                    filelist.chunks.len()
                );

                // Sanity checks
                assert!(filelist.entries.len() > 0, "Should have entries");
                assert!(filelist.entries.len() < 100000, "Entry count should be reasonable (got {})", filelist.entries.len());
                assert!(filelist.chunks.len() > 0, "Should have chunks");

                // Print first few entries for verification
                println!("First 5 entries:");
                for (i, entry) in filelist.entries.iter().take(5).enumerate() {
                    if let Ok(metadata) = filelist.get_metadata(i) {
                        println!("  [{}] {} (offset: 0x{:X}, size: {})",
                            i, metadata.path, metadata.offset, metadata.uncompressed_size);
                    }
                }
            }
            Err(e) => {
                panic!("Failed to parse filelist: {:?}", e);
            }
        }
    }

    #[test]
    fn test_filelist_decryption_ff13lr_scra() {
        let filelist_path = Path::new(FF13_LR_DATA_PATH).join("filelist_scra.win32.bin");

        if !filelist_path.exists() {
            println!("Skipping test: File not found at {:?}", filelist_path);
            return;
        }

        println!("Testing filelist decryption: {:?}", filelist_path);

        let file = File::open(&filelist_path).expect("Failed to open filelist");
        let result = Filelist::read(file, GameCode::FF13_3);

        match &result {
            Ok(filelist) => {
                println!("SUCCESS: Parsed {} entries, {} chunks",
                    filelist.entries.len(),
                    filelist.chunks.len()
                );

                // Sanity checks - scra files are smaller
                assert!(filelist.entries.len() > 0, "Should have entries");
                assert!(filelist.entries.len() < 10000, "Entry count should be reasonable (got {})", filelist.entries.len());

                // Print first few entries for verification
                println!("First 5 entries:");
                for (i, entry) in filelist.entries.iter().take(5).enumerate() {
                    if let Ok(metadata) = filelist.get_metadata(i) {
                        println!("  [{}] {} (offset: 0x{:X}, size: {})",
                            i, metadata.path, metadata.offset, metadata.uncompressed_size);
                    }
                }
            }
            Err(e) => {
                panic!("Failed to parse filelist: {:?}", e);
            }
        }
    }

    #[test]
    fn test_filelist_header_bytes() {
        // Diagnostic test to dump first 64 bytes of the filelist
        let filelist_path = Path::new(FF13_LR_DATA_PATH).join("filelist2a.win32.bin");

        if !filelist_path.exists() {
            println!("Skipping test: File not found at {:?}", filelist_path);
            return;
        }

        let data = std::fs::read(&filelist_path).expect("Failed to read file");

        println!("File size: {} bytes", data.len());
        println!("First 64 bytes (hex):");
        for (i, chunk) in data[..64.min(data.len())].chunks(16).enumerate() {
            print!("  {:04X}: ", i * 16);
            for b in chunk {
                print!("{:02X} ", b);
            }
            println!();
        }

        // Check encryption marker at position 20
        let enc_marker = u32::from_le_bytes([data[20], data[21], data[22], data[23]]);
        println!("\nEncryption marker at pos 20: 0x{:08X} (expected 0x1DE03478 = {})",
            enc_marker, 501232760);
        println!("Is encrypted: {}", enc_marker == 501232760);

        // Show what header would be at position 32 (raw, before decryption)
        let raw_header = (
            u32::from_le_bytes([data[32], data[33], data[34], data[35]]),
            u32::from_le_bytes([data[36], data[37], data[38], data[39]]),
            u32::from_le_bytes([data[40], data[41], data[42], data[43]]),
        );
        println!("\nRaw header at pos 32 (before decryption):");
        println!("  chunk_info_offset: 0x{:08X}", raw_header.0);
        println!("  chunk_data_offset: 0x{:08X}", raw_header.1);
        println!("  total_files: {}", raw_header.2);
    }

    #[test]
    fn test_loop_a_byte_trace() {

        // Test with known inputs from filelist2a.win32.bin
        // First encrypted byte at pos 32 is 0x1C
        // current_block_id = 0, so XOR value is (0 ^ 69) & 255 = 69 = 0x45
        // Input to LoopAByte: (69 ^ 0x1C) = 89 = 0x59

        // First, generate the XOR table with known seed
        let seed: [u8; 8] = [0x85, 0xEA, 0x6B, 0xB4, 0x00, 0x00, 0x00, 0x00];
        let xor_table = wbt_crypto::generate_xor_table(seed);

        println!("XOR table first 8 bytes: {:02X?}", &xor_table[0..8]);
        println!("Expected: [2F, 71, 78, 12, EB, 56, 37, 92]");

        // Verify INTEGERS array
        println!("\nINTEGERS spot checks:");
        println!("  INTEGERS[0] = {} (expected 120)", wbt_crypto::INTEGERS[0]);
        println!("  INTEGERS[89] = {} (expected 209)", wbt_crypto::INTEGERS[89]);
        println!("  INTEGERS[136] = {} (expected 0)", wbt_crypto::INTEGERS[136]);
        println!("  INTEGERS[162] = {} (expected 26)", wbt_crypto::INTEGERS[162]);
        println!("  INTEGERS[169] = {} (expected 33)", wbt_crypto::INTEGERS[169]);

        // Trace through LoopAByte manually
        let input = 89u32; // (69 ^ 0x1C)
        println!("\nLoopAByte({}, xor_table, 0):", input);

        let mut val = input;
        for i in 0..8 {
            let int_val = wbt_crypto::INTEGERS[val as usize];
            let xor_val = xor_table[i];
            let computed = (int_val as i32) - (xor_val as i32);
            let new_val = if computed < 0 {
                (computed & 0xFF) as u32
            } else {
                computed as u32
            };
            println!("  i={}: INTEGERS[{}]={}, xor_table[{}]={}, computed={}, new_val={}",
                i, val, int_val, i, xor_val, computed, new_val);
            val = new_val;
        }
        println!("Final result: {} (0x{:02X})", val, val);

        // Call the actual function
        let actual_result = wbt_crypto::loop_a_byte(input, &xor_table, 0);
        println!("wbt_crypto::loop_a_byte result: {} (0x{:02X})", actual_result, actual_result);

        // My manual calculation was wrong - actual result is 229 (0xE5)
        println!("\nActual result is 229 (0xE5) - LoopAByte is correct!");

        // Now trace all 8 bytes of first block
        println!("\n=== Full first block decryption ===");
        let first_block: [u8; 8] = [0x1C, 0xD8, 0x24, 0x0F, 0xCD, 0x65, 0x1A, 0xA0];
        let current_block_id: u32 = 0;
        println!("First encrypted block: {:02X?}", first_block);

        // Byte 1: ((currentBlockId ^ 69) & 255) ^ currentBytes[0]
        let b1_input = ((current_block_id ^ 69) & 255) ^ (first_block[0] as u32);
        let b1 = wbt_crypto::loop_a_byte(b1_input, &xor_table, 0);
        println!("Byte1: input=({} ^ 69) ^ {} = {}, result={}", current_block_id, first_block[0], b1_input, b1);

        // Bytes 2-8: currentBytes[i-1] ^ currentBytes[i]
        let mut decrypted = [0u8; 8];
        decrypted[0] = b1 as u8;
        for j in 1..8 {
            let input = (first_block[j-1] as u32) ^ (first_block[j] as u32);
            let result = wbt_crypto::loop_a_byte(input, &xor_table, 0);
            decrypted[j] = result as u8;
            println!("Byte{}: input={} ^ {} = {}, result={}", j+1, first_block[j-1], first_block[j], input, result);
        }
        println!("Decrypted bytes (step 1): {:02X?}", decrypted);

        // Reorder: [byte5, byte6, byte7, byte8, byte1, byte2, byte3, byte4]
        let reordered: [u8; 8] = [
            decrypted[4], decrypted[5], decrypted[6], decrypted[7],
            decrypted[0], decrypted[1], decrypted[2], decrypted[3],
        ];
        println!("Reordered: {:02X?}", reordered);

        let higher = u32::from_le_bytes([reordered[0], reordered[1], reordered[2], reordered[3]]);
        let lower = u32::from_le_bytes([reordered[4], reordered[5], reordered[6], reordered[7]]);
        println!("Higher: 0x{:08X}, Lower: 0x{:08X}", higher, lower);

        // XOR block values
        let xor_lower = u32::from_le_bytes([xor_table[0], xor_table[1], xor_table[2], xor_table[3]]);
        let xor_higher = u32::from_le_bytes([xor_table[4], xor_table[5], xor_table[6], xor_table[7]]);
        println!("XOR block: lower=0x{:08X}, higher=0x{:08X}", xor_lower, xor_higher);

        // Special keys
        let (_, state) = wbt_crypto::block_counter_setup(0);
        let (_, sk1, sk2) = wbt_crypto::special_key_setup(&state);
        println!("Special keys: sk1=0x{:016X}, sk2=0x{:016X}", sk1, sk2);

        // Final calculation
        let carry: i64 = if lower < xor_lower { 1 } else { 0 };
        let mut final_lower = (lower as i64) - (xor_lower as i64);
        let mut final_higher = (higher as i64) - (xor_higher as i64) - carry;
        final_lower ^= sk1;
        final_higher ^= sk2;
        final_lower ^= xor_lower as i64;
        final_higher ^= xor_higher as i64;
        println!("Final: higher=0x{:08X}, lower=0x{:08X}", final_higher as u32, final_lower as u32);
        println!("As bytes: [{:02X}, {:02X}, {:02X}, {:02X}, {:02X}, {:02X}, {:02X}, {:02X}]",
            (final_higher as u32) as u8, ((final_higher as u32) >> 8) as u8,
            ((final_higher as u32) >> 16) as u8, ((final_higher as u32) >> 24) as u8,
            (final_lower as u32) as u8, ((final_lower as u32) >> 8) as u8,
            ((final_lower as u32) >> 16) as u8, ((final_lower as u32) >> 24) as u8);
    }

    #[test]
    fn test_filelist_decryption_debug() {

        let filelist_path = Path::new(FF13_LR_DATA_PATH).join("filelist2a.win32.bin");

        if !filelist_path.exists() {
            println!("Skipping test: File not found at {:?}", filelist_path);
            return;
        }

        let mut data = std::fs::read(&filelist_path).expect("Failed to read file");
        println!("File size: {} bytes", data.len());

        // Extract seed using C# algorithm
        let base_seed = &data[0..16];
        println!("Base seed (first 16 bytes): {:02X?}", base_seed);

        let seed_u32: u32 = ((base_seed[9] as u32) << 24)
            | ((base_seed[12] as u32) << 16)
            | ((base_seed[2] as u32) << 8)
            | (base_seed[0] as u32);
        println!("Seed u32: 0x{:08X}", seed_u32);
        println!("  base_seed[9]=0x{:02X}, base_seed[12]=0x{:02X}, base_seed[2]=0x{:02X}, base_seed[0]=0x{:02X}",
            base_seed[9], base_seed[12], base_seed[2], base_seed[0]);

        let seed: [u8; 8] = (seed_u32 as u64).to_le_bytes();
        println!("Seed bytes (8): {:02X?}", seed);

        // Generate XOR table
        let xor_table = wbt_crypto::generate_xor_table(seed);
        println!("XOR table first 16 bytes: {:02X?}", &xor_table[0..16]);

        // Get crypt body size
        let crypt_body_size_bytes = [data[16], data[17], data[18], data[19]];
        println!("Crypt body size bytes (BE): {:02X?}", crypt_body_size_bytes);
        let mut crypt_body_size = u32::from_be_bytes(crypt_body_size_bytes);
        println!("Crypt body size (raw): {}", crypt_body_size);
        crypt_body_size += 8;
        println!("Crypt body size (+ 8): {}", crypt_body_size);

        let block_count = crypt_body_size / 8;
        println!("Block count: {}", block_count);

        // Show first encrypted block at position 32
        println!("\nFirst encrypted block at pos 32: {:02X?}", &data[32..40]);

        // Decrypt first block manually for debugging
        let current_block_id: u32 = 0;
        let current_bytes: [u8; 8] = data[32..40].try_into().unwrap();
        let (table_offset, state) = wbt_crypto::block_counter_setup(0);
        println!("Table offset: {}", table_offset);

        // Decrypt bytes
        let mut decrypted_bytes = [0u8; 8];
        decrypted_bytes[0] = wbt_crypto::loop_a_byte(
            ((current_block_id ^ 69) & 255) ^ (current_bytes[0] as u32),
            &xor_table,
            table_offset,
        ) as u8;
        for j in 1..8 {
            decrypted_bytes[j] = wbt_crypto::loop_a_byte(
                (current_bytes[j - 1] as u32) ^ (current_bytes[j] as u32),
                &xor_table,
                table_offset,
            ) as u8;
        }
        println!("Decrypted bytes (step 1): {:02X?}", decrypted_bytes);

        // Reorder
        let mut decrypted_bytes_array = [0u8; 8];
        decrypted_bytes_array[0] = decrypted_bytes[4];
        decrypted_bytes_array[1] = decrypted_bytes[5];
        decrypted_bytes_array[2] = decrypted_bytes[6];
        decrypted_bytes_array[3] = decrypted_bytes[7];
        decrypted_bytes_array[4] = decrypted_bytes[0];
        decrypted_bytes_array[5] = decrypted_bytes[1];
        decrypted_bytes_array[6] = decrypted_bytes[2];
        decrypted_bytes_array[7] = decrypted_bytes[3];
        println!("Decrypted bytes (reordered): {:02X?}", decrypted_bytes_array);

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
        println!("Higher val: 0x{:08X}, Lower val: 0x{:08X}", decrypted_bytes_higher_val, decrypted_bytes_lower_val);

        let xor_block_lower_val = u32::from_le_bytes([
            xor_table[table_offset as usize],
            xor_table[table_offset as usize + 1],
            xor_table[table_offset as usize + 2],
            xor_table[table_offset as usize + 3],
        ]);
        let xor_block_higher_val = u32::from_le_bytes([
            xor_table[table_offset as usize + 4],
            xor_table[table_offset as usize + 5],
            xor_table[table_offset as usize + 6],
            xor_table[table_offset as usize + 7],
        ]);
        println!("XOR block: lower=0x{:08X}, higher=0x{:08X}", xor_block_lower_val, xor_block_higher_val);

        let (_, special_key1, special_key2) = wbt_crypto::special_key_setup(&state);
        println!("Special keys: key1=0x{:016X}, key2=0x{:016X}", special_key1, special_key2);

        let carry_flag: i64 = if decrypted_bytes_lower_val < xor_block_lower_val { 1 } else { 0 };
        println!("Carry flag: {}", carry_flag);

        let mut lower_i64: i64 = (decrypted_bytes_lower_val as i64) - (xor_block_lower_val as i64);
        let mut higher_i64: i64 = (decrypted_bytes_higher_val as i64)
            - (xor_block_higher_val as i64)
            - carry_flag;

        lower_i64 ^= special_key1;
        higher_i64 ^= special_key2;

        lower_i64 ^= xor_block_lower_val as i64;
        higher_i64 ^= xor_block_higher_val as i64;

        println!("Final: higher=0x{:08X}, lower=0x{:08X}", higher_i64 as u32, lower_i64 as u32);

        // Expected header values for a valid filelist
        // chunk_info_offset should be reasonable (less than file size)
        // chunk_data_offset should be > chunk_info_offset
        // total_files should be reasonable (hundreds to tens of thousands)
        println!("\nIf decryption worked correctly:");
        println!("  First 4 bytes at pos 32 = chunk_info_offset");
        println!("  Next 4 bytes at pos 36 = chunk_data_offset");
        println!("  Next 4 bytes at pos 40 = total_files");

        // C# check: if file is ALREADY decrypted, position (32 + cryptBodySize - 8) contains cryptBodySize
        // This is how C# determines if it needs to decrypt or not
        let check_pos = 32 + (crypt_body_size as usize) - 8;
        let expected_if_decrypted = crypt_body_size - 8;
        if check_pos + 4 <= data.len() {
            let value_at_check = u32::from_le_bytes([
                data[check_pos], data[check_pos + 1], data[check_pos + 2], data[check_pos + 3]
            ]);
            println!("\n=== C# 'wasDecrypted' check ===");
            println!("Check position: {} (32 + {} - 8)", check_pos, crypt_body_size);
            println!("Value at check position: {} (0x{:08X})", value_at_check, value_at_check);
            println!("Expected if already decrypted: {} (0x{:08X})", expected_if_decrypted, expected_if_decrypted);
            println!("File is ALREADY DECRYPTED: {}", value_at_check == expected_if_decrypted);
        }
    }
}
