# Frequently Asked Questions

## General

### What is Oracle Drive?

Oracle Drive is a comprehensive modding suite for the Final Fantasy XIII trilogy (FF13, FF13-2, and Lightning Returns). It provides tools for extracting, editing, and repacking game files including databases, text, textures, and more.

### Which games are supported?

- **Final Fantasy XIII** (full support + Crystalium Editor)
- **Final Fantasy XIII-2** (full support)
- **Lightning Returns: Final Fantasy XIII** (full support)

### What platforms does Oracle Drive run on?

- Windows 10/11
- macOS 11+
- Linux (Ubuntu 20.04+, Fedora, etc.)

### Is Oracle Drive free?

Yes! Oracle Drive is open-source software released under the MIT license.

### Where can I get help?

- This wiki for documentation
- [GitHub Issues](https://github.com/your-repo/oracle-drive/issues) for bugs
- [Discord](https://discord.gg/fabula-nova) for community support

---

## Installation

### How do I install Oracle Drive?

Download the latest release from the [Releases page](https://github.com/your-repo/oracle-drive/releases) and extract it. No installation required.

### Do I need to install any dependencies?

No, Oracle Drive is self-contained. All required libraries are bundled.

### Can I run it from a USB drive?

Yes, Oracle Drive is portable and can run from any location.

### How do I update Oracle Drive?

Download the new version and replace your existing installation. Settings are preserved.

---

## Game Files

### Where are the game files located?

**Steam:**
```
Windows: C:\Program Files (x86)\Steam\steamapps\common\FINAL FANTASY XIII\
macOS: ~/Library/Application Support/Steam/steamapps/common/FINAL FANTASY XIII/
```

**Other versions:**
Check your game installation directory for `white_img.bin`, `white_data.bin`, etc.

### Which files can I edit?

| Extension | Type | Editor |
|-----------|------|--------|
| `.bin` | Archives | Archive Management |
| `.wpd` | Packages | Workspace Manager |
| `.wdb` | Databases | Database Editor |
| `.ztr` | Text | Text Editor |
| `.cgt` | Crystarium | Crystalium Editor |
| `.imgb` | Textures | Image Tools |
| `.clb` | Scripts | Decompiler |

### Will editing files break my game?

If done incorrectly, yes. Always:
1. Backup original files
2. Work on a copy of the game
3. Test changes incrementally
4. Keep notes of what you modify

### Can I undo changes to game files?

Restore from your backup. Oracle Drive cannot reverse changes to game files once saved.

---

## Features

### Why can't I see the Crystalium Editor?

The Crystalium Editor is only available for Final Fantasy XIII. Make sure "FF13" is selected in the game selector.

### How do I create a workflow?

See [[Workflow System]] for a complete guide. Basic steps:
1. Go to Workflow screen
2. Add a Start node
3. Add operation nodes
4. Connect nodes together
5. Add an End node
6. Click Run

### Can I edit multiple files at once?

Yes! Use the Workflow System to batch process files, or open multiple tabs in the editors.

### How do I search for text?

In the Text Editor:
1. Open a ZTR file
2. Type your search term in the search bar
3. Results filter instantly

Oracle Drive uses an optimized database for fast searching.

### Can I translate the game to another language?

Yes! Use the Text Editor to:
1. Export text to TXT
2. Translate the text
3. Import translations
4. Save the ZTR file
5. Repack into the game

---

## Technical

### Why is extraction slow?

Large archives (like `white_img.bin`) contain thousands of files. Extraction uses parallel processing but still takes time for large operations.

### Why is my file too large to repack?

Some file slots have fixed sizes. If your modification makes the file larger, you may need to:
- Reduce content size
- Use a different approach
- Accept the limitation

### Does Oracle Drive modify game EXEs?

No, Oracle Drive only modifies data files. It does not patch executables.

### Is Oracle Drive safe to use?

Yes, Oracle Drive:
- Is open-source (you can review the code)
- Doesn't require administrator rights
- Doesn't access the internet (except for updates)
- Doesn't modify system files

### Why does my antivirus flag it?

Some antivirus programs flag Flutter/Rust applications. This is a false positive. Oracle Drive is safe - you can verify by reviewing the source code.

---

## Modding

### Can I share my mods?

Yes! You can share:
- Modified files (users repack themselves)
- Workflow files (JSON format)
- Complete mod packages

### How do I install mods from others?

1. Backup your game files
2. Extract the mod files
3. Replace the corresponding game files
4. Test the game

### Are mods compatible between games?

No, each game uses different file structures. Mods must be created specifically for each title.

### Can I use Oracle Drive with other mod tools?

Yes, Oracle Drive produces standard file formats compatible with other FF13 modding tools.

---

## Troubleshooting

### The app won't start

See [[Troubleshooting#app-wont-start|App Won't Start]]

### Files aren't loading

See [[Troubleshooting#files-not-loading|Files Not Loading]]

### Changes aren't appearing in-game

See [[Troubleshooting#changes-not-appearing|Changes Not Appearing]]

### I found a bug

Please report it on [GitHub Issues](https://github.com/your-repo/oracle-drive/issues) with:
- Description of the problem
- Steps to reproduce
- Console output
- Your OS and Oracle Drive version

---

## Contributing

### How can I contribute?

See [[Contributing]] for ways to help:
- Code contributions
- Documentation
- Bug reports
- Feature requests
- Community support

### Do I need programming skills?

Not necessarily! You can contribute by:
- Testing and reporting bugs
- Writing documentation
- Helping other users
- Suggesting features

### How do I request a feature?

Open an issue on GitHub with:
- Clear description of the feature
- Use case (why it's needed)
- How it should work

---

## Credits

### Who created Oracle Drive?

Oracle Drive was created by Hector Ramirez with contributions from the community.

### Who researched the file formats?

Special thanks to [Surihix](https://github.com/Surihix) for extensive file format research and documentation.

### Where can I learn more about FF13 modding?

- [Fabula Nova Crystallis Discord](https://discord.gg/fabula-nova)
- [Surihix's Tools](https://github.com/Surihix)
- This wiki

## See Also

- [[Getting Started]] - First steps
- [[Troubleshooting]] - Common issues
- [[Contributing]] - How to help
