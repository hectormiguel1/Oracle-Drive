//! # WDB FFI Bindings
//!
//! C-compatible interface for WDB database file operations.
//!
//! ## Overview
//!
//! WDB files store game data in a binary database format with a header
//! section and multiple record sections. This FFI layer marshals Rust
//! HashMaps to C-compatible structs for cross-language access.
//!
//! ## Data Structure Mapping
//!
//! ```text
//! Rust Side                          C Side
//! ─────────────────────────────────────────────────────────
//! HashMap<String, WdbValue>   ──►    WDBSectionCInternal
//!   ├── "key1" => Int(42)            ├── entries: *WDBEntryInternal
//!   └── "key2" => String("val")      └── entry_count: i32
//! ```
//!
//! ## Value Type Mapping
//!
//! | Rust `WdbValue`     | C `WDBValueTypeC`  |
//! |---------------------|--------------------|
//! | `Int(i32)`          | `Int`              |
//! | `UInt(u32)`         | `UInt`             |
//! | `Float(f32)`        | `Float`            |
//! | `String(String)`    | `String`           |
//! | `Bool(bool)`        | `Bool`             |
//! | `IntArray(Vec)`     | `IntArray`         |
//! | `UIntArray(Vec)`    | `UIntArray`        |
//! | `StringArray(Vec)`  | `StringArray`      |
//!
//! ## Memory Management
//!
//! All allocated memory must be freed via the appropriate free function:
//! - `WDB_FreeString` for individual strings
//! - `WDB_FreeWDBFile` for complete file structures

use std::ffi::{c_char, CStr, CString};
use std::ptr;
use std::mem::ManuallyDrop;
use std::collections::HashMap;
use crate::modules::wdb::{api, structs::*};

// --- FFI EXPORTS ---

/// Frees a string allocated by the WDB module.
///
/// # Safety
///
/// `str_ptr` must be a valid pointer returned by WDB functions,
/// or null (which is a no-op).
#[no_mangle]
pub unsafe extern "C" fn WDB_FreeString(str_ptr: *mut c_char) {
    if !str_ptr.is_null() {
        let _ = CString::from_raw(str_ptr);
    }
}

/// Parses a WDB file and returns structured data.
///
/// # Arguments
///
/// * `file_path_ptr` - Path to WDB file (null-terminated)
/// * `game_code_raw` - Game identifier: 0=FF13_1, 1=FF13_2
///
/// # Returns
///
/// * Non-null pointer to `WDBFileCInternal` on success
/// * Null pointer on error
///
/// # Memory
///
/// **Caller must call `WDB_FreeWDBFile()` to free the returned data.**
///
/// The returned structure contains:
/// - `wdb_name`: File name (without extension)
/// - `header`: Header section entries
/// - `records`: Array of record sections
/// - `record_count`: Number of records
#[no_mangle]
pub unsafe extern "C" fn WDB_ParseFile(
    file_path_ptr: *const c_char,
    _game_code_raw: u8
) -> *mut WDBFileCInternal {
    if file_path_ptr.is_null() { return ptr::null_mut(); }
    
    let file_path = match CStr::from_ptr(file_path_ptr).to_str() {
        Ok(s) => s,
        Err(e) => {
            log::error!("Invalid file path string: {:?}", e);
            return ptr::null_mut();
        }
    };
    
    let gc = match _game_code_raw {
        0 => GameCode::FF13_1,
        1 => GameCode::FF13_2,
        _ => GameCode::FF13_1,
    };
    
    match api::parse_wdb(file_path, gc) {
        Ok(data) => {
            let mut wdb_file_c = Box::new(WDBFileCInternal {
                wdb_name: ptr::null_mut(),
                header: WDBSectionCInternal { entries: ptr::null_mut(), entry_count: 0 },
                records: ptr::null_mut(),
                record_count: 0,
            });
            
            let name = std::path::Path::new(file_path).file_stem().unwrap_or_default().to_string_lossy();
            wdb_file_c.wdb_name = CString::new(name.into_owned()).unwrap().into_raw();
            
            let (header_entries, header_count) = marshal_map_to_c(&data.header);
            wdb_file_c.header.entries = header_entries;
            wdb_file_c.header.entry_count = header_count;
            
            let record_count = data.records.len() as i32;
            wdb_file_c.record_count = record_count;
            
            if record_count > 0 {
                let mut records_vec = Vec::with_capacity(record_count as usize);
                for rec in &data.records {
                    let (entries, count) = marshal_map_to_c(rec);
                    records_vec.push(WDBRecordCInternal {
                        entries,
                        entry_count: count,
                    });
                }
                wdb_file_c.records = records_vec.as_mut_ptr();
                std::mem::forget(records_vec);
            }
            
            Box::into_raw(wdb_file_c)
        },
        Err(e) => {
            log::error!("Error parsing WDB: {:?}", e);
            ptr::null_mut()
        }
    }
}

