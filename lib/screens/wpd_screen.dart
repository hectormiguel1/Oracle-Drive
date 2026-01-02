import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/batch_decompile_dialog.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_dialog.dart';
import 'package:oracle_drive/components/widgets/crystal_divider.dart';
import 'package:oracle_drive/components/widgets/crystal_snackbar.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/components/wpd/wpd_archive_panel.dart';
import 'package:oracle_drive/components/wpd/wpd_file_actions.dart';
import 'package:oracle_drive/components/wpd/wpd_file_browser.dart';
import 'package:oracle_drive/components/wpd/wpd_file_details.dart';
import 'package:oracle_drive/components/wpd/wpd_processing_overlay.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/providers/app_state_provider.dart';
import 'package:oracle_drive/providers/wpd_provider.dart';
import 'package:oracle_drive/screens/java_source_screen.dart';
import 'package:oracle_drive/src/services/java_decompiler_service.dart';
import 'package:path/path.dart' as p;

class WpdScreen extends ConsumerStatefulWidget {
  const WpdScreen({super.key});

  @override
  ConsumerState<WpdScreen> createState() => _WpdScreenState();
}

class _WpdScreenState extends ConsumerState<WpdScreen>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<WpdFileBrowserState> _browserKey = GlobalKey();

  AppGameCode get _gameCode => ref.watch(selectedGameProvider);

  @override
  bool get wantKeepAlive => true;

  // ============================================================
  // UI Callbacks (require BuildContext or Navigator)
  // ============================================================

  Future<void> _pickRootDir() async {
    String? dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Workspace Directory',
    );
    if (dir != null) {
      ref.read(wpdProvider(_gameCode).notifier).setRootDirPath(dir);
    }
  }

  void _viewJavaSource(File javaFile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JavaSourceScreen(filePath: javaFile.path),
      ),
    );
  }

  Future<String?> _pickDdsFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Source DDS',
      type: FileType.custom,
      allowedExtensions: ['dds'],
    );
    return result?.files.single.path;
  }

  Future<void> _batchDecompile(Directory dir) async {
    final config = await BatchDecompileDialog.show(context, dir.path);
    if (config == null) return;

    try {
      final result = await ref
          .read(wpdProvider(_gameCode).notifier)
          .batchDecompileClbs(dir, config);

      if (mounted) {
        _browserKey.currentState?.rebuild();
        await BatchDecompileResultDialog.show(context, result);
      }
    } on JavaNotFoundError {
      if (mounted) _showJavaNotFoundDialog();
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Batch decompilation failed: $e');
      }
    }
  }

  void _showJavaNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => CrystalDialog(
        title: 'Java Not Found',
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Java is required to decompile .class files.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              'Please install Java and ensure it is in your system PATH.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              'You can download Java from:',
              style: TextStyle(color: Colors.white54),
            ),
            SizedBox(height: 8),
            SelectableText(
              'https://adoptium.net/',
              style: TextStyle(color: Colors.cyan),
            ),
          ],
        ),
        actions: [
          CrystalButton(
            label: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _rebuildTree() {
    _browserKey.currentState?.rebuild();
  }

  Future<void> _enterArchiveMode(File file) async {
    final notifier = ref.read(wpdProvider(_gameCode).notifier);
    final fileName = p.basename(file.path).toLowerCase();

    // Check if it's a white*.bin or filelist
    final isWhiteBin = fileName.startsWith('white') &&
        fileName.endsWith('.bin') &&
        !fileName.contains('filelist');
    final isFileList = fileName.contains('filelist') && fileName.endsWith('.bin');

    try {
      if (isFileList) {
        // Filelist selected - ask for the content bin
        final contentBin = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['bin'],
          dialogTitle: 'Select the content .bin (e.g. _white_img.bin)',
        );

        if (contentBin != null && contentBin.files.single.path != null) {
          await notifier.enterArchiveModeWithFileList(file.path);
          notifier.setArchiveBinPath(contentBin.files.single.path!);
        }
      } else if (isWhiteBin) {
        // White*.bin selected - ask for the filelist
        final filelistResult = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['bin'],
          dialogTitle: 'Select the filelist (e.g. white_img.win32.bin)',
        );

        if (filelistResult != null && filelistResult.files.single.path != null) {
          await notifier.enterArchiveModeWithWhiteBin(
            file.path,
            filelistResult.files.single.path!,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to load archive: $e');
      }
    }
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(wpdProvider(_gameCode));

    return Padding(
      padding: const EdgeInsets.all(13.0),
      child: Row(
        children: [
          // Left Pane: File Browser (always visible)
          Expanded(
            flex: 3,
            child: WpdFileBrowser(
              key: _browserKey,
              gameCode: _gameCode,
              onPickDirectory: _pickRootDir,
            ),
          ),
          const CrystalVerticalDivider.subtle(width: 1),
          // Right Pane: Content Area or Archive Panel
          Expanded(
            flex: 7,
            child: state.archive.isActive
                ? WpdArchivePanel(gameCode: _gameCode)
                : Stack(
                    children: [
                      _buildMainContent(state),
                      WpdProcessingOverlay(gameCode: _gameCode),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(WpdState state) {
    if (!state.hasSelection) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, size: 64, color: Colors.white10),
            const SizedBox(height: 16),
            Text(
              "Select a file to view actions",
              style: CrystalStyles.title.copyWith(color: Colors.white24),
            ),
          ],
        ),
      );
    }

    final node = state.selectedNode!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.black26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          WpdFileDetails(node: node),
          const Divider(color: Colors.white24, height: 32),

          // Actions
          Text("ACTIONS", style: CrystalStyles.sectionHeader),
          const SizedBox(height: 16),

          WpdFileActions(
            gameCode: _gameCode,
            node: node,
            onBatchDecompile: _batchDecompile,
            onViewJavaSource: _viewJavaSource,
            onPickDdsFile: _pickDdsFile,
            onEnterArchiveMode: _enterArchiveMode,
            onTreeRebuild: _rebuildTree,
          ),
        ],
      ),
    );
  }
}
