# Building from Source

This guide covers setting up a development environment and building Oracle Drive from source.

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Flutter SDK | 3.10+ | Frontend framework |
| Dart SDK | 3.10.1+ | Included with Flutter |
| Rust | Latest stable | Native SDK |
| Git | Any | Version control |
| Platform tools | See below | Native compilation |

### Platform-Specific Tools

#### Windows
- Visual Studio 2022 with C++ workload
- Windows 10 SDK

#### macOS
- Xcode Command Line Tools
- macOS 11.0+ SDK

#### Linux
- GCC/Clang
- GTK3 development libraries
- pkg-config

```bash
# Ubuntu/Debian
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev

# Fedora
sudo dnf install clang cmake ninja-build gtk3-devel
```

## Setup

### 1. Clone Repository

```bash
git clone https://github.com/your-repo/oracle-drive.git
cd oracle-drive
```

### 2. Install Flutter

```bash
# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable ~/flutter

# Add to PATH
export PATH="$PATH:$HOME/flutter/bin"

# Verify installation
flutter doctor
```

### 3. Install Rust

```bash
# Install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Verify installation
rustc --version
cargo --version
```

### 4. Install Flutter Rust Bridge

```bash
cargo install flutter_rust_bridge_codegen
```

## Building

### Development Build

```bash
# Install Dart dependencies
flutter pub get

# Build Rust SDK (debug)
cd rust/fabula_nova_sdk
cargo build
cd ../..

# Generate FRB bindings
cd rust/fabula_nova_sdk
flutter_rust_bridge_codegen generate
cd ../..

# Run the app
flutter run -d macos  # or windows, linux
```

### Release Build

```bash
# Build Rust SDK (release)
cd rust/fabula_nova_sdk
cargo build --release
cd ../..

# Build Flutter app
flutter build macos --release  # or windows, linux
```

### Build Output

| Platform | Location |
|----------|----------|
| Windows | `build/windows/x64/runner/Release/` |
| macOS | `build/macos/Build/Products/Release/Oracle Drive.app` |
| Linux | `build/linux/x64/release/bundle/` |

## Project Structure

```
oracle-drive/
├── lib/                    # Dart/Flutter source
├── rust/
│   └── fabula_nova_sdk/   # Rust native library
│       ├── src/           # Rust source
│       ├── Cargo.toml     # Rust manifest
│       └── pubspec.yaml   # FRB integration
├── macos/                 # macOS runner
├── windows/               # Windows runner
├── linux/                 # Linux runner
├── test/                  # Unit tests
├── pubspec.yaml           # Flutter manifest
└── analysis_options.yaml  # Lint configuration
```

## Common Tasks

### Regenerate FRB Bindings

After modifying Rust API (`api.rs`):

```bash
cd rust/fabula_nova_sdk
flutter_rust_bridge_codegen generate
```

### Run Tests

```bash
# Dart tests
flutter test

# Rust tests
cd rust/fabula_nova_sdk
cargo test
```

### Code Analysis

```bash
# Dart analysis
flutter analyze

# Rust analysis
cd rust/fabula_nova_sdk
cargo clippy
```

### Format Code

```bash
# Dart formatting
dart format lib/

# Rust formatting
cd rust/fabula_nova_sdk
cargo fmt
```

## Troubleshooting

### "flutter_rust_bridge not found"

```bash
# Ensure cargo bin is in PATH
export PATH="$PATH:$HOME/.cargo/bin"

# Reinstall
cargo install flutter_rust_bridge_codegen --force
```

### "Rust library not found"

The native library must be built before running:

```bash
cd rust/fabula_nova_sdk
cargo build
```

### "dylib loading failed" (macOS)

Ensure the library is properly signed:

```bash
codesign --force --sign - rust/fabula_nova_sdk/target/release/libfabula_nova_sdk.dylib
```

### "GTK not found" (Linux)

Install GTK3 development files:

```bash
sudo apt install libgtk-3-dev
```

### FRB Generation Errors

If code generation fails:

1. Check Rust syntax in `api.rs`
2. Ensure all types are `#[frb(dart_async)]` compatible
3. Clean and rebuild:

```bash
cd rust/fabula_nova_sdk
cargo clean
flutter_rust_bridge_codegen generate
```

## IDE Setup

### VS Code

Recommended extensions:
- Flutter
- Dart
- rust-analyzer
- Better TOML

Settings (`.vscode/settings.json`):
```json
{
  "dart.flutterSdkPath": "~/flutter",
  "rust-analyzer.cargo.features": "all"
}
```

### Android Studio / IntelliJ

1. Install Flutter and Dart plugins
2. Install Rust plugin
3. Configure Flutter SDK path
4. Open project as Flutter project

## Continuous Integration

The project uses GitHub Actions for CI/CD. See `.github/workflows/release.yml`:

```yaml
# Simplified workflow
on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    strategy:
      matrix:
        os: [windows-latest, macos-latest, ubuntu-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - uses: dtolnay/rust-toolchain@stable
      - run: flutter pub get
      - run: cd rust/fabula_nova_sdk && cargo build --release
      - run: flutter build ${{ matrix.platform }} --release
```

## See Also

- [[Contributing]] - Contribution guidelines
- [[Code Style]] - Coding conventions
- [[Architecture]] - System design
