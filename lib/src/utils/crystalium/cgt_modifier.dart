import 'dart:math' as math;
import 'package:oracle_drive/models/crystalium/cgt_file.dart';
import 'package:oracle_drive/models/crystalium/mcp_file.dart';

/// Handles modifications to CGT (Crystarium) data.
class CgtModifier {
  final CgtFile cgtFile;
  final McpFile? mcpPatterns;

  // Mutable copies of the data
  late List<CrystariumEntry> _entries;
  late List<CrystariumNode> _nodes;

  CgtModifier({required this.cgtFile, this.mcpPatterns}) {
    // Create mutable copies
    _entries = List.from(cgtFile.entries);
    _nodes = List.from(cgtFile.nodes);
  }

  /// Get the current entries list.
  List<CrystariumEntry> get entries => _entries;

  /// Get the current nodes list.
  List<CrystariumNode> get nodes => _nodes;

  /// Get the next available node ID.
  int get nextNodeId {
    if (_nodes.isEmpty) return 1;
    return _nodes.map((n) => n.index).reduce(math.max) + 1;
  }

  /// Get character code from existing nodes.
  String get characterCode {
    for (final node in _nodes) {
      final code = node.characterCode;
      if (code != null) return code;
    }
    return 'lt'; // Default to Lightning
  }

