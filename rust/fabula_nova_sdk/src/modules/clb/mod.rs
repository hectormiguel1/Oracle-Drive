//! # CLB Module - Compiled Bytecode Handler
//!
//! This module handles CLB (Compiled bytecode) files, which contain encrypted
//! game scripts in Final Fantasy XIII. CLB files are essentially encrypted
//! Java .class files used by the game's scripting engine.
//!
//! ## CLB File Format
//!
//! ```text
//! ┌─────────────────────────────────────────────────────────────┐
//! │ Seed (8 bytes) - Used to generate XOR table                  │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Encrypted Body (N bytes, must be 8-byte aligned)             │
//! │   - Block cipher: 8-byte blocks                              │
//! │   - XOR-based encryption with byte rearrangement             │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Checksum (4 bytes) - Integrity verification                  │
//! │ Padding (4 bytes)                                            │
//! └─────────────────────────────────────────────────────────────┘
//! ```
//!
//! ## Encryption Algorithm
//!
//! 1. Generate 264-byte XOR table from 8-byte seed
//! 2. Process body in 8-byte blocks
//! 3. Each block: XOR → byte rearrangement → special key operations
//! 4. Append checksum footer for integrity verification
//!
//! ## Submodules
//!
//! - [`converter`] - CLB ↔ Java class file conversion
//! - [`crypto`] - XOR table generation and block cipher operations
//!
//! ## Usage
//!
//! Use via the [`crate::modules::wct`] dispatcher or directly:
//!
//! ```rust,ignore
//! use fabula_nova_sdk::modules::clb;
//! use fabula_nova_sdk::modules::wct::Action;
//!
//! // Decrypt CLB file
//! clb::process_clb(Action::Decrypt, Path::new("script.clb"))?;
//!
//! // Convert to Java class for decompilation
//! clb::process_clb(Action::ClbToJava, Path::new("script.clb"))?;
//! ```

pub mod converter;
pub mod crypto;

use crate::modules::wct::Action;
use crate::modules::wct::Result as WctResult;
use crate::modules::wct::WctError;
use log::info;
use std::fs::{self, File};
use std::io::{Read, Write};
use std::path::Path;

/// Process a CLB file with the specified action.
///
/// This is the main entry point for CLB file operations. It handles:
/// - Decryption/encryption of CLB files
/// - Conversion between CLB and Java .class formats
///
/// # Arguments
/// * `action` - The operation to perform
/// * `input_path` - Path to the CLB file
///
/// # Returns
/// `Ok(())` on success, or an error describing the failure.
pub fn process_clb(action: Action, input_path: &Path) -> WctResult<()> {
    info!("[CLB] Processing: {:?} Action: {:?}", input_path, action);

    if let Action::JavaToClb = action {
        let output_path = input_path.with_extension("clb");
        return converter::java_to_clb(input_path, &output_path)
            .map_err(|e| WctError::Crypto(e.to_string()));
    }

    if let Action::ClbToJava = action {
        let output_path = input_path.with_extension("class");
        return converter::clb_to_java(input_path, &output_path)
            .map_err(|e| WctError::Crypto(e.to_string()));
    }

    let mut file = File::open(input_path).map_err(WctError::Io)?;
    let file_len = file.metadata().map_err(WctError::Io)?.len();

    if file_len < 8 {
        return Err(WctError::Validation("File too small for CLB".into()));
    }

    let mut seed = [0u8; 8];
    file.read_exact(&mut seed).map_err(WctError::Io)?;

    let crypt_body_size = (file_len - 8) as u32;
    if crypt_body_size % 8 != 0 {
        return Err(WctError::Validation(
            "Length of the body is not valid".into(),
        ));
    }

    // Use local crypto
    let xor_table = crypto::generate_xor_table(seed);

    match action {
        Action::Decrypt => decrypt_clb(input_path, &xor_table, crypt_body_size),
        Action::Encrypt => encrypt_clb(input_path, &xor_table, crypt_body_size),
        _ => Ok(()),
    }
}

