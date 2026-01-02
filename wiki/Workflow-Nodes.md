# Workflow Nodes Reference

Complete reference for all node types available in the Workflow System.

## Control Flow Nodes

### Start
**Purpose:** Entry point for workflow execution.

| Property | Type | Description |
|----------|------|-------------|
| None | - | Every workflow needs exactly one Start node |

**Outputs:**
- `flow` → Next node to execute

---

### End
**Purpose:** Marks workflow completion.

| Property | Type | Description |
|----------|------|-------------|
| None | - | Workflow can have multiple End nodes |

**Inputs:**
- `flow` ← Previous node

---

### Condition
**Purpose:** Branch execution based on expression.

| Property | Type | Description |
|----------|------|-------------|
| Expression | String | Boolean expression to evaluate |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `true` → Execute if expression is true
- `false` → Execute if expression is false

**Examples:**
```
${count} > 10
${record.HP} < 1000
${filename}.endsWith(".wdb")
```

---

### Loop
**Purpose:** Repeat operations a fixed number of times.

| Property | Type | Description |
|----------|------|-------------|
| Count | Integer | Number of iterations |
| Index Variable | String | Variable name for current index |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `body` → Execute each iteration
- `complete` → Execute after all iterations

**Context Variables:**
- `${index}` - Current iteration (0-based)
- `${count}` - Total iterations

---

### ForEach
**Purpose:** Iterate over a collection.

| Property | Type | Description |
|----------|------|-------------|
| Collection | Expression | Array/list to iterate |
| Item Variable | String | Variable name for current item |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `item` → Execute for each item
- `complete` → Execute after all items

**Context Variables:**
- `${item}` - Current item
- `${index}` - Current index
- `${count}` - Total items

---

### Fork
**Purpose:** Split into parallel execution paths.

| Property | Type | Description |
|----------|------|-------------|
| Path Count | Integer | Number of parallel paths (2-8) |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `path_1` → First parallel path
- `path_2` → Second parallel path
- ... up to `path_8`

---

### Join
**Purpose:** Synchronize parallel paths.

| Property | Type | Description |
|----------|------|-------------|
| Wait Mode | Enum | `all` (wait for all) or `any` (first to finish) |

**Inputs:**
- `flow_1` ← First path
- `flow_2` ← Second path
- ... (matches Fork outputs)

**Outputs:**
- `flow` → Continue after synchronization

---

## File Operations

### WPD Unpack
**Purpose:** Extract files from WPD package.

| Property | Type | Description |
|----------|------|-------------|
| Input File | Path | WPD file to unpack |
| Output Directory | Path | Destination folder |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Unpack succeeded
- `error` → Unpack failed

---

### WPD Repack
**Purpose:** Create WPD package from directory.

| Property | Type | Description |
|----------|------|-------------|
| Input Directory | Path | Folder to pack |
| Output File | Path | WPD file to create |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Repack succeeded
- `error` → Repack failed

---

### WBT Load
**Purpose:** Open WhiteBin archive.

| Property | Type | Description |
|----------|------|-------------|
| Archive Path | Path | BIN file to open |
| Game | Enum | FF13_1, FF13_2, or FF13_LR |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Archive loaded
- `error` → Load failed

**Output Variables:**
- `${archive}` - Archive handle for other nodes

---

### WBT Extract
**Purpose:** Extract files from archive.

| Property | Type | Description |
|----------|------|-------------|
| Archive | Variable | Archive from WBT Load |
| Pattern | String | File pattern (e.g., `*.wdb`) |
| Output Directory | Path | Destination folder |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Extraction complete
- `error` → Extraction failed

---

### WBT Repack
**Purpose:** Repack modified files into archive.

| Property | Type | Description |
|----------|------|-------------|
| Archive | Variable | Archive from WBT Load |
| Modified Directory | Path | Folder with changes |
| Output Archive | Path | New archive path |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Repack complete
- `error` → Repack failed

---

### IMG Extract
**Purpose:** Convert texture to DDS.

| Property | Type | Description |
|----------|------|-------------|
| Input File | Path | IMGB or XGR file |
| Output File | Path | DDS file to create |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Extraction complete
- `error` → Extraction failed

---

### IMG Repack
**Purpose:** Convert DDS back to game format.

| Property | Type | Description |
|----------|------|-------------|
| Input File | Path | DDS file |
| Output File | Path | IMGB file to create |
| Original | Path | Original file for headers |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Repack complete
- `error` → Repack failed

---

## Database Operations

### WDB Open
**Purpose:** Load database file.

| Property | Type | Description |
|----------|------|-------------|
| File Path | Path | WDB file to open |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → File loaded
- `error` → Load failed

**Output Variables:**
- `${wdb}` - Database handle
- `${records}` - Record collection

---

### WDB Save
**Purpose:** Save database to file.