/// Frees memory allocated by `WDB_ParseFile`.
///
/// This recursively frees:
/// - The file name string
/// - All header entries and their values
/// - All record entries and their values
/// - Array contents (int/uint/string arrays)
///
/// # Safety
///
/// * `ptr` must be a valid pointer from `WDB_ParseFile`
/// * Must not be called twice on the same pointer
#[no_mangle]
pub unsafe extern "C" fn WDB_FreeWDBFile(ptr: *mut WDBFileCInternal) {
    if ptr.is_null() { return; }
    let mut file = Box::from_raw(ptr);
    
    WDB_FreeString(file.wdb_name);
    
    free_section_c(&mut file.header);
    
    if !file.records.is_null() && file.record_count > 0 {
        let records = Vec::from_raw_parts(file.records, file.record_count as usize, file.record_count as usize);
        for mut rec in records {
            free_record_c(&mut rec);
        }
    }
}

/// Writes WDB data to a file.
///
/// Converts the C structure back to Rust types and serializes
/// to WDB binary format.
///
/// # Arguments
///
/// * `file_path_ptr` - Output file path (null-terminated)
/// * `game_code_raw` - Game identifier: 0=FF13_1, 1=FF13_2, 2=FF13_3
/// * `in_wdb_file_ptr` - Pointer to WDB data structure
///
/// # Returns
///
/// * `0` - Success
/// * `-1` - Error (null pointer or write failure)
///
/// # Note
///
/// This does **not** free the input structure. Call `WDB_FreeWDBFile`
/// separately when done with the data.
#[no_mangle]
pub unsafe extern "C" fn WDB_WriteFile(
    file_path_ptr: *const c_char,
    _game_code_raw: u8,
    in_wdb_file_ptr: *mut WDBFileCInternal
) -> i32 {
    if file_path_ptr.is_null() || in_wdb_file_ptr.is_null() { return -1; }
    
    let file_path = match CStr::from_ptr(file_path_ptr).to_str() {
        Ok(s) => s,
        Err(_) => return -1,
    };
    
    let wdb_c = &*in_wdb_file_ptr;
    
    let header_map = unmarshal_section_from_c(&wdb_c.header);
    
    let mut records_vec = Vec::new();
    if !wdb_c.records.is_null() && wdb_c.record_count > 0 {
        let records_slice = std::slice::from_raw_parts(wdb_c.records, wdb_c.record_count as usize);
        for rec_c in records_slice {
            let rec_map = unmarshal_record_from_c(rec_c);
            records_vec.push(rec_map);
        }
    }
    
    let wdb_data = WdbData {
        header: header_map,
        records: records_vec,
    };
    
    let gc = match _game_code_raw {
        0 => GameCode::FF13_1,
        1 => GameCode::FF13_2,
        2 => GameCode::FF13_3,
        _ => GameCode::FF13_1,
    };
    
    match api::pack_wdb(&wdb_data, file_path, gc) {
        Ok(_) => 0,
        Err(e) => {
            log::error!("Error writing WDB: {:?}", e);
            -1
        }
    }
}

// --- MARSHALLING HELPERS ---
//
// These functions convert between Rust types (HashMap, WdbValue) and
// C-compatible structures (WDBEntryInternal, WDBValueInternal).
//
// Memory ownership:
// - marshal_* functions allocate memory that must be freed by free_* functions
// - unmarshal_* functions read C data without taking ownership

