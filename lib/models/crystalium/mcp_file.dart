import 'package:fabula_nova_sdk/bridge_generated/modules/crystalium/structs.dart'
    as sdk;

class Vector3 {
  final double x;
  final double y;
  final double z;

  const Vector3(this.x, this.y, this.z);

  Vector3 operator +(Vector3 other) => Vector3(x + other.x, y + other.y, z + other.z);
  Vector3 operator *(double scale) => Vector3(x * scale, y * scale, z * scale);

  @override
  String toString() => 'Vector3($x, $y, $z)';

  /// Convert from SDK Vec3
  static Vector3 fromSdk(sdk.Vec3 v) => Vector3(v.x, v.y, v.z);

  /// Convert to SDK Vec3
  sdk.Vec3 toSdk() => sdk.Vec3(x: x, y: y, z: z);
}

class McpPattern {
  final String name;
  final List<Vector3> nodes; // Valid nodes only (W=1.0)
  final int count;

  McpPattern({
    required this.name,
    required this.nodes,
    required this.count,
  });

  /// Returns nodes with valid positions (excludes center node at origin if it's the only one)
  List<Vector3> get validNodes => nodes;
}

class McpFile {
  final int version;
  final int patternCount;
  final int reserved;
  final Map<String, McpPattern> patternsMap;

  McpFile({
    required this.version,
    required this.patternCount,
    required this.reserved,
    required this.patternsMap,
  });

  /// Returns patterns as a list (sorted by name for consistent ordering)
  List<McpPattern> get patterns => patternsMap.values.toList();

  /// Get a pattern by name
  McpPattern? getPattern(String name) => patternsMap[name];

  /// Convert from SDK type
  static McpFile fromSdk(sdk.McpFile sdkMcp) {
    final patternsMap = <String, McpPattern>{};
    for (final entry in sdkMcp.patterns.entries) {
      patternsMap[entry.key] = McpPatternConversion.fromSdk(entry.value);
    }
    return McpFile(
      version: sdkMcp.version,
      patternCount: sdkMcp.patternCount,
      reserved: sdkMcp.reserved,
      patternsMap: patternsMap,
    );
  }
}

extension McpPatternConversion on McpPattern {
  static McpPattern fromSdk(sdk.McpPattern sdkPattern) {
    return McpPattern(
      name: sdkPattern.name,
      nodes: sdkPattern.nodes.map((v) => Vector3.fromSdk(v)).toList(),
      count: sdkPattern.count.toInt(),
    );
  }
}
