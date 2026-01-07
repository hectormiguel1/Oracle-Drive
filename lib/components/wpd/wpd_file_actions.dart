import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/widgets/crystal_action_bar.dart';
import 'package:oracle_drive/components/widgets/crystal_snackbar.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/providers/wpd_provider.dart';
import 'package:fabula_nova_sdk/bridge_generated/modules/wct.dart' as wct_sdk;

/// Callback types for WPD actions that need UI interaction
typedef OnBatchDecompile = void Function(Directory dir);
typedef OnViewJavaSource = void Function(File file);
typedef OnPickDdsFile = Future<String?> Function();
typedef OnEnterArchiveMode = void Function(File file);

/// Action toolbars for files and directories in the WPD screen.
class WpdFileActions extends ConsumerWidget {
  final AppGameCode gameCode;
  final FileSystemEntity node;
  final OnBatchDecompile onBatchDecompile;
  final OnViewJavaSource onViewJavaSource;
  final OnPickDdsFile onPickDdsFile;
  final OnEnterArchiveMode onEnterArchiveMode;
  final VoidCallback onTreeRebuild;

  const WpdFileActions({
    super.key,
    required this.gameCode,
    required this.node,
    required this.onBatchDecompile,
    required this.onViewJavaSource,
    required this.onPickDdsFile,
    required this.onEnterArchiveMode,
    required this.onTreeRebuild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(wpdIsProcessingProvider(gameCode));
    final notifier = ref.read(wpdProvider(gameCode).notifier);

    if (node is Directory) {
      return _DirectoryActions(
        dir: node as Directory,
        isProcessing: isProcessing,
        notifier: notifier,
        onBatchDecompile: onBatchDecompile,
        onTreeRebuild: onTreeRebuild,
        showSnackBar: (msg, {bool isError = false}) => _showSnackBar(context, msg, isError: isError),
      );
    } else {
      return _FileActions(
        file: node as File,
        isProcessing: isProcessing,
        notifier: notifier,
        onViewJavaSource: onViewJavaSource,
        onPickDdsFile: onPickDdsFile,
        onEnterArchiveMode: onEnterArchiveMode,
        onTreeRebuild: onTreeRebuild,
        showSnackBar: (msg, {bool isError = false}) => _showSnackBar(context, msg, isError: isError),
      );
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return;
    if (isError) {
      context.showErrorSnackBar(message);
    } else {
      context.showSuccessSnackBar(message);
    }
  }
}

class _DirectoryActions extends StatelessWidget {
  final Directory dir;
  final bool isProcessing;
  final WpdNotifier notifier;
  final OnBatchDecompile onBatchDecompile;
  final VoidCallback onTreeRebuild;
  final void Function(String, {bool isError}) showSnackBar;

  const _DirectoryActions({
    required this.dir,
    required this.isProcessing,
    required this.notifier,
    required this.onBatchDecompile,
    required this.onTreeRebuild,
    required this.showSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        // Archive actions
        CrystalActionBar(
          label: 'ARCHIVE',
          actions: [
            CrystalAction(
              icon: Icons.inventory_2,
              tooltip: 'Repack as WPD',
              onPressed: isProcessing ? null : () => _repackWpd(),
              isPrimary: true,
            ),
          ],
        ),
        // Batch CLB Operations
        CrystalActionBar(
          label: 'BATCH CLB',
          actions: [
            CrystalAction(
              icon: Icons.lock_open,
              tooltip: 'Decrypt All CLB',
              onPressed: isProcessing
                  ? null
                  : () => _processBatchWct(wct_sdk.Action.decrypt, '.clb'),
            ),
            CrystalAction(
              icon: Icons.code,
              tooltip: 'Convert All to Java',
              onPressed: isProcessing
                  ? null
                  : () => _processBatchWct(wct_sdk.Action.clbToJava, '.clb'),
            ),
            CrystalAction(
              icon: Icons.lock,
              tooltip: 'Convert All to CLB',
              onPressed: isProcessing
                  ? null
                  : () => _processBatchWct(wct_sdk.Action.javaToClb, '.class'),
            ),
            CrystalAction(
              icon: Icons.enhanced_encryption,
              tooltip: 'Encrypt All CLB',
              onPressed: isProcessing
                  ? null
                  : () => _processBatchWct(wct_sdk.Action.encrypt, '.clb'),
            ),
          ],
        ),
        // Build actions
        CrystalActionBar(
          label: 'BUILD',
          actions: [
            CrystalAction(
              icon: Icons.folder_special,
              tooltip: 'Build Java Project',
              onPressed: isProcessing ? null : () => onBatchDecompile(dir),
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _repackWpd() async {
    try {
      await notifier.repackWpd(dir);
      onTreeRebuild();
      showSnackBar('Repacked successfully');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _processBatchWct(wct_sdk.Action action, String extension) async {
    try {
      final result = await notifier.processBatchWct(
        dir,
        wct_sdk.TargetType.clb,
        action,
        extension,
      );
      onTreeRebuild();

      if (result.successCount == 0 && result.errorCount == 0) {
        showSnackBar('No $extension files found in directory', isError: true);
      } else if (result.errorCount > 0) {
        showSnackBar(
          '${result.operationName}: ${result.successCount} succeeded, ${result.errorCount} failed',
          isError: true,
        );
      } else {
        showSnackBar('${result.operationName}: ${result.successCount} files processed');
      }
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }
}

class _FileActions extends StatelessWidget {
  final File file;
  final bool isProcessing;
  final WpdNotifier notifier;
  final OnViewJavaSource onViewJavaSource;
  final OnPickDdsFile onPickDdsFile;
  final OnEnterArchiveMode onEnterArchiveMode;
  final VoidCallback onTreeRebuild;
  final void Function(String, {bool isError}) showSnackBar;

  const _FileActions({
    required this.file,
    required this.isProcessing,
    required this.notifier,
    required this.onViewJavaSource,
    required this.onPickDdsFile,
    required this.onEnterArchiveMode,
    required this.onTreeRebuild,
    required this.showSnackBar,
  });

  String get _ext => file.path.split('.').last.toLowerCase();
  String get _name => file.path.split('/').last.toLowerCase();
  // Must start with 'white_' (underscore) to be a WBT archive
  // This excludes files like 'WhiteBaseClassJar.bin' which are WPD data files
  bool get _isWhiteBin =>
      _name.startsWith('white_') && _ext == 'bin' && !_name.contains('filelist');
  bool get _isFileList => _name.contains('filelist') && _ext == 'bin';

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        // WPD Actions
        if (_ext == 'wpd')
          CrystalActionBar(
            label: 'ARCHIVE',
            actions: [
              CrystalAction(
                icon: Icons.folder_zip,
                tooltip: 'Unpack WPD',
                onPressed: isProcessing ? null : _unpackWpd,
                isPrimary: true,
              ),
            ],
          ),

        // White*.bin Archive Actions
        if (_isWhiteBin)
          CrystalActionBar(
            label: 'GAME ARCHIVE',
            actions: [
              CrystalAction(
                icon: Icons.archive,
                tooltip: 'Open Archive Browser',
                onPressed: isProcessing ? null : () => onEnterArchiveMode(file),
                isPrimary: true,
              ),
            ],
          ),

        // FileList Archive Actions
        if (_isFileList)
          CrystalActionBar(
            label: 'GAME ARCHIVE',
            actions: [
              CrystalAction(
                icon: Icons.archive,
                tooltip: 'Open Archive Browser',
                onPressed: isProcessing ? null : () => onEnterArchiveMode(file),
                isPrimary: true,
              ),
            ],
          ),

        // BIN/XGR Actions (non-archive bins)
        if ((_ext == 'bin' || _ext == 'xgr') && !_isWhiteBin && !_isFileList)
          CrystalActionBar(
            label: 'ARCHIVE',
            actions: [
              CrystalAction(
                icon: Icons.download,
                tooltip: 'Unpack BIN',
                onPressed: isProcessing ? null : _unpackBin,
                isPrimary: true,
              ),
            ],
          ),

        // IMG Actions
        if (_ext == 'imgb')
          CrystalActionBar(
            label: 'IMAGE',
            actions: [
              CrystalAction(
                icon: Icons.image,
                tooltip: 'Extract IMG to DDS',
                onPressed: isProcessing ? null : _extractImg,
                isPrimary: true,
              ),
              CrystalAction(
                icon: Icons.upload_file,
                tooltip: 'Inject DDS into IMG',
                onPressed: isProcessing ? null : _repackImg,
              ),
            ],
          ),

        // WDB Actions
        if (_ext == 'wdb')
          CrystalActionBar(
            label: 'DATABASE',
            actions: [
              CrystalAction(
                icon: Icons.table_chart,
                tooltip: 'Open in Database',
                onPressed: isProcessing ? null : _openInDatabase,
                isPrimary: true,
              ),
            ],
          ),

        // CLB Actions
        if (_ext == 'clb')
          CrystalActionBar(
            label: 'SCRIPT',
            actions: [
              CrystalAction(
                icon: Icons.lock_open,
                tooltip: 'Decrypt CLB',
                onPressed: isProcessing ? null : () => _processWct(wct_sdk.Action.decrypt),
                isPrimary: true,
              ),
              CrystalAction(
                icon: Icons.code,
                tooltip: 'Convert to Java',
                onPressed: isProcessing ? null : () => _processWct(wct_sdk.Action.clbToJava),
              ),
            ],
          ),

        // Class file Actions
        if (_ext == 'class')
          CrystalActionBar(
            label: 'JAVA',
            actions: [
              CrystalAction(
                icon: Icons.visibility,
                tooltip: 'Decompile',
                onPressed: isProcessing ? null : _decompileClass,
                isPrimary: true,
              ),
              CrystalAction(
                icon: Icons.lock,
                tooltip: 'Convert to CLB',
                onPressed: isProcessing ? null : () => _processWct(wct_sdk.Action.javaToClb),
              ),
              CrystalAction(
                icon: Icons.enhanced_encryption,
                tooltip: 'Encrypt to CLB',
                onPressed: isProcessing ? null : () => _processWct(wct_sdk.Action.encrypt),
              ),
            ],
          ),

        // Java source Actions
        if (_ext == 'java')
          CrystalActionBar(
            label: 'JAVA',
            actions: [
              CrystalAction(
                icon: Icons.code,
                tooltip: 'View Source',
                onPressed: () => onViewJavaSource(file),
                isPrimary: true,
              ),
              CrystalAction(
                icon: Icons.enhanced_encryption,
                tooltip: 'Encrypt to CLB',
                onPressed: isProcessing ? null : () => _processWct(wct_sdk.Action.encrypt),
              ),
            ],
          ),

        // FileList Actions
        if (_name.contains('filelist'))
          CrystalActionBar(
            label: 'FILELIST',
            actions: [
              CrystalAction(
                icon: Icons.list_alt,
                tooltip: 'Decrypt FileList',
                onPressed: isProcessing
                    ? null
                    : () => _processWct(wct_sdk.Action.decrypt, target: wct_sdk.TargetType.fileList),
              ),
              CrystalAction(
                icon: Icons.save_alt,
                tooltip: 'Encrypt FileList',
                onPressed: isProcessing
                    ? null
                    : () => _processWct(wct_sdk.Action.encrypt, target: wct_sdk.TargetType.fileList),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _unpackWpd() async {
    try {
      await notifier.unpackWpd(file);
      onTreeRebuild();
      showSnackBar('Unpacked successfully');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _unpackBin() async {
    try {
      await notifier.unpackBin(file);
      onTreeRebuild();
      showSnackBar('Unpacked successfully');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _extractImg() async {
    try {
      await notifier.extractImg(file);
      onTreeRebuild();
      showSnackBar('Image extracted to DDS');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _repackImg() async {
    try {
      final ddsPath = await onPickDdsFile();
      if (ddsPath != null) {
        await notifier.repackImg(file, ddsPath);
        showSnackBar('Image repacked successfully');
      }
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _openInDatabase() async {
    try {
      final rowCount = await notifier.openInDatabase(file);
      showSnackBar('Loaded $rowCount records');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _processWct(
    wct_sdk.Action action, {
    wct_sdk.TargetType target = wct_sdk.TargetType.clb,
  }) async {
    try {
      await notifier.processWct(file, target, action);
      onTreeRebuild();
      showSnackBar('${notifier.getActionName(action)} completed');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _decompileClass() async {
    try {
      final javaPath = await notifier.decompileClass(file);
      onTreeRebuild();
      showSnackBar('Decompiled successfully');
      onViewJavaSource(File(javaPath));
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }
}
