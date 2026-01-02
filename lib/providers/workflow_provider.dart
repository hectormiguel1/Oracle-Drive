import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import '../models/app_game_code.dart';
import '../models/workflow/node_status.dart';
import '../models/workflow/workflow_models.dart';
import '../providers/settings_provider.dart';
import '../src/isar/workflow/workflow_repository.dart';
import '../src/isar/workflow/workflow_schemas.dart';
import '../src/workflow/execution/workflow_engine.dart';

import '../models/wdb_model.dart';
import '../src/services/native_service.dart';

final _logger = Logger('WorkflowProvider');

// ============================================================
// Database Provider
// ============================================================

final _workflowDatabaseProvider = Provider<Isar>((ref) {
  final db = Isar.open(
    schemas: workflowSchemas,
    directory: './',
    inspector: false,
    name: 'workflows',
  );
  ref.onDispose(() => db.close());
  return db;
});

final workflowRepositoryProvider = Provider<WorkflowRepository>((ref) {
  final db = ref.watch(_workflowDatabaseProvider);
  return WorkflowRepository(db);
});

// ============================================================
// Workflow List Provider
// ============================================================

final workflowListProvider =
    FutureProvider.family<List<Workflow>, AppGameCode?>((ref, gameCode) async {
      final repo = ref.watch(workflowRepositoryProvider);
      if (gameCode != null) {
        return repo.getAllWorkflows(gameCode);
      }
      return repo.getAllWorkflowsAllGames();
    });

// ============================================================
// Workflow Editor State
// ============================================================

class WorkflowEditorState {
  final Workflow? workflow;
  final String? selectedNodeId;
  final Set<String> selectedNodeIds;
  final String? connectingFromNodeId;
  final String? connectingFromPort;
  final Offset canvasOffset;
  final double canvasScale;
  final bool isDirty;
  final List<Workflow> undoStack;
  final int undoIndex;

  /// Status of immediate nodes (executed in editor, not during workflow run).
  final Map<String, NodeExecutionStatus> immediateNodeStatuses;

  /// Error messages for immediate nodes that failed.
  final Map<String, String> immediateNodeErrors;

  /// Cached data from immediate node executions (e.g., loaded WBT file lists).
  final Map<String, dynamic> immediateNodeData;

  /// Actual rendered positions of port circles (for accurate connection drawing).
  /// Key format: "nodeId:portId:isInput" (e.g., "node123:output:false")
  final Map<String, Offset> portPositions;

  const WorkflowEditorState({
    this.workflow,
    this.selectedNodeId,
    this.selectedNodeIds = const {},
    this.connectingFromNodeId,
    this.connectingFromPort,
    this.canvasOffset = Offset.zero,
    this.canvasScale = 1.0,
    this.isDirty = false,
    this.undoStack = const [],
    this.undoIndex = -1,
    this.immediateNodeStatuses = const {},
    this.immediateNodeErrors = const {},
    this.immediateNodeData = const {},
    this.portPositions = const {},
  });

  WorkflowEditorState copyWith({
    Workflow? workflow,
    String? selectedNodeId,
    Set<String>? selectedNodeIds,
    String? connectingFromNodeId,
    String? connectingFromPort,
    Offset? canvasOffset,
    double? canvasScale,
    bool? isDirty,
    List<Workflow>? undoStack,
    int? undoIndex,
    Map<String, NodeExecutionStatus>? immediateNodeStatuses,
    Map<String, String>? immediateNodeErrors,
    Map<String, dynamic>? immediateNodeData,
    Map<String, Offset>? portPositions,
    bool clearSelectedNode = false,
    bool clearConnecting = false,
  }) {
    return WorkflowEditorState(
      workflow: workflow ?? this.workflow,
      selectedNodeId: clearSelectedNode
          ? null
          : (selectedNodeId ?? this.selectedNodeId),
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      connectingFromNodeId: clearConnecting
          ? null
          : (connectingFromNodeId ?? this.connectingFromNodeId),
      connectingFromPort: clearConnecting
          ? null
          : (connectingFromPort ?? this.connectingFromPort),
      canvasOffset: canvasOffset ?? this.canvasOffset,
      canvasScale: canvasScale ?? this.canvasScale,
      isDirty: isDirty ?? this.isDirty,
      undoStack: undoStack ?? this.undoStack,
      undoIndex: undoIndex ?? this.undoIndex,
      immediateNodeStatuses: immediateNodeStatuses ?? this.immediateNodeStatuses,
      immediateNodeErrors: immediateNodeErrors ?? this.immediateNodeErrors,
      immediateNodeData: immediateNodeData ?? this.immediateNodeData,
      portPositions: portPositions ?? this.portPositions,
    );
  }

