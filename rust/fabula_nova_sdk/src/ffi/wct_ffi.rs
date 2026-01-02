//! # WCT FFI Bindings
//!
//! C-compatible interface for WCT (White Crypto Tool) encryption operations.
//!
//! ## Overview
//!
//! WCT provides encryption/decryption for FF13 game files. Two target
//! types are supported:
//!
//! | Target Type | Code | Description                     |
//! |-------------|------|---------------------------------|
//! | FileList    | 0    | File listing/manifest files     |
//! | CLB         | 1    | Crystal Logic Bytecode files    |
//!
//! ## Operations
//!
//! - **Decrypt**: Converts encrypted file to plaintext
//! - **Encrypt**: Converts plaintext file to encrypted format
//!
//! Output files are written alongside input with appropriate extension.

use std::ffi::{c_char, CStr};
use std::path::Path;
use crate::modules::wct::{self, TargetType, Action};

/// Decrypts an encrypted FF13 file.
///
/// # Arguments
///
/// * `target_type_raw` - Target type: 0=FileList, 1=CLB
/// * `input_file_ptr` - Path to encrypted input file
///
/// # Returns
///
/// * `0` - Success
/// * `1` - Null pointer argument
/// * `2` - Invalid target type
/// * `3` - Decryption error
///
/// # Output
///
/// Creates decrypted file alongside input (with decrypted extension).
#[no_mangle]
pub unsafe extern "C" fn decrypt(target_type_raw: i32, input_file_ptr: *const c_char) -> i32 {
    if input_file_ptr.is_null() {
        return 1;
    }
    
    let input_file = match CStr::from_ptr(input_file_ptr).to_str() {
        Ok(s) => s,
        Err(_) => return 1,
    };

    let target = match target_type_raw {
        0 => TargetType::FileList,
        1 => TargetType::Clb,
        _ => return 2,
    };

    match wct::process_file(target, Action::Decrypt, Path::new(input_file)) {
        Ok(_) => 0,
        Err(e) => {
            log::error!("WCT Decrypt Error: {:?}", e);
            3
        }
    }
}

/// Encrypts a plaintext FF13 file.
///
/// # Arguments
///
/// * `target_type_raw` - Target type: 0=FileList, 1=CLB
/// * `input_file_ptr` - Path to plaintext input file
///
/// # Returns
///
/// * `0` - Success
/// * `1` - Null pointer argument
/// * `2` - Invalid target type
/// * `3` - Encryption error
///
/// # Output
///
/// Creates encrypted file alongside input (with encrypted extension).
#[no_mangle]
pub unsafe extern "C" fn encrypt(target_type_raw: i32, input_file_ptr: *const c_char) -> i32 {
    if input_file_ptr.is_null() {
        return 1;
    }
    
    let input_file = match CStr::from_ptr(input_file_ptr).to_str() {
        Ok(s) => s,
        Err(_) => return 1,
    };

    let target = match target_type_raw {
        0 => TargetType::FileList,
        1 => TargetType::Clb,
        _ => return 2,
    };

    match wct::process_file(target, Action::Encrypt, Path::new(input_file)) {
        Ok(_) => 0,
        Err(e) => {
            log::error!("WCT Encrypt Error: {:?}", e);
            3
        }
    }
}
