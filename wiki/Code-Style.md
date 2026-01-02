# Code Style

This document outlines the coding conventions and style guidelines for Oracle Drive.

## General Principles

1. **Consistency** - Match existing code style
2. **Clarity** - Favor readability over cleverness
3. **Simplicity** - Keep it simple when possible
4. **Documentation** - Document non-obvious behavior

## Dart/Flutter

### Formatting

Use `dart format` with default settings:

```bash
dart format lib/
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `WdbProvider` |
| Variables | camelCase | `selectedFile` |
| Constants | camelCase | `maxEntries` |
| Private | _prefix | `_internalState` |
| Files | snake_case | `wdb_provider.dart` |

### Imports

Order imports by:
1. Dart SDK
2. Flutter
3. Packages
4. Local imports

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wdb_model.dart';
import '../services/native_service.dart';
```

### Classes

```dart
/// Brief description of the class.
///
/// Longer description if needed.
class WdbProvider extends StateNotifier<WdbState> {
  // Constructor first
  WdbProvider(this._service) : super(WdbState.initial());

  // Private fields
  final NativeService _service;

  // Public getters
  bool get hasData => state.data != null;

  // Public methods
  Future<void> loadFile(String path) async {
    // Implementation
  }

  // Private methods
  void _updateState(WdbData data) {
    // Implementation
  }
}
```

### Providers (Riverpod)

```dart
/// Provider for WDB editor state.
final wdbProvider = StateNotifierProvider<WdbProvider, WdbState>((ref) {
  return WdbProvider(ref.read(nativeServiceProvider));
});

/// Derived provider for filtered records.
final filteredRecordsProvider = Provider<List<WdbRecord>>((ref) {
  final state = ref.watch(wdbProvider);
  return state.records.where((r) => r.matches(state.filter)).toList();
});
```

### Widgets

```dart
class WdbTable extends ConsumerWidget {
  const WdbTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wdbProvider);

    return DataTable(
      columns: _buildColumns(state.columns),
      rows: _buildRows(state.records),
    );
  }

  List<DataColumn> _buildColumns(List<WdbColumn> columns) {
    return columns.map((c) => DataColumn(label: Text(c.name))).toList();
  }

  List<DataRow> _buildRows(List<WdbRecord> records) {
    return records.map((r) => DataRow(cells: _buildCells(r))).toList();
  }
}
```

### Error Handling

```dart
Future<void> loadFile(String path) async {
  try {
    state = state.copyWith(loading: true, error: null);
    final data = await _service.parseWdb(path);
    state = state.copyWith(loading: false, data: data);
  } catch (e, stack) {
    state = state.copyWith(loading: false, error: e.toString());
    debugPrint('Failed to load WDB: $e\n$stack');
  }
}
```

### Async/Await

Prefer async/await over .then():

```dart
// Good
Future<void> process() async {
  final data = await fetchData();
  await saveData(data);
}

// Avoid
Future<void> process() {
  return fetchData().then((data) => saveData(data));
}
```

## Rust

### Formatting

Use `cargo fmt` with default settings:

```bash
cargo fmt
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Structs | PascalCase | `WdbData` |
| Functions | snake_case | `parse_file` |
| Constants | SCREAMING_CASE | `MAX_ENTRIES` |
| Modules | snake_case | `wdb_parser` |

### Module Structure

```rust
// mod.rs
//! Module documentation.
//!
//! Detailed description.

mod structs;
mod reader;
mod writer;
mod api;

pub use api::*;
pub use structs::*;
```

### Structs

```rust
/// Represents a WDB database record.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct WdbRecord {
    /// Record identifier.
    pub id: u32,
    /// Field values.
    pub values: HashMap<String, WdbValue>,
}

impl WdbRecord {
    /// Creates a new empty record.
    pub fn new(id: u32) -> Self {
        Self {
            id,
            values: HashMap::new(),
        }
    }
}
```

### Error Handling

Use `anyhow` for error propagation:

```rust
use anyhow::{Context, Result};

pub fn parse_file(path: &str) -> Result<WdbData> {
    let bytes = std::fs::read(path)
        .context(format!("Failed to read file: {}", path))?;

    parse_bytes(&bytes)
        .context("Failed to parse WDB data")
}
```

Use `thiserror` for custom errors:

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum WdbError {
    #[error("Invalid magic bytes: expected {expected:?}, got {actual:?}")]
    InvalidMagic { expected: [u8; 4], actual: [u8; 4] },

    #[error("Unsupported version: {0}")]
    UnsupportedVersion(u32),
}
```

