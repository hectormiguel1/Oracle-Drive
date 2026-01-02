# Oracle Drive Wiki

Welcome to the **Oracle Drive** wiki! Oracle Drive is a comprehensive, modern modding suite for the **Final Fantasy XIII Trilogy**.

![Oracle Drive](https://img.shields.io/badge/Flutter-3.10+-blue?logo=flutter) ![Rust](https://img.shields.io/badge/Rust-2021-orange?logo=rust) ![License](https://img.shields.io/badge/License-MIT-green)

## Supported Games

| Game | Codename | Theme Color | Special Features |
|------|----------|-------------|------------------|
| Final Fantasy XIII | `FF13_1` | Cyan | Crystalium Editor |
| Final Fantasy XIII-2 | `FF13_2` | Indigo | - |
| Lightning Returns | `FF13_LR` | Rose Pink | - |

## Quick Navigation

### Getting Started
- [[Getting Started]] - Installation and first steps
- [[Building from Source]] - Development setup
- [[FAQ]] - Frequently asked questions

### Features
- [[Archive Management]] - WhiteBin Tools for `.bin` archives
- [[Workspace Manager]] - Package data and file management
- [[Database Editor]] - Game database (`.wdb`) editing
- [[Text Editor]] - Localization and text resources
- [[Workflow System]] - Visual automation for modding tasks
- [[Crystalium Editor]] - FF13 character progression editor

### Technical Reference
- [[Architecture]] - System design and components
- [[Rust SDK]] - Native library documentation
- [[File Formats]] - Game file format specifications
- [[Workflow Nodes]] - Complete node reference

### Development
- [[Contributing]] - How to contribute
- [[Code Style]] - Coding conventions
- [[Troubleshooting]] - Common issues and solutions

## Key Capabilities

### Archive Management
Extract and repack game archives with real-time progress tracking and batch operations.

### Database Editing
View, filter, and modify game databases with schema-aware validation and enum resolution.

### Text Localization
Search, edit, and export game text with support for control codes and rich formatting.

### Visual Workflows
Create automated modding pipelines with 30+ node types for complex operations.

### 3D Crystarium Visualization
Navigate and modify the FF13 character progression tree in an interactive 3D environment.

## Technology Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart 3.10+) |
| State Management | Riverpod |
| Backend | Rust SDK via Flutter Rust Bridge |
| Database | Isar (local-first, encrypted) |
| UI Framework | Custom "Crystal" Design System |
| Platforms | Windows, macOS, Linux |

## Community & Support

- **Discord**: [Fabula Nova Crystallis Modding Community](https://discord.gg/fabula-nova)
- **Issues**: [GitHub Issues](https://github.com/your-repo/oracle-drive/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/oracle-drive/discussions)

## Credits

Oracle Drive builds upon foundational research by **[Surihix](https://github.com/Surihix)** and the FF13 modding community:

- [WhiteBinTools](https://github.com/Surihix/WhiteBinTools) - Archive research
- [IMGBlibrary](https://github.com/Surihix/IMGBlibrary) - Image processing
- [WPDtool](https://github.com/Surihix/WPDtool) - Package management
- [WDBJsonTool](https://github.com/Surihix/WDBJsonTool) - Database serialization
- [ZTRtool](https://github.com/Surihix/ZTRtool) - Text resources

---

*Oracle Drive is released under the MIT License.*
