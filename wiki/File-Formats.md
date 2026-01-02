# File Formats

This document describes the binary file formats used by the Final Fantasy XIII trilogy that Oracle Drive supports.

## Overview

| Format | Extension | Description | Games |
|--------|-----------|-------------|-------|
| WhiteBin | `.bin` | Archive container | All |
| WhitePackData | `.wpd` | Package container | All |
| WhiteDatabase | `.wdb` | Structured data | All |
| ZoneTextResource | `.ztr` | Localized text | All |
| Crystal Graph Tree | `.cgt` | Crystarium data | FF13 |
| Master Crystal Pattern | `.mcp` | Crystarium patterns | FF13 |
| Image Binary | `.imgb` | Textures | All |
| XGR | `.xgr` | Compressed textures | All |
| Crystal Logic Bytecode | `.clb` | Compiled scripts | All |

---

## WhiteBin Archives (.bin)

WhiteBin is the primary archive format containing game assets.

### Structure
```
┌─────────────────────────────────────┐
│           File Header               │
│  - Magic number                     │
│  - Version info                     │
├─────────────────────────────────────┤
│         FileList (encrypted)        │
│  - Entry count                      │
│  - For each entry:                  │
│    - File name (null-terminated)    │
│    - Offset into container          │
│    - Compressed size                │
│    - Uncompressed size              │
├─────────────────────────────────────┤
│         Container (compressed)      │
│  - ZLIB-compressed file data        │
│  - Concatenated entries             │
└─────────────────────────────────────┘
```

### FileList Entry
```
Offset  Size  Type     Field
0x00    var   string   File path (null-terminated)
var     4     u32      Offset into container
var+4   4     u32      Compressed size
var+8   4     u32      Uncompressed size
```

### Encryption
FileList uses a simple XOR cipher with game-specific keys:
- **FF13**: Key derived from header
- **FF13-2**: Modified key algorithm
- **LR**: Different key schedule

### Compression
Container data uses ZLIB (deflate) compression. Files are stored contiguously and can be individually decompressed using offset and size from FileList.

---

## WhitePackData (.wpd)

WPD files are nested package containers within archives.

### Structure
```
┌─────────────────────────────────────┐
│           Header (16 bytes)         │
│  - Magic: "WPD\0"                   │
│  - Version: u32                     │
│  - Entry count: u32                 │
│  - Reserved: u32                    │
├─────────────────────────────────────┤
│         Entry Table                 │
│  - For each entry:                  │
│    - Name (32 bytes, null-padded)   │
│    - Offset: u32                    │
│    - Size: u32                      │
│    - Flags: u32                     │
├─────────────────────────────────────┤
│         File Data                   │
│  - Raw or compressed data           │
└─────────────────────────────────────┘
```

### Entry Flags
```
Bit 0: Compressed (0=raw, 1=ZLIB)
Bit 1-7: Reserved
```

---

## WhiteDatabase (.wdb)

WDB files store structured game data in a tabular format.

### Structure
```
┌─────────────────────────────────────┐
│           Header                    │
│  - Magic: "WDB\0"                   │
│  - Version: u32                     │
│  - Sheet name length: u16           │
│  - Sheet name: string               │
├─────────────────────────────────────┤
│         Schema Definition           │
│  - Column count: u16                │
│  - For each column:                 │
│    - Name length: u8                │
│    - Name: string                   │
│    - Type: u8                       │
│    - Flags: u8                      │
├─────────────────────────────────────┤
│         Record Data                 │
│  - Record count: u32                │
│  - For each record:                 │
│    - Field values (packed)          │
└─────────────────────────────────────┘
```

### Data Types
| Code | Type | Size | Description |
|------|------|------|-------------|
| 0x00 | int8 | 1 | Signed byte |
| 0x01 | uint8 | 1 | Unsigned byte |
| 0x02 | int16 | 2 | Signed short |
| 0x03 | uint16 | 2 | Unsigned short |
| 0x04 | int32 | 4 | Signed int |
| 0x05 | uint32 | 4 | Unsigned int |
| 0x06 | float32 | 4 | Single precision |
| 0x07 | string | var | Null-terminated |
| 0x08 | bool | 1 | Boolean |
| 0x09 | enum | 1-4 | Enumerated value |

### Bit-Packed Fields
Some WDB files use bit-packing for efficiency:
```
Field definition: "hp:12,mp:10,str:10"
Packed as: [hp: 12 bits][mp: 10 bits][str: 10 bits] = 32 bits total
```

---

## ZoneTextResource (.ztr)

ZTR files contain localized text with dictionary compression.

### Structure
```
┌─────────────────────────────────────┐
│           Header                    │
│  - Magic: "ZTR\0"                   │
│  - Version: u32                     │
│  - Entry count: u32                 │
│  - Encoding: u16 (0=UTF-8, 1=SJIS)  │
├─────────────────────────────────────┤
│         ID Table                    │
│  - Compressed ID strings            │
│  - Dictionary-based encoding        │
├─────────────────────────────────────┤
│         Text Table                  │
│  - Compressed text strings          │
│  - Dictionary-based encoding        │
├─────────────────────────────────────┤
│         Dictionary                  │
│  - Common substring patterns        │
│  - Game-specific dictionaries       │
└─────────────────────────────────────┘
```

### Text Encoding
- Base encoding: Shift-JIS for Japanese, UTF-8 for Western
- Control codes for formatting (colors, icons, variables)
- Dictionary compression reduces size by ~60%

