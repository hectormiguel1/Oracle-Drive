//! # FFI Types Module
//!
//! This module provides C-compatible types for safe Foreign Function Interface (FFI)
//! communication between Rust and other languages (C, Dart, etc.).
//!
//! ## Overview
//!
//! When Rust code needs to return results to C/Dart code, we can't use Rust's
//! native `Result<T, E>` type because it's not ABI-stable. This module provides
//! a C-compatible alternative: [`NativeResult<T>`].
//!
//! ## Memory Management
//!
//! **CRITICAL**: The caller (C/Dart side) is responsible for freeing memory
//! allocated by these types. Failure to call [`free_result()`] will cause
//! memory leaks.
//!
//! ```text
//! ┌─────────────────────────────────────────────────────────────────┐
//! │                    Memory Ownership Rules                        │
//! ├─────────────────────────────────────────────────────────────────┤
//! │ ResultType::Ok       → Heap pointer, MUST call free_result()    │
//! │ ResultType::Error    → Heap pointer, MUST call free_result()    │
//! │ ResultType::OkInline → Stack value, DO NOT call free_result()   │
//! └─────────────────────────────────────────────────────────────────┘
//! ```
//!
//! ## Usage from Dart
//!
//! ```dart
//! final result = nativeLib.someFunction();
//! try {
//!   if (result.result_type == ResultType.Ok) {
//!     // Use result.payload.data
//!   } else if (result.result_type == ResultType.Error) {
//!     final error = result.payload.err;
//!     throw Exception(error.message.toDartString());
//!   } else {
//!     // OkInline: result.payload.inline_value is the value itself
//!   }
//! } finally {
//!   if (result.result_type != ResultType.OkInline) {
//!     nativeLib.free_result(result);
//!   }
//! }
//! ```
//!
//! ## Design Rationale
//!
//! The use of a C union (`ResultUnion`) allows a single struct to represent
//! three different states without wasting memory:
//! - Success with heap data (pointer to T)
//! - Error with message (pointer to FfiError)
//! - Success with inline value (usize, no heap allocation)
//!
//! The `OkInline` variant is an optimization for simple return values (counts,
//! booleans, sizes) that can fit in a `usize` without heap allocation.

use std::ffi::{c_char, CString};

// =============================================================================
// Result Type Discriminator
// =============================================================================

/// Discriminator for the [`NativeResult`] union, indicating which variant is active.
///
/// This enum uses `#[repr(C)]` to ensure a stable ABI layout that matches
/// what C code expects. The explicit discriminant values (0, 1, 2) provide
/// stability across compilations.
///
/// # Variants
///
/// | Variant   | Value | Meaning                           | Memory Action   |
/// |-----------|-------|-----------------------------------|-----------------|
/// | Ok        | 0     | Success, data on heap             | MUST free       |
/// | Error     | 1     | Failure, error on heap            | MUST free       |
/// | OkInline  | 2     | Success, value inline             | DO NOT free     |
#[repr(C)]
pub enum ResultType {
    /// Operation succeeded. The `payload.data` field contains a heap-allocated
    /// pointer to the result data. **Caller must free this memory.**
    Ok = 0,

    /// Operation failed. The `payload.err` field contains a heap-allocated
    /// pointer to an [`FfiError`] struct with details. **Caller must free this memory.**
    Error = 1,

    /// Operation succeeded with a simple value that fits in a `usize`.
    /// The `payload.inline_value` field contains the value directly.
    /// **Do NOT attempt to free this - no heap allocation was made.**
    OkInline = 2,
}

// =============================================================================
// Error Structure
// =============================================================================

/// C-compatible error structure for FFI error reporting.
///
/// This struct is allocated on the heap when an error occurs and must be
/// freed by calling [`free_result()`].
///
/// # Memory Layout
///
/// ```text
/// FfiError {
///     message: *mut c_char,  // Heap-allocated C string (null-terminated)
///     code: i32,             // Error code (for programmatic handling)
/// }
/// ```
///
/// # Common Error Codes
///
/// | Code | Meaning                    |
/// |------|----------------------------|
/// | 1    | File not found             |
/// | 2    | Invalid format             |
/// | 3    | I/O error                  |
/// | 4    | Parse error                |
/// | 5    | Encryption/decryption error|
/// | -1   | Unknown/generic error      |
#[repr(C)]
pub struct FfiError {
    /// Null-terminated C string containing the error message.
    /// Allocated using `CString::into_raw()`, must be freed with
    /// `CString::from_raw()`.
    pub message: *mut c_char,

