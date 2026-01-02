# Rust SDK (fabula_nova_sdk)

The `fabula_nova_sdk` is Oracle Drive's high-performance native library for parsing, modifying, and writing FF13 game files.

## Overview

The SDK provides:
- Binary file format parsing/writing
- ZLIB compression/decompression
- Encryption/decryption
- Text encoding (Shift-JIS)
- Parallel processing for batch operations

## Architecture

```
fabula_nova_sdk/
├── src/
│   ├── lib.rs              # Crate root
│   ├── api.rs              # Public API (Flutter Rust Bridge)
│   ├── core/               # Shared utilities
│   │   ├── utils.rs        # GameCode, helpers
│   │   ├── logging.rs      # Log streaming
│   │   └── ffi_types.rs    # C-compatible types
│   ├── modules/            # File format handlers
│   │   ├── ztr/            # Text resources
│   │   ├── wbt/            # Archives
│   │   ├── wdb/            # Databases
│   │   ├── wpd/            # Packages
│   │   ├── img/            # Textures
│   │   ├── crystalium/     # CGT/MCP
│   │   ├── wct/            # Crypto
│   │   └── clb/            # Bytecode
│   └── ffi/                # Low-level FFI exports
├── Cargo.toml
└── rust-toolchain.toml
```

## Integration

