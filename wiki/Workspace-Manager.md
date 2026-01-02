# Workspace Manager (WhitePackData)

The Workspace Manager provides a unified interface for managing extracted game files, package data (`.wpd`), and decompilation tools.

## Overview

The Workspace is your central hub for working with extracted game files. It provides:
- File system browsing within your workspace
- Package (`.wpd`) unpacking and repacking
- CLB script decompilation
- Texture conversion tools

## Interface

```
┌─────────────────────────────────────────────────────────┐
│  Workspace: /Users/you/ff13_mod/                        │
│  [Change]  [Refresh]  [Unpack WPD]  [Repack WPD]        │
├──────────────────────────┬──────────────────────────────┤
│                          │                              │
│   📁 workspace           │  File Actions                │
│   ├── 📁 database        │  ─────────────────           │
│   │   └── 📄 enemy.wdb   │  📄 script.clb               │
│   ├── 📁 scripts         │                              │
│   │   └── 📄 script.clb  │  [Decompile]                 │
│   ├── 📁 textures        │  [View Source]               │
│   │   └── 📄 char.imgb   │  [Delete]                    │
│   └── 📁 packages        │                              │
│       └── 📄 data.wpd    │  Size: 24 KB                 │
│                          │  Modified: 2024-01-15        │
└──────────────────────────┴──────────────────────────────┘
```

## Setting Up Your Workspace

### Initial Configuration
1. Go to **Settings**
2. Set **Workspace Path** to your modding directory
3. The workspace persists across sessions

### Recommended Structure
```
workspace/
├── extracted/          # Files from archives
│   ├── white_img/
│   └── white_data/
├── modified/           # Your modifications
├── output/             # Repacked files
└── backup/             # Original backups
```

## Package Data (WPD)

### What is WPD?
WhitePackData (`.wpd`) files are sub-archives within the game that contain grouped assets.

### Unpacking WPD
1. Select a `.wpd` file in the workspace
2. Click **Unpack WPD**
3. Choose destination directory
4. Contents are extracted

### Repacking WPD
1. Click **Repack WPD**
2. Select the unpacked directory
3. Choose output location
4. New `.wpd` is created

### WPD Structure
```
package.wpd
├── file1.wdb
├── file2.ztr
└── subdir/
    └── file3.dat
```

## CLB Decompilation

### Crystal Logic Bytecode
CLB files contain compiled game scripts. Oracle Drive can decompile them to readable Java-like source code.

### Decompiling Scripts
1. Select a `.clb` file
2. Click **Decompile**
3. Wait for the Java decompiler (CFR) to process
4. View source in the **Java Source Viewer**

### Batch Decompilation
1. Select a folder containing `.clb` files
2. Click **Batch Decompile**
3. All scripts are decompiled
4. Output saved alongside originals

### Source Viewer
The integrated source viewer provides:
- Syntax highlighting
- Line numbers
- Search functionality
- Copy to clipboard

```java
// Example decompiled CLB
public class BattleScript {
    public void onBattleStart() {
        if (this.enemyCount > 5) {
            this.playBGM("battle_boss");
        }
    }
}
```

## Texture Handling

### Supported Formats
| Format | Description | Actions |
|--------|-------------|---------|
| `.imgb` | Image binary | Extract to DDS |
| `.xgr` | Compressed texture | Extract to DDS |
| `.dds` | DirectX texture | View, edit, repack |

### Extracting Textures
1. Select an `.imgb` or `.xgr` file
2. Click **Extract to DDS**
3. Choose destination
4. DDS file is created

### Repacking Textures
1. Modify the DDS file externally
2. Select the modified DDS
3. Click **Repack to IMGB**
4. Ensure size matches original

> **Important**: Repacked textures must match original dimensions and format.

## Context Menu Actions

Right-click files for quick actions:

| Action | Description |
|--------|-------------|
| Open | Open with appropriate editor |
| Open in External | Open with system default app |
| Decompile | Decompile CLB to Java |
| Extract | Extract to another location |
| Delete | Remove file from workspace |
| Copy Path | Copy file path to clipboard |
| Reveal in Finder | Open containing folder |

## File Associations

Oracle Drive automatically recognizes file types:

| Extension | Opens With |
|-----------|------------|
| `.wdb` | Database Editor |
| `.ztr` | Text Editor |
| `.cgt` | Crystalium Editor |
| `.clb` | Java Source Viewer |
| `.imgb` | Texture Viewer |
| `.wpd` | Unpack Dialog |

Double-click files to open with the associated editor.

## Workflow Integration

The Workspace integrates with the [[Workflow System]]:

### Available Nodes
- **WPD Unpack** - Unpack package in workflow
- **WPD Repack** - Repack package in workflow
- **IMG Extract** - Extract textures
- **IMG Repack** - Repack textures

### Example Workflow
```
Start → WPD Unpack → Modify WDB → WPD Repack → End
```

## Best Practices

### Organization
- Use descriptive folder names
- Separate extracted and modified files
- Keep backups of originals

### Version Control
- Consider using Git for your workspace
- Track changes to modified files
- Document your modifications

### File Management
- Delete unused extracted files
- Clean up failed extractions
- Organize by modification purpose

## Console Output

Operations show progress in the console:

```
[INFO] Unpacking: data.wpd
[INFO] Extracting: file1.wdb (24 KB)
[INFO] Extracting: file2.ztr (8 KB)
[INFO] Unpacked 2 files to /workspace/data/

[INFO] Decompiling: script.clb
[INFO] Running CFR decompiler...
[INFO] Decompilation complete: script.java
```

## Troubleshooting

### "Workspace path not set"
- Go to Settings and configure your workspace path
- Ensure the path exists and is writable

### "Decompilation failed"
- Check that Java is available in PATH
- Verify the CLB file isn't corrupted
- Check console for detailed error

### "Texture size mismatch"
- Repacked texture must match original dimensions
- Check DDS format compatibility
- Ensure proper compression settings

## See Also

- [[Archive Management]] - Extract files to workspace
- [[Database Editor]] - Edit extracted WDB files
- [[Text Editor]] - Edit extracted ZTR files
- [[Workflow System]] - Automate workspace operations
