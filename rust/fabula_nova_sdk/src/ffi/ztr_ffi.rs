//! # ZTR FFI Bindings
//!
//! C-compatible interface for ZTR text resource operations.
//!
//! ## Functions Overview
//!
//! | Function            | Description                                    |
//! |---------------------|------------------------------------------------|
//! | `ztr_init`          | Initialize logging subsystem                   |
//! | `ztr_extract`       | Extract ZTR to text file                       |
//! | `ztr_extract_data`  | Parse ZTR and return data structure            |
//! | `ztr_free_result`   | Free allocated ZTR result data                 |
//! | `ztr_pack_data`     | Pack in-memory entries to ZTR file             |
//! | `ztr_dump_data`     | Write entries to text file                     |
//! | `ztr_convert`       | Convert text file to ZTR                       |
//!
//! ## Memory Lifecycle
//!
//! ```text
//! ztr_extract_data()           ztr_free_result()
//!        │                            │
//!        ▼                            ▼
//! ┌─────────────┐              ┌─────────────┐
//! │  Allocate   │──────────────│   Free      │
//! │  ZtrResult  │   use data   │  ZtrResult  │
//! │  + entries  │              │  + entries  │
//! └─────────────┘              └─────────────┘
//! ```

use std::ffi::{c_char, CString, CStr};
use std::ptr;
use crate::modules::ztr::{api, key_dicts::GameCode, structs::{ZtrEntryC, ZtrResultDataC}};
use crate::core::logging::init_logger;

/// Initializes the logging subsystem.
///
/// Call this once at application startup before using other ZTR functions.
/// Safe to call multiple times (subsequent calls are no-ops).
#[no_mangle]
pub extern "C" fn ztr_init() {
    let _ = init_logger();
}

/// Extracts a ZTR file to a text file.
///
/// # Arguments
///
/// * `in_file_ptr` - Path to input ZTR file (null-terminated)
/// * `game_code` - Game identifier: 0=FF13_1, 1=FF13_2, 2=FF13_3
/// * `encoding_switch` - Reserved for future encoding options
///
/// # Returns
///
/// * `0` - Success
/// * `1` - Null pointer argument
/// * `99` - Error during extraction
///
/// # Output
///
/// Creates a `.txt` file with the same base name as the input.
#[no_mangle]
pub unsafe extern "C" fn ztr_extract(
    in_file_ptr: *const c_char,
    _game_code: i32,
    _encoding_switch: i32
) -> i32 {
    if in_file_ptr.is_null() { return 1; }
    let in_file = match CStr::from_ptr(in_file_ptr).to_str() {
        Ok(s) => s,
        Err(_) => return 99,
    };
    
    // Assuming out_file is implied (txt) for this legacy C# signature?
    // C# `ExtractProcess` derives out file.
    // Rust API `extract_ztr_to_text` takes both.
    // We'll mimic C# logic: replace extension with .txt
    let path = std::path::Path::new(in_file);
    let out_path = path.with_extension("txt");

    let gc = match _game_code {
        0 => GameCode::FF13_1,
        1 => GameCode::FF13_2,
        2 => GameCode::FF13_3,
        _ => GameCode::FF13_1,
    };
    
    if let Err(e) = api::extract_ztr_to_text(path, &out_path, gc) {
        log::error!("Error extracting ZTR: {:?}", e);
        return 99;
    }
    
    0
}

