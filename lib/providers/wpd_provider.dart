import 'dart:async';
import 'dart:io';

import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart' show Uint64List;
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/providers/app_state_provider.dart';
import 'package:oracle_drive/providers/wbt_provider.dart';
import 'package:oracle_drive/providers/wdb_provider.dart';
import 'package:oracle_drive/src/services/batch_decompilation_service.dart';
import 'package:oracle_drive/src/services/java_decompiler_service.dart';
import 'package:oracle_drive/src/services/native_service.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:fabula_nova_sdk/bridge_generated/modules/wct.dart' as wct_sdk;

final _logger = Logger('WpdProvider');

/// Processing state for batch operations
@immutable
class ProcessingState {
  final bool isProcessing;
  final String message;
  final int processedCount;
  final int totalCount;

  const ProcessingState({
    this.isProcessing = false,
    this.message = '',
    this.processedCount = 0,
    this.totalCount = 0,
  });

  ProcessingState copyWith({
    bool? isProcessing,
    String? message,
    int? processedCount,
    int? totalCount,
  }) {
    return ProcessingState(
      isProcessing: isProcessing ?? this.isProcessing,
      message: message ?? this.message,
      processedCount: processedCount ?? this.processedCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  double get progress => totalCount > 0 ? processedCount / totalCount : 0;
}

/// Archive mode for WBT integration
enum ArchiveMode { none, filelist, whiteBin }

/// State for archive operations (WBT integration)
@immutable
class ArchiveState {
  final ArchiveMode mode;
  final String? fileListPath;
  final String? binPath;
  final List<sdk.WbtFileEntry> fileEntries;
  final WbtTreeNode? rootNode;
  final Set<int> selectedIndices;
  final bool isLoadingFileList;
  final double extractionProgress;
  final String? repackSourceDir;

  const ArchiveState({
    this.mode = ArchiveMode.none,
    this.fileListPath,
    this.binPath,
    this.fileEntries = const [],
    this.rootNode,
    this.selectedIndices = const {},
    this.isLoadingFileList = false,
    this.extractionProgress = 0,
    this.repackSourceDir,
  });

  ArchiveState copyWith({
    ArchiveMode? mode,
    String? fileListPath,
    String? binPath,
    List<sdk.WbtFileEntry>? fileEntries,
    WbtTreeNode? rootNode,
    Set<int>? selectedIndices,
    bool? isLoadingFileList,
    double? extractionProgress,
    String? repackSourceDir,
    bool clearRootNode = false,
  }) {
    return ArchiveState(
      mode: mode ?? this.mode,
      fileListPath: fileListPath ?? this.fileListPath,
      binPath: binPath ?? this.binPath,
      fileEntries: fileEntries ?? this.fileEntries,
      rootNode: clearRootNode ? null : (rootNode ?? this.rootNode),
      selectedIndices: selectedIndices ?? this.selectedIndices,
      isLoadingFileList: isLoadingFileList ?? this.isLoadingFileList,
      extractionProgress: extractionProgress ?? this.extractionProgress,
      repackSourceDir: repackSourceDir ?? this.repackSourceDir,
    );
  }

  bool get isActive => mode != ArchiveMode.none;
  bool get hasFileList => fileListPath != null;
  int get selectedFileCount => selectedIndices.length;
}

/// Main state for the WPD screen
@immutable
class WpdState {
  final String? rootDirPath;
  final FileSystemEntity? selectedNode;
  final ProcessingState processing;
  final ArchiveState archive;

  const WpdState({
    this.rootDirPath,
    this.selectedNode,
    this.processing = const ProcessingState(),
    this.archive = const ArchiveState(),
  });

  WpdState copyWith({
    String? rootDirPath,
    FileSystemEntity? selectedNode,
    ProcessingState? processing,
    ArchiveState? archive,
  }) {
    return WpdState(
      rootDirPath: rootDirPath ?? this.rootDirPath,
      selectedNode: selectedNode ?? this.selectedNode,
      processing: processing ?? this.processing,
      archive: archive ?? this.archive,
    );
  }

  /// Helper getters for the selected node
  bool get hasSelection => selectedNode != null;
  bool get isDirectory => selectedNode is Directory;
  bool get isFile => selectedNode is File;
  String get selectedName => selectedNode != null ? p.basename(selectedNode!.path) : '';
  String get selectedExtension => selectedNode != null ? p.extension(selectedNode!.path).toLowerCase() : '';

  /// Archive detection helpers
  bool get isWhiteBin {
    if (!isFile) return false;
    final name = selectedName.toLowerCase();
    // Must start with 'white_' (underscore) to be a WBT archive
    // This excludes files like 'WhiteBaseClassJar.bin' which are WPD data files
    return name.startsWith('white_') && name.endsWith('.bin') && !name.contains('filelist');
  }

  bool get isFileList {
    if (!isFile) return false;
    final name = selectedName.toLowerCase();
    return name.contains('filelist') && name.endsWith('.bin');
  }

  bool get canEnterArchiveMode => isWhiteBin || isFileList;
}

/// Result of a batch operation
class BatchOperationResult {
  final int successCount;
  final int errorCount;
  final String operationName;

  BatchOperationResult({
    required this.successCount,
    required this.errorCount,
    required this.operationName,
  });
}

/// Provider for WPD state per game
final wpdProvider = StateNotifierProvider.family<WpdNotifier, WpdState, AppGameCode>(
  (ref, gameCode) => WpdNotifier(ref, gameCode),
);

/// Convenience provider for just the processing state
final wpdProcessingProvider = Provider.family<ProcessingState, AppGameCode>((ref, gameCode) {
  return ref.watch(wpdProvider(gameCode)).processing;
});

/// Convenience provider for checking if processing
final wpdIsProcessingProvider = Provider.family<bool, AppGameCode>((ref, gameCode) {
  return ref.watch(wpdProvider(gameCode)).processing.isProcessing;
});

class WpdNotifier extends StateNotifier<WpdState> {
  final Ref _ref;
  final AppGameCode _gameCode;

  WpdNotifier(this._ref, this._gameCode) : super(const WpdState());

  // ============================================================
  // State Management
  // ============================================================

  void setRootDirPath(String? path) {
    state = state.copyWith(
      rootDirPath: path,
      selectedNode: null,
    );
  }

  void setSelectedNode(FileSystemEntity? node) {
    state = state.copyWith(selectedNode: node);
  }

  void _startProcessing(String message, {int totalCount = 1}) {
    state = state.copyWith(
      processing: ProcessingState(
        isProcessing: true,
        message: message,
        processedCount: 0,
        totalCount: totalCount,
      ),
    );
  }

  void _updateProgress(int processedCount, String message) {
    state = state.copyWith(
      processing: state.processing.copyWith(
        processedCount: processedCount,
        message: message,
      ),
    );
  }

  void _stopProcessing() {
    state = state.copyWith(
      processing: const ProcessingState(),
    );
  }

  // ============================================================
  // Archive Operations
  // ============================================================

  Future<void> unpackWpd(File wpdFile) async {
    try {
      _logger.info("Unpacking ${p.basename(wpdFile.path)}...");
      String outputDir = p.join(
        wpdFile.parent.path,
        p.basenameWithoutExtension(wpdFile.path),
      );
      await NativeService.instance.unpackWpd(wpdFile.path, outputDir);
      _logger.info("Unpack finished: $outputDir");
    } catch (e) {
      _logger.severe("Error unpacking WPD: $e");
      rethrow;
    }
  }

  Future<void> repackWpd(Directory dir) async {
    try {
      _logger.info("Repacking ${p.basename(dir.path)}...");
      String outputFile = "${dir.path}.wpd";
      await NativeService.instance.repackWpd(dir.path, outputFile);
      _logger.info("Repack finished: $outputFile");
    } catch (e) {
      _logger.severe("Error repacking WPD: $e");
      rethrow;
    }
  }

  Future<void> unpackBin(File binFile) async {
    try {
      _logger.info("Unpacking .bin: ${binFile.path}");
      String outputDir = p.join(
        binFile.parent.path,
        p.basenameWithoutExtension(binFile.path),
      );
      await NativeService.instance.unpackWpd(binFile.path, outputDir);
      _logger.info("Bin Unpack complete.");
    } catch (e) {
      _logger.severe("Error unpacking bin: $e");
      rethrow;
    }
  }

  // ============================================================
  // Image Operations
  // ============================================================

  Future<void> extractImg(File imgbFile) async {
    try {
      final dir = imgbFile.parent;
      final basename = p.basename(imgbFile.path);
      final headerName = basename.replaceAll('.imgb', '.header');
      final headerFile = File(p.join(dir.path, headerName));

      if (!headerFile.existsSync()) {
        throw Exception("Header file not found: $headerName");
      }

      final outDds = p.join(
        dir.path,
        "${p.basenameWithoutExtension(imgbFile.path)}.dds",
      );

      _logger.info("Extracting IMG: $basename");
      await NativeService.instance.unpackImg(
        headerFile.path,
        imgbFile.path,
        outDds,
      );
      _logger.info("IMG Extracted to $outDds");
    } catch (e) {
      _logger.severe("Error extracting IMG: $e");
      rethrow;
    }
  }

  Future<void> repackImg(File imgbFile, String ddsPath) async {
    try {
      final dir = imgbFile.parent;
      final basename = p.basename(imgbFile.path);
      final headerName = basename.replaceAll('.imgb', '.header');
      final headerFile = File(p.join(dir.path, headerName));

      if (!headerFile.existsSync()) {
        throw Exception("Header file not found: $headerName");
      }

      _logger.info("Repacking IMG from $ddsPath");
      await NativeService.instance.repackImg(
        headerFile.path,
        imgbFile.path,
        ddsPath,
      );
      _logger.info("IMG Repacked.");
    } catch (e) {
      _logger.severe("Error repacking IMG: $e");
      rethrow;
    }
  }

  // ============================================================
  // WCT/CLB Operations
  // ============================================================

  String getActionName(wct_sdk.Action action) {
    switch (action) {
      case wct_sdk.Action.decrypt:
        return 'Decrypt';
      case wct_sdk.Action.encrypt:
        return 'Encrypt';
      case wct_sdk.Action.clbToJava:
        return 'Convert to Java';
      case wct_sdk.Action.javaToClb:
        return 'Convert to CLB';
    }
  }

  Future<void> processWct(
    File file,
    wct_sdk.TargetType target,
    wct_sdk.Action action,
  ) async {
    if (state.processing.isProcessing) return;

    final actionName = getActionName(action);
    _startProcessing('$actionName: ${p.basename(file.path)}');

    try {
      _logger.info("WCT Processing ${file.path} ($action)...");
      await NativeService.instance.processWct(file.path, target, action);
      _logger.info("WCT Operation complete.");
    } catch (e) {
      _logger.severe("Error WCT process: $e");
      rethrow;
    } finally {
      _stopProcessing();
    }
  }

  Future<BatchOperationResult> processBatchWct(
    Directory dir,
    wct_sdk.TargetType target,
    wct_sdk.Action action,
    String extension,
  ) async {
    if (state.processing.isProcessing) {
      return BatchOperationResult(successCount: 0, errorCount: 0, operationName: '');
    }

    final actionName = getActionName(action);
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => p.extension(f.path).toLowerCase() == extension)
        .toList();

    if (files.isEmpty) {
      return BatchOperationResult(
        successCount: 0,
        errorCount: 0,
        operationName: actionName,
      );
    }

    _startProcessing('$actionName: 0/${files.length} files', totalCount: files.length);

    int successCount = 0;
    int errorCount = 0;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      _updateProgress(i + 1, '$actionName: ${i + 1}/${files.length} - ${p.basename(file.path)}');

      try {
        await NativeService.instance.processWct(file.path, target, action);
        successCount++;
      } catch (e) {
        _logger.severe("Error processing ${file.path}: $e");
        errorCount++;
      }
    }

    _stopProcessing();

    return BatchOperationResult(
      successCount: successCount,
      errorCount: errorCount,
      operationName: actionName,
    );
  }

