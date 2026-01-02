# Workflow System

The Workflow System is a powerful visual automation tool for creating complex modding pipelines. Using a node-based editor, you can chain operations together to automate repetitive tasks.

## Overview

Workflows allow you to:
- Automate multi-step modding operations
- Create reusable modification templates
- Batch process multiple files
- Share workflows with the community

## Interface

```
┌─────────────────────────────────────────────────────────────────┐
│  my_workflow.json                                               │
│  [New] [Open] [Save] [Run ▶] [Stop ■] [Validate]               │
├────────────────┬────────────────────────────────────────────────┤
│  Node Palette  │                Canvas                          │
│  ─────────────│                                                 │
│  ▼ Control     │    ┌─────────┐      ┌─────────┐                │
│    Start       │    │  Start  │──────│WDB Open │                │
│    End         │    └─────────┘      └────┬────┘                │
│    Condition   │                          │                     │
│    Loop        │                     ┌────▼────┐                │
│  ▼ Database    │                     │WDB Find │                │
│    WDB Open    │                     └────┬────┘                │
│    WDB Save    │                          │                     │
│    WDB Find    │    ┌─────────┐      ┌────▼────┐                │
│  ▼ Text        │    │   End   │◄─────│WDB Save │                │
│    ZTR Open    │    └─────────┘      └─────────┘                │
│    ZTR Modify  │                                                │
├────────────────┼────────────────────────────────────────────────┤
│  Properties    │  Console                                       │
│  ─────────────│  [INFO] Workflow ready                         │
│  Node: WDB Find│  [INFO] Loaded 3 nodes                        │
│  Column: HP    │                                                │
│  Operator: >   │                                                │
│  Value: 10000  │                                                │
└────────────────┴────────────────────────────────────────────────┘
```

## Canvas Basics

### Navigation
| Action | Control |
|--------|---------|
| Pan | Click + drag on empty space |
| Zoom | Scroll wheel |
| Select | Click node |
| Multi-select | Shift + click |
| Delete | Select + Delete key |

### Adding Nodes
1. Find node in **Node Palette**
2. Drag node onto canvas
3. Or double-click to add at center

### Connecting Nodes
1. Click output port (right side of node)
2. Drag to input port (left side of target)
3. Release to create connection

### Connection Rules
- Each output can connect to multiple inputs
- Each input can receive from one output
- Connections validate types automatically
- Invalid connections show red indicator

## Node Types

### Control Flow

| Node | Purpose | Inputs | Outputs |
|------|---------|--------|---------|
| **Start** | Workflow entry point | - | Flow |
| **End** | Workflow completion | Flow | - |
| **Condition** | Branch based on expression | Flow, Expression | True, False |
| **Loop** | Repeat operations | Flow, Count | Body, Complete |
| **ForEach** | Iterate over collection | Flow, Collection | Item, Complete |
| **Fork** | Split into parallel paths | Flow | Path 1, Path 2, ... |
| **Join** | Synchronize parallel paths | Multiple flows | Flow |

### File Operations

| Node | Purpose |
|------|---------|
| **WPD Unpack** | Extract WPD package |
| **WPD Repack** | Create WPD package |
| **WBT Load** | Open WhiteBin archive |
| **WBT Extract** | Extract files from archive |
| **WBT Repack** | Repack modified files |
| **IMG Extract** | Convert texture to DDS |
| **IMG Repack** | Convert DDS back to game format |

### Database Operations

| Node | Purpose |
|------|---------|
| **WDB Open** | Load database file |
| **WDB Save** | Save database to file |
| **WDB Find** | Search for records |
| **WDB Copy** | Duplicate records |
| **WDB Paste** | Insert copied records |
| **WDB Rename** | Change record identifiers |
| **WDB Delete** | Remove records |
| **WDB Set Field** | Modify field values |
| **WDB Bulk Update** | Mass field updates |

### Text Operations

| Node | Purpose |
|------|---------|
| **ZTR Open** | Load text file |
| **ZTR Save** | Save text file |
| **ZTR Find** | Search for entries |
| **ZTR Modify** | Change entry text |
| **ZTR Add** | Create new entry |
| **ZTR Delete** | Remove entry |

### Variables

| Node | Purpose |
|------|---------|
| **Set Variable** | Store a value |
| **Get Variable** | Retrieve stored value |
| **Expression** | Evaluate math/logic expression |

## Creating Workflows

### Basic Workflow Structure
Every workflow needs:
1. One **Start** node (entry point)
2. One or more **End** nodes (exit points)
3. Connected path from Start to End

### Example: Batch HP Increase
```
┌─────────┐     ┌──────────┐     ┌──────────┐
│  Start  │────►│ WDB Open │────►│ WDB Find │
└─────────┘     └──────────┘     └────┬─────┘
                                      │
                                      ▼
┌─────────┐     ┌──────────┐     ┌──────────┐
│   End   │◄────│ WDB Save │◄────│Set Field │
└─────────┘     └──────────┘     └──────────┘
```

