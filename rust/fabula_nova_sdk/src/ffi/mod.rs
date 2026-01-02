#![allow(clippy::missing_safety_doc)]
//! # Foreign Function Interface (FFI) Layer
//!
//! This module exposes Rust functionality to C-compatible consumers,
//! primarily the Flutter/Dart frontend via `dart:ffi`.
//!
//! ## Architecture
//!
//! ```text
//! ┌────────────────────────────────────────────────────────────┐
//! │                    Flutter/Dart App                        │
//! │                                                            │
//! │  ┌──────────────────────────────────────────────────────┐  │
//! │  │                   dart:ffi bindings                  │  │
//! │  └──────────────────────────────────────────────────────┘  │
//! └─────────────────────────┬──────────────────────────────────┘
//!                           │ C ABI calls
//!                           ▼
//! ┌────────────────────────────────────────────────────────────┐
//! │                      FFI Layer                             │
//! │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
//! │  │ ztr_ffi  │  │ wdb_ffi  │  │ img_ffi  │  │ wpd_ffi  │   │
//! │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
//! │       │             │             │             │         │
//! │  ┌────▼─────────────▼─────────────▼─────────────▼─────┐   │
//! │  │           String/Memory Marshalling                │   │
//! │  │    (CString ↔ &str, Box ↔ raw pointers, etc.)      │   │
//! │  └────────────────────────────────────────────────────┘   │
//! └─────────────────────────┬──────────────────────────────────┘
//!                           │ Safe Rust calls
//!                           ▼
//! ┌────────────────────────────────────────────────────────────┐
//! │                    Rust Modules                            │
//! │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
//! │  │   ztr    │  │   wdb    │  │   img    │  │   wpd    │   │
//! │  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
//! └────────────────────────────────────────────────────────────┘
//! ```
//!
//! ## Memory Management
//!
//! **Critical**: Memory allocated in Rust must be freed by Rust.
//!
//! Each FFI module follows this pattern:
//! 1. **Parse/Create**: Allocate data structures, return raw pointer
//! 2. **Use**: Caller reads/modifies data via pointer
//! 3. **Free**: Caller invokes `*_free*` function to deallocate
//!
//! ## Return Codes
//!
//! Most functions return `i32` status codes:
//! - `0`: Success
//! - `1`: Null pointer argument
//! - `2`: Invalid argument value
//! - `3+`: Operation-specific errors
//! - `99`: Generic/unexpected error
//!
//! ## String Handling
//!
//! - Input: `*const c_char` (null-terminated C string)
//! - Output: `*mut c_char` (Rust-allocated, caller must free)
//! - Conversion: `CStr::from_ptr()` / `CString::new().into_raw()`

pub mod ztr_ffi;
pub mod img_ffi;
pub mod wdb_ffi;
pub mod wpd_ffi;
pub mod wct_ffi;
