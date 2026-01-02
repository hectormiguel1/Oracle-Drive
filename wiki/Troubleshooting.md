# Troubleshooting

This guide covers common issues and their solutions.

## App Issues

### App Won't Start

**Symptoms:**
- App crashes on launch
- Blank window appears then closes
- Error dialog on startup

**Solutions:**

1. **Check system requirements**
   - Windows 10+, macOS 11+, or modern Linux
   - At least 4 GB RAM

2. **Reinstall the app**
   - Delete the existing installation
   - Download fresh copy from releases
   - Extract to a new location

3. **Clear app data**
   ```
   Windows: %APPDATA%\oracle_drive\
   macOS: ~/Library/Application Support/oracle_drive/
   Linux: ~/.local/share/oracle_drive/
   ```

4. **Check for conflicting software**
   - Disable antivirus temporarily
   - Close other resource-heavy apps

5. **Run from terminal for errors**
   ```bash
   # macOS/Linux
   ./oracle_drive

   # Windows
   oracle_drive.exe
   ```

### App is Slow

**Symptoms:**
- UI is unresponsive
- Operations take too long
- High memory usage

**Solutions:**

1. **Close unused tabs**
   - Only keep needed files open
   - Close completed workflows

2. **Clear cache**
   - Settings → Clear Cache
   - Restart the app

3. **Reduce file size**
   - Work with smaller batches
   - Extract only needed files

4. **Check disk space**
   - Ensure sufficient free space
   - Use SSD if possible

### Crashes During Operation

**Symptoms:**
- App closes unexpectedly
- Operations never complete
- "Not responding" message

**Solutions:**

1. **Check console output**
   - Look for error messages before crash
   - Note the operation that caused it

2. **Reduce batch size**
   - Process fewer files at once
   - Split large operations

3. **Verify file integrity**
   - Check if source files are corrupt
   - Re-extract from game

4. **Report the issue**
   - Open GitHub issue with:
     - Console output
     - Steps to reproduce
     - File that caused crash

---

## File Issues

### Files Not Loading

**Symptoms:**
- "Failed to parse" error
- Empty file tree
- "File not found" message

**Solutions:**

1. **Check game selection**
   - Ensure correct game is selected
   - Different games use different formats

2. **Verify file path**
   - Check file exists
   - Avoid special characters in path
   - Use full path without spaces

3. **Check file format**
   - Ensure file has correct extension
   - File may be corrupted
   - Try re-extracting

4. **Check permissions**
   - Ensure read access to file
   - Move to accessible location

### Save/Export Failed

**Symptoms:**
- "Failed to save" error
- Output file not created
- Partial file written

**Solutions:**

1. **Check permissions**
   - Ensure write access to destination
   - Don't save to read-only locations

2. **Check disk space**
   - Ensure sufficient space
   - Clean up temporary files

3. **Check file locks**
   - Close file in other programs
   - Wait for other operations

4. **Try different location**
   - Save to desktop first
   - Then move to final location

### Corrupted Output

**Symptoms:**
- Game crashes with modded file
- File loads but content wrong
- Size mismatch warnings

**Solutions:**

1. **Verify modifications**
   - Check values are valid
   - Ensure schema compliance

2. **Check size constraints**
   - Some slots have max sizes
   - Reduce content if needed

3. **Round-trip test**
   - Open saved file
   - Compare with original
   - Check for differences

4. **Restore from backup**
   - Use original file
   - Apply changes again carefully

---

## Game Issues

### Changes Not Appearing

**Symptoms:**
- Game uses old data
- Modifications not visible
- Same as before editing

**Solutions:**

1. **Verify repacking**
   - Check file was repacked correctly
   - Confirm modified file replaced original

2. **Clear game cache**
   - Some games cache data
   - Delete cache folders:
     ```
     FF13: Documents\My Games\FINAL FANTASY XIII\
     ```

3. **Check file location**
   - Ensure modified archive is in game directory
   - Not in a subfolder

4. **Restart game completely**
   - Close fully (not minimized)
   - Start fresh

