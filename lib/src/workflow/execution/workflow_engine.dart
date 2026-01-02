import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../models/app_game_code.dart';
import '../../../models/workflow/node_status.dart';
import '../../../models/workflow/workflow_models.dart';
import '../../../providers/workflow_provider.dart';
import '../../../src/isar/workflow/workflow_repository.dart';
import 'execution_context.dart';
import 'node_executor.dart';
import 'executors/control_executors.dart';
import 'executors/img_executors.dart';
import 'executors/wbt_executors.dart';
import 'executors/wdb_executors.dart';
import 'executors/wpd_executors.dart';
import 'executors/ztr_executors.dart';

final _logger = Logger('WorkflowEngine');

/// Result of executing a branch in the workflow.
class _BranchResult {
  final bool success;
  final bool cancelled;
  final bool reachedEnd;
  final String? errorMessage;
  final String? stoppedAtJoin;

  _BranchResult({
    required this.success,
    this.cancelled = false,
    this.reachedEnd = false,
    this.errorMessage,
    this.stoppedAtJoin,
  });
}

/// Engine for executing workflows.
class WorkflowEngine {
  final Ref _ref;
  final WorkflowRepository _repo;
  final Map<NodeType, NodeExecutor> _executors = {};

  bool _cancelRequested = false;
  bool _pauseRequested = false;

  WorkflowEngine(this._ref, this._repo) {
    _registerExecutors();
  }

  void _registerExecutors() {
    // Control flow executors
    _executors[NodeType.start] = StartExecutor();
    _executors[NodeType.end] = EndExecutor();
    _executors[NodeType.condition] = ConditionExecutor();
    _executors[NodeType.loop] = LoopExecutor();
    _executors[NodeType.forEach] = ForEachExecutor();
    _executors[NodeType.fork] = ForkExecutor();
    _executors[NodeType.join] = JoinExecutor();

    // Variable executors
    _executors[NodeType.setVariable] = SetVariableExecutor();
    _executors[NodeType.getVariable] = GetVariableExecutor();
    _executors[NodeType.expression] = ExpressionExecutor();

    // WPD executors
    _executors[NodeType.wpdUnpack] = WpdUnpackExecutor();
    _executors[NodeType.wpdRepack] = WpdRepackExecutor();

    // WBT executors
    _executors[NodeType.wbtLoadFileList] = WbtLoadFileListExecutor();
    _executors[NodeType.wbtExtractFiles] = WbtExtractFilesExecutor();
    _executors[NodeType.wbtRepackFiles] = WbtRepackFilesExecutor();

    // IMG executors
    _executors[NodeType.imgExtract] = ImgExtractExecutor();
    _executors[NodeType.imgRepack] = ImgRepackExecutor();

    // WDB executors
    _executors[NodeType.wdbTransform] = WdbTransformExecutor();
    _executors[NodeType.wdbOpen] = WdbOpenExecutor();
    _executors[NodeType.wdbSave] = WdbSaveExecutor();
    _executors[NodeType.wdbFindRecord] = WdbFindRecordExecutor();
    _executors[NodeType.wdbCopyRecord] = WdbCopyRecordExecutor();
    _executors[NodeType.wdbPasteRecord] = WdbPasteRecordExecutor();
    _executors[NodeType.wdbRenameRecord] = WdbRenameRecordExecutor();
    _executors[NodeType.wdbSetField] = WdbSetFieldExecutor();
    _executors[NodeType.wdbDeleteRecord] = WdbDeleteRecordExecutor();
    _executors[NodeType.wdbBulkUpdate] = WdbBulkUpdateExecutor();

    // ZTR executors
    _executors[NodeType.ztrOpen] = ZtrOpenExecutor();
    _executors[NodeType.ztrSave] = ZtrSaveExecutor();
    _executors[NodeType.ztrFindEntry] = ZtrFindEntryExecutor();
    _executors[NodeType.ztrModifyText] = ZtrModifyTextExecutor();
    _executors[NodeType.ztrAddEntry] = ZtrAddEntryExecutor();
    _executors[NodeType.ztrDeleteEntry] = ZtrDeleteEntryExecutor();
  }