  bool get canUndo => undoIndex > 0;
  bool get canRedo => undoIndex < undoStack.length - 1;
  bool get isConnecting => connectingFromNodeId != null;

  WorkflowNode? get selectedNode {
    if (workflow == null || selectedNodeId == null) return null;
    return workflow!.findNode(selectedNodeId!);
  }
}

final workflowEditorProvider =
    StateNotifierProvider<WorkflowEditorNotifier, WorkflowEditorState>((ref) {
      return WorkflowEditorNotifier(ref);
    });

class WorkflowEditorNotifier extends StateNotifier<WorkflowEditorState> {
  final Ref _ref;
  static const _uuid = Uuid();
  static const int _maxUndoSteps = 50;

  WorkflowEditorNotifier(this._ref) : super(const WorkflowEditorState());

  WorkflowRepository get _repo => _ref.read(workflowRepositoryProvider);

  /// Get the default workspace path for a game code from settings.
  String? _getDefaultWorkspace(AppGameCode gameCode) {
    final settings = _ref.read(settingsNotifierProvider);
    switch (gameCode) {
      case AppGameCode.ff13_1:
        return settings.defaultWorkspaceFf13;
      case AppGameCode.ff13_2:
        return settings.defaultWorkspaceFf132;
      case AppGameCode.ff13_lr:
        return settings.defaultWorkspaceFf13Lr;
    }
  }

  // -------------------- Workflow Operations --------------------

  void createNew(String name, AppGameCode gameCode) {
    final workflow = Workflow.create(name: name, gameCode: gameCode);
    // Use default workspace from settings for new workflows
    workflow.workspacePath = _getDefaultWorkspace(gameCode);
    state = WorkflowEditorState(
      workflow: workflow,
      isDirty: true,
      undoStack: [workflow.copy()],
      undoIndex: 0,
    );
    // Sync workspace to executor provider so immediate nodes can access it
    _ref.read(workflowExecutorProvider.notifier).setWorkspaceDir(workflow.workspacePath);
    _logger.info('Created new workflow: $name (workspace: ${workflow.workspacePath})');
  }

  Future<void> load(String workflowId) async {
    final workflow = await _repo.getWorkflow(workflowId);
    if (workflow != null) {
      // If workflow doesn't have a workspace path, use default from settings
      if (workflow.workspacePath == null || workflow.workspacePath!.isEmpty) {
        workflow.workspacePath = _getDefaultWorkspace(workflow.gameCode);
        _logger.info('Using default workspace for workflow: ${workflow.workspacePath}');
      }
      state = WorkflowEditorState(
        workflow: workflow,
        isDirty: false,
        undoStack: [workflow.copy()],
        undoIndex: 0,
      );
      // Sync workspace to executor provider so immediate nodes can access it
      _ref.read(workflowExecutorProvider.notifier).setWorkspaceDir(workflow.workspacePath);
      _logger.info('Loaded workflow: ${workflow.name}');
    }
  }

  Future<void> save() async {
    final workflow = state.workflow;
    if (workflow == null) return;

    workflow.modifiedAt = DateTime.now();
    await _repo.saveWorkflow(workflow);
    state = state.copyWith(isDirty: false);
    _ref.invalidate(workflowListProvider);
    _logger.info('Saved workflow: ${workflow.name}');
  }

  Future<void> close() async {
    // Bug #45 fix: Also reset the executor state when closing
    _ref.read(workflowExecutorProvider.notifier).reset();
    state = const WorkflowEditorState();
  }

  void setName(String name) {
    final workflow = state.workflow;
    if (workflow == null) return;
    workflow.name = name;
    _markDirty();
  }

  void setDescription(String description) {
    final workflow = state.workflow;
    if (workflow == null) return;
    workflow.description = description;
    _markDirty();
  }

  /// Bug #32 fix: Set the workspace path on the workflow.
  /// This is persisted with the workflow in the database.
  void setWorkspacePath(String? path) {
    final workflow = state.workflow;
    if (workflow == null) return;
    workflow.workspacePath = path;
    _markDirty();
  }