**Node Configuration:**
1. **WDB Open**: `file = "enemy.wdb"`
2. **WDB Find**: `column = "HP", operator = "<", value = "1000"`
3. **WDB Set Field**: `column = "HP", value = "1000"`
4. **WDB Save**: `file = "enemy_modified.wdb"`

### Example: Conditional Processing
```
                              ┌──────────┐
                         ┌───►│ Process A│───┐
┌─────────┐  ┌─────────┐ │    └──────────┘   │  ┌─────┐
│  Start  │─►│Condition│─┤                   ├─►│ End │
└─────────┘  └─────────┘ │    ┌──────────┐   │  └─────┘
                         └───►│ Process B│───┘
                              └──────────┘
```

### Example: Loop Processing
```
┌─────────┐     ┌──────┐     ┌──────────┐
│  Start  │────►│ Loop │────►│ Process  │─┐
└─────────┘     └──┬───┘     └──────────┘ │
                   │ complete             │
                   ▼              loop ◄──┘
              ┌─────────┐
              │   End   │
              └─────────┘
```

## Properties Panel

When a node is selected, the Properties Panel shows configurable options:

### Common Properties
| Property | Description |
|----------|-------------|
| Name | Display name for the node |
| Description | Optional notes |
| Enabled | Toggle node on/off |

### Node-Specific Properties
Each node type has unique properties. Example for **WDB Find**:

| Property | Type | Description |
|----------|------|-------------|
| Column | Dropdown | Field to search |
| Operator | Dropdown | =, !=, <, >, contains |
| Value | Text/Number | Value to match |
| Case Sensitive | Boolean | Text matching mode |

## Execution

### Running Workflows
1. Click **Run ▶** or press F5
2. Progress shown in console
3. Nodes highlight as they execute
4. Errors shown with red indicator

### Execution Order
Nodes execute in topological order:
1. Start node first
2. Dependencies before dependents
3. Parallel paths execute concurrently
4. Join nodes wait for all inputs

### Stopping Execution
- Click **Stop ■** to halt
- Running operations complete current step
- State is preserved for debugging

### Validation
Click **Validate** to check:
- All required connections
- Valid property values
- Reachable paths
- No circular dependencies

## Variables and Expressions

### Using Variables
```
Set Variable: myFile = "enemy.wdb"
...
WDB Open: file = ${myFile}
```

### Expression Syntax
| Expression | Result |
|------------|--------|
| `${varName}` | Variable value |
| `${record.HP}` | Record field |
| `${index + 1}` | Math expression |
| `${value * 2}` | Multiplication |

### Built-in Variables
| Variable | Description |
|----------|-------------|
| `${index}` | Loop iteration index |
| `${count}` | Total loop iterations |
| `${item}` | Current ForEach item |
| `${result}` | Previous node result |

## Saving and Loading

### Save Workflow
1. Click **Save**
2. Choose location
3. Workflow saved as JSON

### Workflow JSON Structure
```json
{
  "name": "My Workflow",
  "version": "1.0",
  "nodes": [
    {
      "id": "node_1",
      "type": "Start",
      "position": { "x": 100, "y": 200 }
    }
  ],
  "connections": [
    {
      "from": "node_1",
      "to": "node_2",
      "port": "output"
    }
  ]
}
```

### Sharing Workflows
- Export JSON files to share
- Import community workflows
- Workflows are game-agnostic

## Undo/Redo

Full undo/redo support:
- **Ctrl+Z** - Undo
- **Ctrl+Y** - Redo
- History includes node changes and connections

## Console Output

The workflow console shows execution progress:

```
[INFO] Starting workflow: my_workflow
[INFO] Executing: WDB Open (enemy.wdb)
[INFO] Loaded 342 records
[INFO] Executing: WDB Find (HP < 1000)
[INFO] Found 45 matching records
[INFO] Executing: WDB Set Field (HP = 1000)
[INFO] Updated 45 records
[INFO] Executing: WDB Save
[INFO] Saved enemy_modified.wdb
[INFO] Workflow completed successfully
```

## Best Practices

### Design
- Start simple, add complexity
- Use descriptive node names
- Group related operations
- Add comments via node descriptions

### Testing
- Validate before running
- Test with small datasets first
- Check console for errors
- Use breakpoints for debugging

### Organization
- One workflow per task type
- Create reusable sub-workflows
- Name files descriptively
- Version your workflows

## Troubleshooting

### "Validation failed"
- Check all required connections
- Verify property values
- Look for disconnected nodes

### "Node execution failed"
- Check file paths
- Verify input data format
- Review console for details

### "Circular dependency"
- Remove loops in connections
- Use Loop node for iterations
- Check connection directions

## See Also

- [[Workflow Nodes]] - Complete node reference
- [[Database Editor]] - WDB node targets
- [[Text Editor]] - ZTR node targets
- [[Architecture#workflow-engine|Workflow Engine Architecture]]