  // ============================================================
  // Java Decompilation
  // ============================================================

  Future<String> decompileClass(File classFile) async {
    if (state.processing.isProcessing) throw Exception('Already processing');

    _startProcessing('Decompiling: ${p.basename(classFile.path)}');

    try {
      final javaFilePath = await JavaDecompilerService.instance.decompileAndSave(
        classFile.path,
      );
      _logger.info("Decompiled to ${p.basename(javaFilePath)}");
      return javaFilePath;
    } finally {
      _stopProcessing();
    }
  }

  Future<BatchDecompilationResult> batchDecompileClbs(
    Directory dir,
    BatchDecompileConfig config,
  ) async {
    if (state.processing.isProcessing) {
      throw Exception('Already processing');
    }

    _startProcessing('Initializing...');

    StreamSubscription<BatchDecompilationProgress>? subscription;

    try {
      subscription = BatchDecompilationService.instance.progressStream.listen(
        (progress) {
          if (mounted) {
            state = state.copyWith(
              processing: ProcessingState(
                isProcessing: true,
                processedCount: progress.processedFiles,
                totalCount: progress.totalFiles,
                message: '${_getStageName(progress.currentStage)}: ${progress.currentFile}',
              ),
            );
          }
        },
      );

      final result = await BatchDecompilationService.instance.decompileGameDirectory(
        gameRootPath: dir.path,
        config: config,
        gameCode: _gameCode,
      );

      return result;
    } finally {
      await subscription?.cancel();
      _stopProcessing();
    }
  }