/// Parses a ZTR file and returns structured data.
///
/// # Arguments
///
/// * `in_file_ptr` - Path to input ZTR file
/// * `game_code` - Game identifier: 0=FF13_1, 1=FF13_2, 2=FF13_3
/// * `encoding_switch` - Reserved for future encoding options
///
/// # Returns
///
/// * Non-null pointer to `ZtrResultDataC` on success
/// * Null pointer on error
///
/// # Memory
///
/// **Caller must call `ztr_free_result()` to free the returned data.**
///
/// The returned structure contains:
/// - `entries`: Array of `ZtrEntryC` (id + text pairs)
/// - `entry_count`: Number of entries
#[no_mangle]
pub unsafe extern "C" fn ztr_extract_data(
    in_file_ptr: *const c_char,
    game_code: i32,
    _encoding_switch: i32
) -> *mut ZtrResultDataC {
    if in_file_ptr.is_null() { return ptr::null_mut(); }
    let in_file = match CStr::from_ptr(in_file_ptr).to_str() {
        Ok(s) => s,
        Err(_) => return ptr::null_mut(),
    };
    
    let gc = match game_code {
        0 => GameCode::FF13_1,
        1 => GameCode::FF13_2,
        2 => GameCode::FF13_3,
        _ => GameCode::FF13_1,
    };
    
    match api::parse_ztr(in_file, gc) {
        Ok(data) => {
            // Marshal to C Struct
            // This requires allocating pointers that C will likely NOT free individually if we follow the C# logic (flat memory block).
            // But we can return a standard C-compatible struct and expect C to call a free function.
            // C# `MarshalToNative` allocates ONE block.
            // We can do similar or just use standard heap allocs and a free function.
            // Given I'm rewriting the native layer, standard heap is easier.
            
            let mut entries_c = Vec::new();
            for e in data.entries {
                entries_c.push(ZtrEntryC {
                    id: CString::new(e.id).unwrap().into_raw(),
                    text: CString::new(e.text).unwrap().into_raw(),
                });
            }
            
            // leak the vector buffer
            entries_c.shrink_to_fit();
            let entry_count = entries_c.len() as i32;
            let entries_ptr = entries_c.as_mut_ptr();
            std::mem::forget(entries_c);
            
            let result = Box::new(ZtrResultDataC {
                entries: entries_ptr,
                entry_count,
                mappings: ptr::null_mut(),
                mapping_count: 0,
            });
            
            Box::into_raw(result)
        },
        Err(e) => {
            log::error!("Error parsing ZTR: {:?}", e);
            ptr::null_mut()
        }
    }
}

/// Frees memory allocated by `ztr_extract_data`.
///
/// # Safety
///
/// * `ptr` must be a valid pointer returned by `ztr_extract_data`
/// * `ptr` must not have been freed already
/// * After calling, the pointer is invalid and must not be used
///
/// # Arguments
///
/// * `ptr` - Pointer to `ZtrResultDataC` to free (may be null)
#[no_mangle]
pub unsafe extern "C" fn ztr_free_result(ptr: *mut ZtrResultDataC) {
    if ptr.is_null() { return; }
    let data = Box::from_raw(ptr);
    
    // Free Entries
    if !data.entries.is_null() {
        let entries = Vec::from_raw_parts(data.entries, data.entry_count as usize, data.entry_count as usize);
        for e in entries {
            let _ = CString::from_raw(e.id);
            let _ = CString::from_raw(e.text);
        }
    }
    // Mappings ignored for now
}

/// Packs in-memory ZTR data to a file.
///
/// # Arguments
///
/// * `data_ptr` - Pointer to `ZtrResultDataC` containing entries
/// * `out_file_ptr` - Output ZTR file path
/// * `game_code` - Game identifier: 0=FF13_1, 1=FF13_2, 2=FF13_3
/// * `encoding_switch` - Reserved for future encoding options
/// * `action_switch` - Reserved for future action options
///
/// # Returns
///
/// * `0` - Success
/// * `1` - Null pointer argument
/// * `99` - Error during packing
#[no_mangle]
pub unsafe extern "C" fn ztr_pack_data(
    data_ptr: *const ZtrResultDataC,
    out_file_ptr: *const c_char,
    _game_code: i32,
    _encoding_switch: i32,
    _action_switch: i32
) -> i32 {
    if data_ptr.is_null() || out_file_ptr.is_null() { return 1; }
    
    let out_file = match CStr::from_ptr(out_file_ptr).to_str() {
        Ok(s) => s,
        Err(_) => return 99,
    };
    
    let data = &*data_ptr;
    let mut entries = Vec::new();
    
    if !data.entries.is_null() {
        let entries_slice = std::slice::from_raw_parts(data.entries, data.entry_count as usize);
        for e in entries_slice {
            let id = CStr::from_ptr(e.id).to_string_lossy().to_string();
            let text = CStr::from_ptr(e.text).to_string_lossy().to_string();
            entries.push((id, text));
        }
    }

    let gc = match _game_code {
        0 => GameCode::FF13_1,
        1 => GameCode::FF13_2,
        2 => GameCode::FF13_3,
        _ => GameCode::FF13_1,
    };
    
    if let Err(e) = api::pack_ztr_from_memory(&entries, out_file, gc) {
        log::error!("Error packing ZTR: {:?}", e);
        return 99;
    }
    
    0
}

