import 'dart:math' as math;
import 'package:ff13_mod_resource/models/crystalium/cgt_file.dart';
import 'package:ff13_mod_resource/models/crystalium/mcp_file.dart';

/// Represents a connection between two nodes in the Crystarium.
class CrystariumConnection {
  final int fromNodeId;
  final int toNodeId;
  final Vector3 fromPosition;
  final Vector3 toPosition;
  final int stage;
  final int roleId;

  CrystariumConnection({
    required this.fromNodeId,
    required this.toNodeId,
    required this.fromPosition,
    required this.toPosition,
    required this.stage,
    required this.roleId,
  });

  double get length {
    final dx = toPosition.x - fromPosition.x;
    final dy = toPosition.y - fromPosition.y;
    final dz = toPosition.z - fromPosition.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  Vector3 get midpoint => Vector3(
    (fromPosition.x + toPosition.x) / 2,
    (fromPosition.y + toPosition.y) / 2,
    (fromPosition.z + toPosition.z) / 2,
  );
}

/// Node information with computed world position.
class CrystariumNodeInfo {
  final int nodeId;
  final Vector3 worldPosition;
  final int stage;
  final int roleId;
  final int entryIndex;

  CrystariumNodeInfo({
    required this.nodeId,
    required this.worldPosition,
    required this.stage,
    required this.roleId,
    required this.entryIndex,
  });
}

/// Handles coordinate transformations and rendering calculations for Crystarium data.
class CrystariumRenderer {
  final CgtFile cgtFile;
  final McpFile? mcpPatterns;

  // Computed data
  late final Map<int, Vector3> nodeWorldPositions;
  late final List<CrystariumConnection> connections;
  late final Map<int, CrystariumNodeInfo> nodeInfo;

  CrystariumRenderer({
    required this.cgtFile,
    this.mcpPatterns,
  }) {
    _computeWorldPositions();
    _buildConnections();
  }

  /// Compute world positions for all nodes.
  void _computeWorldPositions() {
    nodeWorldPositions = {};
    nodeInfo = {};

    // Node 0 (root) is at origin
    nodeWorldPositions[0] = Vector3(0, 0, 0);

    for (final entry in cgtFile.entries) {
      // Get pattern geometry if available
      McpPattern? pattern;
      if (mcpPatterns != null) {
        pattern = mcpPatterns!.getPattern(entry.patternName);
      }

      // Create rotation matrix
      final rotMatrix = _createRotationMatrix(
        entry.rotation.x,
        entry.rotation.y,
        entry.rotation.z,
      );

      // Transform each node
      for (var i = 0; i < entry.nodeIds.length; i++) {
        final nodeId = entry.nodeIds[i];
        if (nodeId == 0) continue; // Skip empty slots

        Vector3 localPos;
        if (pattern != null && i < pattern.nodes.length) {
          localPos = pattern.nodes[i];
        } else {
          // Default position if pattern not available
          // Distribute nodes in a circle
          final angle = (i / math.max(entry.nodeIds.length, 1)) * 2 * math.pi;
          final radius = 0.54; // Default pattern radius
          localPos = Vector3(
            radius * math.cos(angle),
            0,
            radius * math.sin(angle),
          );
        }

        // Apply node scale and rotation
        final worldPos = _localToWorld(
          localPos,
          entry.position,
          rotMatrix,
          entry.nodeScale,
        );

        nodeWorldPositions[nodeId] = worldPos;
        nodeInfo[nodeId] = CrystariumNodeInfo(
          nodeId: nodeId,
          worldPosition: worldPos,
          stage: entry.stage,
          roleId: entry.roleId,
          entryIndex: entry.index,
        );
      }
    }
  }

  /// Build connection graph from parent references.
  void _buildConnections() {
    connections = [];

    // Map node ID to stage/role for filtering
    final nodeStages = <int, int>{};
    final nodeRoles = <int, int>{};
    for (final entry in cgtFile.entries) {
      for (final nodeId in entry.nodeIds) {
        if (nodeId > 0) {
          nodeStages[nodeId] = entry.stage;
          nodeRoles[nodeId] = entry.roleId;
        }
      }
    }

    // Build connections from parent references
    for (final node in cgtFile.nodes) {
      if (node.parentIndex < 0) continue; // Skip root

      final fromPos = nodeWorldPositions[node.parentIndex];
      final toPos = nodeWorldPositions[node.index];

      if (fromPos == null || toPos == null) continue;

      connections.add(CrystariumConnection(
        fromNodeId: node.parentIndex,
        toNodeId: node.index,
        fromPosition: fromPos,
        toPosition: toPos,
        stage: nodeStages[node.index] ?? 1,
        roleId: nodeRoles[node.index] ?? 0,
      ));
    }
  }

