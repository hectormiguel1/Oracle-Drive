import 'dart:typed_data';
import 'package:oracle_drive/models/crystalium/mcp_file.dart';

/// Parser for FF13 Crystarium MCP (Master Crystal Pattern) files.
///
/// MCP files define geometric patterns used by the Crystarium system.
/// File format uses Big Endian byte order.
class McpParser {
  // File structure constants
  static const int _headerSize = 16;
  static const int _patternEntrySize = 272;
  static const int _patternNameSize = 16;
  static const int _nodeSize = 16;
  static const int _nodesPerPattern = 16;

  /// Parse an MCP file from raw bytes.
  static McpFile parse(Uint8List data) {
    if (data.length < _headerSize) {
      throw FormatException('MCP file too small: ${data.length} bytes');
    }

    final byteData = ByteData.sublistView(data);

    // Parse header
    final version = byteData.getUint32(0, Endian.big);
    final patternCount = byteData.getUint32(4, Endian.big);
    // Reserved bytes at offset 8-15

    final expectedSize = _headerSize + (patternCount * _patternEntrySize);
    if (data.length < expectedSize) {
      throw FormatException(
        'MCP file too small for $patternCount patterns. '
        'Expected $expectedSize bytes, got ${data.length}',
      );
    }

    // Parse patterns
    final patternsMap = <String, McpPattern>{};

    for (var i = 0; i < patternCount; i++) {
      final offset = _headerSize + (i * _patternEntrySize);
      final pattern = _parsePattern(data, byteData, offset, i);
      patternsMap[pattern.name] = pattern;
    }

    return McpFile(
      version: version,
      patternCount: patternCount,
      reserved: 0,
      patternsMap: patternsMap,
    );
  }

  /// Parse a single pattern entry at the given offset.
  static McpPattern _parsePattern(
    Uint8List data,
    ByteData byteData,
    int offset,
    int index,
  ) {
    // Parse pattern name (16 bytes, null-terminated ASCII)
    final nameBytes = data.sublist(offset, offset + _patternNameSize);
    final nameEnd = nameBytes.indexOf(0);
    final name = String.fromCharCodes(
      nameEnd >= 0 ? nameBytes.sublist(0, nameEnd) : nameBytes,
    );

    // Parse nodes (16 slots × 16 bytes each)
    final nodes = <Vector3>[];
    final nodesOffset = offset + _patternNameSize;

    for (var j = 0; j < _nodesPerPattern; j++) {
      final nodeOffset = nodesOffset + (j * _nodeSize);

      final x = _getFloat32BE(byteData, nodeOffset);
      final y = _getFloat32BE(byteData, nodeOffset + 4);
      final z = _getFloat32BE(byteData, nodeOffset + 8);
      final w = _getFloat32BE(byteData, nodeOffset + 12);

      // W = 1.0 indicates a valid node
      if (w == 1.0) {
        nodes.add(Vector3(x, y, z));
      } else {
        // End of valid nodes for this pattern
        break;
      }
    }

    return McpPattern(
      name: name.isEmpty ? 'pattern_$index' : name,
      nodes: nodes,
      count: nodes.length,
    );
  }

  /// Read a big-endian float32 from the byte data.
  static double _getFloat32BE(ByteData byteData, int offset) {
    return byteData.getFloat32(offset, Endian.big);
  }
}
