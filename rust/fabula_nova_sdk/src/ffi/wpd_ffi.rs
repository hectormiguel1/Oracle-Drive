//! # WPD FFI Bindings
//!
//! C-compatible interface for WPD package file operations.
//!
//! ## Overview
//!
//! WPD (White Package Data) files are archive containers that bundle
//! multiple game assets together. This module provides extraction
//! and repacking functionality.
//!
//! ## Naming Convention
//!
//! The module uses a naming convention for extracted directories:
//! - `archive.wpd` extracts to `_archive.wpd/`
//! - `_archive.wpd/` repacks to `archive.wpd`
//!
//! The leading underscore indicates an extracted directory.
//!
//! ## Return Type
//!
//! Functions return `NativeResult<i32>` which provides both a result
//! value and an optional error message for better error handling.

use std::ffi::{c_char, CStr};
use crate::modules::wpd::api;
use crate::core::ffi_types::NativeResult;

/// Unpacks a WPD archive to a directory.
///
/// # Arguments
///
/// * `in_wpd_file_ptr` - Path to WPD file to extract
///
/// # Returns
///
/// `NativeResult` with:
/// - `result = 0` on success
/// - `result = -1` on null pointer
/// - `result = 2` on extraction error
///
/// # Output Directory
///
/// Creates `_{filename}/` in the same directory as the WPD file.
///
/// # Example
///
/// Input: `/path/to/data.wpd`
/// Output: `/path/to/_data.wpd/` (directory containing extracted files)
#[no_mangle]
pub unsafe extern "C" fn wpd_unpack(in_wpd_file_ptr: *const c_char) -> NativeResult<i32> {
    if in_wpd_file_ptr.is_null() {
        return NativeResult::error("in_wpd_file_ptr is null", -1);
    }

    let in_wpd_file = match CStr::from_ptr(in_wpd_file_ptr).to_str() {
        Ok(s) => s,
        Err(_) => return NativeResult::error("Invalid UTF-8 string", -1),
    };

    // Derived output dir: _fileName
    let path = std::path::Path::new(in_wpd_file);
    let file_name = path.file_name().unwrap().to_str().unwrap();
    let mut output_dir = path.parent().unwrap().to_path_buf();
    output_dir.push(format!("_{}", file_name));

    match api::unpack_wpd(in_wpd_file, output_dir.to_str().unwrap()) {
        Ok(_) => NativeResult::ok_inline(0),
        Err(e) => NativeResult::error(&format!("{:?}", e), 2),
    }
}

/// Repacks an extracted directory back to WPD format.
///
/// # Arguments
///
/// * `in_wpd_dir_ptr` - Path to extracted directory (must start with `_`)
///
/// # Returns
///
/// `NativeResult` with:
/// - `result = 0` on success
/// - `result = -1` on invalid argument
/// - `result = 2` on repacking error
///
/// # Requirements
///
/// The directory name **must** start with `_` to indicate it was extracted
/// by this tool. The output file is created by removing the leading `_`.
///
/// # Example
///
/// Input: `/path/to/_data.wpd/`
/// Output: `/path/to/data.wpd`
#[no_mangle]
pub unsafe extern "C" fn wpd_repack(in_wpd_dir_ptr: *const c_char) -> NativeResult<i32> {
    if in_wpd_dir_ptr.is_null() {
        return NativeResult::error("in_wpd_dir_ptr is null", -1);
    }

    let in_wpd_dir = match CStr::from_ptr(in_wpd_dir_ptr).to_str() {
        Ok(s) => s,
        Err(_) => return NativeResult::error("Invalid UTF-8 string", -1),
    };

    // Target WPD file: remove leading '_' from directory name
    let path = std::path::Path::new(in_wpd_dir);
    let dir_name = path.file_name().unwrap().to_str().unwrap();
    if !dir_name.starts_with('_') {
        return NativeResult::error("Directory name must start with '_' for repacking", -1);
    }
    
    let target_name = &dir_name[1..];
    let mut target_path = path.parent().unwrap().to_path_buf();
    target_path.push(target_name);

    match api::repack_wpd(in_wpd_dir, target_path.to_str().unwrap()) {
        Ok(_) => NativeResult::ok_inline(0),
        Err(e) => NativeResult::error(&format!("{:?}", e), 2),
    }
}
