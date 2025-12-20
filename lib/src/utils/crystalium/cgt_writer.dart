import 'dart:typed_data';
import 'package:ff13_mod_resource/models/crystalium/cgt_file.dart';

/// Writer for FF13 Crystarium CGT (Crystal Graph Tree) files.
///
/// Serializes CGT data back to the binary format.
class CgtWriter {
  // File structure constants
  static const int _headerSize = 16;
  static const int _entrySize = 136; // 0x88
  static const int _nodeRecordSize = 52; // 0x34
  static const int _patternNameSize = 16;
  static const int _nodeIdsCount = 16;

  /// Write a CGT file to bytes.
  static Uint8List write(CgtFile cgtFile) {
    // Calculate total size
    final entryCount = cgtFile.entries.length;
    final nodeCount = cgtFile.nodes.length;
    final totalSize = _headerSize + (entryCount * _entrySize) + (nodeCount * _nodeRecordSize);

    final buffer = ByteData(totalSize);
    var offset = 0;

    // Write header
    buffer.setUint32(offset, cgtFile.version, Endian.big);
    offset += 4;
    buffer.setUint32(offset, entryCount, Endian.big);
    offset += 4;
    buffer.setUint32(offset, nodeCount, Endian.big);
    offset += 4;
    buffer.setUint32(offset, cgtFile.reserved, Endian.big);
    offset += 4;

    // Write entries
    for (final entry in cgtFile.entries) {
      offset = _writeEntry(buffer, offset, entry);
    }

    // Write nodes
    for (final node in cgtFile.nodes) {
      offset = _writeNode(buffer, offset, node);
    }

    return buffer.buffer.asUint8List();
  }

  /// Write a single entry to the buffer.
  static int _writeEntry(ByteData buffer, int offset, CrystariumEntry entry) {
    final startOffset = offset;

    // Pattern name (16 bytes, null-padded)
    final nameBytes = _stringToBytes(entry.patternName, _patternNameSize);
    for (var i = 0; i < _patternNameSize; i++) {
      buffer.setUint8(offset + i, nameBytes[i]);
    }
    offset += _patternNameSize;

    // Position (12 bytes)
    buffer.setFloat32(offset, entry.position.x, Endian.big);
    offset += 4;
    buffer.setFloat32(offset, entry.position.y, Endian.big);
    offset += 4;
    buffer.setFloat32(offset, entry.position.z, Endian.big);
    offset += 4;

    // Scale (4 bytes)
    buffer.setFloat32(offset, entry.scale, Endian.big);
    offset += 4;

    // Rotation (16 bytes)
    buffer.setFloat32(offset, entry.rotation.x, Endian.big);
    offset += 4;
    buffer.setFloat32(offset, entry.rotation.y, Endian.big);
    offset += 4;
    buffer.setFloat32(offset, entry.rotation.z, Endian.big);
    offset += 4;
    buffer.setFloat32(offset, entry.rotationW, Endian.big);
    offset += 4;

    // Node scale (4 bytes)
    buffer.setFloat32(offset, entry.nodeScale, Endian.big);
    offset += 4;

    // Flags (4 bytes)
    buffer.setUint8(offset, entry.roleId);
    offset += 1;
    buffer.setUint8(offset, entry.stage);
    offset += 1;
    buffer.setUint8(offset, entry.entryType);
    offset += 1;
    buffer.setUint8(offset, entry.reserved);
    offset += 1;

    // Node IDs (64 bytes = 16 × 4)
    for (var i = 0; i < _nodeIdsCount; i++) {
      final nodeId = i < entry.nodeIds.length ? entry.nodeIds[i] : 0;
      buffer.setUint32(offset, nodeId, Endian.big);
      offset += 4;
    }

    // Link position (16 bytes)
    buffer.setFloat32(offset, entry.linkPosition.x, Endian.big);
    offset += 4;
    buffer.setFloat32(offset, entry.linkPosition.y, Endian.big);
    offset += 4;
    buffer.setFloat32(offset, entry.linkPosition.z, Endian.big);
    offset += 4;
    buffer.setFloat32(offset, entry.linkW, Endian.big);
    offset += 4;

    assert(offset - startOffset == _entrySize, 'Entry size mismatch');
    return offset;
  }

  /// Write a single node record to the buffer.
  static int _writeNode(ByteData buffer, int offset, CrystariumNode node) {
    final startOffset = offset;

    // Node name (16 bytes, null-padded)
    final nameBytes = _stringToBytes(node.name, _patternNameSize);
    for (var i = 0; i < _patternNameSize; i++) {
      buffer.setUint8(offset + i, nameBytes[i]);
    }
    offset += _patternNameSize;

    // Parent index (4 bytes, signed)
    buffer.setInt32(offset, node.parentIndex, Endian.big);
    offset += 4;

    // Unknown fields (16 bytes)
    for (var i = 0; i < 4; i++) {
      final value = i < node.unknown.length ? node.unknown[i] : 0;
      buffer.setUint32(offset, value, Endian.big);
      offset += 4;
    }

    // Scale fields (16 bytes)
    for (var i = 0; i < 4; i++) {
      final value = i < node.scales.length ? node.scales[i] : 1.0;
      buffer.setFloat32(offset, value, Endian.big);
      offset += 4;
    }

    assert(offset - startOffset == _nodeRecordSize, 'Node size mismatch');
    return offset;
  }

  /// Convert a string to null-padded bytes.
  static List<int> _stringToBytes(String str, int length) {
    final bytes = List<int>.filled(length, 0);
    final strBytes = str.codeUnits;
    for (var i = 0; i < length && i < strBytes.length; i++) {
      bytes[i] = strBytes[i] & 0xFF; // ASCII only
    }
    return bytes;
  }
}
