# Database Editor (WhiteDatabase)

The Database Editor provides a powerful interface for viewing and modifying game databases (`.wdb` files), which contain structured game data like character stats, item properties, and battle parameters.

## Overview

WDB files are the primary data storage format for FF13 games. They contain typed, structured data in rows and columns, similar to a spreadsheet or SQL table.

## Interface

```
┌─────────────────────────────────────────────────────────────┐
│  enemy_stats.wdb                                            │
│  [Open] [Save] [Export JSON] [Import JSON] [Add Row]        │
├─────────────────────────────────────────────────────────────┤
│  Filter: [_______________] [Column ▼] [Contains ▼]          │
├─────────────────────────────────────────────────────────────┤
│  ID    │ Name        │ HP      │ STR   │ MAG   │ Element   │
│────────┼─────────────┼─────────┼───────┼───────┼───────────│
│  001   │ Behemoth    │ 28,500  │ 245   │ 180   │ None      │
│  002   │ Adamantoise │ 167,000 │ 412   │ 95    │ Earth     │
│  003   │ Ochu        │ 12,800  │ 156   │ 234   │ Water     │
│  004   │ Cie'th      │ 8,400   │ 189   │ 201   │ Dark      │
│────────┴─────────────┴─────────┴───────┴───────┴───────────│
│  Showing 4 of 342 records                [< 1 2 3 ... 35 >] │
└─────────────────────────────────────────────────────────────┘
```

## Opening Databases

### Supported Files
- `.wdb` - WhiteDatabase files
- Common files: `enemy.wdb`, `item.wdb`, `ability.wdb`, etc.

### Opening Steps
1. Click **Open** in the toolbar
2. Navigate to extracted game files
3. Select a `.wdb` file
4. Wait for parsing to complete

### Auto-Detection
Oracle Drive automatically detects:
- Schema type based on file name
- Field types and constraints
- Enum value mappings

## Table View

### Columns

| Feature | Description |
|---------|-------------|
| Sortable | Click header to sort |
| Resizable | Drag column borders |
| Reorderable | Drag headers to reorder |
| Type Indicators | Icons show field types |

### Field Types

| Type | Icon | Description |
|------|------|-------------|
| Integer | `#` | Whole numbers |
| Float | `.` | Decimal numbers |
| String | `"` | Text values |
| Boolean | `☑` | True/False |
| Enum | `▼` | Named values |

### Enum Resolution
Enum fields display human-readable names:
```
Raw: 3  →  Display: "Fire Element"
Raw: 7  →  Display: "ATB Bonus"
```

## Filtering

### Quick Filter
1. Enter search term in filter box
2. Select target column (or "All")
3. Choose match type:
   - **Contains** - Partial match
   - **Equals** - Exact match
   - **Starts With** - Prefix match
   - **Regex** - Regular expression

### Filter Examples
| Filter | Column | Type | Result |
|--------|--------|------|--------|
| `Behemoth` | Name | Contains | Behemoth, Behemoth King |
| `>10000` | HP | Expression | HP greater than 10000 |
| `Fire` | Element | Contains | Fire Element entries |
| `^Boss` | Category | Regex | Categories starting with "Boss" |

### Multi-Filter
Combine filters using the advanced filter panel:
```
HP > 10000 AND Element = "Fire" AND Category = "Boss"
```

## Editing Records

### Inline Editing
1. Double-click a cell
2. Enter new value
3. Press Enter to confirm
4. Press Escape to cancel

### Record Editor Dialog
1. Double-click row header (or right-click → Edit)
2. Full record form appears
3. Edit all fields with validation
4. Click **Save** to apply

### Field Validation
Oracle Drive validates entries:
- **Type checking** - Ensures correct data type
- **Range checking** - Validates min/max values
- **Enum validation** - Ensures valid enum values
- **Required fields** - Highlights missing data

## Record Management

### Adding Records
1. Click **Add Row** in toolbar
2. Fill in the record form
3. Click **Create**

