import 'package:ff13_mod_resource/src/third_party/wbtlib/wbt.dart';

class VirtualNode {
  final String name;
  final List<VirtualNode> children;
  final FileEntry? data; // Null if this is a folder, populated if it's a file

  // Helper to check if it's a folder
  bool get isFolder => data == null;

  VirtualNode({required this.name, this.data, List<VirtualNode>? children})
    : children = children ?? [];
}

List<VirtualNode> buildVirtualTree(List<FileEntry> entries) {
  final List<VirtualNode> roots = [];

  for (final entry in entries) {
    // 1. Normalize and split the path
    // e.g. "db/resident/items.wpd" -> ["db", "resident", "items.wpd"]
    final parts = entry.chunkInfo.virtualPath.split('/');

    // 2. Start traversing from the root level
    List<VirtualNode> currentLevel = roots;

    // 3. Iterate through path parts
    for (int i = 0; i < parts.length; i++) {
      final partName = parts[i];
      final isLastPart = i == parts.length - 1;

      // Check if this node already exists in the current level
      // (Using firstWhere is fine for UI lists, usually < 100 items per folder)
      VirtualNode? node;
      try {
        node = currentLevel.firstWhere((n) => n.name == partName);
      } catch (e) {
        node = null;
      }

      if (node == null) {
        // Create new node
        if (isLastPart) {
          // It's a FILE: Create it with the actual FileEntry data
          node = VirtualNode(name: partName, data: entry);
        } else {
          // It's a FOLDER: Create a virtual container
          node = VirtualNode(name: partName);
        }
        currentLevel.add(node);
      }

      // Descend into this node's children for the next iteration
      currentLevel = node.children;
    }
  }

  return roots;
}
