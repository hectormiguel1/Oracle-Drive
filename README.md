# Oracle Drive

**Oracle Drive** is a comprehensive, modern modding suite designed for the **Final Fantasy XIII Trilogy** (FF13, FF13-2, Lightning Returns). Built with Flutter and high-performance native C# AOT libraries, it provides a unified interface for exploring, extracting, and modifying game resources.

## Key Features

### 📦 Archive Management (WhiteBinTools)
Explore and modify game archives (`.bin`) with ease.
*   **File Tree Browsing:** Navigate the internal structure of game archives.
*   **Extraction:** Extract specific files or entire directories for modification.
*   **Batch Repacking:** seamlessly repack modified files back into the archives.

### 🗂️ Workspace Manager (WhitePackData)
A dedicated workspace for managing `.wpd` and `.bin` files.
*   **Context-Sensitive Actions:** Quickly unpack and repack package files.
*   **File System Integration:** View and manage your workspace directly within the tool.

### 📊 Database Editor (WhiteDatabase)
A powerful editor for game database files (`.wdb`).
*   **Table View:** View data in a structured, sortable table.
*   **Smart Filtering:** Filter by raw values, resolved enum names, or linked string content.
*   **Schema-Aware:** Validates edits against known game schemas.
*   **Record Management:** Add new records or clone existing ones to expand game data.

### 📝 Text Editor (ZoneTextResource)
localize and modify game text (`.ztr`).
*   **Fast Search:** Uses a local Isar database for instant text searching across thousands of entries.
*   **Rich Editing:** Modify game strings with support for control codes.
*   **Import/Export:** Export to `.txt` for external translation or edit directly within the app.

### 🔮 Crystarium Editor
A specialized 3D visualizer and editor for character progression (`.cgt`, `.mcp`).
*   **3D Visualization:** View the Crystarium tree in a fully interactive 3D space.
*   **Node Management:** Navigate the tree, rename nodes, and inspect properties.
*   **Progression Editing:** Create new "offshoots" (branches) based on existing patterns to expand character growth.

---

## Credits & Acknowledgements

This project would not be possible without the incredible work of the Final Fantasy XIII modding community.

### 🌟 Special Shoutout
A massive thank you to the **Fabula Nova Crystallis: Modding Community** Discord for their tireless research, documentation, and support.

### 🛠️ Core Technology
Oracle Drive is powered by the foundational research and tools developed by **[Surihix](https://github.com/Surihix)**. This application utilizes custom-compiled C# AOT Native Libraries based on their open-source tools:

*   **[WhiteBinTools](https://github.com/Surihix/WhiteBinTools):** Archive handling.
*   **[IMGBlibrary](https://github.com/Surihix/IMGBlibrary):** Image resource processing.
*   **[WPDtool](https://github.com/Surihix/WPDtool):** Package data management.
*   **[WDBJsonTool](https://github.com/Surihix/WDBJsonTool):** Database serialization.
*   **[ZTRtool](https://github.com/Surihix/ZTRtool):** Text resource management.

---

## Development

This project is a Flutter application.

### Getting Started
For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.