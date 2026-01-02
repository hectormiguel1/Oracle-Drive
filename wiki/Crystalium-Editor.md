# Crystalium Editor

The Crystalium Editor is a specialized 3D visualization and editing tool for the Crystarium character progression system in **Final Fantasy XIII**.

> **Note**: This feature is only available when FF13 is selected as the active game.

## Overview

The Crystarium is FF13's character progression system where players unlock abilities, stat boosts, and role bonuses by spending Crystogen Points (CP). The Crystalium Editor lets you:

- Visualize the Crystarium tree in 3D
- Navigate through node progressions
- Modify node properties
- Create new branches (offshoots)
- Edit role assignments

## Interface

```
┌─────────────────────────────────────────────────────────────────┐
│  lightning_crystarium.cgt                                        │
│  [Open CGT] [Open MCP] [Save] [Reset View]                      │
├─────────────────┬───────────────────────────────────────────────┤
│  Role Filter    │                                               │
│  ☑ Commando     │              ┌───┐                            │
│  ☑ Ravager      │         ┌────┤ ● │────┐                       │
│  ☑ Sentinel     │         │    └───┘    │                       │
│  ☐ Medic        │    ┌────▼────┐   ┌────▼────┐                  │
│  ☐ Synergist    │    │ ● ○ ○ ● │   │ ● ○ ○ ● │                  │
│  ☐ Saboteur     │    └────┬────┘   └────┬────┘                  │
│                 │         │             │                        │
│  Tree Browser   │    ┌────▼────┐   ┌────▼────┐                  │
│  ─────────────  │    │ ○ ○ ● ● │   │ ● ○ ○ ○ │                  │
│  ▼ Stage 1      │    └─────────┘   └─────────┘                  │
│    ├─ Commando  │                                               │
│    ├─ Ravager   │         [◄] [▼] [▲] [►]                       │
│    └─ Sentinel  │         Navigation Controls                   │
│  ▼ Stage 2      │                                               │
│    └─ ...       │  Selected: HP +50                              │
├─────────────────┴───────────────────────────────────────────────┤
│  Console                                                         │
│  [INFO] Loaded crystarium with 1,247 nodes                      │
└─────────────────────────────────────────────────────────────────┘
```

## Visualization Modes

### Walk Mode
Navigate the Crystarium as you would in-game:
- Move between connected nodes
- Camera follows your position
- Direction buttons show available paths
- Visited nodes are marked

### Orbit Mode
Free camera rotation around the tree:
- Click and drag to rotate view
- Scroll to zoom in/out
- Double-click node to select

### Overview Mode
See the entire Crystarium at once:
- Zoomed out view of all nodes
- Click anywhere to jump to that area
- Good for finding specific branches

### Controls
| Mode | Action | Control |
|------|--------|---------|
| Walk | Move | Arrow keys / Direction buttons |
| Walk | Jump to node | Double-click |
| Orbit | Rotate | Click + drag |
| Orbit | Zoom | Scroll wheel |
| All | Select node | Click |
| All | Reset view | R key |

## File Types

### CGT (Crystal Graph Tree)
The main Crystarium data file containing:
- Node positions and connections
- Role assignments
- Stage progressions
- Unlock costs and rewards

### MCP (Master Crystal Pattern)
Pattern templates for branch layouts:
- Predefined node arrangements
- Used when creating offshoots
- Multiple patterns available

### Opening Files
1. Click **Open CGT** to load Crystarium data
2. Optionally **Open MCP** for pattern support
3. Files are typically extracted from game archives

## Node Properties

Select a node to view its properties:

| Property | Description |
|----------|-------------|
| Name | Node identifier |
| Type | Ability, HP, STR, MAG, etc. |
| Value | Stat bonus or ability ID |
| Cost | CP required to unlock |
| Role | Associated role |
| Stage | Progression stage number |
| Position | 3D coordinates |

### Node Types
| Type | Icon | Description |
|------|------|-------------|
| Ability | ⚔️ | Unlocks new ability |
| HP | ❤️ | Health bonus |
| STR | 💪 | Strength bonus |
| MAG | ✨ | Magic bonus |
| ATB | ⏱️ | ATB gauge segment |
| Role Level | ⭐ | Role level increase |
| Accessory | 💎 | Accessory slot |

## Role System

FF13 features 6 combat roles:

| Role | Color | Focus |
|------|-------|-------|
| **Commando** | Red | Physical damage |
| **Ravager** | Blue | Magic damage, chain |
| **Sentinel** | Yellow | Defense, provoke |
| **Medic** | Green | Healing |
| **Synergist** | Purple | Buffs |
| **Saboteur** | Orange | Debuffs |

### Role Filtering
Use checkboxes to show/hide specific roles in the visualization.

## Editing Nodes

### Modifying Properties
1. Select a node
2. Edit properties in the side panel
3. Changes apply immediately
4. Save to persist changes

### Renaming Nodes
1. Select node
2. Click **Rename** or double-click name
3. Enter new name
4. Press Enter

### Moving Nodes
1. Select node
2. Adjust position values
3. Or drag in Orbit mode (if enabled)

> **Warning**: Moving nodes may break visual connections.

## Creating Offshoots

Offshoots are new branches extending from existing nodes.

### Creating an Offshoot
1. Navigate to the desired parent node
2. Click **Add Offshoot**
3. Select a pattern from MCP templates
4. Choose role for new branch
5. Configure node properties
6. Click **Create**

### Pattern Templates
MCP patterns define branch layouts:
- **Linear** - Straight line of nodes
- **Branch** - Y-shaped split
- **Cluster** - Grouped nodes
- **Spiral** - Curved progression

### Offshoot Properties
| Property | Description |
|----------|-------------|
| Pattern | Layout template |
| Role | Role assignment |
| Stage | Starting stage |
| Scale | Size multiplier |
| Rotation | Orientation angle |

## Tree Browser

The sidebar shows a hierarchical view:
```
▼ Stage 1
  ├─ Commando
  │   ├─ Attack (HP +10)
  │   └─ Blitz (Ability)
  ├─ Ravager
  │   └─ Fire (Ability)
  └─ Sentinel
      └─ Steelguard (Ability)
▼ Stage 2
  └─ ...
```

Click entries to navigate directly to nodes.

## Saving Changes

### Save to CGT
1. Click **Save**
2. Choose output location
3. Modified CGT file is written

### Export Options
| Format | Use Case |
|--------|----------|
| CGT | Game-ready binary |
| JSON | Editing/backup |

### Validation
Before saving, Oracle Drive validates:
- Node connections are valid
- No orphaned nodes
- Stage progressions are logical
- Role assignments are consistent

## Workflow Integration

Crystalium data can be processed in [[Workflow System|workflows]]:

### Available Nodes
| Node | Purpose |
|------|---------|
| CGT Open | Load Crystarium file |
| CGT Save | Save modifications |
| MCP Open | Load patterns |

## Console Output

```
[INFO] Loading CGT: lightning.cgt
[INFO] Parsing 1,247 nodes, 156 entries
[INFO] Building spatial index...
[INFO] CGT loaded successfully

[INFO] Creating offshoot at node 47
[INFO] Using pattern: "branch_3"
[INFO] Added 12 new nodes
[INFO] Offshoot created successfully

[INFO] Saving CGT: lightning_modified.cgt
[INFO] Writing 1,259 nodes...
[INFO] Save complete
```

## Best Practices

### Before Editing
1. **Backup** original CGT files
2. **Load MCP** if creating offshoots
3. **Familiarize** with the tree structure

### During Editing
- Use role filtering to reduce clutter
- Work on one stage at a time
- Save frequently
- Test incremental changes

### Testing Changes
1. Save modified CGT
2. Repack into game archive
3. Load game and check Crystarium
4. Verify nodes appear correctly
5. Test progression through nodes

## Known Limitations

### Current
- Camera can swing during navigation (being improved)
- State resets when adding branches (being fixed)
- Some patterns may not place correctly

### Planned Improvements
See [[Roadmap#crystalium|Crystalium Roadmap]] for upcoming features.

## Troubleshooting

### "Failed to parse CGT"
- File may be corrupted
- Wrong game selected (must be FF13)
- Try different CGT file

### "Pattern not found"
- MCP file not loaded
- Pattern name mismatch
- Load correct MCP file

### "Camera spinning"
- Known issue with navigation
- Press R to reset view
- Use Orbit mode for stability

### "Nodes overlap"
- Scale too large for pattern
- Adjust offshoot scale
- Choose different pattern

## See Also

- [[File Formats#cgt|CGT Format Specification]]
- [[File Formats#mcp|MCP Format Specification]]
- [[Rust SDK]] - Crystalium API
- [[Architecture]] - Visualization system