### Cloning Records
1. Select a record
2. Right-click → **Clone**
3. Modify the cloned record
4. New record is added

### Deleting Records
1. Select record(s)
2. Right-click → **Delete**
3. Confirm deletion

> **Warning**: Deleting records may break game references.

### Bulk Updates
1. Select multiple records
2. Right-click → **Bulk Update**
3. Choose field and operation:
   - Set Value
   - Increment/Decrement
   - Multiply
   - Replace String
4. Apply to all selected

## Import/Export

### JSON Export
1. Click **Export JSON**
2. Choose destination
3. Database saved as structured JSON

```json
{
  "sheetName": "enemy_stats",
  "records": [
    {
      "ID": 1,
      "Name": "Behemoth",
      "HP": 28500,
      "STR": 245,
      "Element": "None"
    }
  ]
}
```

### JSON Import
1. Click **Import JSON**
2. Select JSON file
3. Records merged with existing data

### Partial Import
Import specific records:
```json
{
  "records": [
    { "ID": 1, "HP": 35000 }
  ]
}
```
Only specified fields are updated.

## Schema Awareness

### Field Dictionaries
Oracle Drive includes dictionaries for known database schemas:
- Field names and types
- Valid value ranges
- Enum definitions
- Field descriptions

### Unknown Schemas
For unrecognized databases:
- Fields displayed as raw types
- Generic column names (`field_0`, `field_1`)
- Values shown without enum resolution

### Contributing Schemas
Community-contributed schemas are welcome. See [[Contributing]].

## Undo/Redo

All edits support undo/redo:
- **Ctrl+Z** - Undo last change
- **Ctrl+Y** - Redo
- History preserved during session

## Workflow Integration

Database operations are available in [[Workflow System|workflows]]:

### Available Nodes
| Node | Purpose |
|------|---------|
| WDB Open | Load database file |
| WDB Save | Save modifications |
| WDB Find | Search for records |
| WDB Set Field | Modify field values |
| WDB Copy | Copy records |
| WDB Delete | Remove records |
| WDB Bulk Update | Mass modifications |

### Example Workflow
```
Start → WDB Open → WDB Find (HP < 1000) → WDB Set Field (HP = 1000) → WDB Save → End
```

## Console Output

```
[INFO] Loading database: enemy.wdb
[INFO] Detected schema: EnemyStats
[INFO] Parsed 342 records, 12 columns
[INFO] Modified: Record 1, HP: 28500 → 35000
[INFO] Saving database: enemy.wdb
[INFO] Save complete
```

## Best Practices

### Before Editing
1. **Backup** the original WDB file
2. **Understand** the schema and field meanings
3. **Test** changes incrementally

### During Editing
- Use filtering to find specific records
- Clone records before major changes
- Save frequently

### Testing Changes
1. Save the modified WDB
2. Repack into the game archive
3. Test in-game
4. Iterate as needed

## Common Databases

### FF13
| File | Contents |
|------|----------|
| `enemy.wdb` | Enemy stats and behaviors |
| `ability.wdb` | Abilities and commands |
| `item.wdb` | Items and equipment |
| `crystarium.wdb` | Progression data |

### FF13-2
| File | Contents |
|------|----------|
| `monster.wdb` | Monster stats |
| `paradigm.wdb` | Paradigm data |
| `fragment.wdb` | Fragment info |

### Lightning Returns
| File | Contents |
|------|----------|
| `garb.wdb` | Garb/costume data |
| `schema.wdb` | Schema configurations |
| `quest.wdb` | Quest parameters |

## Troubleshooting

### "Unknown schema"
- Database structure not in dictionary
- Fields shown with generic names
- Values still editable

### "Validation failed"
- Value doesn't match expected type
- Check field constraints
- Use correct enum value

### "Save failed"
- Check file permissions
- Ensure file isn't locked
- Verify disk space

## See Also

- [[File Formats#wdb|WDB Format Specification]]
- [[Workflow System]] - Automate database edits
- [[Rust SDK]] - WDB API documentation