  // -------------------- Node Operations --------------------

  void addNode(NodeType type, Offset position) {
    final workflow = state.workflow;
    if (workflow == null) return;

    final node = WorkflowNode(id: _uuid.v4(), type: type, position: position);

    workflow.addNode(node);
    _pushUndo();
    state = state.copyWith(
      workflow: workflow,
      selectedNodeId: node.id,
      isDirty: true,
    );
    _logger.info('Added node: ${type.displayName}');
  }

  void removeNode(String nodeId) {
    final workflow = state.workflow;
    if (workflow == null) return;

    workflow.removeNode(nodeId);
    _pushUndo();
    state = state.copyWith(
      workflow: workflow,
      selectedNodeId: state.selectedNodeId == nodeId
          ? null
          : state.selectedNodeId,
      isDirty: true,
      clearSelectedNode: state.selectedNodeId == nodeId,
    );
    _logger.info('Removed node: $nodeId');
  }

  void updateNodePosition(String nodeId, Offset position) {
    final workflow = state.workflow;
    if (workflow == null) return;

    final node = workflow.findNode(nodeId);
    if (node == null) return;

    node.position = position;
    workflow.modifiedAt = DateTime.now();
    state = state.copyWith(workflow: workflow, isDirty: true);
  }

  void updateNodeConfig(String nodeId, Map<String, dynamic> config) {
    final workflow = state.workflow;
    if (workflow == null) return;

    final node = workflow.findNode(nodeId);
    if (node == null) return;

    node.config = config;
    _pushUndo();
    state = state.copyWith(workflow: workflow, isDirty: true);
    _logger.info('Updated config for node: $nodeId');
  }

  void updateNodeLabel(String nodeId, String? label) {
    final workflow = state.workflow;
    if (workflow == null) return;

    final node = workflow.findNode(nodeId);
    if (node == null) return;

    node.label = label;
    _pushUndo();
    state = state.copyWith(workflow: workflow, isDirty: true);
  }

  void selectNode(String? nodeId) {
    state = state.copyWith(
      selectedNodeId: nodeId,
      clearSelectedNode: nodeId == null,
    );
  }

  void selectMultipleNodes(Set<String> nodeIds) {
    state = state.copyWith(selectedNodeIds: nodeIds);
  }

  void duplicateNode(String nodeId) {
    final workflow = state.workflow;
    if (workflow == null) return;

    final sourceNode = workflow.findNode(nodeId);
    if (sourceNode == null) return;

    final newNode = sourceNode.copyWith(
      id: _uuid.v4(),
      position: sourceNode.position + const Offset(50, 50),
    );

    workflow.addNode(newNode);

    // Check for fork/join connections to preserve
    final incomingConnections = workflow.findConnectionsTo(nodeId);
    final outgoingConnections = workflow.findConnectionsFrom(nodeId);

    for (final conn in incomingConnections) {
      final sourceNodeType = workflow.findNode(conn.sourceNodeId)?.type;
      // If connected from a fork, also connect the new node to the fork
      if (sourceNodeType == NodeType.fork) {
        final newConnection = WorkflowConnection(
          id: WorkflowConnection.createId(
            conn.sourceNodeId,
            conn.sourcePort,
            newNode.id,
            conn.targetPort,
          ),
          sourceNodeId: conn.sourceNodeId,
          sourcePort: conn.sourcePort,
          targetNodeId: newNode.id,
          targetPort: conn.targetPort,
        );
        // Bug #14 fix: Check if equivalent connection already exists
        final exists = workflow.connections.any((c) =>
            c.sourceNodeId == newConnection.sourceNodeId &&
            c.sourcePort == newConnection.sourcePort &&
            c.targetNodeId == newConnection.targetNodeId &&
            c.targetPort == newConnection.targetPort);
        if (!exists) {
          workflow.connections.add(newConnection);
        }
      }
    }

    for (final conn in outgoingConnections) {
      final targetNodeType = workflow.findNode(conn.targetNodeId)?.type;
      // If connected to a join, also connect the new node to the join
      if (targetNodeType == NodeType.join) {
        final newConnection = WorkflowConnection(
          id: WorkflowConnection.createId(
            newNode.id,
            conn.sourcePort,
            conn.targetNodeId,
            conn.targetPort,
          ),
          sourceNodeId: newNode.id,
          sourcePort: conn.sourcePort,
          targetNodeId: conn.targetNodeId,
          targetPort: conn.targetPort,
        );
        // Bug #14 fix: Check if equivalent connection already exists
        final exists = workflow.connections.any((c) =>
            c.sourceNodeId == newConnection.sourceNodeId &&
            c.sourcePort == newConnection.sourcePort &&
            c.targetNodeId == newConnection.targetNodeId &&
            c.targetPort == newConnection.targetPort);
        if (!exists) {
          workflow.connections.add(newConnection);
        }
      }
    }

    _pushUndo();
    state = state.copyWith(
      workflow: workflow,
      selectedNodeId: newNode.id,
      isDirty: true,
    );
    _logger.info('Duplicated node: $nodeId');
  }