### Control Codes
| Code | Bytes | Description |
|------|-------|-------------|
| 0x01 | 2 | Color start (1 byte color ID) |
| 0x02 | 1 | Color end |
| 0x03 | 2 | Icon (1 byte icon ID) |
| 0x04 | 3 | Variable (2 byte var ID) |
| 0x05 | 3 | Wait (2 byte milliseconds) |
| 0x0A | 1 | Newline |

---

## Crystal Graph Tree (.cgt)

CGT files define the Crystarium progression structure (FF13 only).

### Structure (Big Endian)
```
┌─────────────────────────────────────┐
│           Header (16 bytes)         │
│  - Version: u32                     │
│  - Entry count: u32                 │
│  - Total nodes: u32                 │
│  - Reserved: u32                    │
├─────────────────────────────────────┤
│         Entries (136 bytes each)    │
│  - Index: u32                       │
│  - Pattern name: 32 bytes           │
│  - Position: Vec3 (12 bytes)        │
│  - Scale: f32                       │
│  - Rotation: Quaternion (16 bytes)  │
│  - Node scale: f32                  │
│  - Role ID: u8                      │
│  - Stage: u8                        │
│  - Entry type: u8                   │
│  - Reserved: u8                     │
│  - Node IDs: u32[16]                │
│  - Link position: Vec4 (16 bytes)   │
├─────────────────────────────────────┤
│         Nodes (52 bytes each)       │
│  - Index: u32                       │
│  - Name: 16 bytes                   │
│  - Parent index: i32                │
│  - Unknown: u32[4]                  │
│  - Scales: f32[4]                   │
└─────────────────────────────────────┘
```

### Role IDs
| ID | Role |
|----|------|
| 0 | Commando |
| 1 | Ravager |
| 2 | Sentinel |
| 3 | Medic |
| 4 | Synergist |
| 5 | Saboteur |

---

## Master Crystal Pattern (.mcp)

MCP files define layout patterns for Crystarium branches.

### Structure (Big Endian)
```
┌─────────────────────────────────────┐
│           Header (16 bytes)         │
│  - Version: u32                     │
│  - Pattern count: u32               │
│  - Reserved: u32[2]                 │
├─────────────────────────────────────┤
│         Patterns (272 bytes each)   │
│  - Name: 16 bytes                   │
│  - Node positions: Vec4[16]         │
│    (W=1.0 indicates valid node)     │
└─────────────────────────────────────┘
```

### Pattern Usage
Patterns define relative node positions for creating offshoots:
```
Pattern "branch_3":
  Node 0: (0, 0, 0, 1)      # Root
  Node 1: (5, 3, 0, 1)      # First branch
  Node 2: (-5, 3, 0, 1)     # Second branch
  Node 3: (0, 6, 0, 1)      # Top
  Node 4-15: (0, 0, 0, 0)   # Unused (W=0)
```

---

## Image Binary (.imgb)

IMGB files contain DirectX-compatible texture data.

### Structure
```
┌─────────────────────────────────────┐
│         DDS Header (124 bytes)      │
│  - Magic: "DDS "                    │
│  - Size: u32 (always 124)           │
│  - Flags: u32                       │
│  - Height: u32                      │
│  - Width: u32                       │
│  - Pitch/LinearSize: u32            │
│  - Depth: u32                       │
│  - MipMapCount: u32                 │
│  - Reserved: u32[11]                │
│  - Pixel format (32 bytes)          │
│  - Caps: u32[4]                     │
│  - Reserved2: u32                   │
├─────────────────────────────────────┤
│         Pixel Data                  │
│  - Format-dependent data            │
│  - BC1-BC7 compressed or raw        │
└─────────────────────────────────────┘
```

### Common Formats
| FourCC | Format | Description |
|--------|--------|-------------|
| DXT1 | BC1 | 4bpp, 1-bit alpha |
| DXT3 | BC2 | 8bpp, explicit alpha |
| DXT5 | BC3 | 8bpp, interpolated alpha |
| ATI1 | BC4 | 4bpp, single channel |
| ATI2 | BC5 | 8bpp, two channels |

---

## XGR Textures (.xgr)

XGR is a compressed texture format wrapping IMGB data.

### Structure
```
┌─────────────────────────────────────┐
│           Header                    │
│  - Magic: "XGR\0"                   │
│  - Uncompressed size: u32           │
│  - Compressed size: u32             │
├─────────────────────────────────────┤
│         Compressed Data             │
│  - ZLIB-compressed IMGB             │
└─────────────────────────────────────┘
```

---

## Crystal Logic Bytecode (.clb)

CLB files contain compiled game scripts.

### Structure
```
┌─────────────────────────────────────┐
│           Header (encrypted)        │
│  - Magic (after decryption)         │
│  - Version info                     │
├─────────────────────────────────────┤
│         Class Data (encrypted)      │
│  - Java class file structure        │
│  - Bytecode instructions            │
│  - Constant pool                    │
│  - Method definitions               │
└─────────────────────────────────────┘
```

### Processing
1. Decrypt CLB data
2. Convert to standard Java class format
3. Decompile with CFR decompiler
4. View as Java source code

---

## Byte Order

| Format | Byte Order |
|--------|------------|
| WBT | Little Endian |
| WPD | Little Endian |
| WDB | Little Endian |
| ZTR | Little Endian |
| CGT | **Big Endian** |
| MCP | **Big Endian** |
| IMGB | Little Endian |
| CLB | Little Endian |

---

## See Also

- [[Rust SDK]] - Implementation details
- [[Archive Management]] - Working with archives
- [[Database Editor]] - WDB editing
- [[Text Editor]] - ZTR editing
- [[Crystalium Editor]] - CGT/MCP editing
