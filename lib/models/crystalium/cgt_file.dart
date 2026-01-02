import 'dart:typed_data';
import 'package:oracle_drive/models/crystalium/mcp_file.dart';
import 'package:fabula_nova_sdk/bridge_generated/modules/crystalium/structs.dart'
    as sdk;
import 'package:fabula_nova_sdk/bridge_generated/lib.dart' show U32Array4, F32Array4;

/// Represents a Crystarium role (combat class)
enum CrystariumRole {
  defender(0, 'DEF', 'Defender'),
  attacker(1, 'ATT', 'Attacker'),
  blaster(2, 'BLA', 'Blaster'),
  enhancer(3, 'ENH', 'Enhancer'),
  jammer(4, 'JAM', 'Jammer'),
  healer(5, 'MED', 'Healer');

  final int id;
  final String abbreviation;
  final String fullName;

  const CrystariumRole(this.id, this.abbreviation, this.fullName);

  static CrystariumRole fromId(int id) {
    return CrystariumRole.values.firstWhere(
      (r) => r.id == id,
      orElse: () => CrystariumRole.defender,
    );
  }
}

/// Represents an entry type in the Crystarium
enum CrystariumEntryType {
  hub(0, 'Hub'),
  special(5, 'Special'),
  branch(11, 'Branch'),
  leaf(255, 'Leaf');

  final int id;
  final String name;

  const CrystariumEntryType(this.id, this.name);

  static CrystariumEntryType fromId(int id) {
    return CrystariumEntryType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => CrystariumEntryType.hub,
    );
  }
}

/// Represents a single entry (pattern instance) in the Crystarium
class CrystariumEntry {
  final int index;
  final String patternName;
  final Vector3 position;
  final double scale;
  final Vector3 rotation;
  final double rotationW;
  final double nodeScale;
  final int roleId;
  final int stage;
  final int entryType;
  final int reserved;
  final List<int> nodeIds;
  final Vector3 linkPosition;
  final double linkW;

  CrystariumEntry({
    required this.index,
    required this.patternName,
    required this.position,
    required this.scale,
    required this.rotation,
    required this.rotationW,
    required this.nodeScale,
    required this.roleId,
    required this.stage,
    required this.entryType,
    required this.reserved,
    required this.nodeIds,
    required this.linkPosition,
    required this.linkW,
  });

  /// Get the role as an enum
  CrystariumRole get role => CrystariumRole.fromId(roleId);

  /// Get the entry type as an enum
  CrystariumEntryType get type => CrystariumEntryType.fromId(entryType);

  /// Check if this is a hub entry (has valid link position)
  bool get isHub => entryType == 0;

  /// Check if this is a leaf entry (end node)
  bool get isLeaf => entryType == 255;

  /// Check if this is a branch connector
  bool get isBranch => entryType == 11;

  /// Number of valid nodes in this entry
  int get nodeCount => nodeIds.where((id) => id > 0).length;
}

/// Represents a node in the Crystarium tree structure
class CrystariumNode {
  final int index;
  final String name;
  final int parentIndex;
  final List<int> unknown;
  final List<double> scales;

  CrystariumNode({
    required this.index,
    required this.name,
    required this.parentIndex,
    required this.unknown,
    required this.scales,
  });

  /// Check if this is the root node
  bool get isRoot => parentIndex == -1;

  /// Parse character code from node name (e.g., "lt" from "cr_ltat02030000")
  String? get characterCode {
    if (name.startsWith('cr_') && name.length >= 5) {
      return name.substring(3, 5);
    }
    return null;
  }

  /// Parse stage from node name
  int? get stageFromName {
    if (name.startsWith('cr_') && name.length >= 9) {
      final stageStr = name.substring(7, 9);
      return int.tryParse(stageStr);
    }
    return null;
  }
}

/// Represents a complete CGT (Crystal Graph Tree) file
class CgtFile {
  final int version;
  final int entryCount;
  final int totalNodes;
  final int reserved;
  final List<CrystariumEntry> entries;
  final List<CrystariumNode> nodes;

  CgtFile({
    required this.version,
    required this.entryCount,
    required this.totalNodes,
    required this.reserved,
    required this.entries,
    required this.nodes,
  });

  /// Get all unique stages in this file
  List<int> get stages {
    final stageSet = entries.map((e) => e.stage).toSet();
    return stageSet.toList()..sort();
  }

  /// Get entries for a specific stage
  List<CrystariumEntry> entriesForStage(int stage) {
    return entries.where((e) => e.stage == stage).toList();
  }

