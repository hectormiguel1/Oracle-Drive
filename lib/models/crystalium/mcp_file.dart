class Vector3 {
  final double x;
  final double y;
  final double z;

  const Vector3(this.x, this.y, this.z);

  Vector3 operator +(Vector3 other) => Vector3(x + other.x, y + other.y, z + other.z);
  Vector3 operator *(double scale) => Vector3(x * scale, y * scale, z * scale);
  
  @override
  String toString() => 'Vector3($x, $y, $z)';
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
}
