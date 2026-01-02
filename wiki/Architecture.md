# Architecture

Oracle Drive uses a modern, layered architecture combining Flutter for the UI with a high-performance Rust backend for file processing.

## High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Frontend                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Screens   │  │  Components │  │   Crystal Design    │  │
│  │  (7 views)  │  │  (widgets)  │  │      System         │  │
│  └──────┬──────┘  └──────┬──────┘  └─────────────────────┘  │
│         │                │                                   │
│  ┌──────▼────────────────▼──────┐                           │
│  │      Riverpod Providers       │                           │
│  │   (State Management Layer)    │                           │
│  └──────────────┬───────────────┘                           │
│                 │                                            │
│  ┌──────────────▼───────────────┐  ┌─────────────────────┐  │
│  │         Services              │  │    Isar Database    │  │
│  │  (Native, Navigation, etc.)   │  │  (Local Storage)    │  │
│  └──────────────┬───────────────┘  └─────────────────────┘  │
└─────────────────┼───────────────────────────────────────────┘
                  │ Flutter Rust Bridge
┌─────────────────▼───────────────────────────────────────────┐
│                     Rust SDK (fabula_nova_sdk)               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌────────┐ │
│  │   ZTR   │ │   WBT   │ │   WDB   │ │   WPD   │ │  IMG   │ │
│  │  Text   │ │ Archive │ │ Database│ │ Package │ │ Texture│ │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └────────┘ │
│  ┌─────────┐ ┌─────────┐ ┌─────────────────────────────────┐│
│  │Crystalium│ │   WCT   │ │         Core Utilities          ││
│  │ CGT/MCP │ │ Crypto  │ │  (Logging, FFI Types, Utils)    ││
│  └─────────┘ └─────────┘ └─────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
Oracle-Drive/
├── lib/                          # Dart/Flutter code (~50K LOC)
│   ├── main.dart                 # Application entry point
│   ├── models/                   # Data models (immutable)
│   ├── providers/                # Riverpod state management
│   ├── screens/                  # Full-page UI views
│   ├── components/               # Reusable UI widgets
│   ├── theme/                    # Crystal theme system
│   ├── assets/                   # Fonts, icons, shaders
│   └── src/                      # Internal utilities
│       ├── services/             # Core services
│       ├── isar/                 # Database models & repos
│       ├── utils/                # Utility functions
│       └── workflow/             # Workflow engine
│
├── rust/fabula_nova_sdk/         # Rust native library (~15K LOC)
│   └── src/
│       ├── api.rs                # Public API surface
│       ├── core/                 # Shared utilities
│       ├── modules/              # File format handlers
│       └── ffi/                  # Low-level FFI exports
│
├── macos/                        # macOS platform code
├── windows/                      # Windows platform code
├── linux/                        # Linux platform code
└── test/                         # Unit tests
```

## Core Layers

### 1. Presentation Layer (Screens & Components)

**Screens** (`lib/screens/`):
| Screen | File | Description |
|--------|------|-------------|
| Main | `main_screen.dart` | App shell with navigation rail |
| WhiteBin | `wbt_screen.dart` | Archive browser |
| Workspace | `wpd_screen.dart` | File management |
| Database | `wdb_screen.dart` | Table editor |
| Text | `ztr_screen.dart` | Text editor |
| Workflow | `workflow_screen.dart` | Visual editor |
| Crystalium | `crystalium_screen.dart` | 3D visualizer |
| Settings | `settings_screen.dart` | Configuration |

**Components** (`lib/components/`):
- `crystalium/` - 3D visualizer components
- `workflow/` - Node editor components
- `wdb/` - Database table components
- `wpd/` - File browser components
- `widgets/` - Crystal design system (40+ components)

### 2. State Management Layer (Providers)

Oracle Drive uses **Riverpod** for reactive state management:

```dart
// Provider hierarchy example
appStateProvider          // Global app state (selected game)
├── wbtProvider           // WhiteBin archive state
├── wpdProvider           // Workspace state
├── wdbProvider           // Database editor state
├── ztrProvider           // Text editor state
├── workflowProvider      // Workflow editor state
├── crystaliumProvider    // Crystalium editor state
├── journalProvider       // Operation history
├── settingsProvider      // User preferences
└── undoRedoProvider      // Edit history
```

**Key Providers:**

| Provider | Purpose |
|----------|---------|
| `appStateProvider` | Game selection, navigation state |
| `wdbProvider` | Database loading, filtering, editing |
| `workflowProvider` | Workflow nodes, connections, execution |
| `crystaliumProvider` | CGT/MCP data, selected node, modifications |

### 3. Service Layer

**Core Services** (`lib/src/services/`):

| Service | Purpose |
|---------|---------|
| `NativeService` | Bridge to Rust SDK |
| `AppDatabase` | Isar database initialization |
| `NavigationService` | Global navigation |
| `JournalService` | Operation logging |
| `UndoRedoService` | Edit history management |
| `JavaDecompilerService` | CLB decompilation |

### 4. Data Layer (Isar Database)

Oracle Drive uses **Isar** for local-first encrypted storage:

**Database Instances:**
| Database | Purpose |
|----------|---------|
| `ff13.isar` | FF13 text cache, entity lookups |
| `ff13_2.isar` | FF13-2 text cache, entity lookups |
| `ff13_lr.isar` | Lightning Returns text cache, lookups |
| `oracle_drive_central.isar` | Settings, journal, workflows |

**Collections:**
```dart
// Game-specific databases
@collection
class Strings {
  Id? id;
  @Index()
  String key;
  String value;
}