    /// Numeric error code for programmatic error handling.
    /// Allows the caller to switch on error types without parsing
    /// the message string.
    pub code: i32,
}

// =============================================================================
// Result Union (Tagged Union Pattern)
// =============================================================================

/// C-compatible union holding the payload of a [`NativeResult`].
///
/// This is a tagged union - only ONE field is valid at a time, determined
/// by the `result_type` discriminator. Accessing the wrong field is
/// undefined behavior.
///
/// # Type Parameter
///
/// * `T: Copy` - The success data type. Must be `Copy` because unions
///   require all variants to be trivially copyable.
///
/// # Safety
///
/// **Only access the field corresponding to the `ResultType`:**
/// - `ResultType::Ok` → use `data`
/// - `ResultType::Error` → use `err`
/// - `ResultType::OkInline` → use `inline_value`
///
/// # Memory Layout
///
/// All three fields share the same memory (size of the largest field):
/// ```text
/// ResultUnion {
///     data: *mut T,         // 8 bytes (64-bit pointer)
///     err: *mut FfiError,   // 8 bytes (64-bit pointer)
///     inline_value: usize,  // 8 bytes (64-bit usize)
/// }
/// Total size: 8 bytes (not 24 - they overlap)
/// ```
#[repr(C)]
pub union ResultUnion<T: Copy> {
    /// Pointer to heap-allocated success data.
    /// Valid only when `result_type == ResultType::Ok`.
    pub data: *mut T,

    /// Pointer to heap-allocated error information.
    /// Valid only when `result_type == ResultType::Error`.
    pub err: *mut FfiError,

    /// Inline success value (no heap allocation).
    /// Valid only when `result_type == ResultType::OkInline`.
    /// Use for simple values like counts, sizes, or booleans.
    pub inline_value: usize,
}

// =============================================================================
// Native Result Structure
// =============================================================================

/// C-compatible result type for FFI function returns.
///
/// This is the primary type returned by FFI functions. It uses a tagged union
/// pattern to safely represent success (with data), success (inline), or error.
///
/// # Type Parameter
///
/// * `T: Copy` - The type of data returned on success. Must be `Copy` due
///   to union requirements.
///
/// # Memory Management
///
/// The caller is responsible for memory management:
///
/// ```c
/// // C example
/// NativeResult result = some_rust_function();
/// if (result.result_type == Ok) {
///     // Use result.payload.data
///     free_result(result);  // REQUIRED
/// } else if (result.result_type == Error) {
///     printf("Error: %s\n", result.payload.err->message);
///     free_result(result);  // REQUIRED
/// } else {
///     // OkInline - no freeing needed
///     size_t value = result.payload.inline_value;
/// }
/// ```
///
/// # Example (Rust side)
///
/// ```rust,ignore
/// use fabula_nova_sdk::core::ffi_types::NativeResult;
///
/// // Return an inline success (no heap allocation)
/// fn get_count() -> NativeResult<i32> {
///     NativeResult::ok_inline(42)
/// }
///
/// // Return an error
/// fn failing_function() -> NativeResult<i32> {
///     NativeResult::error("File not found", 1)
/// }
/// ```
#[repr(C)]
pub struct NativeResult<T: Copy> {
    /// Discriminator indicating which union field is valid.
    pub result_type: ResultType,

    /// The payload union. Only one field is valid based on `result_type`.
    pub payload: ResultUnion<T>,
}

