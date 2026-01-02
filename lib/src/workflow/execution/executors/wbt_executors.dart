import 'dart:io';

import '../../../../models/workflow/workflow_models.dart';
import '../../../../providers/workflow_provider.dart';
import '../../../services/native_service.dart';
import '../execution_context.dart';
import '../node_executor.dart';

/// Executor for WBT Load File List nodes.
/// Loads the file list from a WBT archive and stores it in the context.
class WbtLoadFileListExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final fileListPath = node.config['fileListPath']?.toString() ?? '';
    final binPath = node.config['binPath']?.toString() ?? '';

    if (fileListPath.isEmpty) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'File list path is required',
      );
    }

    if (binPath.isEmpty) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'Container path is required',
      );
    }

    final resolvedFileListPath = context.resolvePath(fileListPath);
    final resolvedBinPath = context.resolvePath(binPath);

    try {
      final entries = await NativeService.instance.getWbtFileList(
        context.gameCode,
        resolvedFileListPath,
        resolvedBinPath,
      );

      // Store in context for downstream nodes
      context.setVariable('${node.id}_entries', entries);
      context.setVariable('${node.id}_fileListPath', resolvedFileListPath);
      context.setVariable('${node.id}_binPath', resolvedBinPath);
      context.setVariable('${node.id}_count', entries.length);

      return NodeExecutionResult(
        success: true,
        outputValue: entries,
        logMessage: 'Loaded ${entries.length} files from WBT archive',
      );
    } catch (e) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'Failed to load WBT file list: $e',
      );
    }
  }
}

/// Executor for WBT Extract Files nodes.
/// Extracts selected files from a WBT archive.
class WbtExtractFilesExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final sourceNodeId = node.config['sourceNode'] as String?;
    final selectedFiles = (node.config['selectedFiles'] as List<dynamic>?)
            ?.cast<int>()
            .toList() ??
        [];
    final outputDir = node.config['outputDir']?.toString() ?? '';

    if (sourceNodeId == null || sourceNodeId.isEmpty) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'Source node is required',
      );
    }

    if (selectedFiles.isEmpty) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'No files selected for extraction',
      );
    }

    if (outputDir.isEmpty) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'Output directory is required',
      );
    }

    // Get paths from source node
    final fileListPath = context.getVariable('${sourceNodeId}_fileListPath');
    final binPath = context.getVariable('${sourceNodeId}_binPath');

    if (fileListPath == null || binPath == null) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'Source node has not been executed or data not found',
      );
    }

    final resolvedOutputDir = context.resolvePath(outputDir);

    // Bug #40 fix: Add preview mode check
    if (context.previewMode) {
      context.addChange(WbtChange(
        type: 'extract',
        fileListPath: fileListPath.toString(),
        binPath: binPath.toString(),
        outputPath: resolvedOutputDir,
        fileCount: selectedFiles.length,
      ));
      return NodeExecutionResult(
        success: true,
        outputValue: selectedFiles.length,
        logMessage: 'Would extract ${selectedFiles.length} files to $resolvedOutputDir',
      );
    }

    try {
      final count = await NativeService.instance.extractWbtByIndices(
        context.gameCode,
        fileListPath.toString(),
        binPath.toString(),
        selectedFiles,
        resolvedOutputDir,
      );

      // Store the output directory for downstream nodes
      context.setVariable('${node.id}_outputDir', resolvedOutputDir);
      context.setVariable('${node.id}_extractedCount', count);

      return NodeExecutionResult(
        success: true,
        outputValue: count,
        logMessage: 'Extracted $count files to $resolvedOutputDir',
      );
    } catch (e) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'Failed to extract files: $e',
      );
    }
  }
}

