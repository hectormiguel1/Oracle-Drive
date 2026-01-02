//! # WHITE_CLB Module - Alternative CLB Handler
//!
//! This module provides an alternative implementation for CLB file processing
//! with additional features for in-memory operations and auto-detection of
//! encryption state.
//!
//! ## Differences from CLB Module
//!
//! | Feature           | CLB Module          | WHITE_CLB Module       |
//! |-------------------|---------------------|------------------------|
//! | Processing        | File-based          | Memory-based           |
//! | Auto-detection    | No                  | Yes (via checksum)     |
//! | Integration       | Simpler crypto      | Uses CLB module's crypto|
//!
//! ## Encryption Detection
//!
//! The module detects encryption state by checking the footer checksum:
//! - If `stored_checksum == (file_length - 16)` → File is decrypted
//! - Otherwise → File is encrypted
//!
//! ## Submodules
//!
//! - [`converter`] - CLB ↔ Java conversion utilities
//! - [`crypto`] - Simplified crypto operations
//!
//! ## Usage
//!
//! ```rust,ignore
//! use fabula_nova_sdk::modules::white_clb;
//! use fabula_nova_sdk::modules::wct::Action;
//!
//! // Process CLB with auto-decryption
//! white_clb::process_clb(Action::ClbToJava, Path::new("script.clb"))?;
//! // File is automatically decrypted if needed before conversion
//! ```

pub mod converter;
pub mod crypto;

use crate::modules::clb as clb_crypto;
use crate::modules::wct::Action;
use crate::modules::wct::WctError as WhiteClbError;
use log::info;
use std::fs;
use std::path::Path;

/// Process a CLB file with automatic encryption detection.
///
/// This function provides a higher-level interface than the CLB module:
/// 1. Reads file into memory
/// 2. Detects if file is encrypted (via checksum check)
/// 3. Auto-decrypts if needed
/// 4. Performs the requested action
///
/// # Arguments
/// * `action` - The operation to perform
/// * `input_path` - Path to the CLB file
///
/// # Returns
/// `Ok(())` on success, or an error describing the failure.
pub fn process_clb(action: Action, input_path: &Path) -> Result<(), WhiteClbError> {
    info!("Processing: {:?} Action: {:?}", input_path, action);

    // JavaToClb takes a .class file as input, not a CLB - handle it separately
    if let Action::JavaToClb = action {
        let output_path = input_path.with_extension("clb");
        info!("Converting Java class to CLB at {:?}", output_path);
        return converter::java_to_clb(input_path, &output_path)
            .map_err(|e| WhiteClbError::Crypto(e.to_string()));
    }

    // For CLB file operations, read the file and check encryption
    let mut file_data = fs::read(input_path).map_err(WhiteClbError::Io)?;

    // Auto-decrypt if encrypted using the clb module's proper decryption
    if is_encrypted(&file_data) {
        info!("File is encrypted. Decrypting using CLB crypto module...");
        // Use the clb module's proper decryption (writes to file, then read back)
        clb_crypto::process_clb(Action::Decrypt, input_path)?;
        // Re-read the now-decrypted file
        file_data = fs::read(input_path).map_err(WhiteClbError::Io)?;
    }

    match action {
        Action::ClbToJava => {
            let java_class = converter::clb_to_java(&file_data)
                .map_err(|e| WhiteClbError::Crypto(e.to_string()))?;
            let output_path = input_path.with_extension("class");
            info!("Saving Java class to {:?}", output_path);
            fs::write(output_path, java_class).map_err(WhiteClbError::Io)?;
        }
        Action::JavaToClb => unreachable!(), // Handled above
        Action::Decrypt => {
            // Decryption already happened above, just save it
            let output_path = input_path.with_extension("dec.clb");
            info!("Saving decrypted file to {:?}", output_path);
            fs::write(output_path, file_data).map_err(WhiteClbError::Io)?;
        }
        Action::Encrypt => {
            // Encrypt the CLB data
            encrypt_clb(&mut file_data);
            let output_path = input_path.with_extension("enc.clb");
            info!("Saving encrypted file to {:?}", output_path);
            fs::write(output_path, file_data).map_err(WhiteClbError::Io)?;
        }
    }

    Ok(())
}

fn is_encrypted(file_data: &[u8]) -> bool {
    let file_len = file_data.len();
    if file_len < 16 {
        return false;
    }

    // Read stored checksum at offset (file_len - 8), 4 bytes LE
    let stored_checksum = u32::from_le_bytes([
        file_data[file_len - 8],
        file_data[file_len - 7],
        file_data[file_len - 6],
        file_data[file_len - 5],
    ]);

    let expected_value = (file_len - 16) as u32;
    stored_checksum != expected_value
}