@collection
class EntityLookup {
  Id? id;
  String entityType;
  int rawValue;
  String displayName;
}

// Central database
@collection
class JournalEntry { ... }

@collection
class SettingsModel { ... }

@collection
class WorkflowModel { ... }
```

### 5. Native Layer (Rust SDK)

The **fabula_nova_sdk** provides high-performance file format handling:

**Module Structure:**
```
modules/
├── ztr/          # Text resources (.ztr)
├── wbt/          # Archives (.bin)
├── wdb/          # Databases (.wdb)
├── wpd/          # Packages (.wpd)
├── img/          # Textures (.imgb, .xgr)
├── crystalium/   # Crystarium (.cgt, .mcp)
├── wct/          # Crypto utilities
└── clb/          # Crystal Logic Bytecode
```

**Integration via Flutter Rust Bridge:**
```dart
// Dart side
final result = await RustLib.wdbParse(filePath);

// Rust side
pub fn wdb_parse(in_file: String) -> Result<WdbData> { ... }
```

## Data Flow

### Reading Game Files

```
User Action → Provider → NativeService → Rust SDK → File System
                ↓
            State Update → UI Rebuild
```

### Modifying Data

```
User Edit → Provider (validate) → Model Update
                ↓
    UndoRedoService (snapshot)
                ↓
    JournalService (log entry)
                ↓
            State Update → UI Rebuild
```

### Saving Changes

```
Save Action → Provider → NativeService → Rust SDK → File System
                ↓
    JournalService (log completion)
                ↓
            State Update (hasUnsavedChanges = false)
```

## Workflow Engine Architecture

The workflow system has its own execution architecture:

```
┌─────────────────────────────────────────────┐
│             WorkflowEngine                   │
│  ┌─────────────────────────────────────────┐│
│  │         ExecutionContext                 ││
│  │  (variables, current node, errors)       ││
│  └─────────────────┬───────────────────────┘│
│                    │                         │
│  ┌─────────────────▼───────────────────────┐│
│  │         Node Executors                   ││
│  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐    ││
│  │  │Control│ │ WPD  │ │ WDB  │ │ ZTR  │    ││
│  │  └──────┘ └──────┘ └──────┘ └──────┘    ││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

**Execution Phases:**
1. **Validation** - Check node connections and parameters
2. **Initialization** - Set up execution context
3. **Execution** - Process nodes in topological order
4. **Fork/Join** - Handle parallel branches
5. **Completion** - Clean up and report results

## Design Patterns

### Provider Pattern
All state is managed through Riverpod providers, enabling:
- Reactive UI updates
- Dependency injection
- Testability
- State isolation per game

### Repository Pattern
Database access is abstracted through repositories:
```dart
abstract class GenericRepository<T> {
  Future<T?> get(int id);
  Future<List<T>> getAll();
  Future<void> put(T item);
  Future<void> delete(int id);
}
```

### Bridge Pattern
Flutter Rust Bridge abstracts the FFI boundary:
```
Dart API → Generated Bridge → Rust API
```

### Command Pattern
Workflow nodes act as commands:
```dart
abstract class NodeExecutor {
  Future<void> execute(ExecutionContext context, WorkflowNode node);
}
```

## Threading Model

| Layer | Threading |
|-------|-----------|
| Flutter UI | Main isolate |
| Riverpod | Synchronous on main |
| Isar | Async with main isolate |
| Rust SDK | Thread pool (rayon) |
| File I/O | Async/background |

Heavy operations (extraction, repacking) run in Rust with progress callbacks to the UI.

## Error Handling

```
Rust (anyhow::Result) → FRB → Dart (Exception) → Provider → UI (Error State)
```

All Rust errors are propagated through the bridge and handled in providers, which update UI state accordingly.

## See Also

- [[Rust SDK]] - Detailed SDK documentation
- [[File Formats]] - Game file specifications
- [[Workflow Nodes]] - Node type reference
