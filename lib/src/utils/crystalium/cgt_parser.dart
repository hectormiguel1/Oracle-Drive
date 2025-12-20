import 'dart:typed_data';
import 'package:ff13_mod_resource/models/crystalium/cgt_file.dart';
import 'package:ff13_mod_resource/models/crystalium/mcp_file.dart';

/// Parser for FF13 Crystarium CGT (Crystal Graph Tree) files.
///
/// CGT files define character-specific Crystarium layouts including:
/// - Entry positions and rotations
/// - Node IDs and parent connections
/// - Stage and role assignments
///
/// File format uses Big Endian byte order.
class CgtParser {
  // File structure constants
  static const int _headerSize = 16;
  static const int _entrySize = 136; // 0x88
  static const int _nodeRecordSize = 52; // 0x34
  static const int _patternNameSize = 16;
  static const int _nodeIdsCount = 16;

  /// Parse a CGT file from raw bytes.
  static CgtFile parse(Uint8List data) {
    if (data.length < _headerSize) {
      throw FormatException('CGT file too small: ${data.length} bytes');
    }

    final byteData = ByteData.sublistView(data);

    // Parse header
    final version = byteData.getUint32(0, Endian.big);
    final entryCount = byteData.getUint32(4, Endian.big);
    final totalNodes = byteData.getUint32(8, Endian.big);
    final reserved = byteData.getUint32(12, Endian.big);

    final entrySectionSize = entryCount * _entrySize;
    final minSize = _headerSize + entrySectionSize;
    if (data.length < minSize) {
      throw FormatException(
        'CGT file too small for $entryCount entries. '
        'Expected at least $minSize bytes, got ${data.length}',
      );
    }

    // Parse entries
    final entries = <CrystariumEntry>[];
    for (var i = 0; i < entryCount; i++) {
      final offset = _headerSize + (i * _entrySize);
      final entry = _parseEntry(data, byteData, offset, i);
      entries.add(entry);
    }

    // Parse node array
    final nodeArrayOffset = _headerSize + entrySectionSize;
    final nodes = <CrystariumNode>[];
    var nodeIndex = 0;
    var offset = nodeArrayOffset;

    while (offset + _nodeRecordSize <= data.length) {
      final node = _parseNode(data, byteData, offset, nodeIndex);
      nodes.add(node);
      offset += _nodeRecordSize;
      nodeIndex++;
    }

    return CgtFile(
      version: version,
      entryCount: entryCount,
      totalNodes: totalNodes,
      reserved: reserved,
      entries: entries,
      nodes: nodes,
    );
  }

  /// Parse a single entry at the given offset.
  static CrystariumEntry _parseEntry(
    Uint8List data,
    ByteData byteData,
    int offset,
    int index,
  ) {
    // Pattern name (16 bytes, null-terminated ASCII)
    final nameBytes = data.sublist(offset, offset + _patternNameSize);
    final nameEnd = nameBytes.indexOf(0);
    final patternName = String.fromCharCodes(
      nameEnd >= 0 ? nameBytes.sublist(0, nameEnd) : nameBytes,
    );

    // Position (12 bytes: X, Y, Z as float32 BE)
    final posX = _getFloat32BE(byteData, offset + 0x10);
    final posY = _getFloat32BE(byteData, offset + 0x14);
    final posZ = _getFloat32BE(byteData, offset + 0x18);

    // Scale (4 bytes: float32 BE)
    final scale = _getFloat32BE(byteData, offset + 0x1C);

    // Rotation (16 bytes: X, Y, Z, W as float32 BE)
    final rotX = _getFloat32BE(byteData, offset + 0x20);
    final rotY = _getFloat32BE(byteData, offset + 0x24);
    final rotZ = _getFloat32BE(byteData, offset + 0x28);
    final rotW = _getFloat32BE(byteData, offset + 0x2C);

    // Node scale (4 bytes: float32 BE)
    final nodeScale = _getFloat32BE(byteData, offset + 0x30);

    // Flags (4 bytes: role, stage, entry_type, reserved)
    final roleId = data[offset + 0x34];
    final stage = data[offset + 0x35];
    final entryType = data[offset + 0x36];
    final reservedByte = data[offset + 0x37];

    // Node IDs (64 bytes: 16 × uint32 BE)
    final nodeIds = <int>[];
    for (var i = 0; i < _nodeIdsCount; i++) {
      final nodeId = byteData.getUint32(offset + 0x38 + (i * 4), Endian.big);
      if (nodeId > 0) {
        nodeIds.add(nodeId);
      }
    }

    // Link position (16 bytes: X, Y, Z, W as float32 BE)
    final linkX = _getFloat32BE(byteData, offset + 0x78);
    final linkY = _getFloat32BE(byteData, offset + 0x7C);
    final linkZ = _getFloat32BE(byteData, offset + 0x80);
    final linkW = _getFloat32BE(byteData, offset + 0x84);

    return CrystariumEntry(
      index: index,
      patternName: patternName,
      position: Vector3(posX, posY, posZ),
      scale: scale,
      rotation: Vector3(rotX, rotY, rotZ),
      rotationW: rotW,
      nodeScale: nodeScale,
      roleId: roleId,
      stage: stage,
      entryType: entryType,
      reserved: reservedByte,
      nodeIds: nodeIds,
      linkPosition: Vector3(linkX, linkY, linkZ),
      linkW: linkW,
    );
  }

  /// Parse a single node record at the given offset.
  static CrystariumNode _parseNode(
    Uint8List data,
    ByteData byteData,
    int offset,
    int index,
  ) {
    // Node name (16 bytes, null-terminated ASCII)
    final nameBytes = data.sublist(offset, offset + _patternNameSize);
    final nameEnd = nameBytes.indexOf(0);
    final name = String.fromCharCodes(
      nameEnd >= 0 ? nameBytes.sublist(0, nameEnd) : nameBytes,
    );

    // Parent index (4 bytes: int32 BE, signed)
    final parentIndex = byteData.getInt32(offset + 0x10, Endian.big);

    // Unknown fields (16 bytes: 4 × uint32 BE)
    final unknown = <int>[
      byteData.getUint32(offset + 0x14, Endian.big),
      byteData.getUint32(offset + 0x18, Endian.big),
      byteData.getUint32(offset + 0x1C, Endian.big),
      byteData.getUint32(offset + 0x20, Endian.big),
    ];

    // Scale fields (16 bytes: 4 × float32 BE)
    final scales = <double>[
      _getFloat32BE(byteData, offset + 0x24),
      _getFloat32BE(byteData, offset + 0x28),
      _getFloat32BE(byteData, offset + 0x2C),
      _getFloat32BE(byteData, offset + 0x30),
    ];

    return CrystariumNode(
      index: index,
      name: name,
      parentIndex: parentIndex,
      unknown: unknown,
      scales: scales,
    );
  }

  /// Read a big-endian float32 from the byte data.
  static double _getFloat32BE(ByteData byteData, int offset) {
    return byteData.getFloat32(offset, Endian.big);
  }
}