  String _getStageName(String stage) {
    switch (stage) {
      case 'scanning':
        return 'Scanning';
      case 'unpacking':
        return 'Unpacking';
      case 'decompiling':
        return 'Decompiling';
      case 'complete':
        return 'Complete';
      default:
        return stage;
    }
  }

  // ============================================================
  // Database Integration
  // ============================================================

  Future<int> openInDatabase(File wdbFile) async {
    if (state.processing.isProcessing) throw Exception('Already processing');

    _startProcessing('Loading: ${p.basename(wdbFile.path)}');

    try {
      _logger.info("Opening WDB in Database: ${wdbFile.path}");

      // Set the path
      _ref.read(wdbPathProvider(_gameCode).notifier).state = wdbFile.path;
      _ref.read(wdbIsProcessingProvider(_gameCode).notifier).state = true;
      _ref.read(wdbDataProvider(_gameCode).notifier).state = null;
      _ref.read(wdbFilterProvider(_gameCode).notifier).state = '';

      // Parse the WDB
      final data = await NativeService.instance.parseWdb(wdbFile.path, _gameCode);
      _ref.read(wdbDataProvider(_gameCode).notifier).state = data;

      _logger.info("Parsed ${data.rows.length} records.");

      // Navigate to the Database screen (index 2)
      _ref.read(navigationIndexProvider.notifier).state = 2;

      return data.rows.length;
    } finally {
      _ref.read(wdbIsProcessingProvider(_gameCode).notifier).state = false;
      _stopProcessing();
    }
  }