  /// Execute a workflow.
  Future<WorkflowExecutionResult> execute(
    Workflow workflow,
    AppGameCode gameCode, {
    bool previewMode = false,
    String? workspaceDir,
    void Function(WorkflowExecutionState)? onStateChange,
  }) async {
    _cancelRequested = false;
    _pauseRequested = false;

    final context = ExecutionContext(
      gameCode: gameCode,
      ref: _ref,
      previewMode: previewMode,
      workspaceDir: workspaceDir,
    );

    // Initialize workflow variables
    for (final variable in workflow.variables.values) {
      context.setVariable(variable.name, variable.defaultValue);
    }

    final startTime = DateTime.now();
    final executionLog = <WorkflowExecutionStep>[];
    int executedCount = 0;

    // Find start node
    final startNode = workflow.entryNode;
    if (startNode == null) {
      return WorkflowExecutionResult(
        success: false,
        errorMessage: 'No Start node found in workflow',
        executionLog: executionLog,
        changes: context.pendingChanges,
      );
    }

    final completedNodes = <String>{};
    final pendingJoinNodes = <String>{};

    _notifyStateChange(
      onStateChange,
      ExecutionStatus.running,
      startNode.id,
      executedCount,
      workflow.nodes.length,
      executionLog,
      context.variables,
      context.pendingChanges,
      startTime,
    );

    try {
      // Execute the workflow using branch-based execution
      final result = await _executeBranch(
        workflow,
        startNode,
        context,
        executionLog,
        completedNodes,
        pendingJoinNodes,
        onStateChange,
        startTime,
      );

      if (result.cancelled || _cancelRequested) {
        return WorkflowExecutionResult(
          success: false,
          cancelled: true,
          errorMessage: 'Workflow cancelled by user',
          executionLog: executionLog,
          changes: context.pendingChanges,
        );
      }

      if (!result.success) {
        return WorkflowExecutionResult(
          success: false,
          errorMessage: result.errorMessage ?? 'Unknown error',
          executionLog: executionLog,
          changes: context.pendingChanges,
        );
      }

      executedCount = completedNodes.length;

      // Log execution to repository
      await _repo.logExecution(
        workflowId: workflow.id,
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        status: 'completed',
        nodesExecuted: executedCount,
        totalNodes: workflow.nodes.length,
      );

      _notifyStateChange(
        onStateChange,
        ExecutionStatus.completed,
        null,
        executedCount,
        workflow.nodes.length,
        executionLog,
        context.variables,
        context.pendingChanges,
        startTime,
      );

      return WorkflowExecutionResult(
        success: true,
        executionLog: executionLog,
        changes: context.pendingChanges,
        variables: Map.from(context.variables),
      );
    } catch (e, stack) {
      _logger.severe('Workflow execution error: $e', e, stack);

      await _repo.logExecution(
        workflowId: workflow.id,
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        status: 'error',
        errorMessage: e.toString(),
        nodesExecuted: executedCount,
        totalNodes: workflow.nodes.length,
      );

      _notifyStateChange(
        onStateChange,
        ExecutionStatus.error,
        null,
        executedCount,
        workflow.nodes.length,
        executionLog,
        context.variables,
        context.pendingChanges,
        startTime,
        errorMessage: e.toString(),
      );

      return WorkflowExecutionResult(
        success: false,
        errorMessage: e.toString(),
        executionLog: executionLog,
        changes: context.pendingChanges,
      );
    }
  }

  /// Find the next node to execute based on connection from a specific port.
  WorkflowNode? _findNextNode(
    Workflow workflow,
    String sourceNodeId,
    String sourcePort,
  ) {
    for (final connection in workflow.connections) {
      if (connection.sourceNodeId == sourceNodeId &&
          connection.sourcePort == sourcePort) {
        return workflow.findNode(connection.targetNodeId);
      }
    }
    return null;
  }

  /// Find ALL next nodes connected to a port (for fork nodes).
  List<WorkflowNode> _findAllNextNodes(
    Workflow workflow,
    String sourceNodeId,
    String sourcePort,
  ) {
    final nodes = <WorkflowNode>[];
    for (final connection in workflow.connections) {
      if (connection.sourceNodeId == sourceNodeId &&
          connection.sourcePort == sourcePort) {
        final node = workflow.findNode(connection.targetNodeId);
        if (node != null) nodes.add(node);
      }
    }
    return nodes;
  }

