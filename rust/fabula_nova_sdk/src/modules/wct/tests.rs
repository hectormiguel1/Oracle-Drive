#[cfg(test)]
mod tests {
    use crate::modules::white_clb::crypto;
    use crate::modules::white_clb::converter;
    use std::path::Path;

    #[test]
    fn test_white_clb_to_java() {
        let clb_path = Path::new("/Users/hramirez/Desktop/Development/ff13-lr_data/_white_scrv.win32.bin/sys/script/WhiteBaseClassJar/Database.clb");
        let class_path = Path::new("/tmp/Database_white.class");

        if clb_path.exists() {
            let clb_data = std::fs::read(clb_path).unwrap();
            let result = converter::clb_to_java(&clb_data);
            assert!(result.is_ok(), "WhiteCLB conversion failed: {:?}", result.err());
            let java_class = result.unwrap();
            std::fs::write(class_path, java_class).unwrap();
            println!("WhiteCLB conversion successful!");
        } else {
            println!("Skipping test: File not found at {:?}", clb_path);
        }
    }

    #[test]
    fn test_java_to_clb() {
        let class_path = Path::new("/tmp/Database_white.class");
        let clb_out_path = Path::new("/tmp/Database_converted.clb");

        if class_path.exists() {
            let result = converter::java_to_clb(class_path, clb_out_path);
            assert!(result.is_ok(), "Java to CLB conversion failed: {:?}", result.err());
            println!("Java to CLB conversion successful!");

            // Verify the output file was created
            assert!(clb_out_path.exists(), "Output CLB file was not created");

            // Verify we can convert it back to Java
            let clb_data = std::fs::read(clb_out_path).unwrap();
            let java_result = converter::clb_to_java(&clb_data);
            assert!(java_result.is_ok(), "Roundtrip CLB to Java failed: {:?}", java_result.err());

            // Write the roundtrip result
            let roundtrip_path = Path::new("/tmp/Database_roundtrip.class");
            std::fs::write(roundtrip_path, java_result.unwrap()).unwrap();
            println!("Roundtrip conversion successful!");
        } else {
            println!("Skipping test: Run test_white_clb_to_java first to create {:?}", class_path);
        }
    }

    #[test]
    fn test_white_crypto_consistency() {
        let seed = [0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0];
        let xor_table = crypto::generate_xor_table(&seed);

        // Test with a single byte value (0-255)
        let original_val = 0x44u32;
        let table_offset = 0u32;

        // Apply loop_a_byte transformation
        let transformed = crypto::loop_a_byte(original_val, &xor_table, table_offset);

        // Apply reverse transformation
        let recovered = crypto::loop_a_byte_reverse(transformed, &xor_table, table_offset);

        // Verify roundtrip
        assert_eq!(original_val as u8, recovered as u8, "loop_a_byte roundtrip failed");
        println!("Crypto roundtrip: {} -> {} -> {}", original_val, transformed, recovered);
    }

    #[test]
    fn test_clb_encrypt_decrypt_roundtrip() {
        use crate::modules::white_clb;

        let clb_path = Path::new("/tmp/Database_converted.clb");

        if clb_path.exists() {
            // Read the unencrypted CLB
            let original_data = std::fs::read(clb_path).unwrap();

            // Clone and encrypt
            let mut encrypted_data = original_data.clone();
            white_clb::encrypt_clb(&mut encrypted_data);

            // Verify encrypted data is different from original (at least in the body)
            assert_ne!(original_data[8..16], encrypted_data[8..16],
                "Encrypted data should differ from original");

            // Clone encrypted and decrypt
            let mut decrypted_data = encrypted_data.clone();
            // Need to access private decrypt_clb, so we'll simulate it via process_clb
            // For testing, let's manually call the decryption logic
            {
                let file_len = decrypted_data.len();
                let seed: [u8; 8] = decrypted_data[0..8].try_into().unwrap();
                let xor_table = crypto::generate_xor_table(&seed);

                let body_size = file_len - 16;
                let block_count = body_size / 8;

                let mut read_pos = 8usize;
                let mut block_counter = 0u32;

                for _ in 0..block_count {
                    let block: [u8; 8] = decrypted_data[read_pos..read_pos + 8].try_into().unwrap();
                    let table_offset = crypto::get_table_offset(block_counter);

                    let mut v4 = (0x45 ^ (block[0] as u32)) & 0xFF;
                    v4 = crypto::loop_a_byte(v4, &xor_table, table_offset);

                    let mut v5 = (block[0] ^ block[1]) as u32;
                    v5 = crypto::loop_a_byte(v5, &xor_table, table_offset);

                    let mut v6 = (block[1] ^ block[2]) as u32;
                    v6 = crypto::loop_a_byte(v6, &xor_table, table_offset);

                    let mut v7 = (block[2] ^ block[3]) as u32;
                    v7 = crypto::loop_a_byte(v7, &xor_table, table_offset);

                    let mut v8 = (block[3] ^ block[4]) as u32;
                    v8 = crypto::loop_a_byte(v8, &xor_table, table_offset);

                    let mut v9 = (block[4] ^ block[5]) as u32;
                    v9 = crypto::loop_a_byte(v9, &xor_table, table_offset);

                    let mut v10 = (block[5] ^ block[6]) as u32;
                    v10 = crypto::loop_a_byte(v10, &xor_table, table_offset);

                    let mut v11 = (block[6] ^ block[7]) as u32;
                    v11 = crypto::loop_a_byte(v11, &xor_table, table_offset);

                    let decrypted: [u8; 8] = [
                        v8 as u8, v9 as u8, v10 as u8, v11 as u8,
                        v4 as u8, v5 as u8, v6 as u8, v7 as u8,
                    ];

                    decrypted_data[read_pos..read_pos + 8].copy_from_slice(&decrypted);
                    read_pos += 8;
                    block_counter += 8;
                }
            }

            // Compare body (skip first 8 bytes seed and last 8 bytes footer)
            let body_len = original_data.len() - 16;
            assert_eq!(
                &original_data[8..8 + body_len],
                &decrypted_data[8..8 + body_len],
                "Encryption/decryption roundtrip failed - body doesn't match"
            );

            println!("CLB encryption/decryption roundtrip successful!");
        } else {
            println!("Skipping test: Run test_java_to_clb first to create {:?}", clb_path);
        }
    }
}