  // ============================================================
  // Archive Operations (WBT Integration)
  // ============================================================

  /// Enter archive mode with a filelist file
  Future<void> enterArchiveModeWithFileList(String fileListPath) async {
    state = state.copyWith(
      archive: ArchiveState(
        mode: ArchiveMode.filelist,
        fileListPath: fileListPath,
        isLoadingFileList: true,
      ),
    );

    try {
      final entries = await sdk.wbtGetFileList(
        filelistPath: fileListPath,
        gameCode: _gameCode.idx,
      );

      final rootNode = _buildArchiveTree(entries);
      state = state.copyWith(
        archive: state.archive.copyWith(
          fileEntries: entries,
          rootNode: rootNode,
          isLoadingFileList: false,
        ),
      );
      _logger.info("Loaded ${entries.length} file entries from archive");
    } catch (e) {
      _logger.severe("Failed to load file list: $e");
      state = state.copyWith(
        archive: state.archive.copyWith(isLoadingFileList: false),
      );
      rethrow;
    }
  }

  /// Enter archive mode with a white*.bin file (needs filelist)
  Future<void> enterArchiveModeWithWhiteBin(String binPath, String fileListPath) async {
    state = state.copyWith(
      archive: ArchiveState(
        mode: ArchiveMode.whiteBin,
        binPath: binPath,
        fileListPath: fileListPath,
        isLoadingFileList: true,
      ),
    );

    try {
      final entries = await sdk.wbtGetFileList(
        filelistPath: fileListPath,
        gameCode: _gameCode.idx,
      );

      final rootNode = _buildArchiveTree(entries);
      state = state.copyWith(
        archive: state.archive.copyWith(
          fileEntries: entries,
          rootNode: rootNode,
          isLoadingFileList: false,
        ),
      );
      _logger.info("Loaded ${entries.length} file entries for white*.bin");
    } catch (e) {
      _logger.severe("Failed to load file list: $e");
      state = state.copyWith(
        archive: state.archive.copyWith(isLoadingFileList: false),
      );
      rethrow;
    }
  }

  /// Set the content bin path for archive operations
  void setArchiveBinPath(String binPath) {
    state = state.copyWith(
      archive: state.archive.copyWith(binPath: binPath),
    );
  }

  /// Exit archive mode
  void exitArchiveMode() {
    state = state.copyWith(archive: const ArchiveState());
  }

