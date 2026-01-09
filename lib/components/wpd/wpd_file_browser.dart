import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view2/flutter_fancy_tree_view2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/widgets/crystal_compact_button.dart';
import 'package:oracle_drive/components/widgets/crystal_icon_button.dart';
import 'package:oracle_drive/components/widgets/crystal_loading_spinner.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/crystal_snackbar.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/providers/wpd_provider.dart';
import 'package:oracle_drive/components/wpd/wpd_file_utils.dart';
import 'package:oracle_drive/src/services/native_service.dart';
import 'package:path/path.dart' as p;

/// Wrapper for FileSystemEntity with path-based equality.
/// This is needed because FileSystemEntity uses object identity,
/// but the tree controller needs stable equality for expansion tracking.
class FileNode {
  final FileSystemEntity entity;

  FileNode(this.entity);

  String get path => entity.path;
  String get name => p.basename(path);
  bool get isDirectory => entity is Directory;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileNode && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;
}

/// File browser sidebar for the WPD screen.
/// Shows a tree view of the workspace directory.
class WpdFileBrowser extends ConsumerStatefulWidget {
  final AppGameCode gameCode;
  final VoidCallback onPickDirectory;

  const WpdFileBrowser({
    super.key,
    required this.gameCode,
    required this.onPickDirectory,
  });

  @override
  WpdFileBrowserState createState() => WpdFileBrowserState();
}

class WpdFileBrowserState extends ConsumerState<WpdFileBrowser> {
  TreeController<FileNode>? _treeController;
  String? _currentRootPath;
  bool _hideZeroByteFiles = false;
  bool _isBatchProcessing = false;

  @override
  void dispose() {
    _treeController?.dispose();
    super.dispose();
  }

  void _toggleHideZeroByteFiles() {
    setState(() {
      _hideZeroByteFiles = !_hideZeroByteFiles;
    });
    // Rebuild tree with new filter
    if (_currentRootPath != null) {
      _reloadTree(_currentRootPath);
    }
  }

  /// Check if a directory contains any non-zero-byte files (recursively)
  bool _hasNonZeroByteFiles(Directory dir) {
    try {
      for (final entity in dir.listSync()) {
        if (entity is File) {
          try {
            if (entity.lengthSync() > 0) {
              return true;
            }
          } catch (_) {
            // Can't read file, assume it's valid
            return true;
          }
        } else if (entity is Directory) {
          if (_hasNonZeroByteFiles(entity)) {
            return true;
          }
        }
      }
    } catch (_) {
      // Can't read directory, assume it has content
      return true;
    }
    return false;
  }

  void _reloadTree(String? rootPath) {
    if (rootPath == null) {
      _treeController?.dispose();
      _treeController = null;
      _currentRootPath = null;
      setState(() {});
      return;
    }

    final rootDir = Directory(rootPath);
    if (!rootDir.existsSync()) {
      _treeController?.dispose();
      _treeController = null;
      _currentRootPath = null;
      setState(() {});
      return;
    }

    try {
      _treeController?.dispose();
      final rootNode = FileNode(rootDir);
      _treeController = TreeController<FileNode>(
        roots: [rootNode],
        childrenProvider: (FileNode parent) {
          if (parent.isDirectory) {
            try {
              final dir = parent.entity as Directory;
              var list = dir.listSync();

              // Filter out 0-byte files and empty directories if enabled
              if (_hideZeroByteFiles) {
                list = list.where((entity) {
                  if (entity is File) {
                    try {
                      return entity.lengthSync() > 0;
                    } catch (_) {
                      return true; // Keep files we can't read
                    }
                  } else if (entity is Directory) {
                    // Hide directories that only contain 0-byte files
                    return _hasNonZeroByteFiles(entity);
                  }
                  return true;
                }).toList();
              }

              list.sort((a, b) {
                final aIsDir = a is Directory;
                final bIsDir = b is Directory;
                if (aIsDir && !bIsDir) return -1;
                if (!aIsDir && bIsDir) return 1;
                return a.path.compareTo(b.path);
              });
              return list.map((e) => FileNode(e));
            } catch (e) {
              return [];
            }
          }
          return [];
        },
      );

      _treeController!.expand(rootNode);
      _currentRootPath = rootPath;
      setState(() {});
    } catch (e) {
      debugPrint("Error scanning directory: $e");
    }
  }

  void rebuild() {
    setState(() => _treeController?.rebuild());
  }

  void _navigateUp() {
    final currentPath = _currentRootPath;
    if (currentPath == null) return;

    final parentPath = p.dirname(currentPath);
    // Don't navigate above root
    if (parentPath == currentPath) return;

    ref.read(wpdProvider(widget.gameCode).notifier).setRootDirPath(parentPath);
  }