/// Converts a Rust HashMap to a C-compatible entry array.
///
/// Returns a tuple of (pointer to first entry, entry count).
/// The caller is responsible for freeing this memory.
unsafe fn marshal_map_to_c(map: &HashMap<String, WdbValue>) -> (*mut WDBEntryInternal, i32) {
    let mut entries_vec = Vec::with_capacity(map.len());
    for (k, v) in map {
        let key_c = CString::new(k.clone()).unwrap().into_raw();
        let value_c = marshal_value_to_c(v);
        entries_vec.push(WDBEntryInternal {
            key: key_c,
            value: value_c,
        });
    }
    let count = entries_vec.len() as i32;
    let ptr = entries_vec.as_mut_ptr();
    std::mem::forget(entries_vec);
    (ptr, count)
}

unsafe fn marshal_value_to_c(val: &WdbValue) -> WDBValueInternal {
    let mut data_c = std::mem::zeroed::<WDBValueDataC>();
    let type_c;

    match val {
        WdbValue::Int(i) => {
            type_c = WDBValueTypeC::Int;
            data_c.int_val = *i;
        },
        WdbValue::UInt(u) => {
            type_c = WDBValueTypeC::UInt;
            data_c.uint_val = *u;
        },
        WdbValue::Float(f) => {
            type_c = WDBValueTypeC::Float;
            data_c.float_val = *f;
        },
        WdbValue::String(s) => {
            type_c = WDBValueTypeC::String;
            data_c.string_val = CString::new(s.clone()).unwrap().into_raw();
        },
        WdbValue::Bool(b) => {
            type_c = WDBValueTypeC::Bool;
            data_c.bool_val = if *b { 1 } else { 0 };
        },
        WdbValue::IntArray(arr) => {
            type_c = WDBValueTypeC::IntArray;
            let mut c_arr = arr.clone();
            let count = c_arr.len() as i32;
            let items = c_arr.as_mut_ptr();
            std::mem::forget(c_arr);
            data_c.int_array_val = ManuallyDrop::new(WDBIntArrayInternal { items, count });
        },
        WdbValue::UIntArray(arr) => {
            type_c = WDBValueTypeC::UIntArray;
            let mut c_arr = arr.clone();
            let count = c_arr.len() as i32;
            let items = c_arr.as_mut_ptr();
            std::mem::forget(c_arr);
            data_c.uint_array_val = ManuallyDrop::new(WDBUIntArrayInternal { items, count });
        },
        WdbValue::StringArray(arr) => {
            type_c = WDBValueTypeC::StringArray;
            let mut ptrs = Vec::with_capacity(arr.len());
            for s in arr {
                ptrs.push(CString::new(s.clone()).unwrap().into_raw());
            }
            let count = ptrs.len() as i32;
            let items = ptrs.as_mut_ptr();
            std::mem::forget(ptrs);
            data_c.string_array_val = ManuallyDrop::new(WDBStringArrayInternal { items, count });
        },
        _ => {
            type_c = WDBValueTypeC::Unknown;
        }
    }

    WDBValueInternal {
        type_: type_c,
        data: data_c,
    }
}

unsafe fn unmarshal_section_from_c(section: &WDBSectionCInternal) -> HashMap<String, WdbValue> {
    let mut map = HashMap::new();
    if !section.entries.is_null() && section.entry_count > 0 {
        let entries = std::slice::from_raw_parts(section.entries, section.entry_count as usize);
        for e in entries {
            let key = CStr::from_ptr(e.key).to_string_lossy().to_string();
            let val = unmarshal_value_from_c(&e.value);
            map.insert(key, val);
        }
    }
    map
}

unsafe fn unmarshal_record_from_c(record: &WDBRecordCInternal) -> HashMap<String, WdbValue> {
    let mut map = HashMap::new();
    if !record.entries.is_null() && record.entry_count > 0 {
        let entries = std::slice::from_raw_parts(record.entries, record.entry_count as usize);
        for e in entries {
            let key = CStr::from_ptr(e.key).to_string_lossy().to_string();
            let val = unmarshal_value_from_c(&e.value);
            map.insert(key, val);
        }
    }
    map
}