  // -------------------- Connection Operations --------------------

  void startConnection(String nodeId, String port) {
    state = state.copyWith(
      connectingFromNodeId: nodeId,
      connectingFromPort: port,
    );
  }

  void completeConnection(String targetNodeId, String targetPort) {
    final workflow = state.workflow;
    if (workflow == null) return;
    if (state.connectingFromNodeId == null) return;

    // Don't allow self-connections
    if (state.connectingFromNodeId == targetNodeId) {
      cancelConnection();
      return;
    }

    final connection = WorkflowConnection(
      id: WorkflowConnection.createId(
        state.connectingFromNodeId!,
        state.connectingFromPort!,
        targetNodeId,
        targetPort,
      ),
      sourceNodeId: state.connectingFromNodeId!,
      sourcePort: state.connectingFromPort!,
      targetNodeId: targetNodeId,
      targetPort: targetPort,
    );

    workflow.addConnection(connection);
    _pushUndo();
    state = state.copyWith(
      workflow: workflow,
      isDirty: true,
      clearConnecting: true,
    );
    _logger.info('Created connection: ${connection.id}');
  }

  void cancelConnection() {
    state = state.copyWith(clearConnecting: true);
  }

  void removeConnection(String connectionId) {
    final workflow = state.workflow;
    if (workflow == null) return;

    workflow.removeConnection(connectionId);
    _pushUndo();
    state = state.copyWith(workflow: workflow, isDirty: true);
    _logger.info('Removed connection: $connectionId');
  }

  // -------------------- Variable Operations --------------------

  void addVariable(WorkflowVariable variable) {
    final workflow = state.workflow;
    if (workflow == null) return;

    workflow.setVariable(variable.name, variable);
    _pushUndo();
    state = state.copyWith(workflow: workflow, isDirty: true);
    _logger.info('Added variable: ${variable.name}');
  }

  void updateVariable(String name, WorkflowVariable variable) {
    final workflow = state.workflow;
    if (workflow == null) return;

    if (name != variable.name) {
      workflow.removeVariable(name);
    }
    workflow.setVariable(variable.name, variable);
    _pushUndo();
    state = state.copyWith(workflow: workflow, isDirty: true);
  }

  void removeVariable(String name) {
    final workflow = state.workflow;
    if (workflow == null) return;

    workflow.removeVariable(name);
    _pushUndo();
    state = state.copyWith(workflow: workflow, isDirty: true);
    _logger.info('Removed variable: $name');
  }

  // -------------------- Canvas Operations --------------------

  void panCanvas(Offset delta) {
    state = state.copyWith(canvasOffset: state.canvasOffset + delta);
  }

  void zoomCanvas(double scale, Offset focalPoint) {
    final newScale = (state.canvasScale * scale).clamp(0.25, 3.0);
    state = state.copyWith(canvasScale: newScale);
  }

  void setCanvasTransform(Offset offset, double scale) {
    state = state.copyWith(canvasOffset: offset, canvasScale: scale);
  }

  /// Updates the rendered position of a port circle.
  /// Called by port widgets after layout to enable accurate connection drawing.
  void updatePortPosition(String nodeId, String portId, bool isInput, Offset position) {
    final key = '$nodeId:$portId:$isInput';
    final newPositions = Map<String, Offset>.from(state.portPositions);
    newPositions[key] = position;
    state = state.copyWith(portPositions: newPositions);
  }

