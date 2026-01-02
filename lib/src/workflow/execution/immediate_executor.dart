import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../../components/workflow/wbt_file_selector.dart';
import '../../../models/app_game_code.dart';
import '../../../models/workflow/node_status.dart';
import '../../../models/workflow/workflow_models.dart';
import '../../../providers/workflow_provider.dart';
import '../../services/native_service.dart';

final _logger = Logger('ImmediateNodeExecutor');

/// Executor for immediate nodes that run in the editor context.
/// These nodes execute as soon as their configuration is valid,
/// not during workflow execution.
class ImmediateNodeExecutor {
  // Note: Uses WidgetRef since it's only called from widget contexts (property_panel).
  // If background execution is needed, consider passing a ProviderContainer instead.
  final WidgetRef ref;

  ImmediateNodeExecutor(this.ref);

  /// Execute an immediate node based on its type.
  Future<void> executeNode(WorkflowNode node, AppGameCode gameCode) async {
    final notifier = ref.read(workflowEditorProvider.notifier);

    // Set status to executing
    notifier.setImmediateNodeStatus(node.id, NodeExecutionStatus.executing);

    try {
      switch (node.type) {
        case NodeType.wbtLoadFileList:
          await _executeWbtLoadFileList(node, gameCode, notifier);
          break;
        case NodeType.wbtExtractFiles:
          await _executeWbtExtractFiles(node, gameCode, notifier);
          break;
        default:
          throw Exception('Node type ${node.type} is not an immediate node');
      }

      // Set status to success
      notifier.setImmediateNodeStatus(node.id, NodeExecutionStatus.success);
      _logger.info('Immediate node ${node.id} executed successfully');
    } catch (e, stack) {
      // Set status to failure with error message
      notifier.setImmediateNodeStatus(
        node.id,
        NodeExecutionStatus.failure,
        error: e.toString(),
      );
      _logger.severe('Immediate node ${node.id} failed: $e', e, stack);
      rethrow;
    }
  }

  /// Execute a WBT Load File List node.
  /// Loads the file list from the WBT archive and caches it.
  Future<void> _executeWbtLoadFileList(
    WorkflowNode node,
    AppGameCode gameCode,
    WorkflowEditorNotifier notifier,
  ) async {
    final fileListPath = node.config['fileListPath'] as String?;
    final binPath = node.config['binPath'] as String?;

    if (fileListPath == null || fileListPath.isEmpty) {
      throw Exception('File list path is required');
    }
    if (binPath == null || binPath.isEmpty) {
      throw Exception('Container path is required');
    }

    // Resolve paths if workspace is set
    final workspaceDir = ref.read(workflowExecutorProvider).workspaceDir;
    final resolvedFileListPath = _resolvePath(fileListPath, workspaceDir);
    final resolvedBinPath = _resolvePath(binPath, workspaceDir);

    _logger.info('Loading WBT file list: $resolvedFileListPath');

    // Load file list via native service
    final entries = await NativeService.instance.getWbtFileList(
      gameCode,
      resolvedFileListPath,
      resolvedBinPath,
    );

    // Cache the data for downstream nodes
    final data = WbtFileListData(
      fileListPath: resolvedFileListPath,
      binPath: resolvedBinPath,
      entries: entries,
    );
    notifier.setImmediateNodeData(node.id, data);

    _logger.info('Loaded ${entries.length} files from WBT archive');
  }

  /// Execute a WBT Extract Files node.
  /// Extracts selected files from the WBT archive.
  Future<void> _executeWbtExtractFiles(
    WorkflowNode node,
    AppGameCode gameCode,
    WorkflowEditorNotifier notifier,
  ) async {
    final sourceNodeId = node.config['sourceNode'] as String?;
    final selectedFiles = (node.config['selectedFiles'] as List<dynamic>?)
            ?.cast<int>()
            .toList() ??
        [];
    final outputDir = node.config['outputDir'] as String?;

    if (sourceNodeId == null || sourceNodeId.isEmpty) {
      throw Exception('Source node is required');
    }
    if (selectedFiles.isEmpty) {
      throw Exception('No files selected for extraction');
    }
    if (outputDir == null || outputDir.isEmpty) {
      throw Exception('Output directory is required');
    }

    // Get cached data from source node
    final editorState = ref.read(workflowEditorProvider);
    final sourceData = editorState.immediateNodeData[sourceNodeId];

    if (sourceData == null) {
      throw Exception('Source node has not been executed');
    }
    if (sourceData is! WbtFileListData) {
      throw Exception('Invalid source data type');
    }

    // Resolve output path
    final workspaceDir = ref.read(workflowExecutorProvider).workspaceDir;
    final resolvedOutputDir = _resolvePath(outputDir, workspaceDir);

    _logger.info('Extracting ${selectedFiles.length} files to $resolvedOutputDir');

    // Extract files
    final count = await NativeService.instance.extractWbtByIndices(
      gameCode,
      sourceData.fileListPath,
      sourceData.binPath,
      selectedFiles,
      resolvedOutputDir,
    );

    _logger.info('Extracted $count files');
  }

  /// Resolve a path relative to the workspace directory.
  String _resolvePath(String path, String? workspaceDir) {
    if (workspaceDir == null) return path;
    if (path.startsWith('/') || path.contains(':\\')) return path;
    return '$workspaceDir/$path';
  }

}