unsafe fn unmarshal_value_from_c(val: &WDBValueInternal) -> WdbValue {
    match val.type_ {
        WDBValueTypeC::Int => WdbValue::Int(val.data.int_val),
        WDBValueTypeC::UInt => WdbValue::UInt(val.data.uint_val),
        WDBValueTypeC::Float => WdbValue::Float(val.data.float_val),
        WDBValueTypeC::String => {
            if val.data.string_val.is_null() {
                WdbValue::String(String::new())
            } else {
                WdbValue::String(CStr::from_ptr(val.data.string_val).to_string_lossy().to_string())
            }
        },
        WDBValueTypeC::Bool => WdbValue::Bool(val.data.bool_val != 0),
        WDBValueTypeC::IntArray => {
            let arr = &val.data.int_array_val;
            if arr.items.is_null() || arr.count == 0 {
                WdbValue::IntArray(Vec::new())
            } else {
                let slice = std::slice::from_raw_parts(arr.items, arr.count as usize);
                WdbValue::IntArray(slice.to_vec())
            }
        },
        WDBValueTypeC::UIntArray => {
            let arr = &val.data.uint_array_val;
            if arr.items.is_null() || arr.count == 0 {
                WdbValue::UIntArray(Vec::new())
            } else {
                let slice = std::slice::from_raw_parts(arr.items, arr.count as usize);
                WdbValue::UIntArray(slice.to_vec())
            }
        },
        WDBValueTypeC::StringArray => {
             let arr = &val.data.string_array_val;
             if arr.items.is_null() || arr.count == 0 {
                 WdbValue::StringArray(Vec::new())
             } else {
                 let slice = std::slice::from_raw_parts(arr.items, arr.count as usize);
                 let mut vec = Vec::with_capacity(arr.count as usize);
                 for &s_ptr in slice {
                     if !s_ptr.is_null() {
                         vec.push(CStr::from_ptr(s_ptr).to_string_lossy().to_string());
                     } else {
                         vec.push(String::new());
                     }
                 }
                 WdbValue::StringArray(vec)
             }
        },
        _ => WdbValue::Unknown,
    }
}

unsafe fn free_section_c(section: &mut WDBSectionCInternal) {
    if !section.entries.is_null() && section.entry_count > 0 {
        let entries = Vec::from_raw_parts(section.entries, section.entry_count as usize, section.entry_count as usize);
        for mut entry in entries {
            WDB_FreeString(entry.key);
            free_value_c(&mut entry.value);
        }
    }
}

unsafe fn free_record_c(record: &mut WDBRecordCInternal) {
    if !record.entries.is_null() && record.entry_count > 0 {
        let entries = Vec::from_raw_parts(record.entries, record.entry_count as usize, record.entry_count as usize);
        for mut entry in entries {
            WDB_FreeString(entry.key);
            free_value_c(&mut entry.value);
        }
    }
}

unsafe fn free_value_c(val: &mut WDBValueInternal) {
    match val.type_ {
        WDBValueTypeC::String => {
            WDB_FreeString(val.data.string_val);
        },
        WDBValueTypeC::IntArray => {
             let arr = ManuallyDrop::take(&mut val.data.int_array_val);
             if !arr.items.is_null() {
                 let _ = Vec::from_raw_parts(arr.items, arr.count as usize, arr.count as usize);
             }
        },
        WDBValueTypeC::UIntArray => {
             let arr = ManuallyDrop::take(&mut val.data.uint_array_val);
             if !arr.items.is_null() {
                 let _ = Vec::from_raw_parts(arr.items, arr.count as usize, arr.count as usize);
             }
        },
        WDBValueTypeC::StringArray => {
             let arr = ManuallyDrop::take(&mut val.data.string_array_val);
             if !arr.items.is_null() {
                 let ptrs = Vec::from_raw_parts(arr.items, arr.count as usize, arr.count as usize);
                 for ptr in ptrs {
                     WDB_FreeString(ptr);
                 }
             }
        },
        _ => {}
    }
}