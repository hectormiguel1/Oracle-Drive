import 'dart:ui';

import '../../../models/workflow/node_status.dart';
import '../../../models/workflow/workflow_models.dart';
import '../../../providers/workflow_provider.dart';
import '../execution/workflow_engine.dart';

/// Workflow editor/executor mode.
enum WorkflowMode {
  /// No workflow is loaded.
  idle,

  /// Workflow is open for editing.
  editing,

  /// Workflow is currently executing.
  executing,

  /// Workflow execution is paused.
  paused,

  /// Workflow is in preview mode.
  previewing,
}

/// Unified state for the workflow system.
class WorkflowState {
  /// Current mode.
  final WorkflowMode mode;

  /// The current workflow being edited/executed.
  final Workflow? workflow;

  /// Currently selected node.
  final WorkflowNode? selectedNode;

  /// Currently selected connection.
  final WorkflowConnection? selectedConnection;

  /// Node being connected from (when creating a connection).
  final String? pendingConnectionFromNode;
  final String? pendingConnectionFromPort;

  /// Canvas transform state.
  final Offset canvasOffset;
  final double canvasScale;

  /// Execution status for each node.
  final Map<String, NodeExecutionStatus> nodeStatuses;

  /// Last execution result.
  final WorkflowExecutionResult? lastResult;

  /// Execution log.
  final List<WorkflowExecutionStep> executionLog;

  /// Current variable values during execution.
  final Map<String, dynamic> variableValues;

  /// Pending changes (preview mode).
  final List<WorkflowChange> pendingChanges;

  /// Undo/redo stacks.
  final List<Workflow> undoStack;
  final int undoIndex;

  /// Error message if any.
  final String? errorMessage;

  /// Immediate node data cache.
  final Map<String, dynamic> immediateNodeData;

  /// Immediate node status cache.
  final Map<String, NodeExecutionStatus> immediateNodeStatuses;

  /// Workspace directory for file resolution.
  final String? workspaceDir;

  const WorkflowState({
    this.mode = WorkflowMode.idle,
    this.workflow,
    this.selectedNode,
    this.selectedConnection,
    this.pendingConnectionFromNode,
    this.pendingConnectionFromPort,
    this.canvasOffset = Offset.zero,
    this.canvasScale = 1.0,
    this.nodeStatuses = const {},
    this.lastResult,
    this.executionLog = const [],
    this.variableValues = const {},
    this.pendingChanges = const [],
    this.undoStack = const [],
    this.undoIndex = -1,
    this.errorMessage,
    this.immediateNodeData = const {},
    this.immediateNodeStatuses = const {},
    this.workspaceDir,
  });

  /// Whether undo is available.
  bool get canUndo => undoIndex > 0;

  /// Whether redo is available.
  bool get canRedo => undoIndex < undoStack.length - 1;

  /// Whether the workflow has unsaved changes.
  bool get hasUnsavedChanges => undoIndex > 0;

  /// Whether a workflow is loaded.
  bool get hasWorkflow => workflow != null;

  /// Whether execution is in progress.
  bool get isExecuting => mode == WorkflowMode.executing;

  /// Whether execution is paused.
  bool get isPaused => mode == WorkflowMode.paused;

  /// Create a copy with optional modifications.
  WorkflowState copyWith({
    WorkflowMode? mode,
    Workflow? workflow,
    WorkflowNode? selectedNode,
    WorkflowConnection? selectedConnection,
    String? pendingConnectionFromNode,
    String? pendingConnectionFromPort,
    Offset? canvasOffset,
    double? canvasScale,
    Map<String, NodeExecutionStatus>? nodeStatuses,
    WorkflowExecutionResult? lastResult,
    List<WorkflowExecutionStep>? executionLog,
    Map<String, dynamic>? variableValues,
    List<WorkflowChange>? pendingChanges,
    List<Workflow>? undoStack,
    int? undoIndex,
    String? errorMessage,
    Map<String, dynamic>? immediateNodeData,
    Map<String, NodeExecutionStatus>? immediateNodeStatuses,
    String? workspaceDir,
    bool clearSelection = false,
    bool clearPendingConnection = false,
    bool clearError = false,
  }) {
    return WorkflowState(
      mode: mode ?? this.mode,
      workflow: workflow ?? this.workflow,
      selectedNode: clearSelection ? null : (selectedNode ?? this.selectedNode),
      selectedConnection: clearSelection ? null : (selectedConnection ?? this.selectedConnection),
      pendingConnectionFromNode: clearPendingConnection
          ? null
          : (pendingConnectionFromNode ?? this.pendingConnectionFromNode),
      pendingConnectionFromPort: clearPendingConnection
          ? null
          : (pendingConnectionFromPort ?? this.pendingConnectionFromPort),
      canvasOffset: canvasOffset ?? this.canvasOffset,
      canvasScale: canvasScale ?? this.canvasScale,
      nodeStatuses: nodeStatuses ?? this.nodeStatuses,
      lastResult: lastResult ?? this.lastResult,
      executionLog: executionLog ?? this.executionLog,
      variableValues: variableValues ?? this.variableValues,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      undoStack: undoStack ?? this.undoStack,
      undoIndex: undoIndex ?? this.undoIndex,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      immediateNodeData: immediateNodeData ?? this.immediateNodeData,
      immediateNodeStatuses: immediateNodeStatuses ?? this.immediateNodeStatuses,
      workspaceDir: workspaceDir ?? this.workspaceDir,
    );
  }
}