  /// Get entries for a specific role
  List<CrystariumEntry> entriesForRole(CrystariumRole role) {
    return entries.where((e) => e.roleId == role.id).toList();
  }

  /// Get the node at the given index
  CrystariumNode? getNode(int index) {
    if (index < 0 || index >= nodes.length) return null;
    return nodes[index];
  }

  /// Get the entry containing a specific node ID
  CrystariumEntry? getEntryForNode(int nodeId) {
    for (final entry in entries) {
      if (entry.nodeIds.contains(nodeId)) {
        return entry;
      }
    }
    return null;
  }

  /// Build a map of children for each node
  Map<int, List<int>> buildChildrenMap() {
    final childrenMap = <int, List<int>>{};
    for (var i = 0; i < nodes.length; i++) {
      final pIdx = nodes[i].parentIndex;
      if (pIdx != -1) {
        childrenMap.putIfAbsent(pIdx, () => []).add(i);
      }
    }
    return childrenMap;
  }

  /// Convert from SDK type
  static CgtFile fromSdk(sdk.CgtFile sdkCgt) {
    return CgtFile(
      version: sdkCgt.version,
      entryCount: sdkCgt.entryCount,
      totalNodes: sdkCgt.totalNodes,
      reserved: sdkCgt.reserved,
      entries: sdkCgt.entries.map((e) => CrystariumEntryConversion.fromSdk(e)).toList(),
      nodes: sdkCgt.nodes.map((n) => CrystariumNodeConversion.fromSdk(n)).toList(),
    );
  }

  /// Convert to SDK type
  sdk.CgtFile toSdk() {
    return sdk.CgtFile(
      version: version,
      entryCount: entryCount,
      totalNodes: totalNodes,
      reserved: reserved,
      entries: entries.map((e) => e.toSdk()).toList(),
      nodes: nodes.map((n) => n.toSdk()).toList(),
    );
  }
}

// ============================================================
// SDK Conversion Extensions
// ============================================================

extension CrystariumEntryConversion on CrystariumEntry {
  static CrystariumEntry fromSdk(sdk.CrystariumEntry sdkEntry) {
    return CrystariumEntry(
      index: sdkEntry.index,
      patternName: sdkEntry.patternName,
      position: Vector3(
        sdkEntry.position.x,
        sdkEntry.position.y,
        sdkEntry.position.z,
      ),
      scale: sdkEntry.scale,
      rotation: Vector3(
        sdkEntry.rotation.x,
        sdkEntry.rotation.y,
        sdkEntry.rotation.z,
      ),
      rotationW: sdkEntry.rotationW,
      nodeScale: sdkEntry.nodeScale,
      roleId: sdkEntry.roleId,
      stage: sdkEntry.stage,
      entryType: sdkEntry.entryType,
      reserved: sdkEntry.reserved,
      nodeIds: sdkEntry.nodeIds.toList(),
      linkPosition: Vector3(
        sdkEntry.linkPosition.x,
        sdkEntry.linkPosition.y,
        sdkEntry.linkPosition.z,
      ),
      linkW: sdkEntry.linkW,
    );
  }

  sdk.CrystariumEntry toSdk() {
    return sdk.CrystariumEntry(
      index: index,
      patternName: patternName,
      position: sdk.Vec3(x: position.x, y: position.y, z: position.z),
      scale: scale,
      rotation: sdk.Vec3(x: rotation.x, y: rotation.y, z: rotation.z),
      rotationW: rotationW,
      nodeScale: nodeScale,
      roleId: roleId,
      stage: stage,
      entryType: entryType,
      reserved: reserved,
      nodeIds: Uint32List.fromList(nodeIds),
      linkPosition: sdk.Vec3(x: linkPosition.x, y: linkPosition.y, z: linkPosition.z),
      linkW: linkW,
    );
  }
}

extension CrystariumNodeConversion on CrystariumNode {
  static CrystariumNode fromSdk(sdk.CrystariumNode sdkNode) {
    return CrystariumNode(
      index: sdkNode.index,
      name: sdkNode.name,
      parentIndex: sdkNode.parentIndex,
      unknown: sdkNode.unknown.toList(),
      scales: sdkNode.scales.toList(),
    );
  }

  sdk.CrystariumNode toSdk() {
    return sdk.CrystariumNode(
      index: index,
      name: name,
      parentIndex: parentIndex,
      unknown: U32Array4(Uint32List.fromList(unknown)),
      scales: F32Array4(Float32List.fromList(scales)),
    );
  }
}
