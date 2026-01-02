import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow/workflow_models.dart';
import '../widgets/crystal_panel.dart';
import '../widgets/style.dart';

/// Sidebar showing available node types organized by category.
class NodePalette extends ConsumerStatefulWidget {
  const NodePalette({super.key});

  @override
  ConsumerState<NodePalette> createState() => _NodePaletteState();
}

class _NodePaletteState extends ConsumerState<NodePalette> {
  final Map<NodeCategory, bool> _expandedCategories = {
    for (var cat in NodeCategory.values) cat: true,
  };

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return CrystalPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.widgets_outlined,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Nodes', style: CrystalStyles.sectionHeader),
            ],
          ),
          const SizedBox(height: 12),
          // Search
          _buildSearchField(),
          const SizedBox(height: 12),
          // Node categories
          Expanded(
            child: ListView(
              children: NodeCategory.values.map(_buildCategory).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 12),
        cursorColor: Colors.cyan,
        decoration: InputDecoration(
          hintText: 'Search nodes...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.cyan.withValues(alpha: 0.5),
            size: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildCategory(NodeCategory category) {
    final nodes = NodeType.values
        .where((n) => n.category == category)
        .where(
          (n) =>
              _searchQuery.isEmpty ||
              n.displayName.toLowerCase().contains(_searchQuery),
        )
        .toList();

    if (nodes.isEmpty && _searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final isExpanded = _expandedCategories[category] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category header
        InkWell(
          onTap: () {
            setState(() {
              _expandedCategories[category] = !isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  color: Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Icon(
                  category.icon,
                  color: _getCategoryColor(category),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  category.displayName,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${nodes.length}',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        // Nodes
        if (isExpanded)
          ...nodes.map((type) => _DraggableNodeTile(nodeType: type)),
        if (isExpanded) const SizedBox(height: 8),
      ],
    );
  }

  Color _getCategoryColor(NodeCategory category) {
    return switch (category) {
      NodeCategory.control => const Color(0xFF7C4DFF),
      NodeCategory.wpd => const Color(0xFFE91E63),
      NodeCategory.wbt => const Color(0xFF9C27B0),
      NodeCategory.wdb => const Color(0xFF00BCD4),
      NodeCategory.ztr => const Color(0xFFFF9800),
      NodeCategory.variable => const Color(0xFF4CAF50),
      NodeCategory.img => const Color(0xFFFF5722),
    };
  }
}

/// A draggable node tile that can be dropped onto the canvas.
class _DraggableNodeTile extends StatefulWidget {
  final NodeType nodeType;

  const _DraggableNodeTile({required this.nodeType});

  @override
  State<_DraggableNodeTile> createState() => _DraggableNodeTileState();
}

class _DraggableNodeTileState extends State<_DraggableNodeTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final nodeColor = widget.nodeType.nodeColor;

    return Draggable<NodeType>(
      data: widget.nodeType,
      feedback: Material(
        color: Colors.transparent,
        child: _buildNodePreview(nodeColor, isDragging: true),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildTile(nodeColor)),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.grab,
        child: _buildTile(nodeColor),
      ),
    );
  }

  Widget _buildTile(Color nodeColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isHovered
            ? nodeColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: _isHovered
            ? Border.all(color: nodeColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Icon(widget.nodeType.icon, color: nodeColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.nodeType.displayName,
              style: TextStyle(
                color: _isHovered ? Colors.white : Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          if (_isHovered)
            Icon(Icons.drag_indicator, color: Colors.white38, size: 14),
        ],
      ),
    );
  }

  Widget _buildNodePreview(Color nodeColor, {bool isDragging = false}) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: nodeColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: nodeColor.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.nodeType.icon, color: nodeColor, size: 18),
          const SizedBox(width: 8),
          Text(
            widget.nodeType.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