/// Events that can be dispatched to the workflow state machine.
sealed class WorkflowEvent {}

// Workflow lifecycle events
class CreateWorkflowEvent extends WorkflowEvent {
  final String name;
  final String description;

  CreateWorkflowEvent({required this.name, this.description = ''});
}

class LoadWorkflowEvent extends WorkflowEvent {
  final Workflow workflow;

  LoadWorkflowEvent(this.workflow);
}

class CloseWorkflowEvent extends WorkflowEvent {}

class SaveWorkflowEvent extends WorkflowEvent {}

// Node events
class AddNodeEvent extends WorkflowEvent {
  final NodeType type;
  final Offset position;

  AddNodeEvent({required this.type, required this.position});
}

class RemoveNodeEvent extends WorkflowEvent {
  final String nodeId;

  RemoveNodeEvent(this.nodeId);
}

class MoveNodeEvent extends WorkflowEvent {
  final String nodeId;
  final Offset position;

  MoveNodeEvent({required this.nodeId, required this.position});
}

class UpdateNodeConfigEvent extends WorkflowEvent {
  final String nodeId;
  final String key;
  final dynamic value;

  UpdateNodeConfigEvent({
    required this.nodeId,
    required this.key,
    required this.value,
  });
}

class SelectNodeEvent extends WorkflowEvent {
  final String? nodeId;

  SelectNodeEvent(this.nodeId);
}

// Connection events
class StartConnectionEvent extends WorkflowEvent {
  final String nodeId;
  final String portId;

  StartConnectionEvent({required this.nodeId, required this.portId});
}

class CompleteConnectionEvent extends WorkflowEvent {
  final String targetNodeId;
  final String targetPortId;

  CompleteConnectionEvent({required this.targetNodeId, required this.targetPortId});
}

class CancelConnectionEvent extends WorkflowEvent {}

class RemoveConnectionEvent extends WorkflowEvent {
  final String connectionId;

  RemoveConnectionEvent(this.connectionId);
}

class SelectConnectionEvent extends WorkflowEvent {
  final String? connectionId;

  SelectConnectionEvent(this.connectionId);
}

// Canvas events
class PanCanvasEvent extends WorkflowEvent {
  final Offset delta;

  PanCanvasEvent(this.delta);
}

class ZoomCanvasEvent extends WorkflowEvent {
  final double delta;
  final Offset focalPoint;

  ZoomCanvasEvent({required this.delta, required this.focalPoint});
}

class ResetCanvasEvent extends WorkflowEvent {}

// Undo/Redo events
class UndoEvent extends WorkflowEvent {}

class RedoEvent extends WorkflowEvent {}

// Execution events
class StartExecutionEvent extends WorkflowEvent {
  final bool previewMode;

  StartExecutionEvent({this.previewMode = false});
}

class PauseExecutionEvent extends WorkflowEvent {}

class ResumeExecutionEvent extends WorkflowEvent {}

class CancelExecutionEvent extends WorkflowEvent {}

class ExecutionProgressEvent extends WorkflowEvent {
  final String nodeId;
  final NodeExecutionStatus status;

  ExecutionProgressEvent({required this.nodeId, required this.status});
}

class ExecutionCompleteEvent extends WorkflowEvent {
  final WorkflowExecutionResult result;

  ExecutionCompleteEvent(this.result);
}

// Workspace events
class SetWorkspaceDirEvent extends WorkflowEvent {
  final String? dir;

  SetWorkspaceDirEvent(this.dir);
}

/// State machine for workflow state management.
///
/// This provides a unified approach to managing workflow state
/// with clear event-driven updates and consistent state transitions.
abstract class WorkflowStateMachine {
  /// Get the current state.
  WorkflowState get state;

  /// Dispatch an event to update the state.
  void dispatch(WorkflowEvent event);

  /// Stream of state changes.
  Stream<WorkflowState> get stateStream;
}
