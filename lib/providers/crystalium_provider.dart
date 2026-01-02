import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:oracle_drive/models/crystalium/cgt_file.dart';
import 'package:oracle_drive/models/crystalium/mcp_file.dart';
import 'package:oracle_drive/src/utils/crystalium/cgt_modifier.dart';
import 'package:oracle_drive/src/utils/crystalium/cgt_parser.dart';
import 'package:oracle_drive/src/utils/crystalium/cgt_writer.dart';
import 'package:oracle_drive/src/utils/crystalium/mcp_parser.dart';
import 'package:path/path.dart' as p;

enum CrystaliumViewMode { mcp, cgt }

/// State for the Crystalium screen
@immutable
class CrystaliumState {
  final CrystaliumViewMode viewMode;

  // MCP State
  final McpFile? mcpFile;
  final McpPattern? selectedPattern;

  // CGT State
  final CgtFile? cgtFile;
  final McpFile? cgtPatterns;
  final CrystariumEntry? selectedEntry;
  final int? selectedNodeIdx;
  final Map<int, List<int>> childrenMap;
  final int visualizerKey;
  final String? currentFilePath;

  // Modification state
  final bool hasUnsavedChanges;

  const CrystaliumState({
    this.viewMode = CrystaliumViewMode.mcp,
    this.mcpFile,
    this.selectedPattern,
    this.cgtFile,
    this.cgtPatterns,
    this.selectedEntry,
    this.selectedNodeIdx,
    this.childrenMap = const {},
    this.visualizerKey = 0,
    this.currentFilePath,
    this.hasUnsavedChanges = false,
  });

  CrystaliumState copyWith({
    CrystaliumViewMode? viewMode,
    McpFile? mcpFile,
    McpPattern? selectedPattern,
    CgtFile? cgtFile,
    McpFile? cgtPatterns,
    CrystariumEntry? selectedEntry,
    int? selectedNodeIdx,
    Map<int, List<int>>? childrenMap,
    int? visualizerKey,
    String? currentFilePath,
    bool? hasUnsavedChanges,
    bool clearSelectedPattern = false,
    bool clearSelectedEntry = false,
    bool clearSelectedNodeIdx = false,
  }) {
    return CrystaliumState(
      viewMode: viewMode ?? this.viewMode,
      mcpFile: mcpFile ?? this.mcpFile,
      selectedPattern: clearSelectedPattern ? null : (selectedPattern ?? this.selectedPattern),
      cgtFile: cgtFile ?? this.cgtFile,
      cgtPatterns: cgtPatterns ?? this.cgtPatterns,
      selectedEntry: clearSelectedEntry ? null : (selectedEntry ?? this.selectedEntry),
      selectedNodeIdx: clearSelectedNodeIdx ? null : (selectedNodeIdx ?? this.selectedNodeIdx),
      childrenMap: childrenMap ?? this.childrenMap,
      visualizerKey: visualizerKey ?? this.visualizerKey,
      currentFilePath: currentFilePath ?? this.currentFilePath,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }

  /// Get available pattern names from CGT patterns or defaults
  List<String> get availablePatternNames {
    return cgtPatterns?.patterns.map((p) => p.name).toList() ??
        ['test1', 'test2', 'test3', 'test4', 'test5', 'test6', 'test7', 'test8'];
  }
}

/// Provider for Crystalium state
final crystaliumProvider = StateNotifierProvider<CrystaliumNotifier, CrystaliumState>(
  (ref) => CrystaliumNotifier(),
);

class CrystaliumNotifier extends StateNotifier<CrystaliumState> {
  CgtModifier? _modifier;

  CrystaliumNotifier() : super(const CrystaliumState());

  CgtModifier? get modifier => _modifier;

  // ============================================================
  // View Mode
  // ============================================================

  void setViewMode(CrystaliumViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void resetCamera() {
    state = state.copyWith(visualizerKey: state.visualizerKey + 1);
  }

  // ============================================================
  // File Loading
  // ============================================================

  Future<void> loadFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final fileName = p.basename(filePath).toLowerCase();

    if (fileName.endsWith('.mcp')) {
      await _loadMcpFile(bytes);
    } else if (fileName.endsWith('.cgt')) {
      await _loadCgtFile(filePath, bytes);
    } else {
      throw Exception('Unsupported file type');
    }
  }

  Future<void> _loadMcpFile(Uint8List bytes) async {
    final mcp = McpParser.parse(bytes);
    state = state.copyWith(
      mcpFile: mcp,
      viewMode: CrystaliumViewMode.mcp,
      selectedPattern: mcp.patterns.isNotEmpty ? mcp.patterns.first : null,
    );
  }

  Future<void> _loadCgtFile(String filePath, Uint8List bytes) async {
    final cgt = CgtParser.parse(bytes);

    // Try to load patterns file from same directory
    McpFile? patterns;
    final patternsPath = p.join(p.dirname(filePath), 'patterns.mcp');
    if (await File(patternsPath).exists()) {
      final pBytes = await File(patternsPath).readAsBytes();
      patterns = McpParser.parse(pBytes);
    }

    // Build children map
    final childrenMap = _buildChildrenMap(cgt);

    // Find first valid node
    int? firstNodeIdx;
    CrystariumEntry? firstEntry;
    if (cgt.entries.isNotEmpty) {
      firstEntry = cgt.entries.first;
      final firstNode = cgt.entries.first.nodeIds.firstWhere(
        (id) => id != 0,
        orElse: () => -1,
      );
      if (firstNode != -1) {
        firstNodeIdx = firstNode;
      }
    }

    _modifier = CgtModifier(cgtFile: cgt, mcpPatterns: patterns);

    state = state.copyWith(
      cgtFile: cgt,
      cgtPatterns: patterns,
      viewMode: CrystaliumViewMode.cgt,
      childrenMap: childrenMap,
      currentFilePath: filePath,
      hasUnsavedChanges: false,
      selectedEntry: firstEntry,
      selectedNodeIdx: firstNodeIdx,
    );
  }