### Flutter Rust Bridge
The primary integration uses [Flutter Rust Bridge](https://cjycode.com/flutter_rust_bridge/) for seamless Dart interop:

```rust
// Rust (api.rs)
pub fn wdb_parse(in_file: String) -> Result<WdbData> {
    wdb::api::parse(&in_file)
}

pub fn wdb_write(data: WdbData, out_file: String) -> Result<()> {
    wdb::api::write(&data, &out_file)
}
```

```dart
// Dart (via generated bindings)
final data = await RustLib.wdbParse(filePath);
await RustLib.wdbWrite(data, outputPath);
```

### Code Generation
After modifying Rust API, regenerate bindings:
```bash
cd rust/fabula_nova_sdk
flutter_rust_bridge_codegen generate
```

## Modules

### ZTR Module (Text Resources)

Handles `.ztr` text files with dictionary compression and Shift-JIS encoding.

#### API Functions
```rust
// Parse ZTR file
pub fn ztr_parse(in_file: String) -> Result<ZtrData>
pub fn ztr_parse_from_memory(data: Vec<u8>) -> Result<ZtrData>

// Write ZTR file
pub fn ztr_write(ztr: ZtrData, out_file: String) -> Result<()>
pub fn ztr_write_to_memory(ztr: ZtrData) -> Result<Vec<u8>>

// JSON conversion
pub fn ztr_to_json(ztr: ZtrData) -> Result<String>
pub fn ztr_from_json(json: String) -> Result<ZtrData>
```

#### Data Structures
```rust
pub struct ZtrData {
    pub entries: Vec<ZtrEntry>,
    pub encoding: String,
}

pub struct ZtrEntry {
    pub id: String,
    pub text: String,
}
```

#### Features
- Dictionary-based decompression
- Shift-JIS text decoding
- Control code preservation
- Game-specific dictionaries

---

### WBT Module (Archives)

Handles WhiteBin archive (`.bin`) files.

#### API Functions
```rust
// Open archive
pub fn wbt_open(archive_path: String, game: GameCode) -> Result<WbtArchive>

// List contents
pub fn wbt_list_files(archive: &WbtArchive) -> Vec<WbtFileEntry>

// Extract files
pub fn wbt_extract_file(archive: &WbtArchive, entry: &WbtFileEntry, out_path: String) -> Result<()>
pub fn wbt_extract_all(archive: &WbtArchive, out_dir: String) -> Result<()>

// Repack
pub fn wbt_repack(archive: &WbtArchive, modified_dir: String, out_path: String) -> Result<()>
```

#### Data Structures
```rust
pub struct WbtArchive {
    pub path: String,
    pub game: GameCode,
    pub entries: Vec<WbtFileEntry>,
}

pub struct WbtFileEntry {
    pub name: String,
    pub path: String,
    pub offset: u64,
    pub compressed_size: u32,
    pub uncompressed_size: u32,
}
```

#### Features
- Encrypted filelist parsing
- ZLIB decompression
- Parallel extraction (rayon)
- Size-aware repacking

---

### WDB Module (Databases)

Handles game database (`.wdb`) files.

#### API Functions
```rust
// Parse database
pub fn wdb_parse(in_file: String) -> Result<WdbData>
pub fn wdb_parse_from_memory(data: Vec<u8>) -> Result<WdbData>

// Write database
pub fn wdb_write(wdb: WdbData, out_file: String) -> Result<()>
pub fn wdb_write_to_memory(wdb: WdbData) -> Result<Vec<u8>>

// JSON conversion
pub fn wdb_to_json(wdb: WdbData) -> Result<String>
pub fn wdb_from_json(json: String) -> Result<WdbData>
```

#### Data Structures
```rust
pub struct WdbData {
    pub sheet_name: String,
    pub columns: Vec<WdbColumn>,
    pub records: Vec<WdbRecord>,
}

pub struct WdbColumn {
    pub name: String,
    pub data_type: WdbType,
    pub is_key: bool,
}

pub struct WdbRecord {
    pub values: HashMap<String, WdbValue>,
}

pub enum WdbValue {
    Int(i32),
    Float(f32),
    String(String),
    Bool(bool),
    Enum { raw: i32, name: Option<String> },
}
```

#### Features
- Field type detection
- Enum value resolution
- Bit-packed field handling
- Schema dictionaries

---

### WPD Module (Packages)

Handles package data (`.wpd`) files.

#### API Functions
```rust
// Unpack WPD
pub fn wpd_unpack(in_file: String, out_dir: String) -> Result<()>

// Repack WPD
pub fn wpd_repack(in_dir: String, out_file: String) -> Result<()>

// Parse metadata
pub fn wpd_parse(in_file: String) -> Result<WpdData>
```

#### Data Structures
```rust
pub struct WpdData {
    pub entries: Vec<WpdEntry>,
}

pub struct WpdEntry {
    pub name: String,
    pub offset: u64,
    pub size: u32,
    pub compressed: bool,
}
```

---

### IMG Module (Textures)

Handles image/texture files (`.imgb`, `.xgr`).

#### API Functions
```rust
// Extract to DDS
pub fn img_extract(in_file: String, out_file: String) -> Result<()>

// Repack from DDS
pub fn img_repack(in_file: String, out_file: String, original: String) -> Result<()>
```

#### Features
- DirectX texture format support
- DDS header parsing/writing
- Size validation for repacking

---

### Crystalium Module (CGT/MCP)

Handles Crystarium data files.

#### API Functions
```rust
// CGT operations
pub fn cgt_parse(in_file: String) -> Result<CgtFile>
pub fn cgt_parse_from_memory(data: Vec<u8>) -> Result<CgtFile>
pub fn cgt_write(cgt: CgtFile, out_file: String) -> Result<()>
pub fn cgt_write_to_memory(cgt: CgtFile) -> Result<Vec<u8>>

// MCP operations
pub fn mcp_parse(in_file: String) -> Result<McpFile>
pub fn mcp_parse_from_memory(data: Vec<u8>) -> Result<McpFile>

// Validation
pub fn cgt_validate(cgt: &CgtFile) -> Vec<ValidationWarning>

// JSON conversion
pub fn cgt_to_json(cgt: CgtFile) -> Result<String>
pub fn cgt_from_json(json: String) -> Result<CgtFile>
```

#### Data Structures
```rust
pub struct CgtFile {
    pub version: u32,
    pub entries: Vec<CrystariumEntry>,
    pub nodes: Vec<CrystariumNode>,
}

pub struct CrystariumEntry {
    pub index: u32,
    pub pattern_name: String,
    pub position: Vec3,
    pub rotation: Quaternion,
    pub role_id: u8,
    pub stage: u8,
    pub node_ids: Vec<u32>,
}

pub struct McpFile {
    pub patterns: Vec<McpPattern>,
}
```

---

### WCT Module (Crypto)

Encryption/decryption utilities.

#### API Functions
```rust
// FileList encryption
pub fn wct_encrypt_filelist(data: Vec<u8>, game: GameCode) -> Vec<u8>
pub fn wct_decrypt_filelist(data: Vec<u8>, game: GameCode) -> Vec<u8>

// CLB encryption
pub fn wct_encrypt_clb(data: Vec<u8>) -> Vec<u8>
pub fn wct_decrypt_clb(data: Vec<u8>) -> Vec<u8>
```

---

### CLB Module (Bytecode)

Crystal Logic Bytecode handling.

#### API Functions
```rust
// Convert to/from decompilable format
pub fn clb_to_class(clb_data: Vec<u8>) -> Result<Vec<u8>>
pub fn clb_from_class(class_data: Vec<u8>) -> Result<Vec<u8>>
```

## Core Utilities

### GameCode Enum
```rust
pub enum GameCode {
    FF13_1,  // Final Fantasy XIII
    FF13_2,  // Final Fantasy XIII-2
    FF13_LR, // Lightning Returns
}
```

### Logging
```rust
// Initialize logging (called from Dart)
pub fn init_logging() -> Result<()>

// Get buffered logs
pub fn get_logs() -> Vec<LogEntry>

// Clear log buffer
pub fn clear_logs()
```

### Error Handling
All API functions return `Result<T>` using `anyhow`:
```rust
pub fn example() -> Result<Data> {
    let file = std::fs::read(&path)
        .context("Failed to read file")?;
    // ...
}
```

Errors are propagated to Dart as exceptions.

## Dependencies

```toml
[dependencies]
flutter_rust_bridge = "2.11.1"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
binrw = "0.13"
flate2 = "1.0"
rayon = "1.8"
encoding_rs = "0.8"
walkdir = "2.5"
anyhow = "1.0"
thiserror = "1.0"
log = "0.4"
chrono = "0.4"
once_cell = "1.19"
indexmap = "2.0"
```

## Building

### Prerequisites
- Rust toolchain (see `rust-toolchain.toml`)
- Platform-specific build tools

### Build Commands
```bash
# Development build
cargo build

# Release build
cargo build --release

# Run tests
cargo test

# Generate FRB bindings
flutter_rust_bridge_codegen generate
```

### Output
- **Windows**: `fabula_nova_sdk.dll`
- **macOS**: `libfabula_nova_sdk.dylib`
- **Linux**: `libfabula_nova_sdk.so`

## Testing

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_wdb_roundtrip() {
        let original = wdb_parse("test_data/enemy.wdb").unwrap();
        let bytes = wdb_write_to_memory(original.clone()).unwrap();
        let parsed = wdb_parse_from_memory(bytes).unwrap();
        assert_eq!(original, parsed);
    }
}
```

Run tests:
```bash
cargo test
cargo test -- --nocapture  # See output
```

## Performance

The SDK uses several optimization strategies:
- **Rayon** for parallel processing
- **Memory-mapped I/O** for large files
- **Lazy parsing** where applicable
- **Buffer reuse** to minimize allocations

## See Also

- [[Architecture]] - System overview
- [[File Formats]] - Format specifications
- [[Contributing]] - Development guidelines
