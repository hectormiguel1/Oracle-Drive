import 'package:logging/logging.dart';

import '../../../models/app_game_code.dart';
import '../../../models/workflow/node_status.dart';
import '../../../models/workflow/workflow_models.dart';
import '../services/file_service.dart';
import '../utils/path_resolver.dart';

final _logger = Logger('ImmediateNodeExecutorV2');

/// Data from loading a WBT file list.
class WbtFileListResult {
  final String fileListPath;
  final String binPath;
  final List<String> entries;

  const WbtFileListResult({
    required this.fileListPath,
    required this.binPath,
    required this.entries,
  });
}

/// Result of immediate node execution.
class ImmediateExecutionResult {
  final bool success;
  final NodeExecutionStatus status;
  final dynamic data;
  final String? errorMessage;

  const ImmediateExecutionResult({
    required this.success,
    required this.status,
    this.data,
    this.errorMessage,
  });

  factory ImmediateExecutionResult.success(dynamic data) {
    return ImmediateExecutionResult(
      success: true,
      status: NodeExecutionStatus.success,
      data: data,
    );
  }

  factory ImmediateExecutionResult.failure(String error) {
    return ImmediateExecutionResult(
      success: false,
      status: NodeExecutionStatus.failure,
      errorMessage: error,
    );
  }
}

/// Callbacks for immediate execution state changes.
abstract class ImmediateExecutionCallbacks {
  void onStatusChanged(String nodeId, NodeExecutionStatus status, {String? error});
  void onDataProduced(String nodeId, dynamic data);
  dynamic getNodeData(String sourceNodeId);
}

/// Decoupled executor for immediate nodes.
///
/// This version doesn't depend on WidgetRef and can be used in
/// any context (including tests and background execution).
class ImmediateNodeExecutorV2 {
  final IArchiveService _archiveService;
  final PathResolver _pathResolver;

  ImmediateNodeExecutorV2({
    required IArchiveService archiveService,
    required PathResolver pathResolver,
  })  : _archiveService = archiveService,
        _pathResolver = pathResolver;

  /// Execute an immediate node.
  Future<ImmediateExecutionResult> executeNode(
    WorkflowNode node,
    AppGameCode gameCode,
    ImmediateExecutionCallbacks callbacks,
  ) async {
    callbacks.onStatusChanged(node.id, NodeExecutionStatus.executing);

    try {
      final result = await _executeNodeInternal(node, gameCode, callbacks);

      if (result.success) {
        callbacks.onStatusChanged(node.id, NodeExecutionStatus.success);
        if (result.data != null) {
          callbacks.onDataProduced(node.id, result.data);
        }
        _logger.info('Immediate node ${node.id} executed successfully');
      } else {
        callbacks.onStatusChanged(
          node.id,
          NodeExecutionStatus.failure,
          error: result.errorMessage,
        );
        _logger.warning('Immediate node ${node.id} failed: ${result.errorMessage}');
      }

      return result;
    } catch (e, stack) {
      final error = e.toString();
      callbacks.onStatusChanged(
        node.id,
        NodeExecutionStatus.failure,
        error: error,
      );
      _logger.severe('Immediate node ${node.id} failed: $e', e, stack);
      return ImmediateExecutionResult.failure(error);
    }
  }

  Future<ImmediateExecutionResult> _executeNodeInternal(
    WorkflowNode node,
    AppGameCode gameCode,
    ImmediateExecutionCallbacks callbacks,
  ) async {
    switch (node.type) {
      case NodeType.wbtLoadFileList:
        return _executeWbtLoadFileList(node, gameCode);
      case NodeType.wbtExtractFiles:
        return _executeWbtExtractFiles(node, gameCode, callbacks);
      default:
        return ImmediateExecutionResult.failure(
          'Node type ${node.type} is not an immediate node',
        );
    }
  }

  Future<ImmediateExecutionResult> _executeWbtLoadFileList(
    WorkflowNode node,
    AppGameCode gameCode,
  ) async {
    final fileListPath = node.config['fileListPath'] as String?;
    final binPath = node.config['binPath'] as String?;

    if (fileListPath == null || fileListPath.isEmpty) {
      return ImmediateExecutionResult.failure('File list path is required');
    }
    if (binPath == null || binPath.isEmpty) {
      return ImmediateExecutionResult.failure('Container path is required');
    }

    final resolvedFileListPath = _pathResolver.resolve(fileListPath);
    final resolvedBinPath = _pathResolver.resolve(binPath);

    _logger.info('Loading WBT file list: $resolvedFileListPath');

    final entries = await _archiveService.loadWbtFileList(
      gameCode,
      resolvedFileListPath,
      resolvedBinPath,
    );

    final data = WbtFileListResult(
      fileListPath: resolvedFileListPath,
      binPath: resolvedBinPath,
      entries: entries,
    );

    _logger.info('Loaded ${entries.length} files from WBT archive');

    return ImmediateExecutionResult.success(data);
  }

  Future<ImmediateExecutionResult> _executeWbtExtractFiles(
    WorkflowNode node,
    AppGameCode gameCode,
    ImmediateExecutionCallbacks callbacks,
  ) async {
    final sourceNodeId = node.config['sourceNode'] as String?;
    final selectedFiles = (node.config['selectedFiles'] as List<dynamic>?)
            ?.cast<int>()
            .toList() ??
        [];
    final outputDir = node.config['outputDir'] as String?;

    if (sourceNodeId == null || sourceNodeId.isEmpty) {
      return ImmediateExecutionResult.failure('Source node is required');
    }
    if (selectedFiles.isEmpty) {
      return ImmediateExecutionResult.failure('No files selected for extraction');
    }
    if (outputDir == null || outputDir.isEmpty) {
      return ImmediateExecutionResult.failure('Output directory is required');
    }

    final sourceData = callbacks.getNodeData(sourceNodeId);
    if (sourceData == null) {
      return ImmediateExecutionResult.failure('Source node has not been executed');
    }
    if (sourceData is! WbtFileListResult) {
      return ImmediateExecutionResult.failure('Invalid source data type');
    }

    final resolvedOutputDir = _pathResolver.resolve(outputDir);

    _logger.info('Extracting ${selectedFiles.length} files to $resolvedOutputDir');

    final count = await _archiveService.extractWbtByIndices(
      gameCode,
      sourceData.fileListPath,
      sourceData.binPath,
      selectedFiles,
      resolvedOutputDir,
    );

    _logger.info('Extracted $count files');

    return ImmediateExecutionResult.success(count);
  }
}