  /// Gets the rendered position of a port, or null if not yet registered.
  Offset? getPortPosition(String nodeId, String portId, bool isInput) {
    final key = '$nodeId:$portId:$isInput';
    return state.portPositions[key];
  }

  void fitToView(Size viewportSize) {
    final workflow = state.workflow;
    if (workflow == null || workflow.nodes.isEmpty) return;

    // Calculate bounds
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (final node in workflow.nodes) {
      minX = minX < node.position.dx ? minX : node.position.dx;
      minY = minY < node.position.dy ? minY : node.position.dy;
      // Bug #9 fix: use correct node width (220, not 150)
      maxX = maxX > node.position.dx + 220 ? maxX : node.position.dx + 220;
      maxY = maxY > node.position.dy + 80 ? maxY : node.position.dy + 80;
    }

    final contentWidth = maxX - minX;
    final contentHeight = maxY - minY;

    final scaleX = (viewportSize.width - 100) / contentWidth;
    final scaleY = (viewportSize.height - 100) / contentHeight;
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.25, 1.5);

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    final offset = Offset(
      viewportSize.width / 2 - centerX * scale,
      viewportSize.height / 2 - centerY * scale,
    );

    state = state.copyWith(canvasOffset: offset, canvasScale: scale);
  }

  // -------------------- Undo/Redo --------------------

  void _pushUndo() {
    final workflow = state.workflow;
    if (workflow == null) return;

    var stack = List<Workflow>.from(state.undoStack);
    // Remove any redo states
    if (state.undoIndex < stack.length - 1) {
      stack = stack.sublist(0, state.undoIndex + 1);
    }
    // Add current state
    stack.add(workflow.copy());
    // Limit stack size
    if (stack.length > _maxUndoSteps) {
      stack = stack.sublist(stack.length - _maxUndoSteps);
    }
    state = state.copyWith(undoStack: stack, undoIndex: stack.length - 1);
  }

  void undo() {
    if (!state.canUndo) return;

    final newIndex = state.undoIndex - 1;
    final workflow = state.undoStack[newIndex].copy();
    state = state.copyWith(
      workflow: workflow,
      undoIndex: newIndex,
      isDirty: true,
      clearSelectedNode: true,
    );
    _logger.info('Undo');
  }

  void redo() {
    if (!state.canRedo) return;

    final newIndex = state.undoIndex + 1;
    final workflow = state.undoStack[newIndex].copy();
    state = state.copyWith(
      workflow: workflow,
      undoIndex: newIndex,
      isDirty: true,
      clearSelectedNode: true,
    );
    _logger.info('Redo');
  }

  void _markDirty() {
    state = state.copyWith(isDirty: true);
  }

  // -------------------- Validation --------------------

  List<WorkflowValidationError> validate() {
    return state.workflow?.validate() ?? [];
  }

  // -------------------- Immediate Node Status --------------------

  /// Sets the execution status for an immediate node.
  void setImmediateNodeStatus(
    String nodeId,
    NodeExecutionStatus status, {
    String? error,
  }) {
    final newStatuses = Map<String, NodeExecutionStatus>.from(
      state.immediateNodeStatuses,
    );
    newStatuses[nodeId] = status;

    final newErrors = Map<String, String>.from(state.immediateNodeErrors);
    if (error != null) {
      newErrors[nodeId] = error;
    } else {
      newErrors.remove(nodeId);
    }

    state = state.copyWith(
      immediateNodeStatuses: newStatuses,
      immediateNodeErrors: newErrors,
    );
  }

  /// Sets cached data for an immediate node (e.g., loaded file list).
  void setImmediateNodeData(String nodeId, dynamic data) {
    final newData = Map<String, dynamic>.from(state.immediateNodeData);
    newData[nodeId] = data;
    state = state.copyWith(immediateNodeData: newData);
  }

  /// Gets cached data for an immediate node.
  T? getImmediateNodeData<T>(String nodeId) {
    return state.immediateNodeData[nodeId] as T?;
  }

  /// Clears immediate node status and data (e.g., when node is deleted or config changes).
  void clearImmediateNodeStatus(String nodeId) {
    final newStatuses = Map<String, NodeExecutionStatus>.from(
      state.immediateNodeStatuses,
    );
    newStatuses.remove(nodeId);

    final newErrors = Map<String, String>.from(state.immediateNodeErrors);
    newErrors.remove(nodeId);

    final newData = Map<String, dynamic>.from(state.immediateNodeData);
    newData.remove(nodeId);

    state = state.copyWith(
      immediateNodeStatuses: newStatuses,
      immediateNodeErrors: newErrors,
      immediateNodeData: newData,
    );
  }

  /// Gets the status of an immediate node.
  NodeExecutionStatus getImmediateNodeStatus(String nodeId) {
    return state.immediateNodeStatuses[nodeId] ?? NodeExecutionStatus.pending;
  }

  /// Gets the error message for an immediate node (if any).
  String? getImmediateNodeError(String nodeId) {
    return state.immediateNodeErrors[nodeId];
  }
}

