//! # Core Module
//!
//! The `core` module provides foundational infrastructure for the Fabula Nova SDK.
//! This module contains cross-cutting concerns that are used throughout the entire SDK,
//! including logging, utility functions, and FFI (Foreign Function Interface) types.
//!
//! ## Submodules
//!
//! - [`logging`] - Comprehensive logging system with hot-reload support for Flutter integration.
//!   Provides a ring buffer that persists across hot restarts and supports both callback-based
//!   and polling-based log retrieval.
//!
//! - [`utils`] - Common utility types and functions used across all format handlers.
//!   Includes the [`GameCode`] enum for distinguishing between FF13, FF13-2, and Lightning Returns.
//!
//! - [`ffi_types`] - C-compatible result types for safe FFI interoperability.
//!   Provides [`NativeResult<T>`] union type for returning success/error states to C code.
//!
//! ## Architecture
//!
//! The core module sits at the bottom of the dependency hierarchy - all other modules
//! (ZTR, WDB, WBT, WPD, IMG, WCT, CLB) depend on core, but core has no dependencies
//! on other SDK modules. This ensures clean separation of concerns and prevents
//! circular dependencies.
//!
//! ```text
//! ┌─────────────────────────────────────────┐
//! │  Format Handlers (ZTR, WDB, WBT, etc.)  │
//! └─────────────────────┬───────────────────┘
//!                       │
//!                       ▼
//! ┌─────────────────────────────────────────┐
//! │              Core Module                │
//! │  (logging, utils, ffi_types)            │
//! └─────────────────────────────────────────┘
//! ```

pub mod logging;
pub mod utils;
pub mod ffi_types;

// Re-export commonly used items at the core module level for convenience
pub use logging::*;
pub use utils::*;