  /// Create a rotation matrix from Euler angles (Y-X-Z order).
  List<List<double>> _createRotationMatrix(double rx, double ry, double rz) {
    final cosX = math.cos(rx);
    final sinX = math.sin(rx);
    final cosY = math.cos(ry);
    final sinY = math.sin(ry);
    final cosZ = math.cos(rz);
    final sinZ = math.sin(rz);

    // Y rotation
    final rotY = [
      [cosY, 0.0, sinY],
      [0.0, 1.0, 0.0],
      [-sinY, 0.0, cosY],
    ];

    // X rotation
    final rotX = [
      [1.0, 0.0, 0.0],
      [0.0, cosX, -sinX],
      [0.0, sinX, cosX],
    ];

    // Z rotation
    final rotZ = [
      [cosZ, -sinZ, 0.0],
      [sinZ, cosZ, 0.0],
      [0.0, 0.0, 1.0],
    ];

    // Combine: result = rotY * rotX * rotZ
    final temp = _multiplyMatrix(rotY, rotX);
    return _multiplyMatrix(temp, rotZ);
  }

  /// Multiply two 3x3 matrices.
  List<List<double>> _multiplyMatrix(
    List<List<double>> a,
    List<List<double>> b,
  ) {
    return [
      for (var i = 0; i < 3; i++)
        [
          for (var j = 0; j < 3; j++)
            a[i][0] * b[0][j] + a[i][1] * b[1][j] + a[i][2] * b[2][j],
        ],
    ];
  }

  /// Transform a local position to world space.
  Vector3 _localToWorld(
    Vector3 localPos,
    Vector3 entryPosition,
    List<List<double>> rotMatrix,
    double scale,
  ) {
    // Scale local position
    final sx = localPos.x * scale;
    final sy = localPos.y * scale;
    final sz = localPos.z * scale;

    // Apply rotation
    final rx = rotMatrix[0][0] * sx + rotMatrix[0][1] * sy + rotMatrix[0][2] * sz;
    final ry = rotMatrix[1][0] * sx + rotMatrix[1][1] * sy + rotMatrix[1][2] * sz;
    final rz = rotMatrix[2][0] * sx + rotMatrix[2][1] * sy + rotMatrix[2][2] * sz;

    // Translate to world position
    return Vector3(
      rx + entryPosition.x,
      ry + entryPosition.y,
      rz + entryPosition.z,
    );
  }

  /// Get all connections filtered by stage.
  List<CrystariumConnection> getConnectionsForStage(int maxStage) {
    return connections.where((c) => c.stage <= maxStage).toList();
  }

  /// Get all node positions filtered by stage.
  Map<int, Vector3> getNodesForStage(int maxStage) {
    final result = <int, Vector3>{};
    result[0] = Vector3(0, 0, 0); // Always include root

    for (final entry in nodeInfo.entries) {
      if (entry.value.stage <= maxStage) {
        result[entry.key] = entry.value.worldPosition;
      }
    }
    return result;
  }

  /// Build adjacency list for node navigation.
  Map<int, List<int>> buildAdjacencyList() {
    final adjacency = <int, List<int>>{};

    for (final conn in connections) {
      adjacency.putIfAbsent(conn.fromNodeId, () => []).add(conn.toNodeId);
      adjacency.putIfAbsent(conn.toNodeId, () => []).add(conn.fromNodeId);
    }

    return adjacency;
  }

  /// Find path between two nodes using BFS.
  List<int> findPath(int start, int end) {
    final adjacency = buildAdjacencyList();
    final visited = <int>{};
    final queue = <List<int>>[[start]];

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      if (current == end) return path;
      if (visited.contains(current)) continue;
      visited.add(current);

      for (final neighbor in adjacency[current] ?? <int>[]) {
        if (!visited.contains(neighbor)) {
          queue.add([...path, neighbor]);
        }
      }
    }

    return []; // No path found
  }

  /// Get bounding box of all nodes.
  ({Vector3 min, Vector3 max}) getBoundingBox() {
    if (nodeWorldPositions.isEmpty) {
      return (min: Vector3(0, 0, 0), max: Vector3(0, 0, 0));
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var minZ = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    var maxZ = double.negativeInfinity;

    for (final pos in nodeWorldPositions.values) {
      minX = math.min(minX, pos.x);
      minY = math.min(minY, pos.y);
      minZ = math.min(minZ, pos.z);
      maxX = math.max(maxX, pos.x);
      maxY = math.max(maxY, pos.y);
      maxZ = math.max(maxZ, pos.z);
    }

    return (
      min: Vector3(minX, minY, minZ),
      max: Vector3(maxX, maxY, maxZ),
    );
  }

  /// Get center of all nodes.
  Vector3 getCenter() {
    final bounds = getBoundingBox();
    return Vector3(
      (bounds.min.x + bounds.max.x) / 2,
      (bounds.min.y + bounds.max.y) / 2,
      (bounds.min.z + bounds.max.z) / 2,
    );
  }
}
