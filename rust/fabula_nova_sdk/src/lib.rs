//! # Fabula Nova SDK
//!
//! A modding toolkit for Final Fantasy XIII trilogy games, providing
//! file format parsing, modification, and repacking capabilities.
//!
//! ## Crate Structure
//!
//! ```text
//! fabula_nova_sdk
//! ├── api          # Public API for Flutter/Dart (via flutter_rust_bridge)
//! ├── core         # Shared utilities, logging, FFI types
//! ├── ffi          # C-compatible FFI exports (for dart:ffi)
//! └── modules      # File format implementations
//!     ├── ztr      # Text resources (.ztr)
//!     ├── wdb      # Game databases (.wdb)
//!     ├── wbt      # WhiteBin archives (.bin)
//!     ├── wpd      # Package data (.wpd)
//!     ├── img      # Textures (.imgb)
//!     ├── wct      # Crypto tool (encryption/decryption)
//!     ├── clb      # Crystal Logic Bytecode
//!     └── white_clb# Alternative CLB implementation
//! ```
//!
//! ## Supported Games
//!
//! | Code | Abbreviation | Full Name                     |
//! |------|--------------|-------------------------------|
//! | 0    | FF13_1       | Final Fantasy XIII            |
//! | 1    | FF13_2       | Final Fantasy XIII-2          |
//! | 2    | FF13_3/LR    | Lightning Returns: FF XIII    |
//!
//! ## Integration
//!
//! This crate is designed for two integration patterns:
//!
//! 1. **Flutter Rust Bridge** (`api` module): High-level Dart-friendly API
//!    for the Flutter application. Functions are exposed with Dart-compatible
//!    types and error handling.
//!
//! 2. **C FFI** (`ffi` module): Low-level C-compatible exports for `dart:ffi`
//!    bindings. Used for performance-critical operations or when FRB isn't
//!    suitable.
//!
//! ## Example
//!
//! ```rust,ignore
//! use fabula_nova_sdk::api;
//!
//! // Initialize logging
//! api::init_app();
//!
//! // Extract ZTR text resources
//! api::ztr_extract_to_text(
//!     "strings.ztr".into(),
//!     "strings.txt".into(),
//!     0, // FF13_1
//! )?;
//! ```

mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */

/// Core utilities, logging, and FFI type definitions.
pub mod core;

/// File format implementations for FF13 trilogy.
pub mod modules;

/// C-compatible FFI exports for dart:ffi integration.
pub mod ffi;

/// Public API surface for Flutter Rust Bridge.
pub mod api;