// ============================================================
// Workflow Execution State
// ============================================================

enum ExecutionStatus { idle, running, paused, completed, error, cancelled }

class WorkflowExecutionState {
  final ExecutionStatus status;
  final String? currentNodeId;
  final int executedNodeCount;
  final int totalNodeCount;
  final List<WorkflowExecutionStep> executionLog;
  final Map<String, dynamic> variableValues;
  final String? errorMessage;
  final List<WorkflowChange> pendingChanges;
  final DateTime? startTime;
  final String? workspaceDir;

  /// Per-node execution status during workflow runs.
  final Map<String, NodeExecutionStatus> nodeStatuses;

  /// Per-node error messages during workflow runs.
  final Map<String, String> nodeErrors;

  const WorkflowExecutionState({
    this.status = ExecutionStatus.idle,
    this.currentNodeId,
    this.executedNodeCount = 0,
    this.totalNodeCount = 0,
    this.executionLog = const [],
    this.variableValues = const {},
    this.errorMessage,
    this.pendingChanges = const [],
    this.startTime,
    this.workspaceDir,
    this.nodeStatuses = const {},
    this.nodeErrors = const {},
  });

  WorkflowExecutionState copyWith({
    ExecutionStatus? status,
    String? currentNodeId,
    int? executedNodeCount,
    int? totalNodeCount,
    List<WorkflowExecutionStep>? executionLog,
    Map<String, dynamic>? variableValues,
    String? errorMessage,
    List<WorkflowChange>? pendingChanges,
    DateTime? startTime,
    String? workspaceDir,
    Map<String, NodeExecutionStatus>? nodeStatuses,
    Map<String, String>? nodeErrors,
    bool clearCurrentNode = false,
    bool clearError = false,
    bool clearWorkspaceDir = false,
  }) {
    return WorkflowExecutionState(
      status: status ?? this.status,
      currentNodeId: clearCurrentNode
          ? null
          : (currentNodeId ?? this.currentNodeId),
      executedNodeCount: executedNodeCount ?? this.executedNodeCount,
      totalNodeCount: totalNodeCount ?? this.totalNodeCount,
      executionLog: executionLog ?? this.executionLog,
      variableValues: variableValues ?? this.variableValues,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingChanges: pendingChanges ?? this.pendingChanges,
      startTime: startTime ?? this.startTime,
      workspaceDir: clearWorkspaceDir ? null : (workspaceDir ?? this.workspaceDir),
      nodeStatuses: nodeStatuses ?? this.nodeStatuses,
      nodeErrors: nodeErrors ?? this.nodeErrors,
    );
  }

  bool get isRunning => status == ExecutionStatus.running;
  bool get isPaused => status == ExecutionStatus.paused;
  bool get isCompleted => status == ExecutionStatus.completed;
  bool get hasError => status == ExecutionStatus.error;

  double get progress =>
      totalNodeCount > 0 ? executedNodeCount / totalNodeCount : 0;
}

class WorkflowExecutionStep {
  final String nodeId;
  final String nodeName;
  final DateTime startTime;
  DateTime? endTime;
  bool success;
  String? message;

  WorkflowExecutionStep({
    required this.nodeId,
    required this.nodeName,
    required this.startTime,
    this.endTime,
    this.success = true,
    this.message,
  });

  Duration? get duration => endTime?.difference(startTime);
}

/// Represents a change that would be applied by a workflow.
abstract class WorkflowChange {
  String get description;
}

class WdbFieldChange extends WorkflowChange {
  final String wdbName;
  final String recordId;
  final String column;
  final dynamic oldValue;
  final dynamic newValue;

  WdbFieldChange({
    required this.wdbName,
    required this.recordId,
    required this.column,
    required this.oldValue,
    required this.newValue,
  });