/// Executor for WBT Repack Files nodes.
/// Repacks modified files back into a WBT archive.
/// Supports three modes: directory (all files), single file, or multiple files.
class WbtRepackFilesExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final fileListPath = node.config['fileListPath']?.toString() ?? '';
    final binPath = node.config['binPath']?.toString() ?? '';
    final repackMode = node.config['repackMode']?.toString() ?? 'directory';

    if (fileListPath.isEmpty) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'File list path is required',
      );
    }

    if (binPath.isEmpty) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'Container path is required',
      );
    }

    final resolvedFileListPath = context.resolvePath(fileListPath);
    final resolvedBinPath = context.resolvePath(binPath);

    // Validate that files exist
    final fileListFile = File(resolvedFileListPath);
    final binFile = File(resolvedBinPath);

    if (!fileListFile.existsSync()) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'File list not found: $resolvedFileListPath',
      );
    }

    if (!binFile.existsSync()) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'Container file not found: $resolvedBinPath',
      );
    }

    // Validate that paths aren't swapped (file list should be smaller than container)
    final fileListSize = fileListFile.lengthSync();
    final binSize = binFile.lengthSync();
    if (fileListSize > binSize) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'File list ($fileListSize bytes) is larger than container ($binSize bytes). '
            'Are the paths swapped? File list should be the smaller file (e.g., white_img.win32.bin), '
            'container should be the larger file (e.g., _white_img.win32.bin with underscore prefix).',
      );
    }

    // Bug #40 fix: Add preview mode check
    if (context.previewMode) {
      context.addChange(WbtChange(
        type: 'repack',
        fileListPath: resolvedFileListPath,
        binPath: resolvedBinPath,
      ));
      return NodeExecutionResult(
        success: true,
        logMessage: 'Would repack WBT archive ($repackMode mode): $resolvedBinPath',
      );
    }

    try {
      switch (repackMode) {
        case 'directory':
          return await _repackDirectory(node, context, resolvedFileListPath, resolvedBinPath);
        case 'single':
          return await _repackSingle(node, context, resolvedFileListPath, resolvedBinPath);
        case 'multiple':
          return await _repackMultiple(node, context, resolvedFileListPath, resolvedBinPath);
        default:
          return NodeExecutionResult(
            success: false,
            errorMessage: 'Unknown repack mode: $repackMode',
          );
      }
    } catch (e) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'Failed to repack WBT: $e',
      );
    }
  }

  /// Repack all files from a directory.
  Future<NodeExecutionResult> _repackDirectory(
    WorkflowNode node,
    ExecutionContext context,
    String fileListPath,
    String binPath,
  ) async {
    final inputDir = node.config['inputDir']?.toString() ?? '';

    if (inputDir.isEmpty) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'Input directory is required for directory mode',
      );
    }

    final resolvedInputDir = context.resolvePath(inputDir);

    await NativeService.instance.repackWbtAll(
      context.gameCode,
      fileListPath,
      binPath,
      resolvedInputDir,
    );

    context.setVariable('${node.id}_fileListPath', fileListPath);
    context.setVariable('${node.id}_binPath', binPath);

    return NodeExecutionResult(
      success: true,
      logMessage: 'Repacked WBT archive from directory: $resolvedInputDir',
    );
  }

  /// Repack a single file into the archive.
  Future<NodeExecutionResult> _repackSingle(
    WorkflowNode node,
    ExecutionContext context,
    String fileListPath,
    String binPath,
  ) async {
    final targetPathInArchive = node.config['targetPathInArchive']?.toString() ?? '';
    final fileToInject = node.config['fileToInject']?.toString() ?? '';

    if (targetPathInArchive.isEmpty) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'Target path in archive is required for single file mode',
      );
    }

    if (fileToInject.isEmpty) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'File to inject is required for single file mode',
      );
    }

    final resolvedFileToInject = context.resolvePath(fileToInject);

    await NativeService.instance.repackWbtSingle(
      context.gameCode,
      fileListPath,
      binPath,
      targetPathInArchive,
      resolvedFileToInject,
    );

    context.setVariable('${node.id}_fileListPath', fileListPath);
    context.setVariable('${node.id}_binPath', binPath);

    return NodeExecutionResult(
      success: true,
      logMessage: 'Injected $resolvedFileToInject at $targetPathInArchive',
    );
  }

  /// Repack multiple files into the archive.
  Future<NodeExecutionResult> _repackMultiple(
    WorkflowNode node,
    ExecutionContext context,
    String fileListPath,
    String binPath,
  ) async {
    final fileMappings = node.config['fileMappings']?.toString() ?? '';

    if (fileMappings.isEmpty) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'File mappings are required for multiple files mode',
      );
    }

    // Parse the file mappings (format: archivePath:localPath,archivePath:localPath,...)
    final List<(String, String)> filesToPatch = [];
    final mappings = fileMappings.split(',');

    for (final mapping in mappings) {
      final trimmed = mapping.trim();
      if (trimmed.isEmpty) continue;

      final parts = trimmed.split(':');
      if (parts.length != 2) {
        return NodeExecutionResult(
          success: false,
          errorMessage: 'Invalid mapping format: $trimmed (expected archivePath:localPath)',
        );
      }

      final archivePath = parts[0].trim();
      final localPath = context.resolvePath(parts[1].trim());
      filesToPatch.add((archivePath, localPath));
    }

    if (filesToPatch.isEmpty) {
      return NodeExecutionResult(
        success: false,
        errorMessage: 'No valid file mappings provided',
      );
    }

    await NativeService.instance.repackWbtMultiple(
      context.gameCode,
      fileListPath,
      binPath,
      filesToPatch,
    );

    context.setVariable('${node.id}_fileListPath', fileListPath);
    context.setVariable('${node.id}_binPath', binPath);

    return NodeExecutionResult(
      success: true,
      logMessage: 'Injected ${filesToPatch.length} files into WBT archive',
    );
  }
}
