//! # IMG FFI Bindings
//!
//! C-compatible interface for texture extraction and repacking.
//!
//! ## Overview
//!
//! FF13 stores textures as header/data pairs:
//! - Header file (`.txbh`, `.xgr`, `.trb`): Contains GTEX metadata
//! - Data file (`.imgb`): Contains raw pixel data
//!
//! ## Functions
//!
//! | Function              | Description                              |
//! |-----------------------|------------------------------------------|
//! | `unpack_imgb`         | Extract texture to DDS file              |
//! | `repack_imgb_strict`  | Repack DDS back to IMGB (same size)      |
//! | `repack_imgb_resize`  | Repack with potential resize (legacy)    |
//!
//! ## Workflow
//!
//! ```text
//! Extract:
//! unpack_imgb(header.txbh, data.imgb, output_dir/)
//!     → Creates output_dir/header.dds
//!
//! Repack:
//! repack_imgb_strict(header.txbh, data.imgb, extracted_dir/)
//!     → Reads extracted_dir/header.dds
//!     → Writes pixel data back to data.imgb
//! ```

use std::ffi::{c_char, CStr};
use crate::modules::img::api;

/// Extracts a texture from IMGB to DDS format.
///
/// # Arguments
///
/// * `img_header_blk_ptr` - Path to header file (.txbh, .xgr, .trb)
/// * `in_file_ptr` - Path to IMGB data file
/// * `extract_dir_ptr` - Directory to write DDS file
/// * `platform_raw` - Platform identifier (currently unused)
///
/// # Returns
///
/// * `0` - Success
/// * `1` - Error during extraction
///
/// # Output
///
/// Creates `{extract_dir}/{header_name}.dds`
#[no_mangle]
pub unsafe extern "C" fn unpack_imgb(
    img_header_blk_ptr: *const c_char,
    in_file_ptr: *const c_char,
    extract_dir_ptr: *const c_char,
    _platform_raw: i32
) -> i32 {
    let header_path = CStr::from_ptr(img_header_blk_ptr).to_str().unwrap();
    let in_file = CStr::from_ptr(in_file_ptr).to_str().unwrap();
    let extract_dir = CStr::from_ptr(extract_dir_ptr).to_str().unwrap();
    
    // Output: extract_dir/HeaderName.dds
    let header_name = std::path::Path::new(header_path).file_name().unwrap();
    let mut out_path = std::path::PathBuf::from(extract_dir);
    out_path.push(header_name);
    out_path.set_extension("dds");
    
    match api::extract_img_to_dds(header_path, in_file, out_path.to_str().unwrap()) {
        Ok(_) => 0,
        Err(e) => {
            log::error!("IMG Unpack Error: {:?}", e);
            1
        }
    }
}

/// Repacks a DDS file back into an IMGB container.
///
/// **Strict mode**: The DDS must have the exact same dimensions and
/// mipmap structure as the original texture. Pixel data is written
/// directly to the original offsets in the IMGB file.
///
/// # Arguments
///
/// * `img_header_blk_ptr` - Path to original header file
/// * `out_imgb_ptr` - Path to IMGB file to modify
/// * `extracted_dir_ptr` - Directory containing the DDS file
/// * `platform_raw` - Platform identifier (currently unused)
///
/// # Returns
///
/// * `0` - Success
/// * `1` - Error during repacking
///
/// # Warning
///
/// This modifies the IMGB file in-place. Make a backup if needed.
#[no_mangle]
pub unsafe extern "C" fn repack_imgb_strict(
    img_header_blk_ptr: *const c_char,
    out_imgb_ptr: *const c_char,
    extracted_dir_ptr: *const c_char,
    _platform_raw: i32
) -> i32 {
    let header_path = CStr::from_ptr(img_header_blk_ptr).to_str().unwrap();
    let out_imgb = CStr::from_ptr(out_imgb_ptr).to_str().unwrap();
    let extracted_dir = CStr::from_ptr(extracted_dir_ptr).to_str().unwrap();
    
    // Input DDS: extracted_dir/HeaderName.dds
    let header_name = std::path::Path::new(header_path).file_name().unwrap();
    let mut dds_path = std::path::PathBuf::from(extracted_dir);
    dds_path.push(header_name);
    dds_path.set_extension("dds");
    
    match api::repack_img_strict(header_path, out_imgb, dds_path.to_str().unwrap()) {
        Ok(_) => 0,
        Err(e) => {
            log::error!("IMG Repack Error: {:?}", e);
            1
        }
    }
}

/// Legacy repack function with resize support.
///
/// **Note**: In the current implementation, this forwards to
/// `repack_imgb_strict`. The resize functionality from the original
/// C# code is not yet ported.
///
/// # Arguments
///
/// * `tmp_img_header_blk_ptr` - Temporary header (currently ignored)
/// * `img_header_blk_ptr` - Path to original header file
/// * `out_imgb_ptr` - Path to IMGB file to modify
/// * `extracted_dir_ptr` - Directory containing the DDS file
/// * `platform_raw` - Platform identifier
///
/// # Returns
///
/// Same as `repack_imgb_strict`.
#[no_mangle]
pub unsafe extern "C" fn repack_imgb_resize(
    _tmp_img_header_blk_ptr: *const c_char,
    img_header_blk_ptr: *const c_char,
    out_imgb_ptr: *const c_char,
    extracted_dir_ptr: *const c_char,
    platform_raw: i32
) -> i32 {
    // In the legacy C# code, RepackResize just calls RepackStrict
    // (ignoring the temp header mostly or just logging it).
    // We forward to repack_imgb_strict logic.
    repack_imgb_strict(img_header_blk_ptr, out_imgb_ptr, extracted_dir_ptr, platform_raw)
}