  Map<int, List<int>> _buildChildrenMap(CgtFile cgt) {
    final childrenMap = <int, List<int>>{};
    for (var i = 0; i < cgt.nodes.length; i++) {
      final pIdx = cgt.nodes[i].parentIndex;
      if (pIdx != -1) {
        childrenMap.putIfAbsent(pIdx, () => []).add(i);
      }
    }
    return childrenMap;
  }

  // ============================================================
  // File Saving
  // ============================================================

  Future<void> saveCgtFile(String outputPath) async {
    if (state.cgtFile == null) return;

    final fileToSave = _modifier != null ? _modifier!.build() : state.cgtFile!;
    final bytes = CgtWriter.write(fileToSave);
    await File(outputPath).writeAsBytes(bytes);

    state = state.copyWith(
      currentFilePath: outputPath,
      hasUnsavedChanges: false,
    );
  }

  // ============================================================
  // Selection
  // ============================================================

  void selectPattern(McpPattern pattern) {
    state = state.copyWith(selectedPattern: pattern);
  }

  void selectEntry(CrystariumEntry entry) {
    state = state.copyWith(
      selectedEntry: entry,
      clearSelectedNodeIdx: true,
    );
  }

  void selectNode(int nodeIdx) {
    state = state.copyWith(selectedNodeIdx: nodeIdx);
  }

  // ============================================================
  // Node Navigation
  // ============================================================

  void handleNodeNavigation(LogicalKeyboardKey key) {
    if (state.cgtFile == null) return;

    if (state.selectedNodeIdx == null) {
      _selectFirstNode();
      return;
    }

    final currentIdx = state.selectedNodeIdx!;
    if (currentIdx >= state.cgtFile!.nodes.length) return;

    final currentNode = state.cgtFile!.nodes[currentIdx];

    if (key == LogicalKeyboardKey.arrowUp) {
      if (currentNode.parentIndex > 0) {
        state = state.copyWith(selectedNodeIdx: currentNode.parentIndex);
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      final children = state.childrenMap[currentIdx];
      if (children != null && children.isNotEmpty) {
        state = state.copyWith(selectedNodeIdx: children.first);
      }
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      _navigateSibling(currentIdx, currentNode.parentIndex, key == LogicalKeyboardKey.arrowLeft);
    }
  }

  void _selectFirstNode() {
    if (state.cgtFile!.entries.isNotEmpty) {
      final firstNode = state.cgtFile!.entries.first.nodeIds.firstWhere(
        (id) => id != 0,
        orElse: () => -1,
      );
      if (firstNode != -1) {
        state = state.copyWith(selectedNodeIdx: firstNode);
      }
    }
  }

  void _navigateSibling(int currentIdx, int parentIdx, bool goLeft) {
    if (parentIdx == -1) return;
    final siblings = state.childrenMap[parentIdx];
    if (siblings == null) return;

    final myIndex = siblings.indexOf(currentIdx);
    if (myIndex == -1) return;

    final newIndex = goLeft
        ? (myIndex - 1 + siblings.length) % siblings.length
        : (myIndex + 1) % siblings.length;
    state = state.copyWith(selectedNodeIdx: siblings[newIndex]);
  }

  // ============================================================
  // Modifications
  // ============================================================

  CrystariumEntry? addOffshoot({
    required int parentNodeId,
    required String patternName,
    required int stage,
    required int roleId,
    bool autoFindBranchPoint = true,
    String? customNodeName,
  }) {
    if (_modifier == null) return null;

    final newEntry = _modifier!.addOffshoot(
      parentNodeId: parentNodeId,
      patternName: patternName,
      stage: stage,
      roleId: roleId,
      autoFindBranchPoint: autoFindBranchPoint,
      customNodeName: customNodeName,
    );

    if (newEntry != null) {
      _applyModifierChanges(selectNewEntry: !autoFindBranchPoint ? false : true, newEntry: newEntry);
    }

    return newEntry;
  }

  bool updateNodeName(int nodeId, String newName) {
    if (_modifier == null) return false;

    final success = _modifier!.updateNodeName(nodeId, newName);
    if (success) {
      _applyModifierChanges();
    }
    return success;
  }

  void _applyModifierChanges({bool selectNewEntry = false, CrystariumEntry? newEntry}) {
    final updatedCgt = _modifier!.build();
    final childrenMap = _buildChildrenMap(updatedCgt);

    if (selectNewEntry && newEntry != null) {
      state = state.copyWith(
        cgtFile: updatedCgt,
        childrenMap: childrenMap,
        hasUnsavedChanges: true,
        visualizerKey: state.visualizerKey + 1,
        selectedEntry: newEntry,
        selectedNodeIdx: newEntry.nodeIds.isNotEmpty ? newEntry.nodeIds.first : null,
      );
    } else {
      state = state.copyWith(
        cgtFile: updatedCgt,
        childrenMap: childrenMap,
        hasUnsavedChanges: true,
      );
    }
  }
}
