# Oracle Drive

**Oracle Drive** is a comprehensive, modern modding suite designed for the **Final Fantasy XIII Trilogy** (FF13, FF13-2, Lightning Returns). Built with Flutter and high-performance Rust libraries via Flutter Rust Bridge, it provides a unified interface for exploring, extracting, and modifying game resources.

## Supported Games

- **Final Fantasy XIII** - Includes exclusive Crystalium Editor
- **Final Fantasy XIII-2**
- **Lightning Returns: Final Fantasy XIII**

Each game features unique theming and game-specific functionality, with seamless switching between titles.

---

## Key Features

### Archive Management (WhiteBinTools)
Explore and modify game archives (`.bin`) with ease.
- **File Tree Browsing:** Navigate the internal structure of game archives hierarchically.
- **Extraction:** Extract specific files or entire directories for modification.
- **Batch Repacking:** Seamlessly repack modified files back into the archives.
- **Real-time Progress:** Track extraction and repacking progress with detailed logging.

### Workspace Manager (WhitePackData)
A dedicated workspace for managing `.wpd` and `.bin` files.
- **Context-Sensitive Actions:** Quickly unpack and repack package files.
- **File System Integration:** View and manage your workspace directly within the tool.
- **Batch CLB Decompilation:** Decompile Crystal Logic Bytecode files with integrated Java decompiler.
- **DDS Texture Support:** Manipulate and convert texture files.
- **Java Source Viewer:** View decompiled CLB source code.

### Database Editor (WhiteDatabase)
A powerful editor for game database files (`.wdb`).
- **Table View:** View data in a structured, sortable table.
- **Smart Filtering:** Filter by raw values, resolved enum names, or linked string content.
- **Schema-Aware:** Validates edits against known game schemas.
- **Record Management:** Add new records, clone existing ones, or bulk update fields.
- **Import/Export:** Export and import databases as JSON.

### Text Editor (ZoneTextResource)
Localize and modify game text (`.ztr`).
- **Fast Search:** Uses a local Isar database for instant text searching across thousands of entries.
- **Rich Editing:** Modify game strings with support for control codes.
- **Region-Aware Loading:** Filter ZTR files by language/region.
- **Import/Export:** Export to `.txt` for external translation or edit directly within the app.

### Workflow System
A powerful visual automation system for complex modding tasks.
- **Visual Node Editor:** Drag-and-drop node-based workflow canvas.
- **30+ Node Types:** Including control flow, WPD/WBT/WDB/ZTR/IMG operations, and variable management.
- **Connection Validation:** Type-safe connections between nodes.
- **Execution Engine:** Run workflows with real-time progress tracking and error reporting.
- **Save/Load Workflows:** Persist workflows as JSON for reuse and sharing.
- **Undo/Redo Support:** Full history management for workflow editing.
- **Example Workflows:** Includes sample workflows demonstrating database transformations.

### Crystalium Editor (FF13 Only)
A specialized 3D visualizer and editor for character progression (`.cgt`, `.mcp`).
- **3D Visualization:** View the Crystarium tree in a fully interactive 3D space.
- **Node Management:** Navigate the tree, rename nodes, and inspect properties.
- **Progression Editing:** Create new "offshoots" (branches) based on existing patterns to expand character growth.
- **Role Support:** Supports all 6 roles - Defender, Attacker, Blaster, Enhancer, Jammer, Healer.

### Settings & Journal
- **Operation Journal:** Tracks all modifications with timestamps and batch grouping.
- **Retention Policies:** Configure automatic cleanup based on age or entry count.
- **Workspace Configuration:** Per-workflow path management.

### Console
- **Real-time Logging:** Live log streaming from both Dart and Rust layers.
- **Collapsible Panel:** Slide-in console at the bottom of the screen.
- **Debug Support:** Full visibility into application operations.

---

## Technology Stack

- **Frontend:** Flutter (Dart 3.10+) with Riverpod state management
- **Backend:** Rust SDK (`fabula_nova_sdk`) via Flutter Rust Bridge
- **Database:** Isar (local-first, encrypted storage)
- **UI:** Custom "Crystal" design system with 40+ themed components
- **Platforms:** Windows, macOS, Linux

---

## Credits & Acknowledgements

This project would not be possible without the incredible work of the Final Fantasy XIII modding community.

### Special Shoutout
A massive thank you to the **Fabula Nova Crystallis: Modding Community** Discord for their tireless research, documentation, and support.

### Core Research
Oracle Drive builds upon the foundational research and documentation developed by **[Surihix](https://github.com/Surihix)** and their open-source tools:

- **[WhiteBinTools](https://github.com/Surihix/WhiteBinTools):** Archive handling research.
- **[IMGBlibrary](https://github.com/Surihix/IMGBlibrary):** Image resource processing.
- **[WPDtool](https://github.com/Surihix/WPDtool):** Package data management.
- **[WDBJsonTool](https://github.com/Surihix/WDBJsonTool):** Database serialization.
- **[ZTRtool](https://github.com/Surihix/ZTRtool):** Text resource management.

---

## Development

This project is a Flutter application with Rust FFI integration.

### Prerequisites
- Flutter SDK 3.10+
- Rust toolchain (for building `fabula_nova_sdk`)
- Platform-specific build tools

### Getting Started
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Build the Rust SDK: `cd rust/fabula_nova_sdk && cargo build --release`
4. Run the app: `flutter run`

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
