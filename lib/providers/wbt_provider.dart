import 'package:fabula_nova_sdk/bridge_generated/api.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Represents a node in the file tree (either a file or directory)
class WbtTreeNode {
  final String name;
  final String fullPath;
  final bool isDirectory;
  final int? fileIndex;
  final int? uncompressedSize;
  final int? compressedSize;
  final List<WbtTreeNode> children;
  bool isExpanded;
  bool isSelected;

  WbtTreeNode({
    required this.name,
    required this.fullPath,
    required this.isDirectory,
    this.fileIndex,
    this.uncompressedSize,
    this.compressedSize,
    List<WbtTreeNode>? children,
    this.isExpanded = false,
    this.isSelected = false,
  }) : children = children ?? [];

  WbtTreeNode copyWith({
    bool? isExpanded,
    bool? isSelected,
    List<WbtTreeNode>? children,
  }) {
    return WbtTreeNode(
      name: name,
      fullPath: fullPath,
      isDirectory: isDirectory,
      fileIndex: fileIndex,
      uncompressedSize: uncompressedSize,
      compressedSize: compressedSize,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class WbtState {
  final String? fileListPath;
  final String? binPath;
  final bool isProcessing;
  final double extractionProgress;
  final String? repackSourceDir;
  final List<WbtFileEntry> fileEntries;
  final WbtTreeNode? rootNode;
  final Set<int> selectedIndices;
  final bool isLoadingFileList;

  WbtState({
    this.fileListPath,
    this.binPath,
    this.isProcessing = false,
    this.extractionProgress = 0,
    this.repackSourceDir,
    this.fileEntries = const [],
    this.rootNode,
    this.selectedIndices = const {},
    this.isLoadingFileList = false,
  });

  WbtState copyWith({
    String? fileListPath,
    String? binPath,
    bool? isProcessing,
    double? extractionProgress,
    String? repackSourceDir,
    List<WbtFileEntry>? fileEntries,
    WbtTreeNode? rootNode,
    Set<int>? selectedIndices,
    bool? isLoadingFileList,
    bool clearRootNode = false,
  }) {
    return WbtState(
      fileListPath: fileListPath ?? this.fileListPath,
      binPath: binPath ?? this.binPath,
      isProcessing: isProcessing ?? this.isProcessing,
      extractionProgress: extractionProgress ?? this.extractionProgress,
      repackSourceDir: repackSourceDir ?? this.repackSourceDir,
      fileEntries: fileEntries ?? this.fileEntries,
      rootNode: clearRootNode ? null : (rootNode ?? this.rootNode),
      selectedIndices: selectedIndices ?? this.selectedIndices,
      isLoadingFileList: isLoadingFileList ?? this.isLoadingFileList,
    );
  }

  /// Counts total selected files (including files in selected directories)
  int get selectedFileCount {
    if (selectedIndices.isEmpty) return 0;
    return selectedIndices.length;
  }

  /// Checks if a specific directory prefix is selected
  bool isDirectorySelected(String dirPath) {
    if (rootNode == null) return false;
    return _findNode(rootNode!, dirPath)?.isSelected ?? false;
  }

  WbtTreeNode? _findNode(WbtTreeNode node, String path) {
    if (node.fullPath == path) return node;
    for (final child in node.children) {
      final found = _findNode(child, path);
      if (found != null) return found;
    }
    return null;
  }
}

final wbtProvider =
    StateNotifierProvider.family<WbtNotifier, WbtState, AppGameCode>((
      ref,
      gameCode,
    ) {
      return WbtNotifier();
    });

class WbtNotifier extends StateNotifier<WbtState> {
  WbtNotifier() : super(WbtState());

  void setFileListPath(String? path) {
    state = WbtState(
      fileListPath: path,
      binPath: state.binPath,
      isProcessing: false,
      extractionProgress: 0,
      repackSourceDir: state.repackSourceDir,
      fileEntries: const [],
      rootNode: null,
      selectedIndices: const {},
    );
  }

  void setBinPath(String? path) {
    state = state.copyWith(binPath: path);
  }

  void setProcessing(bool processing) {
    state = state.copyWith(isProcessing: processing);
  }

  void setExtractionProgress(double progress) {
    state = state.copyWith(extractionProgress: progress);
  }

  void setRepackSourceDir(String? dir) {
    state = state.copyWith(repackSourceDir: dir);
  }

  void setLoadingFileList(bool loading) {
    state = state.copyWith(isLoadingFileList: loading);
  }

  /// Sets the file entries and builds the tree structure
  void setFileEntries(List<WbtFileEntry> entries) {
    final rootNode = _buildTree(entries);
    state = state.copyWith(
      fileEntries: entries,
      rootNode: rootNode,
      selectedIndices: {},
    );
  }

  /// Builds a tree structure from flat file entries
  WbtTreeNode _buildTree(List<WbtFileEntry> entries) {
    final root = WbtTreeNode(
      name: 'root',
      fullPath: '',
      isDirectory: true,
    );

    for (final entry in entries) {
      // Normalize path separators and filter empty parts
      // This ensures paths ending with '/' don't cause files to be treated as directories
      final path = entry.path.replaceAll('\\', '/');
      final parts = path.split('/').where((p) => p.isNotEmpty).toList();

      var currentNode = root;
      var currentPath = '';

      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];

        currentPath = currentPath.isEmpty ? part : '$currentPath/$part';
        final isLast = i == parts.length - 1;

        // Find or create child node
        var childNode = currentNode.children.cast<WbtTreeNode?>().firstWhere(
          (child) => child!.name == part,
          orElse: () => null,
        );

        if (childNode == null) {
          childNode = WbtTreeNode(
            name: part,
            fullPath: currentPath,
            isDirectory: !isLast,
            fileIndex: isLast ? entry.index.toInt() : null,
            uncompressedSize: isLast ? entry.uncompressedSize : null,
            compressedSize: isLast ? entry.compressedSize : null,
          );
          currentNode.children.add(childNode);
        }

        currentNode = childNode;
      }
    }

    // Sort children recursively (directories first, then alphabetically)
    _sortTree(root);

    return root;
  }

  void _sortTree(WbtTreeNode node) {
    node.children.sort((a, b) {
      // Directories first
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      // Then alphabetically
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    for (final child in node.children) {
      _sortTree(child);
    }
  }

  /// Toggles the expanded state of a directory node
  void toggleExpanded(String path) {
    if (state.rootNode == null) return;

    final newRoot = _toggleExpandedRecursive(state.rootNode!, path);
    state = state.copyWith(rootNode: newRoot);
  }

  WbtTreeNode _toggleExpandedRecursive(WbtTreeNode node, String targetPath) {
    if (node.fullPath == targetPath) {
      return node.copyWith(isExpanded: !node.isExpanded);
    }

    if (!node.isDirectory) return node;

    final newChildren = node.children
        .map((child) => _toggleExpandedRecursive(child, targetPath))
        .toList();

    return node.copyWith(children: newChildren);
  }

  /// Toggles selection of a file or directory
  void toggleSelection(String path, {bool? selectChildren}) {
    if (state.rootNode == null) return;

    final node = _findNode(state.rootNode!, path);
    if (node == null) return;

    final newSelected = !node.isSelected;
    var newIndices = Set<int>.from(state.selectedIndices);

    if (node.isDirectory) {
      // Select/deselect all files in this directory
      _collectFileIndices(node, newSelected, newIndices);
    } else if (node.fileIndex != null) {
      if (newSelected) {
        newIndices.add(node.fileIndex!);
      } else {
        newIndices.remove(node.fileIndex!);
      }
    }

    final newRoot = _updateSelectionRecursive(
      state.rootNode!,
      path,
      newSelected,
      selectChildren: selectChildren ?? node.isDirectory,
    );

    state = state.copyWith(rootNode: newRoot, selectedIndices: newIndices);
  }

  WbtTreeNode? _findNode(WbtTreeNode node, String path) {
    if (node.fullPath == path) return node;
    for (final child in node.children) {
      final found = _findNode(child, path);
      if (found != null) return found;
    }
    return null;
  }

  void _collectFileIndices(WbtTreeNode node, bool select, Set<int> indices) {
    if (!node.isDirectory && node.fileIndex != null) {
      if (select) {
        indices.add(node.fileIndex!);
      } else {
        indices.remove(node.fileIndex!);
      }
    }
    for (final child in node.children) {
      _collectFileIndices(child, select, indices);
    }
  }

  WbtTreeNode _updateSelectionRecursive(
    WbtTreeNode node,
    String targetPath,
    bool selected, {
    bool selectChildren = false,
  }) {
    if (node.fullPath == targetPath) {
      if (selectChildren && node.isDirectory) {
        // Select all children recursively
        final newChildren = node.children
            .map((child) => _setSelectionRecursive(child, selected))
            .toList();
        return node.copyWith(isSelected: selected, children: newChildren);
      }
      return node.copyWith(isSelected: selected);
    }

    if (!node.isDirectory) return node;

    final newChildren = node.children
        .map((child) => _updateSelectionRecursive(
              child,
              targetPath,
              selected,
              selectChildren: selectChildren,
            ))
        .toList();

    return node.copyWith(children: newChildren);
  }

  WbtTreeNode _setSelectionRecursive(WbtTreeNode node, bool selected) {
    final newChildren = node.children
        .map((child) => _setSelectionRecursive(child, selected))
        .toList();
    return node.copyWith(isSelected: selected, children: newChildren);
  }

  /// Clears all selections
  void clearSelection() {
    if (state.rootNode == null) return;

    final newRoot = _setSelectionRecursive(state.rootNode!, false);
    state = state.copyWith(rootNode: newRoot, selectedIndices: {});
  }

  /// Selects all files
  void selectAll() {
    if (state.rootNode == null) return;

    final allIndices = <int>{};
    for (final entry in state.fileEntries) {
      allIndices.add(entry.index.toInt());
    }

    final newRoot = _setSelectionRecursive(state.rootNode!, true);
    state = state.copyWith(rootNode: newRoot, selectedIndices: allIndices);
  }

  /// Gets list of selected file paths for directory extraction
  List<String> getSelectedDirectoryPaths() {
    if (state.rootNode == null) return [];
    return _collectSelectedDirectories(state.rootNode!);
  }

  List<String> _collectSelectedDirectories(WbtTreeNode node) {
    final result = <String>[];
    if (node.isDirectory && node.isSelected) {
      result.add(node.fullPath);
    } else {
      for (final child in node.children) {
        result.addAll(_collectSelectedDirectories(child));
      }
    }
    return result;
  }
}