impl<T: Copy> NativeResult<T> {
    /// Creates a successful result with an inline value (no heap allocation).
    ///
    /// Use this for simple return values that can fit in a `usize`:
    /// - Counts (number of records, files, etc.)
    /// - Sizes (byte counts, lengths)
    /// - Boolean results (0 = false, 1 = true)
    /// - Small integers
    ///
    /// # Arguments
    /// * `val` - The value to return, cast to `usize`
    ///
    /// # Returns
    /// A `NativeResult` with `result_type = OkInline` and the value stored
    /// directly in `payload.inline_value`.
    ///
    /// # Memory
    /// **No heap allocation** - the caller does NOT need to free this result.
    ///
    /// # Example
    /// ```rust,ignore
    /// // Return a count
    /// let result = NativeResult::<i32>::ok_inline(items.len());
    ///
    /// // Return a boolean (success = 1)
    /// let result = NativeResult::<i32>::ok_inline(1);
    /// ```
    pub fn ok_inline(val: usize) -> Self {
        Self {
            result_type: ResultType::OkInline,
            payload: ResultUnion { inline_value: val },
        }
    }

    /// Creates an error result with a message and code.
    ///
    /// This allocates memory for the error message and [`FfiError`] struct.
    /// **The caller MUST call [`free_result()`] to avoid memory leaks.**
    ///
    /// # Arguments
    /// * `message` - Human-readable error description (will be copied to heap)
    /// * `code` - Numeric error code for programmatic handling
    ///
    /// # Returns
    /// A `NativeResult` with `result_type = Error` and `payload.err` pointing
    /// to a heap-allocated [`FfiError`].
    ///
    /// # Panics
    /// Panics if `message` contains a null byte (invalid for C strings).
    ///
    /// # Example
    /// ```rust,ignore
    /// // File not found error
    /// let result: NativeResult<i32> = NativeResult::error(
    ///     "File 'config.wdb' not found",
    ///     1  // Error code for "not found"
    /// );
    /// ```
    pub fn error(message: &str, code: i32) -> Self {
        // Convert Rust string to null-terminated C string
        // into_raw() transfers ownership to C - we must NOT drop this
        let c_str = CString::new(message).unwrap();

        // Allocate FfiError on heap
        let err = Box::new(FfiError {
            message: c_str.into_raw(), // Transfer ownership of string
            code,
        });

        Self {
            result_type: ResultType::Error,
            // Box::into_raw() transfers ownership - caller must free
            payload: ResultUnion {
                err: Box::into_raw(err),
            },
        }
    }
}

// =============================================================================
// Memory Deallocation
// =============================================================================

/// Frees memory allocated by a [`NativeResult`].
///
/// **This function MUST be called for results with `ResultType::Ok` or
/// `ResultType::Error`.** Do NOT call for `ResultType::OkInline` results.
///
/// # Safety
///
/// This function is `unsafe` because it:
/// - Dereferences raw pointers
/// - Takes ownership of heap-allocated memory
/// - Can cause double-free if called twice on the same result
///
/// # Arguments
/// * `result` - The result to free. After this call, the result is invalid.
///
/// # Behavior by ResultType
///
/// | ResultType | Action                                          |
/// |------------|-------------------------------------------------|
/// | Ok         | Frees the data pointer                          |
/// | Error      | Frees the error message string and FfiError     |
/// | OkInline   | No-op (no memory was allocated)                 |
///
/// # Example (C)
/// ```c
/// NativeResult result = rust_function();
/// // ... use result ...
/// if (result.result_type != OkInline) {
///     free_result(result);
/// }
/// ```
#[no_mangle]
pub unsafe extern "C" fn free_result(result: NativeResult<i32>) {
    match result.result_type {
        // OkInline has no heap allocation - nothing to free
        ResultType::OkInline => {}

        // Error: free both the message string and the FfiError struct
        ResultType::Error => {
            if !result.payload.err.is_null() {
                // Take back ownership of the FfiError
                let err = Box::from_raw(result.payload.err);

                // Free the message string if it exists
                if !err.message.is_null() {
                    // CString::from_raw takes ownership and drops when done
                    let _ = CString::from_raw(err.message);
                }
                // err is dropped here, freeing the FfiError struct
            }
        }

        // Ok: free the data pointer
        ResultType::Ok => {
            if !result.payload.data.is_null() {
                // Take back ownership of the data and drop it
                let _ = Box::from_raw(result.payload.data);
            }
        }
    }
}