  /// Toggle archive tree node expansion
  void toggleArchiveExpanded(String path) {
    if (state.archive.rootNode == null) return;

    final newRoot = _toggleExpandedRecursive(state.archive.rootNode!, path);
    state = state.copyWith(
      archive: state.archive.copyWith(rootNode: newRoot),
    );
  }

  /// Toggle archive file/directory selection
  void toggleArchiveSelection(String path) {
    if (state.archive.rootNode == null) return;

    final node = _findArchiveNode(state.archive.rootNode!, path);
    if (node == null) return;

    final newSelected = !node.isSelected;
    var newIndices = Set<int>.from(state.archive.selectedIndices);

    if (node.isDirectory) {
      _collectArchiveFileIndices(node, newSelected, newIndices);
    } else if (node.fileIndex != null) {
      if (newSelected) {
        newIndices.add(node.fileIndex!);
      } else {
        newIndices.remove(node.fileIndex!);
      }
    }

    final newRoot = _updateArchiveSelectionRecursive(
      state.archive.rootNode!,
      path,
      newSelected,
      selectChildren: node.isDirectory,
    );

    state = state.copyWith(
      archive: state.archive.copyWith(rootNode: newRoot, selectedIndices: newIndices),
    );
  }

  /// Select all archive files
  void selectAllArchiveFiles() {
    if (state.archive.rootNode == null) return;

    final allIndices = <int>{};
    for (final entry in state.archive.fileEntries) {
      allIndices.add(entry.index.toInt());
    }

    final newRoot = _setArchiveSelectionRecursive(state.archive.rootNode!, true);
    state = state.copyWith(
      archive: state.archive.copyWith(rootNode: newRoot, selectedIndices: allIndices),
    );
  }

  /// Clear all archive selections
  void clearArchiveSelection() {
    if (state.archive.rootNode == null) return;

    final newRoot = _setArchiveSelectionRecursive(state.archive.rootNode!, false);
    state = state.copyWith(
      archive: state.archive.copyWith(rootNode: newRoot, selectedIndices: {}),
    );
  }

  /// Extract all files from archive
  Future<void> extractAllArchiveFiles(String outputDir) async {
    final archive = state.archive;
    if (archive.fileListPath == null || archive.binPath == null) return;

    _startProcessing('Extracting archive...');
    state = state.copyWith(
      archive: archive.copyWith(extractionProgress: 0),
    );

    try {
      await NativeService.instance.unpackWbt(
        _gameCode,
        archive.fileListPath!,
        archive.binPath!,
        outputDir: outputDir,
        onProgress: (p) {
          state = state.copyWith(
            archive: state.archive.copyWith(extractionProgress: p),
          );
        },
      );
      _logger.info("Archive extraction complete.");
    } catch (e) {
      _logger.severe("Archive extraction failed: $e");
      rethrow;
    } finally {
      _stopProcessing();
      state = state.copyWith(
        archive: state.archive.copyWith(extractionProgress: 0),
      );
    }
  }

  /// Extract selected files from archive
  Future<int> extractSelectedArchiveFiles(String outputDir) async {
    final archive = state.archive;
    if (archive.fileListPath == null || archive.binPath == null) return 0;
    if (archive.selectedIndices.isEmpty) return 0;

    _startProcessing('Extracting selected files...');

    try {
      final indices = Uint64List.fromList(
        archive.selectedIndices.toList(),
      );
      final count = await sdk.wbtExtractFilesByIndices(
        filelistPath: archive.fileListPath!,
        containerPath: archive.binPath!,
        indices: indices,
        outputDir: outputDir,
        gameCode: _gameCode.idx,
      );
      _logger.info("Extracted ${count.toInt()} files.");
      return count.toInt();
    } catch (e) {
      _logger.severe("Extraction failed: $e");
      rethrow;
    } finally {
      _stopProcessing();
    }
  }

  /// Extract directory from archive
  Future<int> extractArchiveDirectory(String dirPath, String outputDir) async {
    final archive = state.archive;
    if (archive.fileListPath == null || archive.binPath == null) return 0;

    _startProcessing('Extracting directory...');

    try {
      final count = await sdk.wbtExtractDirectory(
        filelistPath: archive.fileListPath!,
        containerPath: archive.binPath!,
        dirPrefix: dirPath,
        outputDir: outputDir,
        gameCode: _gameCode.idx,
      );
      _logger.info("Extracted ${count.toInt()} files from $dirPath");
      return count.toInt();
    } catch (e) {
      _logger.severe("Directory extraction failed: $e");
      rethrow;
    } finally {
      _stopProcessing();
    }
  }

