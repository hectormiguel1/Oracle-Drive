# Text Editor (ZoneTextResource)

The Text Editor provides tools for viewing and modifying game text and localization files (`.ztr`), enabling translation and text customization for the Final Fantasy XIII trilogy.

## Overview

ZTR (Zone Text Resource) files contain all in-game text, including:
- Dialogue and cutscene text
- Menu labels and UI strings
- Item names and descriptions
- Tutorial and help text
- System messages

## Interface

```
┌─────────────────────────────────────────────────────────────┐
│  zone_menu.ztr (English)                                    │
│  [Open] [Save] [Export TXT] [Import TXT] [Add Entry]        │
├─────────────────────────────────────────────────────────────┤
│  Search: [potion___________] [🔍]  Results: 12 of 1,847     │
├─────────────────────────────────────────────────────────────┤
│  ID                    │ Text                               │
│────────────────────────┼────────────────────────────────────│
│  ITM_POTION_NAME       │ Potion                             │
│  ITM_POTION_DESC       │ Restores a small amount of HP.     │
│  ITM_HIPOTION_NAME     │ Hi-Potion                          │
│  ITM_HIPOTION_DESC     │ Restores a moderate amount of HP.  │
│  ITM_MEGAPOTION_NAME   │ Mega-Potion                        │
│────────────────────────┴────────────────────────────────────│
│  Entry Editor                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Restores a small amount of HP.                         │ │
│  │ {color:cyan}Heals 100 HP{/color}                       │ │
│  └────────────────────────────────────────────────────────┘ │
│  [Save Entry] [Revert] [Preview]                            │
└─────────────────────────────────────────────────────────────┘
```

## Opening Files

### Supported Formats
- `.ztr` - Zone Text Resource files
- Multiple language variants per file

### Opening Steps
1. Click **Open** in the toolbar
2. Navigate to extracted ZTR file
3. Select the file
4. Text entries load into the table

### Language Filtering
ZTR files may contain multiple languages. Use the language selector to filter:
- English (EN)
- Japanese (JP)
- French (FR)
- German (DE)
- Spanish (ES)
- Italian (IT)

## Searching Text

### Quick Search
Oracle Drive uses Isar for instant searching across thousands of entries:

1. Type search term in the search bar
2. Results filter in real-time
3. Matches highlighted in results

### Search Options
| Option | Description |
|--------|-------------|
| Case Sensitive | Match exact case |
| ID Only | Search entry IDs only |
| Text Only | Search text content only |
| Regex | Use regular expressions |

### Search Examples
| Search | Finds |
|--------|-------|
| `potion` | All entries containing "potion" |
| `^ITM_` | IDs starting with "ITM_" (regex) |
| `{color}` | Entries with color codes |

## Editing Text

### Inline Editing
1. Double-click a text entry
2. Edit in the text area below
3. Click **Save Entry** or press Ctrl+S

### Control Codes
ZTR files support special control codes for formatting:

| Code | Effect | Example |
|------|--------|---------|
| `{color:red}` | Red text | `{color:red}Warning!{/color}` |
| `{color:cyan}` | Cyan text | `{color:cyan}Info{/color}` |
| `{icon:button_a}` | Button icon | `Press {icon:button_a}` |
| `{wait:1000}` | Pause display | `Loading{wait:500}...` |
| `{newline}` | Line break | `Line 1{newline}Line 2` |
| `{var:0}` | Variable insert | `{var:0} HP restored` |

### Preview
Click **Preview** to see how text will appear in-game with:
- Formatted colors
- Icon substitutions
- Line breaks applied

### Text Rendering
The editor shows a preview of formatted text:
```
┌─────────────────────────────────────┐
│  Restores a small amount of HP.    │
│  Heals 100 HP  ← (shown in cyan)   │
└─────────────────────────────────────┘
```

## Entry Management

### Adding Entries
1. Click **Add Entry**
2. Enter unique ID
3. Enter text content
4. Click **Create**

### Deleting Entries
1. Select entry
2. Right-click → **Delete**
3. Confirm deletion

> **Warning**: Deleting entries may cause missing text in-game.

