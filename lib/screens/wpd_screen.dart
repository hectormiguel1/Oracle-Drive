import 'dart:io';

import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/models/app_game_code.dart'; // Import AppGameCode
import 'package:oracle_drive/providers/app_state_provider.dart';
import 'package:oracle_drive/providers/wpd_provider.dart';
import 'package:oracle_drive/src/third_party/wpdlib/wpd.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view2/flutter_fancy_tree_view2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

class WpdScreen extends ConsumerStatefulWidget {
  const WpdScreen({super.key});
  static const wpdExtractExtensions = ['.bin', '.xgr'];
  @override
  ConsumerState<WpdScreen> createState() => _WpdScreenState();
}

class _WpdScreenState extends ConsumerState<WpdScreen>
    with AutomaticKeepAliveClientMixin {
  final Logger _logger = Logger('WpdScreen');
  TreeController<FileSystemEntity>? _treeController;

  AppGameCode get _gameCode => ref.watch(selectedGameProvider);

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickRootDir() async {
    String? dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Workspace Directory (extracted .bin content)',
    );
    if (dir != null) {
      ref.read(wpdProvider(_gameCode).notifier).setRootDirPath(dir);
      _reloadTree(dir);
    }
  }

  void _reloadTree(String? rootPath) {
    if (rootPath == null) {
      _treeController = null;
      setState(() {});
      return;
    }

    final rootDir = Directory(rootPath);
    if (!rootDir.existsSync()) {
      _treeController = null;
      setState(() {});
      return;
    }

    try {
      final roots = [rootDir];

      _treeController = TreeController<FileSystemEntity>(
        roots: roots,
        childrenProvider: (FileSystemEntity parent) {
          if (parent is Directory) {
            try {
              final list = parent.listSync()
                ..sort((a, b) {
                  final aIsDir = a is Directory;
                  final bIsDir = b is Directory;
                  if (aIsDir && !bIsDir) return -1;
                  if (!aIsDir && bIsDir) return 1;
                  return a.path.compareTo(b.path);
                });
              return list;
            } catch (e) {
              return [];
            }
          }
          return [];
        },
      );

      _treeController!.expand(rootDir);
      setState(() {});
    } catch (e) {
      _logger.severe("Error scanning directory: $e");
    }
  }

  Future<void> _unpackWpd(File wpdFile) async {
    try {
      _logger.info("Unpacking ${p.basename(wpdFile.path)}...");
      final status = await WpdTool.unpackFile(wpdFile.path);
      _logger.info("Unpack finished with status: $status");
      setState(() {
        _treeController?.rebuild();
      });
    } catch (e) {
      _logger.severe("Error unpacking: $e");
    }
  }

  Future<void> _repackWpd(Directory dir) async {
    try {
      _logger.info("Repacking ${p.basename(dir.path)}...");
      final status = await WpdTool.repackDir(dir.path);
      _logger.info("Repack finished with status: $status");
      setState(() {
        _treeController?.rebuild();
      });
    } catch (e) {
      _logger.severe("Error repacking: $e");
    }
  }

  Future<void> _unpackWhiteBin(File binFile) async {
    try {
      final wbtGameCode = _gameCode.toWbtGameCode();
      if (wbtGameCode == null) {
        throw Exception(
          "Unsupported game code for WBT operations: ${_gameCode.displayName}",
        );
      }

      _logger.info("Unpacking .bin: ${binFile.path}");
      String outputDir = p.join(
        binFile.parent.path,
        p.basenameWithoutExtension(binFile.path),
      );
      await Directory(outputDir).create(recursive: true);

      await WpdTool.unpackFile(binFile.path);
      _logger.info("Unpack complete.");
      setState(() => _treeController?.rebuild());
    } catch (e) {
      _logger.severe("Error unpacking bin: $e");
    }
  }

  Future<void> _repackWhiteBin(File binFile) async {
    String? sourceDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Source Directory (Modded Files)',
      initialDirectory: binFile.parent.path,
    );
    if (sourceDir == null) return;

    try {
      final wbtGameCode = _gameCode.toWbtGameCode();
      if (wbtGameCode == null) {
        throw Exception(
          "Unsupported game code for WBT operations: ${_gameCode.displayName}",
        );
      }

      _logger.info("Repacking .bin from $sourceDir...");
      await WpdTool.repackDir(sourceDir);
      _logger.info("Repack complete.");
    } catch (e) {
      _logger.severe("Error repacking bin: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final state = ref.watch(wpdProvider(_gameCode));

    // Re-init tree if game changed and rootPath is different from what we show
    // We can't easily compare the tree controller's root with state.rootDirPath
    // So we might need to store the current tree root path in state too, or just check here.
    if (state.rootDirPath != null &&
        (_treeController == null ||
            _treeController!.roots.first.path != state.rootDirPath)) {
      // Need to defer this as it calls setState during build
      Future.microtask(() => _reloadTree(state.rootDirPath));
    } else if (state.rootDirPath == null && _treeController != null) {
      Future.microtask(() => _reloadTree(null));
    }

    return Column(
      children: [
        // Toolbar
        Container(
          color: Colors.black.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CrystalButton(
                onPressed: _pickRootDir,
                icon: Icons.folder,
                label: "Open Workspace",
                isPrimary: true,
              ),
              if (state.rootDirPath != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    state.rootDirPath!,
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Action Bar (Context Sensitive)
        Container(
          height: 50,
          color: Colors.black.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (state.selectedNode != null) ...[
                // .WPD Actions
                if (state.selectedNode is File &&
                    p.extension(state.selectedNode!.path).toLowerCase() ==
                        '.wpd')
                  CrystalButton(
                    onPressed: () => _unpackWpd(state.selectedNode as File),
                    icon: Icons.folder_zip,
                    label: "UNPACK WPD",
                    isPrimary: true,
                  ),

                // .BIN Actions
                if (state.selectedNode is File &&
                    WpdScreen.wpdExtractExtensions.contains(
                      p.extension(state.selectedNode!.path).toLowerCase(),
                    )) ...[
                  CrystalButton(
                    onPressed: () =>
                        _unpackWhiteBin(state.selectedNode as File),
                    icon: Icons.download_for_offline,
                    label: "UNPACK BIN",
                  ),
                  const SizedBox(width: 16),
                  CrystalButton(
                    onPressed: () =>
                        _repackWhiteBin(state.selectedNode as File),
                    icon: Icons.upload_file,
                    label: "REPACK BIN",
                  ),
                ],

                // Folder Actions
                if (state.selectedNode is Directory)
                  CrystalButton(
                    onPressed: () =>
                        _repackWpd(state.selectedNode as Directory),
                    icon: Icons.inventory,
                    label: "REPACK FOLDER",
                  ),

                const Spacer(),
                Flexible(
                  child: Text(
                    p.basename(state.selectedNode!.path),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Text(
                  "Select a file or folder to see actions",
                  style: TextStyle(color: Colors.white24),
                ),
            ],
          ),
        ),

        // Tree View
        Expanded(
          child: state.rootDirPath == null
              ? const Center(
                  child: Text(
                    "Select a directory to browse",
                    style: TextStyle(color: Colors.white24),
                  ),
                )
              : _treeController == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CrystalPanel(
                    child: AnimatedTreeView<FileSystemEntity>(
                      treeController: _treeController!,
                      nodeBuilder: (context, entry) {
                        final node = entry.node;
                        final isDir = node is Directory;
                        final isSelected =
                            state.selectedNode?.path == node.path;
                        final name = p.basename(node.path);

                        return TreeIndentation(
                          entry: entry,
                          guide: const IndentGuide.connectingLines(
                            indent: 30,
                            color: Colors.grey,
                            thickness: 1.0,
                            origin: 0.5,
                            roundCorners: true,
                          ),
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(wpdProvider(_gameCode).notifier)
                                  .setSelectedNode(node);
                              if (isDir) {
                                _treeController!.toggleExpansion(node);
                              }
                            },
                            child: Container(
                              color: isSelected
                                  ? Colors.cyan.withValues(alpha: 0.2)
                                  : null,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    isDir
                                        ? (entry.isExpanded
                                              ? Icons.folder_open
                                              : Icons.folder)
                                        : (name.endsWith('.wpd')
                                              ? Icons.folder_zip
                                              : Icons.description),
                                    color: isDir
                                        ? Colors.cyan
                                        : (name.endsWith('.wpd')
                                              ? Colors.cyan
                                              : Colors.white54),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
