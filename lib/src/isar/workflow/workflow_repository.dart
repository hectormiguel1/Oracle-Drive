import 'package:isar_plus/isar_plus.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import '../../../models/workflow/workflow.dart';
import 'workflow_models.dart';

final _logger = Logger('WorkflowRepository');
const _uuid = Uuid();

/// Repository for workflow persistence operations.
/// Note: This repository is now instantiated per-game-database, so all methods
/// operate on workflows for a single game (the database determines the game).
class WorkflowRepository {
  final Isar _isar;

  WorkflowRepository(this._isar);

  /// Get all workflows in this database.
  /// Bug #31 fix: Add error handling for corrupt JSON data.
  Future<List<Workflow>> getAllWorkflows() async {
    final stored = _isar.read((db) {
      return db.storedWorkflows.where().sortByModifiedAtDesc().findAll();
    });

    final workflows = <Workflow>[];
    for (final s in stored) {
      try {
        final workflow = Workflow.fromJsonString(s.jsonData);
        workflow.workspacePath = s.workspacePath;
        workflows.add(workflow);
      } catch (e) {
        _logger.warning('Failed to parse workflow ${s.workflowId}: $e');
        // Skip corrupt entry instead of failing entirely
      }
    }
    return workflows;
  }

  /// Get a workflow by ID.
  /// Bug #31 fix: Add error handling for corrupt JSON data.
  Future<Workflow?> getWorkflow(String id) async {
    final stored = _isar.read((db) {
      return db.storedWorkflows.where().workflowIdEqualTo(id).findFirst();
    });

    if (stored == null) return null;
    try {
      final workflow = Workflow.fromJsonString(stored.jsonData);
      workflow.workspacePath = stored.workspacePath;
      return workflow;
    } catch (e) {
      _logger.warning('Failed to parse workflow $id: $e');
      return null;
    }
  }

  /// Save a workflow (insert or update).
  Future<void> saveWorkflow(Workflow workflow) async {
    final stored = StoredWorkflow(
      workflowId: workflow.id,
      name: workflow.name,
      description: workflow.description,
      createdAt: workflow.createdAt,
      modifiedAt: workflow.modifiedAt,
      jsonData: workflow.toJsonString(),
      workspacePath: workflow.workspacePath,
    );

    _isar.write((db) {
      db.storedWorkflows.put(stored);
    });
  }

  /// Delete a workflow by ID.
  Future<void> deleteWorkflow(String id) async {
    _isar.write((db) {
      db.storedWorkflows.where().workflowIdEqualTo(id).deleteAll();
    });
  }

  /// Check if a workflow exists.
  Future<bool> workflowExists(String id) async {
    return _isar.read((db) {
      return db.storedWorkflows.where().workflowIdEqualTo(id).count() > 0;
    });
  }

  /// Export a workflow to JSON string.
  Future<String?> exportToJson(String id) async {
    final workflow = await getWorkflow(id);
    return workflow?.toJsonString();
  }

  /// Import a workflow from JSON string.
  Future<Workflow> importFromJson(
    String json, {
    bool generateNewId = true,
  }) async {
    var workflow = Workflow.fromJsonString(json);

    if (generateNewId) {
      // Bug #30 fix: Use UUID instead of timestamp to avoid ID collisions
      workflow = Workflow(
        id: _uuid.v4(),
        name: '${workflow.name} (Imported)',
        description: workflow.description,
        gameCode: workflow.gameCode,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        nodes: workflow.nodes,
        connections: workflow.connections,
        variables: workflow.variables,
      );
    }

    await saveWorkflow(workflow);
    return workflow;
  }

  /// Log a workflow execution.
  Future<void> logExecution({
    required String workflowId,
    required int durationMs,
    required String status,
    String? errorMessage,
    required int nodesExecuted,
    required int totalNodes,
    String? detailsJson,
  }) async {
    final log = WorkflowExecutionLog(
      workflowId: workflowId,
      executedAt: DateTime.now(),
      durationMs: durationMs,
      status: status,
      errorMessage: errorMessage,
      nodesExecuted: nodesExecuted,
      totalNodes: totalNodes,
      detailsJson: detailsJson,
    );

    _isar.write((db) {
      db.workflowExecutionLogs.put(log);
    });
  }

  /// Get execution history for a workflow.
  Future<List<WorkflowExecutionLog>> getExecutionHistory(
    String workflowId, {
    int limit = 50,
  }) async {
    return _isar.read((db) {
      return db.workflowExecutionLogs
          .where()
          .workflowIdEqualTo(workflowId)
          .sortByExecutedAtDesc()
          .findAll()
          .take(limit)
          .toList();
    });
  }

  /// Get recent executions across all workflows.
  Future<List<WorkflowExecutionLog>> getRecentExecutions({
    int limit = 20,
  }) async {
    return _isar.read((db) {
      return db.workflowExecutionLogs
          .where()
          .sortByExecutedAtDesc()
          .findAll()
          .take(limit)
          .toList();
    });
  }

  /// Clear execution history for a workflow.
  Future<void> clearExecutionHistory(String workflowId) async {
    _isar.write((db) {
      db.workflowExecutionLogs
          .where()
          .workflowIdEqualTo(workflowId)
          .deleteAll();
    });
  }
}