### Duplicating Entries
1. Select entry
2. Right-click → **Duplicate**
3. Modify the new entry ID

## Import/Export

### TXT Export
Export entries as plain text for external editing:

1. Click **Export TXT**
2. Choose destination
3. File created with ID/text pairs

```
ITM_POTION_NAME=Potion
ITM_POTION_DESC=Restores a small amount of HP.
ITM_HIPOTION_NAME=Hi-Potion
```

### TXT Import
Import modified text:

1. Click **Import TXT**
2. Select TXT file
3. Entries merged with existing data

### Translation Workflow
1. Export to TXT
2. Send to translator
3. Receive translated TXT
4. Import translations
5. Save ZTR file

### Partial Import
Only changed entries are updated. Missing IDs are ignored.

## Text Encoding

### Shift-JIS Support
FF13 games use Shift-JIS encoding for Japanese text. Oracle Drive handles:
- Automatic encoding detection
- Character conversion
- Control code preservation

### Special Characters
Some characters require escape sequences:
| Character | Escape |
|-----------|--------|
| `{` | `{{` |
| `}` | `}}` |
| `=` | `\=` |

## Text Caching

Oracle Drive caches ZTR text in local Isar databases for fast searching:

### Cache Benefits
- Instant search across all loaded files
- Persistent between sessions
- Indexed for performance

### Cache Management
- Cache auto-updates when files change
- Clear cache in Settings if issues occur
- Cache stored per-game

## Workflow Integration

Text operations available in [[Workflow System|workflows]]:

### Available Nodes
| Node | Purpose |
|------|---------|
| ZTR Open | Load text file |
| ZTR Save | Save modifications |
| ZTR Find | Search for entries |
| ZTR Modify | Change entry text |
| ZTR Add | Add new entry |
| ZTR Delete | Remove entry |

### Example Workflow
```
Start → ZTR Open → ZTR Find (contains "gold")
      → ZTR Modify (replace "gold" with "Gil") → ZTR Save → End
```

## Console Output

```
[INFO] Loading ZTR: zone_menu.ztr
[INFO] Decompressing dictionary...
[INFO] Decoded 1,847 text entries
[INFO] Caching entries to Isar database
[INFO] Modified entry: ITM_POTION_DESC
[INFO] Saving ZTR: zone_menu.ztr
[INFO] Compressing with dictionary...
[INFO] Save complete (24 KB)
```

## Best Practices

### Before Editing
1. **Backup** original ZTR files
2. **Note** control codes before modifying
3. **Test** short text changes first

### During Editing
- Preserve control codes (colors, icons)
- Keep text within reasonable length
- Use Preview to check formatting

### Text Length
Some text fields have length limits:
- Dialogue boxes have max width
- Menu items may truncate
- Test in-game after changes

### Translation Tips
- Preserve `{var:N}` placeholders
- Maintain control code structure
- Consider text expansion (translations often longer)

## Common ZTR Files

### FF13
| File | Contents |
|------|----------|
| `zone_menu.ztr` | Menu strings |
| `zone_btl.ztr` | Battle text |
| `zone_event.ztr` | Event/dialogue |
| `zone_tutorial.ztr` | Tutorial text |

### FF13-2
| File | Contents |
|------|----------|
| `zone_live.ztr` | Live Trigger text |
| `zone_historia.ztr` | Historia Crux |
| `zone_monster.ztr` | Monster info |

### Lightning Returns
| File | Contents |
|------|----------|
| `zone_quest.ztr` | Quest text |
| `zone_garb.ztr` | Garb descriptions |
| `zone_npc.ztr` | NPC dialogue |

## Troubleshooting

### "Encoding error"
- File may use unsupported encoding
- Try different game selection
- Check file isn't corrupted

### "Control code invalid"
- Mismatched braces
- Unknown code name
- Check syntax carefully

### "Text truncated in-game"
- Text exceeds display width
- Shorten the text
- Test different line breaks

### "Search slow"
- Cache may need rebuilding
- Clear cache in Settings
- Reload the file

## See Also

- [[File Formats#ztr|ZTR Format Specification]]
- [[Workflow System]] - Automate text edits
- [[Rust SDK]] - ZTR API documentation