fn decrypt_clb(input_path: &Path, xor_table: &[u8; 264], crypt_body_size: u32) -> WctResult<()> {
    info!("[CLB] Starting decryption for {:?}", input_path);
    let mut in_file = File::open(input_path).map_err(WctError::Io)?;
    // Create temp output path - append .tmp to avoid overwriting input
    // Note: with_extension("dec").with_extension("clb") would return the SAME path as input!
    let out_path = input_path.with_extension("clb.tmp");
    let mut out_file = File::create(&out_path).map_err(WctError::Io)?;

    let mut header = [0u8; 8];
    in_file.read_exact(&mut header).map_err(WctError::Io)?;
    out_file.write_all(&header).map_err(WctError::Io)?;

    let block_count = crypt_body_size / 8;
    let mut block_counter: u32 = 0;

    for _ in 0..block_count {
        let current_block_id = block_counter >> 3;
        let mut current_bytes = [0u8; 8];
        in_file
            .read_exact(&mut current_bytes)
            .map_err(WctError::Io)?;

        let (table_offset, state) = crypto::block_counter_setup(block_counter);

        let mut decrypted_bytes = [0u8; 8];
        decrypted_bytes[0] = crypto::loop_a_byte(
            ((current_block_id ^ 69) & 255) ^ (current_bytes[0] as u32),
            xor_table,
            table_offset,
        ) as u8;
        for j in 1..8 {
            decrypted_bytes[j] = crypto::loop_a_byte(
                (current_bytes[j - 1] as u32) ^ (current_bytes[j] as u32),
                xor_table,
                table_offset,
            ) as u8;
        }

        let mut decrypted_bytes_array = [0u8; 8];
        decrypted_bytes_array[0] = decrypted_bytes[4];
        decrypted_bytes_array[1] = decrypted_bytes[5];
        decrypted_bytes_array[2] = decrypted_bytes[6];
        decrypted_bytes_array[3] = decrypted_bytes[7];
        decrypted_bytes_array[4] = decrypted_bytes[0];
        decrypted_bytes_array[5] = decrypted_bytes[1];
        decrypted_bytes_array[6] = decrypted_bytes[2];
        decrypted_bytes_array[7] = decrypted_bytes[3];

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

        let (_, special_key1, special_key2) = crypto::special_key_setup(&state);

        // Compare u32 values for carry flag (matches C# behavior)
        let carry_flag: i64 = if decrypted_bytes_lower_val < xor_block_lower_val {
            1
        } else {
            0
        };

        // Subtraction must be done on i64 values to preserve sign extension
        // C#: decryptedBytesLongLowerVal -= xorBlockLowerVal; (on i64)
        // This can produce negative values which affects the XOR operations
        let mut lower_i64: i64 = (decrypted_bytes_lower_val as i64) - (xor_block_lower_val as i64);
        let mut higher_i64: i64 = (decrypted_bytes_higher_val as i64)
            - (xor_block_higher_val as i64)
            - carry_flag;

        lower_i64 ^= special_key1;
        higher_i64 ^= special_key2;

        lower_i64 ^= xor_block_lower_val as i64;
        higher_i64 ^= xor_block_higher_val as i64;

        out_file
            .write_all(&(higher_i64 as u32).to_le_bytes())
            .map_err(WctError::Io)?;
        out_file
            .write_all(&(lower_i64 as u32).to_le_bytes())
            .map_err(WctError::Io)?;

        block_counter += 8;
    }

    drop(in_file);
    drop(out_file);
    fs::rename(&out_path, input_path).map_err(WctError::Io)?;
    Ok(())
}

