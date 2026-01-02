//! # WCT Module - WhiteCrypt Tool
//!
//! This module provides cryptographic operations for Final Fantasy XIII game files.
//! It serves as a dispatcher for encryption/decryption of various file types.
//!
//! ## Supported Operations
//!
//! | Target    | Action      | Description                          |
//! |-----------|-------------|--------------------------------------|
//! | CLB       | Decrypt     | Decrypt encrypted CLB file           |
//! | CLB       | Encrypt     | Encrypt plaintext CLB file           |
//! | CLB       | ClbToJava   | Convert CLB to Java .class file      |
//! | CLB       | JavaToClb   | Convert Java .class to CLB format    |
//! | FileList  | Decrypt     | Decrypt WBT filelist (planned)       |
//!
//! ## CLB Files
//!
//! CLB (Compiled Lua/Java Bytecode) files contain encrypted game scripts.
//! The encryption uses a custom XOR-based block cipher with an 8-byte seed.
//!
//! ## Usage Example
//!
//! ```rust,ignore
//! use fabula_nova_sdk::modules::wct::{process_file, TargetType, Action};
//! use std::path::Path;
//!
//! // Decrypt a CLB file
//! process_file(TargetType::Clb, Action::Decrypt, Path::new("script.clb"))?;
//!
//! // Convert CLB to Java class for decompilation
//! process_file(TargetType::Clb, Action::ClbToJava, Path::new("script.clb"))?;
//! ```

use std::path::Path;
use thiserror::Error;

/// Errors that can occur during WCT operations.
#[derive(Error, Debug)]
pub enum WctError {
    /// Standard I/O error (file not found, permission denied, etc.)
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    /// Cryptographic operation failed
    #[error("Crypto error: {0}")]
    Crypto(String),

    /// File format or size validation failed
    #[error("Validation failed: {0}")]
    Validation(String),
}

/// Result type for WCT operations
pub type Result<T> = std::result::Result<T, WctError>;

#[cfg(test)]
mod tests;

/// Target file type for cryptographic operations.
#[derive(Debug, Clone, Copy)]
pub enum TargetType {
    /// WBT filelist (encrypted file index)
    FileList,
    /// CLB script file (encrypted bytecode)
    Clb,
}

/// Action to perform on the target file.
#[derive(Debug, Clone, Copy)]
pub enum Action {
    /// Decrypt the file in place
    Decrypt,
    /// Encrypt the file in place
    Encrypt,
    /// Convert CLB to standard Java .class format
    ClbToJava,
    /// Convert Java .class to CLB format
    JavaToClb,
}

/// Main dispatch function for cryptographic file operations.
///
/// This function routes the request to the appropriate handler based on
/// the target type and action.
///
/// # Arguments
/// * `target` - The type of file to process
/// * `action` - The operation to perform
/// * `input_path` - Path to the input file
///
/// # Returns
/// `Ok(())` on success, or an error describing the failure.
pub fn process_file(target: TargetType, action: Action, input_path: &Path) -> Result<()> {
    match target {
        TargetType::Clb => crate::modules::white_clb::process_clb(action, input_path),
        TargetType::FileList => {
            // For now, FileList is stubbed as the focus is on WhiteCLB
            Err(WctError::Validation("FileList processing moved. Use dedicated FileList module.".into()))
        }
    }
}
