import 'package:ff13_mod_resource/models/file_node.dart';
import 'package:ff13_mod_resource/src/third_party/wbtlib/wbt.dart';
import 'package:ff13_mod_resource/theme/crystal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view2/flutter_fancy_tree_view2.dart';

class MyTreeWidget extends StatefulWidget {
  final List<FileEntry> files;
  // 1. Add this callback definition
  final ValueChanged<List<FileEntry>>? onSelectionChanged;

  const MyTreeWidget({
    super.key,
    required this.files,
    this.onSelectionChanged, // Add to constructor
  });

  @override
  State<MyTreeWidget> createState() => _MyTreeWidgetState();
}

class _MyTreeWidgetState extends State<MyTreeWidget> {
  late final TreeController<VirtualNode> _controller;

  // 1. The Set stores currently selected nodes
  final Set<VirtualNode> _selectedNodes = {};

  // ... existing initState ...

  // 2. Logic to toggle selection
  void _toggleSelection(VirtualNode node) {
    setState(() {
      final isSelected = !_selectedNodes.contains(node);
      _recursiveToggle(node, isSelected);

      // 2. Notify Parent whenever selection changes
      if (widget.onSelectionChanged != null) {
        final selectedFiles = _selectedNodes
            .where((n) => !n.isFolder && n.data != null)
            .map((n) => n.data!)
            .toList();

        widget.onSelectionChanged!(selectedFiles);
      }
    });
  }

  // 3. Recursive helper: If a folder is clicked, select all descendants
  void _recursiveToggle(VirtualNode node, bool isSelected) {
    if (isSelected) {
      _selectedNodes.add(node);
    } else {
      _selectedNodes.remove(node);
    }

    // Propagate to children (files inside the folder)
    for (var child in node.children) {
      _recursiveToggle(child, isSelected);
    }
  }

  // 4. Helper to get the final list for your "Extract" button
  List<FileEntry> getFilesToExtract() {
    return _selectedNodes
        .where((node) => !node.isFolder && node.data != null)
        .map((node) => node.data!)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    // 1. Convert the flat list to a tree
    final roots = buildVirtualTree(widget.files);

    // 2. Initialize controller with the new structure
    _controller = TreeController<VirtualNode>(
      roots: roots,
      childrenProvider: (VirtualNode node) => node.children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>()!;
    return AnimatedTreeView<VirtualNode>(
      treeController: _controller,
      nodeBuilder: (context, entry) {
        final isFolder = entry.node.isFolder;
        final isSelected = _selectedNodes.contains(entry.node);

        return TreeIndentation(
          entry: entry,
          guide: const IndentGuide.connectingLines(
            indent: 30,
            color: Colors.white70,
            thickness: 1.0,
            origin: 0.5,
            roundCorners: false,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                // ------------------------------------------------
                // ZONE 1: SELECTION (Checkbox Only)
                // ------------------------------------------------
                // logic: checking this selects THIS node and children,
                // but does NOT affect the parent.
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isSelected,
                    // ONLY toggle selection here
                    onChanged: (_) => _toggleSelection(entry.node),
                    activeColor: theme.accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                const SizedBox(width: 8),

                // ------------------------------------------------
                // ZONE 2: NAVIGATION (Icon + Text)
                // ------------------------------------------------
                // logic: clicking anywhere here expands/collapses
                Expanded(
                  child: InkWell(
                    // CRITICAL CHANGE: Tapping the row expands, does not select
                    onTap: () => _controller.toggleExpansion(entry.node),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 4.0,
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Icon(
                            isFolder
                                ? (entry.isExpanded
                                      ? Icons.folder_open
                                      : Icons.folder)
                                : Icons.description_outlined,
                            color: isFolder
                                ? theme.accent
                                : const Color(0xFF64B5F6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),

                          // Text (Filename)
                          Flexible(
                            child: Text(
                              entry.node.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: isFolder
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