### API Functions

```rust
/// Parses a WDB file from disk.
///
/// # Arguments
/// * `in_file` - Path to the WDB file
///
/// # Returns
/// Parsed WDB data or error
///
/// # Example
/// ```
/// let data = wdb_parse("enemy.wdb")?;
/// println!("Records: {}", data.records.len());
/// ```
pub fn wdb_parse(in_file: String) -> Result<WdbData> {
    let path = Path::new(&in_file);
    wdb::api::parse(path)
}
```

### Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_valid_file() {
        let data = parse("test_data/valid.wdb").unwrap();
        assert!(!data.records.is_empty());
    }

    #[test]
    fn test_parse_invalid_magic() {
        let result = parse("test_data/invalid.wdb");
        assert!(result.is_err());
    }

    #[test]
    fn test_roundtrip() {
        let original = parse("test_data/enemy.wdb").unwrap();
        let bytes = write_to_memory(&original).unwrap();
        let parsed = parse_from_memory(&bytes).unwrap();
        assert_eq!(original, parsed);
    }
}
```

## Documentation

### Dart

Use `///` for documentation comments:

```dart
/// Loads a WDB file from disk.
///
/// This method parses the file and updates the provider state.
/// Progress is reported via the console.
///
/// Throws [FileNotFoundException] if the file doesn't exist.
/// Throws [ParseException] if the file format is invalid.
Future<void> loadFile(String path) async {
  // ...
}
```

### Rust

Use `///` for item documentation:

```rust
/// Parses WDB data from a byte slice.
///
/// # Arguments
/// * `data` - Raw WDB file bytes
///
/// # Returns
/// * `Ok(WdbData)` - Successfully parsed data
/// * `Err(...)` - Parse error
///
/// # Example
/// ```
/// let bytes = std::fs::read("enemy.wdb")?;
/// let data = parse_from_memory(&bytes)?;
/// ```
pub fn parse_from_memory(data: &[u8]) -> Result<WdbData> {
    // ...
}
```

Use `//!` for module documentation:

```rust
//! WDB (WhiteDatabase) module.
//!
//! This module handles parsing and writing WDB database files
//! used by the FF13 trilogy for game data storage.
//!
//! ## File Format
//! WDB files contain structured data with typed fields...
```

## Comments

### When to Comment

- Non-obvious algorithms
- Workarounds for bugs
- Complex business logic
- Performance considerations

### When Not to Comment

- Self-explanatory code
- Restating what code does
- Obsolete information

```dart
// Good: Explains why
// Use insertion sort for small arrays (faster than quicksort for n < 10)
if (items.length < 10) {
  insertionSort(items);
}

// Bad: Restates what
// Check if length is less than 10
if (items.length < 10) {
```

## File Organization

### Dart

```
lib/
├── main.dart
├── models/
│   ├── wdb_model.dart      # WDB data models
│   └── ztr_model.dart      # ZTR data models
├── providers/
│   ├── wdb_provider.dart   # WDB state management
│   └── app_state_provider.dart
├── screens/
│   ├── wdb_screen.dart     # WDB editor screen
│   └── main_screen.dart
└── components/
    ├── wdb/
    │   ├── wdb_table.dart
    │   └── wdb_toolbar.dart
    └── widgets/
        └── crystal_button.dart
```

### Rust

```
src/
├── lib.rs
├── api.rs                  # Public API surface
├── core/
│   ├── mod.rs
│   └── utils.rs
└── modules/
    └── wdb/
        ├── mod.rs          # Module exports
        ├── structs.rs      # Data structures
        ├── reader.rs       # Parsing logic
        ├── writer.rs       # Writing logic
        ├── api.rs          # Module API
        └── tests.rs        # Unit tests
```

## Tools

### Linting

```bash
# Dart
flutter analyze

# Rust
cargo clippy
```

### Formatting

```bash
# Dart
dart format lib/ test/

# Rust
cargo fmt
```

### Pre-commit

Consider using pre-commit hooks:

```bash
#!/bin/sh
# .git/hooks/pre-commit

dart format --set-exit-if-changed lib/ test/ || exit 1
flutter analyze || exit 1
cd rust/fabula_nova_sdk && cargo fmt --check && cargo clippy || exit 1
```

## See Also

- [[Contributing]] - How to contribute
- [[Building from Source]] - Development setup
- [[Architecture]] - System design