5. **Verify mod priority**
   - Some mods may override
   - Check load order

### Game Crashes After Mod

**Symptoms:**
- Crash on startup
- Crash at specific point
- Infinite loading

**Solutions:**

1. **Restore backup**
   - Replace modded files with originals
   - Confirm game works again

2. **Isolate the change**
   - Apply modifications one at a time
   - Find which change causes crash

3. **Check references**
   - Modified data may reference missing content
   - Verify all IDs exist

4. **Validate file structure**
   - Use Oracle Drive to check format
   - Compare with working file

5. **Check size limits**
   - Oversize files may corrupt
   - Reduce content size

### Visual Glitches

**Symptoms:**
- Texture errors
- Model distortions
- UI problems

**Solutions:**

1. **Check texture format**
   - Must match original format
   - Same dimensions required

2. **Verify compression**
   - Use correct DDS compression
   - BC1-BC5 depending on original

3. **Check metadata**
   - Texture headers must match
   - Don't change resolution

---

## Specific Features

### Archive Management

**"Failed to parse archive"**
- Check correct game selected
- Verify file is valid archive
- File may be corrupted

**"Encryption key not found"**
- Select correct game
- Unknown archive variant
- Try different game selection

**"File too large for slot"**
- Reduce file size
- Different modification approach
- Some changes impossible

### Database Editor

**"Unknown schema"**
- Schema not in dictionary
- Values still editable
- Field names generic

**"Validation failed"**
- Check value type matches
- Verify within valid range
- Use correct enum value

**Enum not resolving**
- Schema may be incomplete
- Raw values still work
- Contribute schema fixes

### Text Editor

**"Encoding error"**
- Wrong game selected
- File uses unexpected encoding
- Try different game

**Text truncated in-game**
- Text exceeds display width
- Shorten text content
- Add line breaks

**Control codes not working**
- Check syntax carefully
- Match original format
- Verify code exists

### Workflow System

**"Validation failed"**
- Check required connections
- Verify property values
- Look for disconnected nodes

**"Circular dependency"**
- Remove connection loops
- Use Loop nodes properly
- Check connection directions

**Node execution failed**
- Check input file paths
- Verify data format
- Review console output

### Crystalium Editor

**Camera spinning**
- Known limitation
- Press R to reset view
- Use Orbit mode

**Branches misplaced**
- Known issue being fixed
- Check parent node selection
- Verify pattern loaded

**State reset on modification**
- Known issue being fixed
- Save position manually
- Work incrementally

---

## Console Errors

### Common Error Messages

**"NullPointerException"**
- Missing data or state
- Reload the file
- Check input validity

**"IndexOutOfBoundsException"**
- Array access error
- File may be corrupted
- Report with file sample

**"IOException"**
- File system error
- Check permissions
- Verify path exists

**"ParseException"**
- Invalid file format
- Wrong game selected
- File may be corrupted

**"RustPanic"**
- Rust code error
- Usually data-related
- Report with details

### Reading Error Logs

Console output format:
```
[LEVEL] Timestamp - Message
[INFO]  Normal operation
[WARN]  Warning (continue)
[ERROR] Error occurred
[DEBUG] Detailed info
```

When reporting issues, include full console output.

---

## Getting Help

### Before Asking

1. Check this troubleshooting guide
2. Search existing issues on GitHub
3. Try basic solutions (restart, reinstall)
4. Prepare information to share

### Information to Provide

When reporting issues, include:

1. **Oracle Drive version**
2. **Operating system and version**
3. **Game being modded**
4. **Steps to reproduce**
5. **Expected vs actual behavior**
6. **Console output**
7. **Sample files (if possible)**

### Where to Get Help

- [[FAQ]] - Common questions
- [GitHub Issues](https://github.com/your-repo/oracle-drive/issues)
- [Discord](https://discord.gg/fabula-nova)

## See Also

- [[FAQ]] - Frequently asked questions
- [[Getting Started]] - Basic usage
- [[Contributing]] - Report bugs
