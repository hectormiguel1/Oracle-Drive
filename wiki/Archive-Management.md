# Archive Management (WhiteBin Tools)

The Archive Management module provides tools for browsing, extracting, and repacking game archives (`.bin` files) used by the Final Fantasy XIII trilogy.

## Overview

WhiteBin archives are the primary container format used by FF13 games to store game assets. Each archive contains compressed files organized in a hierarchical structure.

## Interface

### Main View

```
┌─────────────────────────────────────────────────────────┐
│  [Open Archive]  [Extract All]  [Repack]  [Refresh]     │
├──────────────────────────┬──────────────────────────────┤
│                          │                              │
│   📁 white_img           │  File Details                │
│   ├── 📁 gui             │  ─────────────────           │
│   │   ├── 📁 menu        │  Name: icon_weapon.dds       │
│   │   │   ├── 📄 bg.dds  │  Size: 1,024 KB              │
│   │   │   └── 📄 btn.dds │  Compressed: 512 KB          │
│   │   └── 📁 hud         │  Type: DDS Texture           │
│   └── 📁 chr             │                              │
│       └── ...            │  [Extract] [View]            │
│                          │                              │
└──────────────────────────┴──────────────────────────────┘
```

### Components

| Component | Description |
|-----------|-------------|
| File Tree | Hierarchical view of archive contents |
| Details Panel | Metadata for selected file |
| Toolbar | Primary actions |
| Context Menu | Right-click options |

## Opening Archives

### Supported Files
- `.bin` - WhiteBin archive files
- Common archives: `white_img.bin`, `white_data.bin`, etc.

### Opening Steps
1. Click **Open Archive** in the toolbar
2. Navigate to your game's data directory
3. Select a `.bin` file
4. Wait for the file tree to populate

> **Note**: Large archives may take a few seconds to parse.

## Browsing Files

### Navigation
- **Click** folders to expand/collapse
- **Double-click** files to view details
- **Right-click** for context menu
- Use **keyboard arrows** to navigate

### File Types

| Extension | Type | Description |
|-----------|------|-------------|
| `.wdb` | Database | Game data tables |
| `.ztr` | Text | Localization strings |
| `.imgb` | Texture | Image data (DDS format) |
| `.xgr` | Texture | Compressed texture |
| `.wpd` | Package | Sub-archive package |
| `.clb` | Script | Crystal Logic Bytecode |
| `.cgt` | Crystarium | Progression tree data |
| `.mcp` | Pattern | Crystarium patterns |

### Search
- Use the search bar to filter files by name
- Supports partial matching and wildcards

## Extracting Files

### Single File Extraction
1. Select a file in the tree
2. Click **Extract** in the details panel (or right-click)
3. Choose destination directory
4. File is extracted and decompressed

### Folder Extraction
1. Right-click a folder
2. Select **Extract Folder**
3. Choose destination
4. All files in the folder are extracted

### Batch Extraction
1. Click **Extract All** in the toolbar
2. Choose destination directory
3. Entire archive is extracted with folder structure preserved

### Extraction Options

| Option | Description |
|--------|-------------|
| Preserve Structure | Maintain folder hierarchy |
| Decompress | Automatically decompress ZLIB data |
| Overwrite | Replace existing files |

## Repacking Archives

After modifying extracted files, you can repack them into the archive.

### Repack Workflow
1. Extract files you want to modify
2. Edit files using appropriate editors (Database, Text, etc.)
3. Open the original archive
4. Click **Repack**
5. Select the directory containing modified files
6. Oracle Drive identifies changed files
7. Creates new archive with modifications

### Repack Options

| Option | Description |
|--------|-------------|
| Validate Sizes | Ensure repacked files fit in original slots |
| Create Backup | Save original archive before overwriting |
| Compress | Apply ZLIB compression to files |

### Size Constraints
Some file slots have size limits. If a modified file exceeds its slot:
- A warning is displayed
- You may need to reduce file size
- Or use a different modification approach

## Console Output

The console shows real-time progress during operations:

```
[INFO] Opening archive: white_img.bin
[INFO] Parsing filelist... 2,847 entries
[INFO] Archive loaded successfully
[INFO] Extracting: gui/menu/bg.dds
[INFO] Extracted 1 file (1,024 KB)
```

### Log Levels
- **INFO**: Normal operation progress
- **WARN**: Non-critical issues
- **ERROR**: Operation failures

## Technical Details

### Archive Format

WhiteBin archives consist of:
1. **FileList** - Encrypted index of file entries
2. **Container** - ZLIB-compressed file data

```
┌────────────────────────┐
│      File Header       │
├────────────────────────┤
│  FileList (encrypted)  │
│  - File names          │
│  - Offsets             │
│  - Sizes               │
├────────────────────────┤
│  Container (ZLIB)      │
│  - Compressed data     │
│  - File boundaries     │
└────────────────────────┘
```

### Encryption
FileLists are encrypted with game-specific keys. Oracle Drive handles decryption automatically based on the selected game.

### Compression
File data uses ZLIB compression. Decompression is automatic during extraction.

## Best Practices

### Before Modifying
1. **Backup** original archives
2. **Test** on a copy of your game installation
3. **Document** changes you make

### During Extraction
- Extract to a dedicated workspace folder
- Keep extracted files organized
- Note which files you modify

### During Repacking
- Validate file sizes before repacking
- Test the game after repacking
- Keep original archives for rollback

## Troubleshooting

### "Failed to parse archive"
- Ensure the file is a valid WhiteBin archive
- Check that the correct game is selected
- Verify the file isn't corrupted

### "File too large for slot"
- Modified file exceeds size limit
- Reduce file size or use alternative approach
- Some modifications may not be possible

### "Encryption key not found"
- Wrong game selected
- Unsupported archive variant
- Try selecting a different game

## See Also

- [[File Formats#whiteBin|WhiteBin Format Specification]]
- [[Workspace Manager]] - Managing extracted files
- [[Workflow System]] - Automating extraction/repacking