  /// Check if all input connections to a join node have been satisfied.
  bool _areAllInputsSatisfied(
    Workflow workflow,
    String nodeId,
    Set<String> completedNodes,
  ) {
    final incomingConnections = workflow.findConnectionsTo(nodeId);
    for (final conn in incomingConnections) {
      if (!completedNodes.contains(conn.sourceNodeId)) {
        return false;
      }
    }
    return true;
  }

  /// Execute a parallel branch starting from a node, stopping at join nodes.
  Future<_BranchResult> _executeBranch(
    Workflow workflow,
    WorkflowNode startNode,
    ExecutionContext context,
    List<WorkflowExecutionStep> executionLog,
    Set<String> completedNodes,
    Set<String> pendingJoinNodes,
    void Function(WorkflowExecutionState)? onStateChange,
    DateTime startTime,
  ) async {
    WorkflowNode? currentNode = startNode;

    while (currentNode != null && !_cancelRequested) {
      // Handle pause
      while (_pauseRequested && !_cancelRequested) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (_cancelRequested) {
        return _BranchResult(success: false, cancelled: true);
      }

      // Skip nodes that have already been executed (prevents duplicate execution at joins)
      if (completedNodes.contains(currentNode.id)) {
        // Bug #48 fix: Use the node type's default output port instead of hardcoded 'output'
        final defaultPort = currentNode.type.outputPorts.firstOrNull?.id ?? 'output';
        currentNode = _findNextNode(workflow, currentNode.id, defaultPort);
        continue;
      }

      // If this is a join node, check if we should wait
      if (currentNode.type == NodeType.join) {
        if (!_areAllInputsSatisfied(workflow, currentNode.id, completedNodes)) {
          // Mark this join as pending and stop this branch
          pendingJoinNodes.add(currentNode.id);
          return _BranchResult(success: true, stoppedAtJoin: currentNode.id);
        }
        // Remove from pending since we're about to execute it
        pendingJoinNodes.remove(currentNode.id);
      }

      final step = WorkflowExecutionStep(
        nodeId: currentNode.id,
        nodeName: currentNode.label ?? currentNode.type.displayName,
        startTime: DateTime.now(),
      );

      _logger.info('Executing node: ${currentNode.type.displayName} (${currentNode.id})');

      // Check if this is an immediate node - skip execution during workflow runs
      // Immediate nodes execute in the editor context, not during workflow execution
      if (currentNode.type.executionMode == NodeExecutionMode.immediate) {
        _logger.info('Skipping immediate node during workflow execution: ${currentNode.id}');
        step.success = true;
        step.message = 'Immediate node (executed in editor)';
        step.endTime = DateTime.now();
        executionLog.add(step);
        completedNodes.add(currentNode.id);

        // Bug #49 fix: Use the node type's default output port instead of hardcoded 'output'
        final defaultPort = currentNode.type.outputPorts.firstOrNull?.id ?? 'output';
        currentNode = _findNextNode(workflow, currentNode.id, defaultPort);
        continue;
      }

      // Get executor for this node type
      final executor = _executors[currentNode.type];
      if (executor == null) {
        step.success = false;
        step.message = 'No executor for node type: ${currentNode.type}';
        step.endTime = DateTime.now();
        executionLog.add(step);
        return _BranchResult(
          success: false,
          errorMessage: step.message,
        );
      }

      // Execute the node
      final result = await executor.execute(currentNode, context);

      step.endTime = DateTime.now();
      step.success = result.success;
      step.message = result.logMessage ?? result.errorMessage;
      executionLog.add(step);

      // Mark node as completed
      completedNodes.add(currentNode.id);

      _notifyStateChange(
        onStateChange,
        ExecutionStatus.running,
        currentNode.id,
        completedNodes.length,
        workflow.nodes.length,
        executionLog,
        context.variables,
        context.pendingChanges,
        startTime,
      );

      if (!result.success) {
        return _BranchResult(
          success: false,
          errorMessage: result.errorMessage ?? 'Unknown error',
        );
      }

      // Terminal node (like End)
      if (result.nextPort == null) {
        return _BranchResult(success: true, reachedEnd: true);
      }

      // Bug #5 fix: Handle loop/forEach nodes specially
      // When a loop returns 'body', execute body then return to loop for re-evaluation
      if ((currentNode.type == NodeType.loop || currentNode.type == NodeType.forEach) &&
          result.nextPort == 'body') {
        // Find the body branch start node
        final bodyNode = _findNextNode(workflow, currentNode.id, 'body');

        if (bodyNode != null) {
          // Execute the body branch - but DON'T mark loop as completed yet
          // Remove from completed so we can re-execute it
          completedNodes.remove(currentNode.id);

          // Execute body branch
          final bodyResult = await _executeBranch(
            workflow,
            bodyNode,
            context,
            executionLog,
            completedNodes,
            pendingJoinNodes,
            onStateChange,
            startTime,
          );

          if (!bodyResult.success) {
            return bodyResult;
          }

          // Return to the loop node for next iteration check
          // Don't set currentNode = null, just continue the loop with same node
          continue;
        }

        // No body connected, exit loop
        currentNode = _findNextNode(workflow, currentNode.id, 'done');
        continue;
      }

      // Check if this is a fork node - execute branches in parallel
      if (currentNode.type == NodeType.fork) {
        final nextNodes = _findAllNextNodes(
          workflow,
          currentNode.id,
          result.nextPort!,
        );

        if (nextNodes.isEmpty) {
          return _BranchResult(success: true);
        }

        // Bug #8 fix: Execute all branches in parallel with isolated contexts
        final branchFutures = nextNodes.map((nextNode) {
          // Fork the context for each parallel branch
          final branchContext = context.fork();
          return _executeBranch(
            workflow,
            nextNode,
            branchContext,
            executionLog,
            completedNodes,
            pendingJoinNodes,
            onStateChange,
            startTime,
          ).then((result) => (result: result, context: branchContext));
        });

        final branchResults = await Future.wait(branchFutures);

        // Check if any branch failed and merge contexts
        for (final branchData in branchResults) {
          if (!branchData.result.success) {
            return branchData.result;
          }
          // Merge the branch context back into the main context
          context.merge(branchData.context);
        }

        // Check if we have pending joins that can now proceed
        final joinsToProcess = pendingJoinNodes.where((joinId) {
          return _areAllInputsSatisfied(workflow, joinId, completedNodes);
        }).toList();

        for (final joinId in joinsToProcess) {
          pendingJoinNodes.remove(joinId);
          final joinNode = workflow.findNode(joinId);
          if (joinNode != null) {
            final joinResult = await _executeBranch(
              workflow,
              joinNode,
              context,
              executionLog,
              completedNodes,
              pendingJoinNodes,
              onStateChange,
              startTime,
            );
            if (!joinResult.success) {
              return joinResult;
            }
          }
        }

        return _BranchResult(success: true);
      }

      // Find the next node (linear execution)
      currentNode = _findNextNode(
        workflow,
        currentNode.id,
        result.nextPort!,
      );
    }

    return _BranchResult(success: true);
  }