  @override
  String get description =>
      '$wdbName[$recordId].$column: $oldValue → $newValue';
}

class ZtrTextChange extends WorkflowChange {
  final String entryId;
  final String? oldText;
  final String newText;

  ZtrTextChange({required this.entryId, this.oldText, required this.newText});

  @override
  String get description => 'ZTR[$entryId]: ${oldText ?? "(new)"} → $newText';
}

class WpdChange extends WorkflowChange {
  final String type; // 'unpack' or 'repack'
  final String inputPath;
  final String outputPath;

  WpdChange({
    required this.type,
    required this.inputPath,
    required this.outputPath,
  });

  @override
  String get description => type == 'unpack'
      ? 'Unpack WPD: $inputPath → $outputPath'
      : 'Repack WPD: $inputPath → $outputPath';
}

class ImgChange extends WorkflowChange {
  final String type; // 'extract' or 'repack'
  final String headerPath;
  final String imgbPath;
  final String ddsPath;

  ImgChange({
    required this.type,
    required this.headerPath,
    required this.imgbPath,
    required this.ddsPath,
  });

  @override
  String get description => type == 'extract'
      ? 'Extract IMG: $imgbPath → $ddsPath'
      : 'Repack IMG: $ddsPath → $imgbPath';
}

/// Change class for WBT archive operations (Bug #40 fix).
class WbtChange extends WorkflowChange {
  final String type; // 'loadFileList', 'extract', 'repack'
  final String fileListPath;
  final String binPath;
  final String? outputPath;
  final int? fileCount;

  WbtChange({
    required this.type,
    required this.fileListPath,
    required this.binPath,
    this.outputPath,
    this.fileCount,
  });

  @override
  String get description {
    switch (type) {
      case 'loadFileList':
        return 'Load WBT file list: $fileListPath (${fileCount ?? 0} files)';
      case 'extract':
        return 'Extract ${fileCount ?? 0} files from WBT archive to: $outputPath';
      case 'repack':
        return 'Repack files into WBT archive: $binPath';
      default:
        return 'WBT operation: $type';
    }
  }
}

final workflowExecutorProvider =
    StateNotifierProvider<WorkflowExecutorNotifier, WorkflowExecutionState>((
      ref,
    ) {
      return WorkflowExecutorNotifier(ref);
    });

class WorkflowExecutorNotifier extends StateNotifier<WorkflowExecutionState> {
  final Ref _ref;

  WorkflowExecutorNotifier(this._ref) : super(const WorkflowExecutionState());

  void reset() {
    state = const WorkflowExecutionState();
  }

  void setWorkspaceDir(String? dir) {
    state = state.copyWith(workspaceDir: dir, clearWorkspaceDir: dir == null);
  }

  void pause() {
    final engine = _ref.read(workflowEngineProvider);
    engine.pause();
    state = state.copyWith(status: ExecutionStatus.paused);
  }

  void resume() {
    final engine = _ref.read(workflowEngineProvider);
    engine.resume();
    state = state.copyWith(status: ExecutionStatus.running);
  }

  void cancel() {
    final engine = _ref.read(workflowEngineProvider);
    engine.cancel();
    state = state.copyWith(status: ExecutionStatus.cancelled);
  }

  /// Execute a workflow.
  Future<void> execute(
    Workflow workflow,
    AppGameCode gameCode, {
    bool previewMode = false,
    String? workspaceDir,
  }) async {
    final engine = _ref.read(workflowEngineProvider);

    // Use provided workspace or the one stored in state
    final effectiveWorkspace = workspaceDir ?? state.workspaceDir;

    _logger.info(
      'Executing workflow: ${workflow.name} (preview: $previewMode, workspace: $effectiveWorkspace)',
    );

    state = state.copyWith(
      status: ExecutionStatus.running,
      totalNodeCount: workflow.nodes.length,
      startTime: DateTime.now(),
      pendingChanges: [],
      executionLog: [],
      workspaceDir: effectiveWorkspace,
      clearError: true,
    );

    final result = await engine.execute(
      workflow,
      gameCode,
      previewMode: previewMode,
      workspaceDir: effectiveWorkspace,
      onStateChange: (newState) {
        state = newState.copyWith(workspaceDir: effectiveWorkspace);
      },
    );

    if (result.cancelled) {
      state = state.copyWith(status: ExecutionStatus.cancelled);
    } else if (result.success) {
      state = state.copyWith(
        status: ExecutionStatus.completed,
        pendingChanges: result.changes,
      );
    } else {
      state = state.copyWith(
        status: ExecutionStatus.error,
        errorMessage: result.errorMessage,
      );
    }
  }
}