/// Writes ZTR entries to a text file.
///
/// Unlike `ztr_pack_data`, this writes a human-readable text format
/// rather than binary ZTR format.
///
/// # Arguments
///
/// * `data_ptr` - Pointer to `ZtrResultDataC` containing entries
/// * `out_file_ptr` - Output text file path
///
/// # Returns
///
/// * `0` - Success
/// * `1` - Null pointer argument
/// * `99` - Error during dump
#[no_mangle]
pub unsafe extern "C" fn ztr_dump_data(
    data_ptr: *const ZtrResultDataC,
    out_file_ptr: *const c_char
) -> i32 {
    if data_ptr.is_null() || out_file_ptr.is_null() { return 1; }
    
    let out_file = match CStr::from_ptr(out_file_ptr).to_str() {
        Ok(s) => s,
        Err(_) => return 99,
    };
    
    let data = &*data_ptr;
    let mut entries = Vec::new();
    
    if !data.entries.is_null() {
        let entries_slice = std::slice::from_raw_parts(data.entries, data.entry_count as usize);
        for e in entries_slice {
            let id = CStr::from_ptr(e.id).to_string_lossy().to_string();
            let text = CStr::from_ptr(e.text).to_string_lossy().to_string();
            entries.push((id, text));
        }
    }
    
    if let Err(e) = api::write_ztr_text_file(&entries, out_file) {
        log::error!("Error dumping ZTR data: {:?}", e);
        return 99;
    }
    
    0
}

/// Converts a text file to ZTR format.
///
/// This is the inverse of `ztr_extract`. It reads a text file with
/// id/text pairs and produces a binary ZTR file.
///
/// # Arguments
///
/// * `in_file_ptr` - Path to input text file
/// * `game_code` - Game identifier: 0=FF13_1, 1=FF13_2, 2=FF13_3
/// * `encoding_switch` - Reserved for future encoding options
/// * `action_switch` - Reserved for future action options
///
/// # Returns
///
/// * `0` - Success
/// * `1` - Null pointer argument
/// * `99` - Error during conversion
///
/// # Output
///
/// Creates a `.ztr` file with the same base name as the input.
#[no_mangle]
pub unsafe extern "C" fn ztr_convert(
    in_file_ptr: *const c_char,
    _game_code: i32,
    _encoding_switch: i32,
    _action_switch: i32
) -> i32 {
    if in_file_ptr.is_null() { return 1; }
    let in_file = match CStr::from_ptr(in_file_ptr).to_str() {
        Ok(s) => s,
        Err(_) => return 99,
    };
    
    let path = std::path::Path::new(in_file);
    let out_path = path.with_extension("ztr");

    let gc = match _game_code {
        0 => GameCode::FF13_1,
        1 => GameCode::FF13_2,
        2 => GameCode::FF13_3,
        _ => GameCode::FF13_1,
    };
    
    if let Err(e) = api::pack_text_to_ztr(path, &out_path, gc) {
        log::error!("Error converting to ZTR: {:?}", e);
        return 99;
    }
    
    0
}