  void _navigateToPath(String path) {
    ref.read(wpdProvider(widget.gameCode).notifier).setRootDirPath(path);
  }

  Future<void> _convertAllScdToWav() async {
    if (_currentRootPath == null || _isBatchProcessing) return;

    setState(() => _isBatchProcessing = true);

    try {
      final dir = Directory(_currentRootPath!);
      int successCount = 0;
      int errorCount = 0;

      // Find all .scd files recursively
      final scdFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.scd'))
          .toList();

      if (scdFiles.isEmpty) {
        if (mounted) {
          context.showWarningSnackBar('No SCD files found in workspace');
        }
        return;
      }

      if (mounted) {
        context.showSuccessSnackBar('Converting ${scdFiles.length} SCD files to WAV...');
      }

      for (final scdFile in scdFiles) {
        try {
          final wavPath = '${scdFile.path.substring(0, scdFile.path.length - 4)}.wav';
          await NativeService.instance.extractScdToWav(scdFile.path, wavPath);
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      rebuild();
      if (mounted) {
        if (errorCount > 0) {
          context.showErrorSnackBar('SCD→WAV: $successCount succeeded, $errorCount failed');
        } else {
          context.showSuccessSnackBar('SCD→WAV: $successCount files converted');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error: $e');
      }
    } finally {
      setState(() => _isBatchProcessing = false);
    }
  }

  Future<void> _convertAllWavToScd() async {
    if (_currentRootPath == null || _isBatchProcessing) return;

    setState(() => _isBatchProcessing = true);

    try {
      final dir = Directory(_currentRootPath!);
      int successCount = 0;
      int errorCount = 0;

      // Find all .wav files recursively
      final wavFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.wav'))
          .toList();

      if (wavFiles.isEmpty) {
        if (mounted) {
          context.showWarningSnackBar('No WAV files found in workspace');
        }
        return;
      }

      if (mounted) {
        context.showSuccessSnackBar('Converting ${wavFiles.length} WAV files to SCD...');
      }

      for (final wavFile in wavFiles) {
        try {
          final scdPath = '${wavFile.path.substring(0, wavFile.path.length - 4)}.scd';
          await NativeService.instance.convertWavToScd(wavFile.path, scdPath);
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      rebuild();
      if (mounted) {
        if (errorCount > 0) {
          context.showErrorSnackBar('WAV→SCD: $successCount succeeded, $errorCount failed');
        } else {
          context.showSuccessSnackBar('WAV→SCD: $successCount files converted');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error: $e');
      }
    } finally {
      setState(() => _isBatchProcessing = false);
    }
  }

  List<_BreadcrumbSegment> _buildBreadcrumbs(String rootPath) {
    final segments = <_BreadcrumbSegment>[];
    var current = rootPath;

    // Build path segments from root to current
    while (true) {
      final name = p.basename(current);
      final path = current;

      // Handle root directory
      if (name.isEmpty || current == p.dirname(current)) {
        segments.insert(0, _BreadcrumbSegment(name: '/', path: current));
        break;
      }

      segments.insert(0, _BreadcrumbSegment(name: name, path: path));
      current = p.dirname(current);
    }

    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wpdProvider(widget.gameCode));

    // Handle tree sync with state
    if (state.rootDirPath != _currentRootPath) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reloadTree(state.rootDirPath);
      });
    }

    final canNavigateUp = state.rootDirPath != null &&
        p.dirname(state.rootDirPath!) != state.rootDirPath;

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.black.withValues(alpha: 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Action buttons row
              Row(
                children: [
                  CrystalIconButton(
                    onPressed: canNavigateUp ? _navigateUp : null,
                    icon: Icons.arrow_upward,
                    tooltip: "Go to parent directory",
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CrystalCompactButton(
                      onPressed: widget.onPickDirectory,
                      icon: Icons.folder_open,
                      label: "Open",
                    ),
                  ),
                  const SizedBox(width: 8),
                  CrystalIconButton(
                    onPressed: _toggleHideZeroByteFiles,
                    icon: _hideZeroByteFiles
                        ? Icons.filter_alt
                        : Icons.filter_alt_off,
                    tooltip: _hideZeroByteFiles
                        ? "Show all files"
                        : "Hide 0-byte files",
                    isSelected: _hideZeroByteFiles,
                  ),
                ],
              ),
              // Breadcrumb bar
              if (state.rootDirPath != null) ...[
                const SizedBox(height: 8),
                _BreadcrumbBar(
                  segments: _buildBreadcrumbs(state.rootDirPath!),
                  onNavigate: _navigateToPath,
                ),
                // Batch sound operations row
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CrystalCompactButton(
                        onPressed: _isBatchProcessing ? null : _convertAllScdToWav,
                        icon: Icons.music_note,
                        label: "Extract All SCD",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CrystalCompactButton(
                        onPressed: _isBatchProcessing ? null : _convertAllWavToScd,
                        icon: Icons.transform,
                        label: "Convert All WAV",
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Tree View
        Expanded(
          child: state.rootDirPath == null
              ? const Center(
                  child: Text(
                    "No Workspace Open",
                    style: TextStyle(color: Colors.white24),
                  ),
                )
              : _treeController == null
                  ? const Center(child: CrystalLoadingSpinner())
                  : CrystalPanel(
                      padding: EdgeInsets.zero,
                      child: AnimatedTreeView<FileNode>(
                        treeController: _treeController!,
                        nodeBuilder: (context, entry) {
                          return _TreeNode(
                            entry: entry,
                            gameCode: widget.gameCode,
                            onTap: () {
                              final node = entry.node;
                              if (node.isDirectory) {
                                // Directories: expand/collapse
                                _treeController!.toggleExpansion(node);
                              } else {
                                // Files: select to show in center pane
                                ref
                                    .read(wpdProvider(widget.gameCode).notifier)
                                    .setSelectedNode(node.entity);
                              }
                            },
                            isSelected:
                                state.selectedNode?.path == entry.node.path,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _BreadcrumbSegment {
  final String name;
  final String path;

  const _BreadcrumbSegment({required this.name, required this.path});
}

class _BreadcrumbBar extends StatelessWidget {
  final List<_BreadcrumbSegment> segments;
  final ValueChanged<String> onNavigate;

  const _BreadcrumbBar({
    required this.segments,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true, // Show end of path (most relevant) when overflowing
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 4),
            for (int i = 0; i < segments.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: Colors.white24,
                  ),
                ),
              _BreadcrumbChip(
                segment: segments[i],
                isLast: i == segments.length - 1,
                onTap: () => onNavigate(segments[i].path),
              ),
            ],
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbChip extends StatefulWidget {
  final _BreadcrumbSegment segment;
  final bool isLast;
  final VoidCallback onTap;

  const _BreadcrumbChip({
    required this.segment,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_BreadcrumbChip> createState() => _BreadcrumbChipState();
}

class _BreadcrumbChipState extends State<_BreadcrumbChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.cyan.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            widget.segment.name,
            style: TextStyle(
              fontSize: 12,
              color: widget.isLast
                  ? Colors.white
                  : (_isHovered ? Colors.cyan : Colors.white60),
              fontWeight: widget.isLast ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _TreeNode extends StatefulWidget {
  final TreeEntry<FileNode> entry;
  final AppGameCode gameCode;
  final VoidCallback onTap;
  final bool isSelected;

  const _TreeNode({
    required this.entry,
    required this.gameCode,
    required this.onTap,
    required this.isSelected,
  });

  @override
  State<_TreeNode> createState() => _TreeNodeState();
}

class _TreeNodeState extends State<_TreeNode> {
  bool _isHovered = false;

  /// Format file size in bytes with appropriate unit
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.entry.node;
    final isDir = node.isDirectory;
    final name = node.name;
    final isExpanded = widget.entry.isExpanded;

    // Get file size for files
    int? fileSize;
    if (!isDir) {
      try {
        fileSize = (node.entity as File).lengthSync();
      } catch (_) {
        // Ignore errors reading file size
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: widget.isSelected
              ? Colors.cyan.withValues(alpha: 0.2)
              : (_isHovered ? Colors.white.withValues(alpha: 0.05) : null),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: TreeIndentation(
            entry: widget.entry,
            guide: const IndentGuide.connectingLines(
              indent: 20,
              color: Colors.white12,
              thickness: 1.0,
              origin: 0.5,
              roundCorners: true,
            ),
            child: Row(
              children: [
                // Expand/collapse chevron for directories
                if (isDir)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      color: Colors.white38,
                      size: 16,
                    ),
                  )
                else
                  const SizedBox(width: 20), // Alignment spacer for files
                Icon(
                  isDir
                      ? (isExpanded ? Icons.folder_open : Icons.folder)
                      : WpdFileUtils.getFileIcon(name),
                  color: isDir ? Colors.cyan : WpdFileUtils.getFileColor(name),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: widget.isSelected ? Colors.white : Colors.white70,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                // File size for files
                if (fileSize != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _formatFileSize(fileSize),
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
