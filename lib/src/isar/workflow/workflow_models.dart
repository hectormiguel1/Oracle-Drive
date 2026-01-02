import 'package:isar_plus/isar_plus.dart';
import '../common/models.dart';

part 'workflow_models.g.dart';

/// Stored workflow in the database.
@Collection()
class StoredWorkflow {
  /// Unique workflow ID (UUID).
  @Index()
  String workflowId;

  /// User-defined name for the workflow.
  String name;

  /// Description of what the workflow does.
  String description;

  /// Game code index (0=FF13, 1=FF13-2, 2=FF13-LR).
  @Index()
  int gameCode;

  /// When the workflow was created.
  DateTime createdAt;

  /// When the workflow was last modified.
  DateTime modifiedAt;

  /// JSON-encoded workflow data (nodes, connections, variables).
  String jsonData;

  /// Local workspace directory path (not exported with workflow).
  String? workspacePath;

  StoredWorkflow({
    required this.workflowId,
    required this.name,
    required this.description,
    required this.gameCode,
    required this.createdAt,
    required this.modifiedAt,
    required this.jsonData,
    this.workspacePath,
  });

  int get id => fastHash(workflowId);
}

/// Execution log entry for a workflow run.
@Collection()
class WorkflowExecutionLog {
  /// ID of the workflow that was executed.
  @Index()
  String workflowId;

  /// When the execution started.
  @Index()
  DateTime executedAt;

  /// Duration of execution in milliseconds.
  int durationMs;

  /// Status: 'success', 'error', 'cancelled'.
  String status;

  /// Error message if status is 'error'.
  String? errorMessage;

  /// Number of nodes that were executed.
  int nodesExecuted;

  /// Total number of nodes in the workflow.
  int totalNodes;

  /// JSON-encoded execution details for debugging.
  String? detailsJson;

  WorkflowExecutionLog({
    required this.workflowId,
    required this.executedAt,
    required this.durationMs,
    required this.status,
    this.errorMessage,
    required this.nodesExecuted,
    required this.totalNodes,
    this.detailsJson,
  });

  int get id => fastHash('$workflowId:${executedAt.millisecondsSinceEpoch}');
}
