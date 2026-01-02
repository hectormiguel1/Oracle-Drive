# Getting Started

This guide will help you get Oracle Drive up and running for modding Final Fantasy XIII trilogy games.

## System Requirements

### Minimum Requirements
- **OS**: Windows 10+, macOS 11+, or Linux (Ubuntu 20.04+)
- **RAM**: 4 GB
- **Storage**: 500 MB for application
- **Display**: 1280x720 minimum resolution

### Recommended
- **RAM**: 8 GB+ (for large archives)
- **Storage**: SSD recommended for faster extraction
- **Display**: 1920x1080 or higher

## Installation

### Pre-built Releases

1. Download the latest release from the [Releases page](https://github.com/your-repo/oracle-drive/releases)
2. Extract the archive to your preferred location
3. Run the executable:
   - **Windows**: `oracle_drive.exe`
   - **macOS**: `Oracle Drive.app`
   - **Linux**: `oracle_drive`

### Building from Source

See [[Building from Source]] for detailed instructions.

## First Launch

### 1. Select Your Game

On first launch, Oracle Drive defaults to **Final Fantasy XIII**. Use the game selector in the navigation rail to switch between:

- **FF13** (Cyan theme) - Includes Crystalium Editor
- **FF13-2** (Indigo theme)
- **Lightning Returns** (Rose Pink theme)

The selected game affects:
- Theme colors throughout the UI
- Available features (Crystalium is FF13-only)
- Database schema interpretation
- Text encoding dictionaries

### 2. Set Up Your Workspace

Navigate to **Settings** (gear icon) to configure:

| Setting | Description |
|---------|-------------|
| Workspace Path | Root directory for extracted/modified files |
| Game Installation | Path to your game installation (optional) |
| Auto-backup | Enable automatic backup of modified files |

### 3. Understanding the Interface

Oracle Drive uses a **navigation rail** on the left with these sections:

| Icon | Section | Purpose |
|------|---------|---------|
| 📦 | WhiteBin Tools | Browse and extract game archives |
| 📁 | Workspace | Manage extracted files and packages |
| 📊 | Database | Edit game databases (.wdb) |
| 📝 | Text | Edit localization files (.ztr) |
| 🔄 | Workflow | Create automation pipelines |
| ✨ | Crystalium | Edit FF13 progression (FF13 only) |
| ⚙️ | Settings | Configure application |

## Basic Workflow

### Extracting Game Files

1. Go to **WhiteBin Tools**
2. Click **Open Archive** and select a `.bin` file from your game
3. Browse the file tree to find assets
4. Right-click files or folders to extract

### Editing a Database

1. Extract a `.wdb` file using WhiteBin Tools or Workspace
2. Go to **Database Editor**
3. Click **Open** and select the extracted `.wdb`
4. Edit values in the table view
5. Click **Save** to write changes

### Modifying Text

1. Extract a `.ztr` file from the game
2. Go to **Text Editor**
3. Open the extracted `.ztr` file
4. Search for specific text using the search bar
5. Double-click entries to edit
6. Save changes when done

### Repacking Files

1. After making modifications, go to **Workspace**
2. Select the modified files
3. Click **Repack** to create the modified archive
4. Replace the original archive in your game installation

## Console and Logging

The collapsible **Console** at the bottom of the screen shows:
- Real-time operation progress
- Extraction/repacking status
- Error messages and warnings
- Debug information (in development mode)

Click the console header to expand/collapse.

## Tips for New Users

### Start Small
Begin with simple text edits before attempting complex database modifications.

### Backup Everything
Always keep copies of original game files before modifying.

### Use Workflows
For repetitive tasks, create [[Workflow System|workflows]] to automate the process.

### Check the Journal
The **Settings > Journal** tab tracks all modifications with timestamps.

### Understand File Relationships
Many game files reference each other. Modifying one may require changes to related files.

## Next Steps

- [[Archive Management]] - Deep dive into WhiteBin Tools
- [[Database Editor]] - Learn database editing features
- [[Workflow System]] - Create automated modding pipelines
- [[File Formats]] - Understand game file structures

## Troubleshooting

If you encounter issues:

1. Check the [[Troubleshooting]] guide
2. Review console output for error messages
3. Ensure you have the correct game selected
4. Verify file permissions in your workspace

For additional help, see [[FAQ]] or open an issue on GitHub.