fn decrypt_clb(data: &mut [u8]) {
    let file_len = data.len();
    if file_len < 16 {
        return;
    }

    // Seed from first 8 bytes
    let seed: [u8; 8] = data[0..8].try_into().unwrap();
    let xor_table = crypto::generate_xor_table(&seed);

    let body_size = file_len - 16;
    let block_count = body_size / 8;

    let mut read_pos = 8usize;
    let mut block_counter = 0u32;

    for _ in 0..block_count {
        let block: [u8; 8] = data[read_pos..read_pos + 8].try_into().unwrap();
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
            v8 as u8, v9 as u8, v10 as u8, v11 as u8, v4 as u8, v5 as u8, v6 as u8, v7 as u8,
        ];

        data[read_pos..read_pos + 8].copy_from_slice(&decrypted);
        read_pos += 8;
        block_counter += 8;
    }

    // Update footer checksum to mark file as decrypted
    // is_encrypted() checks if stored_checksum != (file_len - 16)
    // Setting it to (file_len - 16) marks the file as decrypted
    let decrypted_marker = (file_len - 16) as u32;
    data[file_len - 8..file_len - 4].copy_from_slice(&decrypted_marker.to_le_bytes());
}

/// Encrypts CLB data in place
/// The reverse of decrypt_clb
pub fn encrypt_clb(data: &mut [u8]) {
    let file_len = data.len();
    if file_len < 16 {
        return;
    }

    // Seed from first 8 bytes (should already be set in the data)
    let seed: [u8; 8] = data[0..8].try_into().unwrap();
    let xor_table = crypto::generate_xor_table(&seed);

    let body_size = file_len - 16;
    let block_count = body_size / 8;

    let mut write_pos = 8usize;
    let mut block_counter = 0u32;

    for _ in 0..block_count {
        let plain: [u8; 8] = data[write_pos..write_pos + 8].try_into().unwrap();
        let table_offset = crypto::get_table_offset(block_counter);

        // Reverse the decryption transformation
        // After decrypt: [v8, v9, v10, v11, v4, v5, v6, v7]
        // Where v4 = loop_a_byte(enc[0] ^ 0x45)
        //       v5 = loop_a_byte(enc[0] ^ enc[1])
        //       v6 = loop_a_byte(enc[1] ^ enc[2])
        //       v7 = loop_a_byte(enc[2] ^ enc[3])
        //       v8 = loop_a_byte(enc[3] ^ enc[4])
        //       v9 = loop_a_byte(enc[4] ^ enc[5])
        //       v10 = loop_a_byte(enc[5] ^ enc[6])
        //       v11 = loop_a_byte(enc[6] ^ enc[7])

        let p0 = plain[0] as u32; // was v8
        let p1 = plain[1] as u32; // was v9
        let p2 = plain[2] as u32; // was v10
        let p3 = plain[3] as u32; // was v11
        let p4 = plain[4] as u32; // was v4
        let p5 = plain[5] as u32; // was v5
        let p6 = plain[6] as u32; // was v6
        let p7 = plain[7] as u32; // was v7

        // Solve for enc[0..8] using loop_a_byte_reverse
        let enc0 = (crypto::loop_a_byte_reverse(p4, &xor_table, table_offset) ^ 0x45) as u8;
        let enc1 =
            (crypto::loop_a_byte_reverse(p5, &xor_table, table_offset) ^ (enc0 as u32)) as u8;
        let enc2 =
            (crypto::loop_a_byte_reverse(p6, &xor_table, table_offset) ^ (enc1 as u32)) as u8;
        let enc3 =
            (crypto::loop_a_byte_reverse(p7, &xor_table, table_offset) ^ (enc2 as u32)) as u8;
        let enc4 =
            (crypto::loop_a_byte_reverse(p0, &xor_table, table_offset) ^ (enc3 as u32)) as u8;
        let enc5 =
            (crypto::loop_a_byte_reverse(p1, &xor_table, table_offset) ^ (enc4 as u32)) as u8;
        let enc6 =
            (crypto::loop_a_byte_reverse(p2, &xor_table, table_offset) ^ (enc5 as u32)) as u8;
        let enc7 =
            (crypto::loop_a_byte_reverse(p3, &xor_table, table_offset) ^ (enc6 as u32)) as u8;

        let encrypted: [u8; 8] = [enc0, enc1, enc2, enc3, enc4, enc5, enc6, enc7];
        data[write_pos..write_pos + 8].copy_from_slice(&encrypted);
        write_pos += 8;
        block_counter += 8;
    }

    // Update footer checksum at offset (file_len - 8)
    // The stored checksum should NOT equal (file_len - 16) for encrypted files
    // We compute the checksum of the encrypted body
    let checksum = crypto::compute_checksum(&data[8..file_len - 8]);
    data[file_len - 8..file_len - 4].copy_from_slice(&checksum.to_le_bytes());
}