// ============================================================
// WDB Metadata Provider (for workflow editor)
// ============================================================

/// Cached WDB metadata for workflow editing.
class WdbMetadataCache {
  final Map<String, List<WdbColumn>> _cache = {};
  final Map<String, DateTime> _timestamps = {};
  static const _maxAge = Duration(minutes: 5);

  bool _isStale(String key) {
    final timestamp = _timestamps[key];
    if (timestamp == null) return true;
    return DateTime.now().difference(timestamp) > _maxAge;
  }

  List<WdbColumn>? get(String key) {
    if (_isStale(key)) return null;
    return _cache[key];
  }

  void set(String key, List<WdbColumn> columns) {
    _cache[key] = columns;
    _timestamps[key] = DateTime.now();
  }

  void invalidate(String key) {
    _cache.remove(key);
    _timestamps.remove(key);
  }

  void clear() {
    _cache.clear();
    _timestamps.clear();
  }
}

final _wdbMetadataCache = WdbMetadataCache();

/// Provider for fetching WDB metadata (columns) for workflow editing.
final wdbMetadataProvider = FutureProvider.family<List<WdbColumn>?, WdbMetadataRequest>((
  ref,
  request,
) async {
  if (request.filePath == null || request.filePath!.isEmpty) return null;

  // Resolve the file path
  String resolvedPath = request.filePath!;
  if (request.workspaceDir != null &&
      !resolvedPath.startsWith('/') &&
      !resolvedPath.contains(':\\')) {
    resolvedPath = '${request.workspaceDir}/$resolvedPath';
  }

  // Check cache
  final cacheKey = '${request.gameCode.index}:$resolvedPath';
  final cached = _wdbMetadataCache.get(cacheKey);
  if (cached != null) return cached;

  try {
    _logger.info('Fetching WDB metadata: $resolvedPath');
    final wdbData = await NativeService.instance.parseWdb(
      resolvedPath,
      request.gameCode,
    );
    _wdbMetadataCache.set(cacheKey, wdbData.columns);
    return wdbData.columns;
  } catch (e) {
    _logger.warning('Failed to fetch WDB metadata: $e');
    return null;
  }
});

/// Request parameters for WDB metadata.
class WdbMetadataRequest {
  final String? filePath;
  final String? workspaceDir;
  final AppGameCode gameCode;

  const WdbMetadataRequest({
    this.filePath,
    this.workspaceDir,
    required this.gameCode,
  });

  @override
  bool operator ==(Object other) =>
      other is WdbMetadataRequest &&
      other.filePath == filePath &&
      other.workspaceDir == workspaceDir &&
      other.gameCode == gameCode;

  @override
  int get hashCode => Object.hash(filePath, workspaceDir, gameCode);
}

/// Extension to find the WDB source for a given node by tracing connections.
extension WorkflowWdbSource on Workflow {
  /// Finds the WDB file path that provides data to the given node.
  /// Traces back through connections to find wdbOpen or wdbTransform nodes.
  String? findWdbSourcePath(String nodeId, {Set<String>? visited}) {
    visited ??= {};
    if (visited.contains(nodeId)) return null; // Prevent cycles
    visited.add(nodeId);

    final node = findNode(nodeId);
    if (node == null) return null;

    // If this node has its own file path, use it
    if (node.type == NodeType.wdbOpen || node.type == NodeType.wdbTransform) {
      final filePath = node.config['filePath'] as String?;
      if (filePath != null && filePath.isNotEmpty) {
        return filePath;
      }
    }

    // Trace back through input connections
    for (final conn in connections) {
      if (conn.targetNodeId == nodeId) {
        final result = findWdbSourcePath(conn.sourceNodeId, visited: visited);
        if (result != null) return result;
      }
    }

    return null;
  }

  /// Gets all record IDs from the WDB metadata for suggestions.
  List<String> getAvailableRecordIds(String nodeId) {
    // This would require parsing the WDB which is async
    // For now, return empty - can be enhanced later
    return [];
  }
}
