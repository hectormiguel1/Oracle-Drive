// This file is currently disabled as WbtFileEntry is missing from the SDK.
// 
// import 'package:fabula_nova_sdk/src/rust/api.dart' show WbtFileEntry;
// 
// class VirtualNode {
//   final String name;
//   final List<VirtualNode> children;
//   final WbtFileEntry? data; // Null if this is a folder, populated if it's a file
// 
//   // Helper to check if it's a folder
//   bool get isFolder => data == null;
// 
//   VirtualNode({required this.name, this.data, List<VirtualNode>? children})
//     : children = children ?? [];
// }
// 
// List<VirtualNode> buildVirtualTree(List<WbtFileEntry> entries) {
//   final List<VirtualNode> roots = [];
// 
//   for (final entry in entries) {
//     // 1. Normalize and split the path
//     // e.g. "db/resident/items.wpd" -> ["db", "resident", "items.wpd"]
//     final parts = entry.virtualPath.split('/');
// 
//     // 2. Start traversing from the root level
//     List<VirtualNode> currentLevel = roots;
// 
//     // 3. Iterate through path parts
//     for (int i = 0; i < parts.length; i++) {
//       final partName = parts[i];
//       final isLastPart = i == parts.length - 1;
// 
//       // Check if this node already exists in the current level
//       VirtualNode? node;
//       for (final n in currentLevel) {
//         if (n.name == partName) {
//           node = n;
//           break;
//         }
//       }
// 
//       if (node == null) {
//         // Create new node
//         if (isLastPart) {
//           // It's a FILE: Create it with the actual WbtFileEntry data
//           node = VirtualNode(name: partName, data: entry);
//         } else {
//           // It's a FOLDER: Create a virtual container
//           node = VirtualNode(name: partName);
//         }
//         currentLevel.add(node);
//       }
// 
//       // Descend into this node's children for the next iteration
//       currentLevel = node.children;
//     }
//   }
// 
//   return roots;
// }