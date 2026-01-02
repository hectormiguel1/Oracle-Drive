import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_game_code.dart';
import '../../providers/workflow_provider.dart';
import '../widgets/crystal_text_field.dart';

/// A file selection widget for WBT archives in workflows.
/// Shows a searchable tree of files that can be selected for extraction.
class WbtFileSelector extends ConsumerStatefulWidget {
  final String nodeId;
  final String? sourceNodeId;
  final List<int> selectedIndices;
  final ValueChanged<List<int>> onSelectionChanged;
  final AppGameCode gameCode;

  const WbtFileSelector({
    super.key,
    required this.nodeId,
    required this.sourceNodeId,
    required this.selectedIndices,
    required this.onSelectionChanged,
    required this.gameCode,
  });

  @override
  ConsumerState<WbtFileSelector> createState() => _WbtFileSelectorState();
}

class _WbtFileSelectorState extends ConsumerState<WbtFileSelector> {
  String _searchQuery = '';
  final bool _isLoading = false;
  String? _errorMessage;
  WbtTreeNode? _rootNode;
  List<sdk.WbtFileEntry> _fileEntries = [];
  Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _selectedIndices = widget.selectedIndices.toSet();
  }

  @override
  void didUpdateWidget(WbtFileSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndices != widget.selectedIndices) {
      _selectedIndices = widget.selectedIndices.toSet();
    }
  }

  /// Load file list data from the source node's cached data.
  /// This is called during build to react to state changes.
  void _loadFileListFromState(Map<String, dynamic> immediateNodeData) {
    if (widget.sourceNodeId == null) {
      _rootNode = null;
      _fileEntries = [];
      _errorMessage = 'Select a source WBT node';
      return;
    }

    // Get the cached data from the source node
    final sourceData = immediateNodeData[widget.sourceNodeId];

    if (sourceData == null) {
      _errorMessage = 'Source node has not been executed yet';
      _rootNode = null;
      _fileEntries = [];
      return;
    }

    if (sourceData is! WbtFileListData) {
      _errorMessage = 'Invalid source data type';
      _rootNode = null;
      _fileEntries = [];
      return;
    }

    // Only rebuild tree if data changed
    if (_fileEntries.length != sourceData.entries.length ||
        (_fileEntries.isNotEmpty && _fileEntries.first.path != sourceData.entries.first.path)) {
      _fileEntries = sourceData.entries;
      _rootNode = _buildTree(sourceData.entries);
      _updateTreeSelection();
    }
    _errorMessage = null;
  }

  WbtTreeNode _buildTree(List<sdk.WbtFileEntry> entries) {
    final root = WbtTreeNode(
      name: 'root',
      fullPath: '',
      isDirectory: true,
    );

    for (final entry in entries) {
      final path = entry.path.replaceAll('\\', '/');
      final parts = path.split('/').where((p) => p.isNotEmpty).toList();

      var currentNode = root;
      var currentPath = '';

      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        currentPath = currentPath.isEmpty ? part : '$currentPath/$part';
        final isLast = i == parts.length - 1;

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

    _sortTree(root);
    return root;
  }

  void _sortTree(WbtTreeNode node) {
    node.children.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    for (final child in node.children) {
      _sortTree(child);
    }
  }

  void _updateTreeSelection() {
    if (_rootNode == null) return;
    _rootNode = _applySelectionToTree(_rootNode!, _selectedIndices);
  }

  WbtTreeNode _applySelectionToTree(WbtTreeNode node, Set<int> selectedIndices) {
    bool isSelected = false;
    if (!node.isDirectory && node.fileIndex != null) {
      isSelected = selectedIndices.contains(node.fileIndex);
    } else if (node.isDirectory) {
      // Check if all children are selected
      isSelected = node.children.isNotEmpty &&
          _allChildrenSelected(node, selectedIndices);
    }

    final newChildren = node.children
        .map((child) => _applySelectionToTree(child, selectedIndices))
        .toList();

    return WbtTreeNode(
      name: node.name,
      fullPath: node.fullPath,
      isDirectory: node.isDirectory,
      fileIndex: node.fileIndex,
      uncompressedSize: node.uncompressedSize,
      compressedSize: node.compressedSize,
      children: newChildren,
      isExpanded: node.isExpanded,
      isSelected: isSelected,
    );
  }

  bool _allChildrenSelected(WbtTreeNode node, Set<int> selectedIndices) {
    for (final child in node.children) {
      if (!child.isDirectory && child.fileIndex != null) {
        if (!selectedIndices.contains(child.fileIndex)) return false;
      } else if (child.isDirectory) {
        if (!_allChildrenSelected(child, selectedIndices)) return false;
      }
    }
    return true;
  }

  void _toggleSelection(WbtTreeNode node) {
    final newSelected = !node.isSelected;

    if (node.isDirectory) {
      _setDirectorySelection(node, newSelected);
    } else if (node.fileIndex != null) {
      if (newSelected) {
        _selectedIndices.add(node.fileIndex!);
      } else {
        _selectedIndices.remove(node.fileIndex!);
      }
    }

    _updateTreeSelection();
    widget.onSelectionChanged(_selectedIndices.toList());
    setState(() {});
  }

  void _setDirectorySelection(WbtTreeNode node, bool selected) {
    for (final child in node.children) {
      if (child.isDirectory) {
        _setDirectorySelection(child, selected);
      } else if (child.fileIndex != null) {
        if (selected) {
          _selectedIndices.add(child.fileIndex!);
        } else {
          _selectedIndices.remove(child.fileIndex!);
        }
      }
    }
  }

  void _toggleExpanded(WbtTreeNode node) {
    if (_rootNode == null) return;
    _rootNode = _toggleExpandedInTree(_rootNode!, node.fullPath);
    setState(() {});
  }

  WbtTreeNode _toggleExpandedInTree(WbtTreeNode node, String targetPath) {
    if (node.fullPath == targetPath) {
      return WbtTreeNode(
        name: node.name,
        fullPath: node.fullPath,
        isDirectory: node.isDirectory,
        fileIndex: node.fileIndex,
        uncompressedSize: node.uncompressedSize,
        compressedSize: node.compressedSize,
        children: node.children,
        isExpanded: !node.isExpanded,
        isSelected: node.isSelected,
      );
    }

    final newChildren = node.children
        .map((child) => _toggleExpandedInTree(child, targetPath))
        .toList();

    return WbtTreeNode(
      name: node.name,
      fullPath: node.fullPath,
      isDirectory: node.isDirectory,
      fileIndex: node.fileIndex,
      uncompressedSize: node.uncompressedSize,
      compressedSize: node.compressedSize,
      children: newChildren,
      isExpanded: node.isExpanded,
      isSelected: node.isSelected,
    );
  }

  void _selectAll() {
    for (final entry in _fileEntries) {
      _selectedIndices.add(entry.index.toInt());
    }
    _updateTreeSelection();
    widget.onSelectionChanged(_selectedIndices.toList());
    setState(() {});
  }

  void _clearSelection() {
    _selectedIndices.clear();
    _updateTreeSelection();
    widget.onSelectionChanged(_selectedIndices.toList());
    setState(() {});
  }

  List<WbtTreeNode> _filterTree(WbtTreeNode node, String query) {
    if (query.isEmpty) {
      return node.children;
    }

    final results = <WbtTreeNode>[];
    _collectMatchingNodes(node, query.toLowerCase(), results);
    return results;
  }

  void _collectMatchingNodes(
    WbtTreeNode node,
    String query,
    List<WbtTreeNode> results,
  ) {
    if (node.fullPath.toLowerCase().contains(query)) {
      results.add(node);
      return;
    }
    for (final child in node.children) {
      _collectMatchingNodes(child, query, results);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes to immediate node data (reacts when source node executes)
    final editorState = ref.watch(workflowEditorProvider);
    _loadFileListFromState(editorState.immediateNodeData);

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.orange[300], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_rootNode == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(strokeWidth: 2)
              : Text(
                  'No files loaded',
                  style: TextStyle(color: Colors.white54),
                ),
        ),
      );
    }

    final filteredNodes = _searchQuery.isEmpty
        ? _rootNode!.children
        : _filterTree(_rootNode!, _searchQuery);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search bar
        CrystalTextField(
          hintText: 'Search files...',
          prefixIcon: Icons.search,
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 8),

        // File tree
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: filteredNodes.isEmpty
              ? Center(
                  child: Text(
                    'No matching files',
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(4),
                  itemCount: filteredNodes.length,
                  itemBuilder: (context, index) {
                    return _buildTreeNode(filteredNodes[index], 0);
                  },
                ),
        ),
        const SizedBox(height: 8),

        // Action bar
        Row(
          children: [
            _buildSmallButton(
              label: 'Select All',
              icon: Icons.select_all,
              onPressed: _selectAll,
            ),
            const SizedBox(width: 8),
            _buildSmallButton(
              label: 'Clear',
              icon: Icons.clear_all,
              onPressed: _clearSelection,
              isSecondary: true,
            ),
            const Spacer(),
            Text(
              '${_selectedIndices.length} selected',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTreeNode(WbtTreeNode node, int depth) {
    final indent = 16.0 * depth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            if (node.isDirectory) {
              _toggleExpanded(node);
            } else {
              _toggleSelection(node);
            }
          },
          child: Padding(
            padding: EdgeInsets.only(left: indent),
            child: Row(
              children: [
                // Expand/collapse arrow for directories
                if (node.isDirectory)
                  GestureDetector(
                    onTap: () => _toggleExpanded(node),
                    child: Icon(
                      node.isExpanded
                          ? Icons.expand_more
                          : Icons.chevron_right,
                      size: 16,
                      color: Colors.white54,
                    ),
                  )
                else
                  const SizedBox(width: 16),

                // Checkbox
                GestureDetector(
                  onTap: () => _toggleSelection(node),
                  child: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: node.isSelected
                          ? Colors.purple.withValues(alpha: 0.8)
                          : Colors.transparent,
                      border: Border.all(
                        color: node.isSelected
                            ? Colors.purple
                            : Colors.white38,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: node.isSelected
                        ? Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                ),

                // Icon
                Icon(
                  node.isDirectory ? Icons.folder : Icons.insert_drive_file,
                  size: 14,
                  color: node.isDirectory
                      ? Colors.amber.withValues(alpha: 0.7)
                      : Colors.white54,
                ),
                const SizedBox(width: 6),

                // Name
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Size for files
                if (!node.isDirectory && node.uncompressedSize != null)
                  Text(
                    _formatSize(node.uncompressedSize!),
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Children if expanded
        if (node.isDirectory && node.isExpanded)
          ...node.children.map((child) => _buildTreeNode(child, depth + 1)),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildSmallButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSecondary
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.purple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSecondary
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.purple.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class to store WBT file list data in immediate node cache.
class WbtFileListData {
  final String fileListPath;
  final String binPath;
  final List<sdk.WbtFileEntry> entries;

  const WbtFileListData({
    required this.fileListPath,
    required this.binPath,
    required this.entries,
  });
}

/// Tree node for representing WBT file hierarchy.
class WbtTreeNode {
  final String name;
  final String fullPath;
  final bool isDirectory;
  final int? fileIndex;
  final int? uncompressedSize;
  final int? compressedSize;
  final List<WbtTreeNode> children;
  final bool isExpanded;
  final bool isSelected;

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
}