  /// Check if a node is a valid branch point (root node or center/first node of an entry).
  bool isValidBranchPoint(int nodeId) {
    // Node 0 is always valid (root)
    if (nodeId == 0) return true;

    // Check if this node is the first/center node of any entry
    for (final entry in _entries) {
      if (entry.nodeIds.isNotEmpty && entry.nodeIds.first == nodeId) {
        return true;
      }
      // Also check if it's the center node (typically at index length/2 for patterns)
      if (entry.nodeIds.length > 1) {
        final centerIdx = entry.nodeIds.length ~/ 2;
        if (entry.nodeIds[centerIdx] == nodeId) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get the entry that contains a specific node.
  CrystariumEntry? getEntryForNode(int nodeId) {
    for (final entry in _entries) {
      if (entry.nodeIds.contains(nodeId)) {
        return entry;
      }
    }
    return null;
  }

  /// Find the best branch point for a given node.
  /// Returns the node itself if it exists, prioritizing user's selection.
  /// Falls back to valid branch points only if the node doesn't exist.
  int findBestBranchPoint(int nodeId) {
    // If node exists, use it (respect user's selection)
    final nodeExists = _nodes.any((n) => n.index == nodeId) || nodeId == 0;
    if (nodeExists) return nodeId;

    // Node doesn't exist - try to find a valid branch point in the same entry
    final entry = getEntryForNode(nodeId);
    if (entry != null && entry.nodeIds.isNotEmpty) {
      // Return the first valid node from the entry
      for (final id in entry.nodeIds) {
        if (_nodes.any((n) => n.index == id)) {
          return id;
        }
      }
    }

    return nodeId; // Fallback
  }

  /// Count how many children a node has.
  int getChildCount(int nodeId) {
    return _nodes.where((n) => n.parentIndex == nodeId).length;
  }

  /// Add an offshoot (new branch) from an existing node.
  ///
  /// The parent node should ideally be a root or center node of an entry.
  /// If not, the method will automatically find the best branch point.
  ///
  /// [customNodeName] - Optional custom name for the nodes. If empty or null,
  /// auto-generates names based on character code and stage.
  ///
  /// Returns the new entry, or null if failed.
  CrystariumEntry? addOffshoot({
    required int parentNodeId,
    required String patternName,
    required int stage,
    required int roleId,
    Vector3? positionOffset,
    bool autoFindBranchPoint = true,
    String? customNodeName,
  }) {
    // Find the best branch point if needed
    final actualParentId = autoFindBranchPoint
        ? findBestBranchPoint(parentNodeId)
        : parentNodeId;

    // Validate parent node exists (variable intentionally unused - validation only)
    final _ = _nodes.firstWhere(
      (n) => n.index == actualParentId,
      orElse: () =>
          throw ArgumentError('Parent node $actualParentId not found'),
    );

    // Get pattern info
    int patternNodeCount = 1;
    if (mcpPatterns != null) {
      final pattern = mcpPatterns!.getPattern(patternName);
      if (pattern != null) {
        patternNodeCount = pattern.count;
      }
    } else {
      // Estimate from pattern name (testN = N nodes)
      final match = RegExp(r'test(\d+)').firstMatch(patternName);
      if (match != null) {
        patternNodeCount = int.parse(match.group(1)!);
      }
    }

    // Find parent's entry to get position reference
    CrystariumEntry? parentEntry;
    for (final entry in _entries) {
      if (entry.nodeIds.contains(actualParentId)) {
        parentEntry = entry;
        break;
      }
    }

    // Calculate position for new entry
    Vector3 newPosition;
    if (positionOffset != null) {
      final basePos = parentEntry?.position ?? Vector3(0, 0, 0);
      newPosition = Vector3(
        basePos.x + positionOffset.x,
        basePos.y + positionOffset.y,
        basePos.z + positionOffset.z,
      );
    } else {
      // Default: place above and offset from parent using golden ratio for unique angles
      final basePos = parentEntry?.position ?? Vector3(0, 0, 0);

      // Calculate unique angle based on parent node ID and existing sibling count
      // Golden ratio ensures well-distributed angles even with many children
      const goldenRatio = 0.618033988749895;
      final siblingCount = getChildCount(actualParentId);
      final baseAngle = (actualParentId * goldenRatio) * 2 * math.pi;
      final angle = baseAngle + (siblingCount * math.pi / 3); // ~60° apart per sibling

      // Distance varies slightly based on stage to prevent exact overlaps
      final distance = 12.0 + (stage % 5) * 2.0;

      newPosition = Vector3(
        basePos.x + math.cos(angle) * distance,
        basePos.y + 8 + (siblingCount * 2), // Step up for each sibling
        basePos.z + math.sin(angle) * distance,
      );
    }

    // Generate new node IDs
    final startNodeId = nextNodeId;
    final newNodeIds = List.generate(patternNodeCount, (i) => startNodeId + i);

    // Create the new entry
    final newEntry = CrystariumEntry(
      index: _entries.length,
      patternName: patternName,
      position: newPosition,
      scale: 1.0,
      rotation: Vector3(0, 0, 0),
      rotationW: 0.0,
      nodeScale: 10.0,
      roleId: roleId,
      stage: stage,
      entryType: patternNodeCount == 1
          ? 255
          : 0, // Leaf if single node, Hub otherwise
      reserved: 0,
      nodeIds: newNodeIds,
      linkPosition: patternNodeCount == 1
          ? Vector3(0, 0, 0)
          : Vector3(0.3, 0.2, -0.3),
      linkW: patternNodeCount == 1 ? 0.0 : 1.0,
    );

    // Create new node records
    final newNodes = <CrystariumNode>[];
    for (var i = 0; i < patternNodeCount; i++) {
      final nodeId = newNodeIds[i];

      // Use custom name if provided (non-empty), otherwise generate
      String nodeName;
      if (customNodeName != null && customNodeName.isNotEmpty) {
        // For multiple nodes, append index to the custom name
        if (patternNodeCount > 1) {
          nodeName = '${customNodeName}_$i'.padRight(16).substring(0, 16);
        } else {
          nodeName = customNodeName.padRight(16).substring(0, 16);
        }
      } else {
        nodeName = _generateNodeName(characterCode, stage, nodeId);
      }

      // First node connects to parent, others connect to first node
      final nodeParent = i == 0 ? actualParentId : newNodeIds[0];

      newNodes.add(
        CrystariumNode(
          index: nodeId,
          name: nodeName,
          parentIndex: nodeParent,
          unknown: [0, 0, 0, 0],
          scales: [1.0, 1.0, 1.0, 1.0],
        ),
      );
    }

    // Add to lists
    _entries.add(newEntry);
    _nodes.addAll(newNodes);

    return newEntry;
  }

  /// Add a chain of nodes (multiple entries connected in sequence).
  List<CrystariumEntry> addChain({
    required int parentNodeId,
    required List<({String patternName, int stage, int roleId})>
    chainDefinition,
    Vector3? startOffset,
    Vector3? stepOffset,
  }) {
    final addedEntries = <CrystariumEntry>[];
    var currentParentId = parentNodeId;
    var currentOffset = startOffset ?? Vector3(0, 10, 0);
    final step = stepOffset ?? Vector3(0, 8, 0);

    for (final def in chainDefinition) {
      final entry = addOffshoot(
        parentNodeId: currentParentId,
        patternName: def.patternName,
        stage: def.stage,
        roleId: def.roleId,
        positionOffset: currentOffset,
      );

      if (entry != null) {
        addedEntries.add(entry);
        // Next offshoot connects to the last node of this entry (usually center)
        currentParentId = entry.nodeIds.last;
        currentOffset = Vector3(
          currentOffset.x + step.x,
          currentOffset.y + step.y,
          currentOffset.z + step.z,
        );
      }
    }

    return addedEntries;
  }

  /// Delete an entry and its nodes.
  bool deleteEntry(int entryIndex) {
    if (entryIndex < 0 || entryIndex >= _entries.length) {
      return false;
    }

    final entry = _entries[entryIndex];

    // Check if any other nodes reference this entry's nodes as parents
    for (final node in _nodes) {
      if (entry.nodeIds.contains(node.parentIndex)) {
        // Cannot delete - has children
        return false;
      }
    }

    // Remove the entry
    _entries.removeAt(entryIndex);

    // Remove the associated nodes
    _nodes.removeWhere((n) => entry.nodeIds.contains(n.index));

    // Update entry indices
    for (var i = entryIndex; i < _entries.length; i++) {
      final oldEntry = _entries[i];
      _entries[i] = CrystariumEntry(
        index: i,
        patternName: oldEntry.patternName,
        position: oldEntry.position,
        scale: oldEntry.scale,
        rotation: oldEntry.rotation,
        rotationW: oldEntry.rotationW,
        nodeScale: oldEntry.nodeScale,
        roleId: oldEntry.roleId,
        stage: oldEntry.stage,
        entryType: oldEntry.entryType,
        reserved: oldEntry.reserved,
        nodeIds: oldEntry.nodeIds,
        linkPosition: oldEntry.linkPosition,
        linkW: oldEntry.linkW,
      );
    }

    return true;
  }

  /// Update an entry's properties.
  bool updateEntry({
    required int entryIndex,
    Vector3? position,
    Vector3? rotation,
    int? stage,
    int? roleId,
  }) {
    if (entryIndex < 0 || entryIndex >= _entries.length) {
      return false;
    }

    final oldEntry = _entries[entryIndex];
    _entries[entryIndex] = CrystariumEntry(
      index: oldEntry.index,
      patternName: oldEntry.patternName,
      position: position ?? oldEntry.position,
      scale: oldEntry.scale,
      rotation: rotation ?? oldEntry.rotation,
      rotationW: oldEntry.rotationW,
      nodeScale: oldEntry.nodeScale,
      roleId: roleId ?? oldEntry.roleId,
      stage: stage ?? oldEntry.stage,
      entryType: oldEntry.entryType,
      reserved: oldEntry.reserved,
      nodeIds: oldEntry.nodeIds,
      linkPosition: oldEntry.linkPosition,
      linkW: oldEntry.linkW,
    );

    // Update node names if stage changed
    if (stage != null && stage != oldEntry.stage) {
      for (final nodeId in oldEntry.nodeIds) {
        final nodeIndex = _nodes.indexWhere((n) => n.index == nodeId);
        if (nodeIndex >= 0) {
          final oldNode = _nodes[nodeIndex];
          _nodes[nodeIndex] = CrystariumNode(
            index: oldNode.index,
            name: _generateNodeName(characterCode, stage, oldNode.index),
            parentIndex: oldNode.parentIndex,
            unknown: oldNode.unknown,
            scales: oldNode.scales,
          );
        }
      }
    }

    return true;
  }

  /// Update a node's name.
  ///
  /// Returns true if successful, false if node not found.
  bool updateNodeName(int nodeId, String newName) {
    final nodeIndex = _nodes.indexWhere((n) => n.index == nodeId);
    if (nodeIndex < 0) {
      return false;
    }

    final oldNode = _nodes[nodeIndex];
    // Pad/truncate to 16 characters
    final paddedName = newName.padRight(16).substring(0, 16);

    _nodes[nodeIndex] = CrystariumNode(
      index: oldNode.index,
      name: paddedName,
      parentIndex: oldNode.parentIndex,
      unknown: oldNode.unknown,
      scales: oldNode.scales,
    );

    return true;
  }

  /// Get a node by ID.
  CrystariumNode? getNode(int nodeId) {
    try {
      return _nodes.firstWhere((n) => n.index == nodeId);
    } catch (_) {
      return null;
    }
  }

  /// Build the modified CGT file.
  CgtFile build() {
    return CgtFile(
      version: cgtFile.version,
      entryCount: _entries.length,
      totalNodes: _nodes.length,
      reserved: cgtFile.reserved,
      entries: _entries,
      nodes: _nodes,
    );
  }

  /// Generate a node name following the FF13 convention.
  String _generateNodeName(String charCode, int stage, int nodeId) {
    // Format: cr_XXYYZZZZ0000
    // XX = char code (2), YY = type (2), ZZZZ = index (4), 0000 = padding
    final stageStr = stage.toString().padLeft(2, '0');
    final idStr = nodeId.toString().padLeft(4, '0');
    return 'cr_${charCode}at$stageStr${idStr}0000'.substring(0, 16);
  }

  /// Validate the current state.
  List<String> validate() {
    final errors = <String>[];

    // Check node parent references
    final nodeIds = _nodes.map((n) => n.index).toSet();
    for (final node in _nodes) {
      if (node.parentIndex >= 0 && !nodeIds.contains(node.parentIndex)) {
        errors.add(
          'Node ${node.index} references non-existent parent ${node.parentIndex}',
        );
      }
    }

    // Check entry node IDs
    for (final entry in _entries) {
      for (final nodeId in entry.nodeIds) {
        if (nodeId > 0 && !nodeIds.contains(nodeId)) {
          errors.add(
            'Entry ${entry.index} references non-existent node $nodeId',
          );
        }
      }
    }

    // Check for orphaned nodes (no path to root)
    final reachable = <int>{0};
    var changed = true;
    while (changed) {
      changed = false;
      for (final node in _nodes) {
        if (!reachable.contains(node.index) &&
            reachable.contains(node.parentIndex)) {
          reachable.add(node.index);
          changed = true;
        }
      }
    }

    for (final node in _nodes) {
      if (!reachable.contains(node.index)) {
        errors.add('Node ${node.index} is not connected to root');
      }
    }

    return errors;
  }
}