| Property | Type | Description |
|----------|------|-------------|
| Database | Variable | Database from WDB Open |
| File Path | Path | Output file path |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Save complete
- `error` → Save failed

---

### WDB Find
**Purpose:** Search for records.

| Property | Type | Description |
|----------|------|-------------|
| Database | Variable | Database handle |
| Column | String | Field to search |
| Operator | Enum | =, !=, <, >, <=, >=, contains |
| Value | String | Value to match |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `found` → At least one match
- `none` → No matches

**Output Variables:**
- `${results}` - Matching records
- `${count}` - Number of matches

---

### WDB Set Field
**Purpose:** Modify field value.

| Property | Type | Description |
|----------|------|-------------|
| Database | Variable | Database handle |
| Records | Variable | Records to modify (or all) |
| Column | String | Field to change |
| Value | Expression | New value |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Update complete
- `error` → Update failed

---

### WDB Copy
**Purpose:** Copy records to clipboard.

| Property | Type | Description |
|----------|------|-------------|
| Records | Variable | Records to copy |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `flow` → Continue

---

### WDB Paste
**Purpose:** Paste records from clipboard.

| Property | Type | Description |
|----------|------|-------------|
| Database | Variable | Target database |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Paste complete
- `error` → Paste failed

---

### WDB Delete
**Purpose:** Remove records.

| Property | Type | Description |
|----------|------|-------------|
| Database | Variable | Database handle |
| Records | Variable | Records to delete |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Delete complete
- `error` → Delete failed

---

### WDB Bulk Update
**Purpose:** Mass field modification.

| Property | Type | Description |
|----------|------|-------------|
| Database | Variable | Database handle |
| Column | String | Field to modify |
| Operation | Enum | Set, Add, Multiply, Replace |
| Value | Expression | Operation parameter |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Update complete
- `error` → Update failed

---

## Text Operations

### ZTR Open
**Purpose:** Load text file.

| Property | Type | Description |
|----------|------|-------------|
| File Path | Path | ZTR file to open |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → File loaded
- `error` → Load failed

**Output Variables:**
- `${ztr}` - Text file handle
- `${entries}` - Entry collection

---

### ZTR Save
**Purpose:** Save text file.

| Property | Type | Description |
|----------|------|-------------|
| ZTR | Variable | Text file handle |
| File Path | Path | Output file path |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Save complete
- `error` → Save failed

---

### ZTR Find
**Purpose:** Search for entries.

| Property | Type | Description |
|----------|------|-------------|
| ZTR | Variable | Text file handle |
| Pattern | String | Search text or regex |
| Search In | Enum | ID, Text, or Both |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `found` → At least one match
- `none` → No matches

**Output Variables:**
- `${results}` - Matching entries
- `${count}` - Number of matches

---

### ZTR Modify
**Purpose:** Change entry text.

| Property | Type | Description |
|----------|------|-------------|
| ZTR | Variable | Text file handle |
| Entry ID | String | Entry to modify |
| New Text | String | Replacement text |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Modify complete
- `error` → Entry not found

---

### ZTR Add
**Purpose:** Create new entry.

| Property | Type | Description |
|----------|------|-------------|
| ZTR | Variable | Text file handle |
| Entry ID | String | New entry ID |
| Text | String | Entry text |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Add complete
- `error` → Add failed

---

### ZTR Delete
**Purpose:** Remove entry.

| Property | Type | Description |
|----------|------|-------------|
| ZTR | Variable | Text file handle |
| Entry ID | String | Entry to delete |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `success` → Delete complete
- `error` → Entry not found

---

## Variable Operations

### Set Variable
**Purpose:** Store a value.

| Property | Type | Description |
|----------|------|-------------|
| Name | String | Variable name |
| Value | Expression | Value to store |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `flow` → Continue

---

### Get Variable
**Purpose:** Retrieve stored value.

| Property | Type | Description |
|----------|------|-------------|
| Name | String | Variable name |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `found` → Variable exists
- `not_found` → Variable undefined

**Output Variables:**
- `${value}` - Retrieved value

---

### Expression
**Purpose:** Evaluate math/logic expression.

| Property | Type | Description |
|----------|------|-------------|
| Expression | String | Expression to evaluate |
| Result Variable | String | Variable for result |

**Inputs:**
- `flow` ← Previous node

**Outputs:**
- `flow` → Continue

**Supported Operations:**
- Arithmetic: `+`, `-`, `*`, `/`, `%`
- Comparison: `==`, `!=`, `<`, `>`, `<=`, `>=`
- Logic: `&&`, `||`, `!`
- String: `.contains()`, `.startsWith()`, `.endsWith()`

---

## See Also

- [[Workflow System]] - Workflow system overview
- [[Architecture#workflow-engine|Workflow Engine]]
