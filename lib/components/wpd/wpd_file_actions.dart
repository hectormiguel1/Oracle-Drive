import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/widgets/crystal_action_bar.dart';
import 'package:oracle_drive/components/widgets/crystal_snackbar.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/providers/wpd_provider.dart';
import 'package:oracle_drive/src/services/native_service.dart';
import 'package:fabula_nova_sdk/bridge_generated/modules/wct.dart' as wct_sdk;
import 'package:path/path.dart' as p;
import 'package:audioplayers/audioplayers.dart';

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
        showSnackBar: (msg, {bool isError = false, bool isWarning = false}) =>
            _showSnackBar(context, msg, isError: isError, isWarning: isWarning),
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
        showSnackBar: (msg, {bool isError = false, bool isWarning = false}) =>
            _showSnackBar(context, msg, isError: isError, isWarning: isWarning),
      );
    }
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false, bool isWarning = false}) {
    if (!context.mounted) return;
    if (isError) {
      context.showErrorSnackBar(message);
    } else if (isWarning) {
      context.showWarningSnackBar(message);
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
  final void Function(String, {bool isError, bool isWarning}) showSnackBar;

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
        // Batch Sound Operations
        CrystalActionBar(
          label: 'BATCH SOUND',
          actions: [
            CrystalAction(
              icon: Icons.music_note,
              tooltip: 'Convert All SCD to WAV',
              onPressed: isProcessing ? null : _convertAllScdToWav,
              isPrimary: true,
            ),
            CrystalAction(
              icon: Icons.transform,
              tooltip: 'Convert All WAV to SCD',
              onPressed: isProcessing ? null : _convertAllWavToScd,
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

  Future<void> _convertAllScdToWav() async {
    try {
      int successCount = 0;
      int errorCount = 0;

      // Find all .scd files recursively
      final scdFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.scd'))
          .toList();

      if (scdFiles.isEmpty) {
        showSnackBar('No SCD files found in directory', isWarning: true);
        return;
      }

      showSnackBar('Converting ${scdFiles.length} SCD files to WAV...');

      for (final scdFile in scdFiles) {
        try {
          final wavPath = '${scdFile.path.substring(0, scdFile.path.length - 4)}.wav';
          await NativeService.instance.extractScdToWav(scdFile.path, wavPath);
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      onTreeRebuild();
      if (errorCount > 0) {
        showSnackBar('SCD→WAV: $successCount succeeded, $errorCount failed', isError: true);
      } else {
        showSnackBar('SCD→WAV: $successCount files converted');
      }
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _convertAllWavToScd() async {
    try {
      int successCount = 0;
      int errorCount = 0;

      // Find all .wav files recursively
      final wavFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.wav'))
          .toList();

      if (wavFiles.isEmpty) {
        showSnackBar('No WAV files found in directory', isWarning: true);
        return;
      }

      showSnackBar('Converting ${wavFiles.length} WAV files to SCD...');

      for (final wavFile in wavFiles) {
        try {
          final scdPath = '${wavFile.path.substring(0, wavFile.path.length - 4)}.scd';
          await NativeService.instance.convertWavToScd(wavFile.path, scdPath);
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      onTreeRebuild();
      if (errorCount > 0) {
        showSnackBar('WAV→SCD: $successCount succeeded, $errorCount failed', isError: true);
      } else {
        showSnackBar('WAV→SCD: $successCount files converted');
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
  final void Function(String, {bool isError, bool isWarning}) showSnackBar;

  // Static audio player for playback across the app
  static AudioPlayer? _audioPlayer;

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

        // Force WPD unpack for files that might be misidentified
        // (e.g., filelist_sound_pack*.bin are WPD containers, not WBT archives)
        if (_ext == 'bin' && (_isWhiteBin || _isFileList))
          CrystalActionBar(
            label: 'FORCE',
            actions: [
              CrystalAction(
                icon: Icons.folder_zip_outlined,
                tooltip: 'Force Unpack as WPD',
                onPressed: isProcessing ? null : _unpackBin,
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

        // SCD (Sound) Actions
        if (_ext == 'scd')
          CrystalActionBar(
            label: 'SOUND',
            actions: [
              CrystalAction(
                icon: Icons.play_arrow,
                tooltip: 'Play Sound',
                onPressed: isProcessing ? null : _playScd,
                isPrimary: true,
              ),
              CrystalAction(
                icon: Icons.save_alt,
                tooltip: 'Extract to WAV',
                onPressed: isProcessing ? null : _extractScdToWav,
              ),
            ],
          ),

        // WAV (Audio) Actions
        if (_ext == 'wav')
          CrystalActionBar(
            label: 'AUDIO',
            actions: [
              CrystalAction(
                icon: Icons.play_arrow,
                tooltip: 'Play WAV',
                onPressed: isProcessing ? null : _playWav,
                isPrimary: true,
              ),
              CrystalAction(
                icon: Icons.stop,
                tooltip: 'Stop Playback',
                onPressed: _stopPlayback,
              ),
              CrystalAction(
                icon: Icons.transform,
                tooltip: 'Convert to SCD',
                onPressed: isProcessing ? null : _convertWavToScd,
              ),
              CrystalAction(
                icon: Icons.translate,
                tooltip: 'Translate Audio',
                onPressed: isProcessing ? null : _translateWav,
              ),
            ],
          ),
      ],
    );
  }

  /// Returns true if file is 0 bytes (shows warning and should skip action)
  bool _isZeroByteFile() {
    if (file.lengthSync() == 0) {
      showSnackBar('File is 0 bytes, skipping action', isWarning: true);
      return true;
    }
    return false;
  }

  Future<void> _unpackWpd() async {
    if (_isZeroByteFile()) return;
    try {
      await notifier.unpackWpd(file);
      onTreeRebuild();
      showSnackBar('Unpacked successfully');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _unpackBin() async {
    if (_isZeroByteFile()) return;
    try {
      await notifier.unpackBin(file);
      onTreeRebuild();
      showSnackBar('Unpacked successfully');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _extractImg() async {
    if (_isZeroByteFile()) return;
    try {
      await notifier.extractImg(file);
      onTreeRebuild();
      showSnackBar('Image extracted to DDS');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _repackImg() async {
    if (_isZeroByteFile()) return;
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
    if (_isZeroByteFile()) return;
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
    if (_isZeroByteFile()) return;
    try {
      await notifier.processWct(file, target, action);
      onTreeRebuild();
      showSnackBar('${notifier.getActionName(action)} completed');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _playScd() async {
    if (_isZeroByteFile()) return;
    try {
      // Convert SCD to WAV bytes in memory
      final wavBytes = await NativeService.instance.scdToWav(file.path);

      // Write to a temporary file for playback
      final tempDir = Directory.systemTemp;
      final wavFile = File(
        p.join(tempDir.path, '${p.basenameWithoutExtension(file.path)}.wav'),
      );
      await wavFile.writeAsBytes(wavBytes);

      // Play the audio
      final player = AudioPlayer();
      await player.play(DeviceFileSource(wavFile.path));

      showSnackBar('Playing: ${p.basename(file.path)}');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _extractScdToWav() async {
    if (_isZeroByteFile()) return;
    try {
      final wavPath = p.join(
        file.parent.path,
        '${p.basenameWithoutExtension(file.path)}.wav',
      );
      await NativeService.instance.extractScdToWav(file.path, wavPath);
      onTreeRebuild();
      showSnackBar('Extracted to ${p.basename(wavPath)}');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _decompileClass() async {
    if (_isZeroByteFile()) return;
    try {
      final javaPath = await notifier.decompileClass(file);
      onTreeRebuild();
      showSnackBar('Decompiled successfully');
      onViewJavaSource(File(javaPath));
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _playWav() async {
    if (_isZeroByteFile()) return;
    try {
      // Stop any existing playback
      await _audioPlayer?.stop();
      _audioPlayer?.dispose();

      // Create new player and play the WAV file directly
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.play(DeviceFileSource(file.path));

      showSnackBar('Playing: ${p.basename(file.path)}');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _audioPlayer?.stop();
      showSnackBar('Playback stopped');
    } catch (e) {
      showSnackBar('Error stopping playback: $e', isError: true);
    }
  }

  Future<void> _translateWav() async {
    if (_isZeroByteFile()) return;
    try {
      showSnackBar('Translation starting... (this may take a while)');

      // Call the translation API
      final translatedWavPath = await NativeService.instance.translateWav(
        file.path,
        'eng', // Target language: English
      );

      onTreeRebuild();
      showSnackBar('Translated to: ${p.basename(translatedWavPath)}');

      // Optionally play the translated audio
      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.play(DeviceFileSource(translatedWavPath));
    } catch (e) {
      showSnackBar('Translation error: $e', isError: true);
    }
  }

  Future<void> _convertWavToScd() async {
    if (_isZeroByteFile()) return;
    try {
      final scdPath = p.join(
        file.parent.path,
        '${p.basenameWithoutExtension(file.path)}.scd',
      );
      await NativeService.instance.convertWavToScd(file.path, scdPath);
      onTreeRebuild();
      showSnackBar('Converted to ${p.basename(scdPath)}');
    } catch (e) {
      showSnackBar('Error: $e', isError: true);
    }
  }
}