  /// Repack files into archive
  Future<void> repackArchiveFiles(String sourceDir) async {
    final archive = state.archive;
    if (archive.fileListPath == null || archive.binPath == null) return;

    _startProcessing('Repacking archive...');
    state = state.copyWith(
      archive: archive.copyWith(repackSourceDir: sourceDir),
    );

    try {
      _logger.info("Repacking from $sourceDir for game ${_gameCode.displayName}...");
      await NativeService.instance.repackMultipleWbt(
        _gameCode,
        archive.fileListPath!,
        archive.binPath!,
        sourceDir,
      );
      _logger.info("Repack complete. Backup created.");
    } catch (e) {
      _logger.severe("Repack failed: $e");
      rethrow;
    } finally {
      _stopProcessing();
    }
  }

  // ============================================================
  // Archive Tree Helper Methods
  // ============================================================

  WbtTreeNode _buildArchiveTree(List<sdk.WbtFileEntry> entries) {
    final root = WbtTreeNode(
      name: 'root',
      fullPath: '',
      isDirectory: true,
    );

    for (final entry in entries) {
      final path = entry.path.replaceAll('\\', '/');
      final parts = path.split('/').where((p) => p.isNotEmpty).toList();

      var currentNode = root;
      var currentPath = '';

      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        currentPath = currentPath.isEmpty ? part : '$currentPath/$part';
        final isLast = i == parts.length - 1;

        var childNode = currentNode.children.cast<WbtTreeNode?>().firstWhere(
          (child) => child!.name == part,
          orElse: () => null,
        );

        if (childNode == null) {
          childNode = WbtTreeNode(
            name: part,
            fullPath: currentPath,
            isDirectory: !isLast,
            fileIndex: isLast ? entry.index.toInt() : null,
            uncompressedSize: isLast ? entry.uncompressedSize : null,
            compressedSize: isLast ? entry.compressedSize : null,
          );
          currentNode.children.add(childNode);
        }

        currentNode = childNode;
      }
    }

    _sortArchiveTree(root);
    return root;
  }

  void _sortArchiveTree(WbtTreeNode node) {
    node.children.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    for (final child in node.children) {
      _sortArchiveTree(child);
    }
  }

  WbtTreeNode _toggleExpandedRecursive(WbtTreeNode node, String targetPath) {
    if (node.fullPath == targetPath) {
      return node.copyWith(isExpanded: !node.isExpanded);
    }

    if (!node.isDirectory) return node;

    final newChildren = node.children
        .map((child) => _toggleExpandedRecursive(child, targetPath))
        .toList();

    return node.copyWith(children: newChildren);
  }

  WbtTreeNode? _findArchiveNode(WbtTreeNode node, String path) {
    if (node.fullPath == path) return node;
    for (final child in node.children) {
      final found = _findArchiveNode(child, path);
      if (found != null) return found;
    }
    return null;
  }

  void _collectArchiveFileIndices(WbtTreeNode node, bool select, Set<int> indices) {
    if (!node.isDirectory && node.fileIndex != null) {
      if (select) {
        indices.add(node.fileIndex!);
      } else {
        indices.remove(node.fileIndex!);
      }
    }
    for (final child in node.children) {
      _collectArchiveFileIndices(child, select, indices);
    }
  }

  WbtTreeNode _updateArchiveSelectionRecursive(
    WbtTreeNode node,
    String targetPath,
    bool selected, {
    bool selectChildren = false,
  }) {
    if (node.fullPath == targetPath) {
      if (selectChildren && node.isDirectory) {
        final newChildren = node.children
            .map((child) => _setArchiveSelectionRecursive(child, selected))
            .toList();
        return node.copyWith(isSelected: selected, children: newChildren);
      }
      return node.copyWith(isSelected: selected);
    }

    if (!node.isDirectory) return node;

    final newChildren = node.children
        .map((child) => _updateArchiveSelectionRecursive(
              child,
              targetPath,
              selected,
              selectChildren: selectChildren,
            ))
        .toList();

    return node.copyWith(children: newChildren);
  }

  WbtTreeNode _setArchiveSelectionRecursive(WbtTreeNode node, bool selected) {
    final newChildren = node.children
        .map((child) => _setArchiveSelectionRecursive(child, selected))
        .toList();
    return node.copyWith(isSelected: selected, children: newChildren);
  }
}