  /// Request pause.
  void pause() {
    _pauseRequested = true;
  }

  /// Resume from pause.
  void resume() {
    _pauseRequested = false;
  }

  /// Request cancellation.
  void cancel() {
    _cancelRequested = true;
    _pauseRequested = false;
  }

  void _notifyStateChange(
    void Function(WorkflowExecutionState)? callback,
    ExecutionStatus status,
    String? currentNodeId,
    int executedCount,
    int totalCount,
    List<WorkflowExecutionStep> log,
    Map<String, dynamic> variables,
    List<WorkflowChange> changes,
    DateTime startTime, {
    String? errorMessage,
  }) {
    callback?.call(WorkflowExecutionState(
      status: status,
      currentNodeId: currentNodeId,
      executedNodeCount: executedCount,
      totalNodeCount: totalCount,
      executionLog: List.from(log),
      variableValues: Map.from(variables),
      pendingChanges: List.from(changes),
      errorMessage: errorMessage,
      startTime: startTime,
    ));
  }
}

/// Result of workflow execution.
class WorkflowExecutionResult {
  final bool success;
  final bool cancelled;
  final String? errorMessage;
  final List<WorkflowExecutionStep> executionLog;
  final List<WorkflowChange> changes;
  final Map<String, dynamic> variables;

  WorkflowExecutionResult({
    required this.success,
    this.cancelled = false,
    this.errorMessage,
    required this.executionLog,
    required this.changes,
    this.variables = const {},
  });
}

/// Provider for the workflow engine.
final workflowEngineProvider = Provider<WorkflowEngine>((ref) {
  final repo = ref.watch(workflowRepositoryProvider);
  return WorkflowEngine(ref, repo);
});