fn encrypt_clb(input_path: &Path, xor_table: &[u8; 264], crypt_body_size: u32) -> WctResult<()> {
    info!("[CLB] Starting encryption for {:?}", input_path);
    let mut in_file = File::open(input_path).map_err(WctError::Io)?;
    let tmp_path = input_path.with_extension("tmp");
    let mut tmp_file = File::create(&tmp_path).map_err(WctError::Io)?;

    let mut header = [0u8; 8];
    in_file.read_exact(&mut header).map_err(WctError::Io)?;
    tmp_file.write_all(&header).map_err(WctError::Io)?;

    let mut body = vec![0u8; (crypt_body_size - 8) as usize];
    in_file.read_exact(&mut body).map_err(WctError::Io)?;
    tmp_file.write_all(&body).map_err(WctError::Io)?;

    let mut last_4_bytes = [0u8; 4];
    in_file
        .read_exact(&mut last_4_bytes)
        .map_err(WctError::Io)?;
    tmp_file.write_all(&last_4_bytes).map_err(WctError::Io)?;

    let checksum = crypto::compute_checksum(&body);
    tmp_file
        .write_all(&checksum.to_le_bytes())
        .map_err(WctError::Io)?;
    drop(tmp_file);

    let mut in_tmp_file = File::open(&tmp_path).map_err(WctError::Io)?;
    let enc_path = input_path.with_extension("enc");
    let mut enc_file = File::create(&enc_path).map_err(WctError::Io)?;

    in_tmp_file.read_exact(&mut header).map_err(WctError::Io)?;
    enc_file.write_all(&header).map_err(WctError::Io)?;

    let block_count = crypt_body_size / 8;
    let mut block_counter: u32 = 0;

    for _ in 0..block_count {
        let current_block_id = block_counter >> 3;
        let mut bytes_to_encrypt = [0u8; 8];
        in_tmp_file
            .read_exact(&mut bytes_to_encrypt)
            .map_err(WctError::Io)?;

        let bytes_to_encrypt_lower_array = [
            bytes_to_encrypt[7],
            bytes_to_encrypt[6],
            bytes_to_encrypt[5],
            bytes_to_encrypt[4],
        ];
        let bytes_to_encrypt_higher_array = [
            bytes_to_encrypt[3],
            bytes_to_encrypt[2],
            bytes_to_encrypt[1],
            bytes_to_encrypt[0],
        ];

        let mut bytes_to_encrypt_lower_val = crypto::array_to_ff_num(&bytes_to_encrypt_lower_array);
        let mut bytes_to_encrypt_higher_val =
            crypto::array_to_ff_num(&bytes_to_encrypt_higher_array);

        let (table_offset, state) = crypto::block_counter_setup(block_counter);
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

        let (_, special_key1, special_key2) = crypto::special_key_setup(&state);

        bytes_to_encrypt_lower_val ^= xor_block_lower_val as i64;
        bytes_to_encrypt_higher_val ^= xor_block_higher_val as i64;
        bytes_to_encrypt_lower_val ^= special_key1;
        bytes_to_encrypt_higher_val ^= special_key2;

        bytes_to_encrypt_lower_val =
            (bytes_to_encrypt_lower_val as u32).wrapping_add(xor_block_lower_val) as i64;
        bytes_to_encrypt_higher_val =
            (bytes_to_encrypt_higher_val as u32).wrapping_add(xor_block_higher_val) as i64;

        let carry_flag = if (bytes_to_encrypt_lower_val as u32) < xor_block_lower_val {
            1
        } else {
            0
        };
        bytes_to_encrypt_higher_val =
            (bytes_to_encrypt_higher_val as u32).wrapping_add(carry_flag) as i64;

        let mut computed_bytes_array = [0u8; 8];
        computed_bytes_array[0..4]
            .copy_from_slice(&(bytes_to_encrypt_lower_val as u32).to_le_bytes());
        computed_bytes_array[4..8]
            .copy_from_slice(&(bytes_to_encrypt_higher_val as u32).to_le_bytes());

        let mut encrypted_bytes = [0u8; 8];
        encrypted_bytes[0] =
            crypto::loop_a_byte_reverse(computed_bytes_array[0], xor_table, table_offset);
        encrypted_bytes[0] ^= ((current_block_id ^ 69) & 255) as u8;

        for j in 1..8 {
            encrypted_bytes[j] =
                crypto::loop_a_byte_reverse(computed_bytes_array[j], xor_table, table_offset);
            encrypted_bytes[j] ^= encrypted_bytes[j - 1];
        }

        enc_file.write_all(&encrypted_bytes).map_err(WctError::Io)?;
        block_counter += 8;
    }

    drop(in_tmp_file);
    drop(enc_file);
    fs::remove_file(&tmp_path).map_err(WctError::Io)?;
    fs::rename(&enc_path, input_path).map_err(WctError::Io)?;
    Ok(())
}
