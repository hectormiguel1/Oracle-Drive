import 'package:flutter/material.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:oracle_drive/components/widgets/style.dart';

/// A node in the crystal file browser tree
class CrystalFileNode {
  final String name;
  final String fullPath;
  final bool isDirectory;
  final int? fileIndex;
  final int? size;
  final int? compressedSize;
  final List<CrystalFileNode> children;
  bool isExpanded;
  bool isSelected;

  CrystalFileNode({
    required this.name,
    required this.fullPath,
    required this.isDirectory,
    this.fileIndex,
    this.size,
    this.compressedSize,
    List<CrystalFileNode>? children,
    this.isExpanded = false,
    this.isSelected = false,
  }) : children = children ?? [];
}

/// Crystal-themed file browser widget with FF13 aesthetic
class CrystalFileBrowser extends StatelessWidget {
  final List<CrystalFileNode> nodes;
  final ValueChanged<String>? onToggleExpand;
  final ValueChanged<String>? onToggleSelect;
  final ValueChanged<String>? onExtractDirectory;
  final ScrollController? scrollController;

  const CrystalFileBrowser({
    super.key,
    required this.nodes,
    this.onToggleExpand,
    this.onToggleSelect,
    this.onExtractDirectory,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final flattenedNodes = _flattenNodes(nodes, 0);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: flattenedNodes.length,
      itemBuilder: (context, index) {
        final item = flattenedNodes[index];
        return _CrystalFileRow(
          node: item.node,
          depth: item.depth,
          onToggleExpand: onToggleExpand,
          onToggleSelect: onToggleSelect,
          onExtractDirectory: onExtractDirectory,
        );
      },
    );
  }

  List<_FlatNode> _flattenNodes(List<CrystalFileNode> nodes, int depth) {
    final result = <_FlatNode>[];
    for (final node in nodes) {
      result.add(_FlatNode(node: node, depth: depth));
      if (node.isDirectory && node.isExpanded) {
        result.addAll(_flattenNodes(node.children, depth + 1));
      }
    }
    return result;
  }
}

class _FlatNode {
  final CrystalFileNode node;
  final int depth;
  _FlatNode({required this.node, required this.depth});
}

class _CrystalFileRow extends StatefulWidget {
  final CrystalFileNode node;
  final int depth;
  final ValueChanged<String>? onToggleExpand;
  final ValueChanged<String>? onToggleSelect;
  final ValueChanged<String>? onExtractDirectory;

  const _CrystalFileRow({
    required this.node,
    required this.depth,
    this.onToggleExpand,
    this.onToggleSelect,
    this.onExtractDirectory,
  });

  @override
  State<_CrystalFileRow> createState() => _CrystalFileRowState();
}

class _CrystalFileRowState extends State<_CrystalFileRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>()!;
    final node = widget.node;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          if (node.isDirectory) {
            widget.onToggleExpand?.call(node.fullPath);
          } else {
            widget.onToggleSelect?.call(node.fullPath);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: _getBackgroundColor(theme),
            borderRadius: BorderRadius.circular(4),
            border: node.isSelected
                ? Border.all(color: theme.accent.withValues(alpha: 0.5), width: 1)
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 8 + (widget.depth * 20.0),
              right: 8,
              top: 6,
              bottom: 6,
            ),
            child: Row(
              children: [
                // Selection checkbox
                _buildCheckbox(theme),
                const SizedBox(width: 6),

                // Expand/collapse arrow for directories
                _buildExpandArrow(theme),
                const SizedBox(width: 4),

                // File/folder icon
                _buildIcon(theme),
                const SizedBox(width: 10),

                // Name
                Expanded(child: _buildName(theme)),

                // Size info
                if (!node.isDirectory) _buildSizeInfo(theme),

                // Directory extract button
                if (node.isDirectory && _isHovered) _buildExtractButton(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(CrystalTheme theme) {
    if (widget.node.isSelected) {
      return theme.accent.withValues(alpha: 0.15);
    }
    if (_isHovered) {
      return Colors.white.withValues(alpha: 0.05);
    }
    return Colors.transparent;
  }

  Widget _buildCheckbox(CrystalTheme theme) {
    return GestureDetector(
      onTap: () => widget.onToggleSelect?.call(widget.node.fullPath),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: widget.node.isSelected
              ? theme.accent.withValues(alpha: 0.3)
              : CrystalColors.panelBackground,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: widget.node.isSelected
                ? theme.accent
                : Colors.white24,
            width: 1,
          ),
        ),
        child: widget.node.isSelected
            ? Icon(Icons.check, size: 14, color: theme.accent)
            : null,
      ),
    );
  }

  Widget _buildExpandArrow(CrystalTheme theme) {
    if (!widget.node.isDirectory) {
      return const SizedBox(width: 18);
    }

    return GestureDetector(
      onTap: () => widget.onToggleExpand?.call(widget.node.fullPath),
      child: AnimatedRotation(
        turns: widget.node.isExpanded ? 0.25 : 0,
        duration: const Duration(milliseconds: 200),
        child: Icon(
          Icons.chevron_right,
          size: 18,
          color: theme.accent.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildIcon(CrystalTheme theme) {
    final node = widget.node;

    if (node.isDirectory) {
      return Icon(
        node.isExpanded ? Icons.folder_open : Icons.folder,
        size: 18,
        color: theme.accent,
      );
    }

    final iconData = _getFileIcon(node.name);
    final iconColor = _getFileIconColor(node.name, theme);

    return Icon(iconData, size: 18, color: iconColor);
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'trb':
      case 'wdb':
        return Icons.table_chart_outlined;
      case 'ztr':
        return Icons.translate;
      case 'imgb':
      case 'img':
      case 'dds':
      case 'xgr':
        return Icons.image_outlined;
      case 'scd':
      case 'sab':
        return Icons.music_note_outlined;
      case 'clb':
        return Icons.code;
      case 'wpd':
        return Icons.inventory_2_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileIconColor(String fileName, CrystalTheme theme) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'trb':
      case 'wdb':
        return const Color(0xFF81C784); // Green
      case 'ztr':
        return const Color(0xFFFFB74D); // Orange
      case 'imgb':
      case 'img':
      case 'dds':
      case 'xgr':
        return const Color(0xFFBA68C8); // Purple
      case 'scd':
      case 'sab':
        return const Color(0xFF4FC3F7); // Light blue
      case 'clb':
        return const Color(0xFFFF8A65); // Deep orange
      case 'wpd':
        return const Color(0xFFFFD54F); // Amber
      default:
        return Colors.white54;
    }
  }

  Widget _buildName(CrystalTheme theme) {
    return Text(
      widget.node.name,
      style: TextStyle(
        color: widget.node.isSelected
            ? theme.accent
            : (widget.node.isDirectory ? Colors.white : Colors.white70),
        fontWeight: widget.node.isDirectory ? FontWeight.w500 : FontWeight.normal,
        fontSize: 13,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSizeInfo(CrystalTheme theme) {
    final node = widget.node;
    if (node.size == null) return const SizedBox.shrink();

    final sizeStr = _formatSize(node.size!);
    final hasCompression = node.compressedSize != null &&
        node.compressedSize != node.size;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          sizeStr,
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        if (hasCompression) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              _formatSize(node.compressedSize!),
              style: TextStyle(
                color: theme.accent.withValues(alpha: 0.7),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExtractButton(CrystalTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () => widget.onExtractDirectory?.call(widget.node.fullPath),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: theme.accent.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download, size: 14, color: theme.accent),
              const SizedBox(width: 4),
              Text(
                'EXTRACT',
                style: TextStyle(
                  color: theme.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
