import 'package:oracle_drive/src/isar/common/models.dart';
import 'package:oracle_drive/src/isar/workflow/workflow_models.dart';
import 'package:oracle_drive/models/workflow/workflow.dart';

abstract class GameRepository {
  // --- Read (Sync - Fast Isolate access) ---
  String? getAbilityName(String abilityId);
  Map<String, String?> getBatchAbilityNames(List<String> abilityIds);
  String? getAbilityDescription(String abilityId);
  Map<String, String?> getBatchAbilityDescriptions(List<String> abilityIds);
  String? getItemDescription(String itemId);
  Map<String, String?> getBatchItemDescriptions(List<String> itemIds);
  String? getItemName(String itemId);
  Map<String, String?> getBatchItemNames(List<String> itemIds);
  String? resolveStringId(String stringId);
  Map<String, String?> resolveBatchStringIds(List<String> stringIds);
  bool stringsLoaded();

  // --- Write / Async Operations (Moved from AppDatabase) ---
  int insertStringData(Map<String, String> strings);
  void addString(String id, String value);
  void updateString(String id, String newValue);
  void deleteString(String id);
  int getStringCount();

  void clearDatabase();
  void close();

  /// Upsert lookup entities to the database.
  void upsertLookups(List<EntityLookup> lookups);

  Stream<Map<String, String>> getStrings();

  /// Get all strings with source file information.
  Stream<List<Strings>> getStringsWithSource();

  /// Insert strings with source file tracking.
  void insertStringsWithSource(List<Strings> strings);

  /// Get strings filtered by source file path.
  Map<String, String> getStringsBySourceFile(String sourceFile);

  /// Get all distinct source files in the database.
  List<String> getDistinctSourceFiles();

  // --- Workflow Operations ---
  /// Get all workflows in this game's database.
  Future<List<Workflow>> getAllWorkflows();

  /// Get a workflow by ID.
  Future<Workflow?> getWorkflow(String id);

  /// Save a workflow (insert or update).
  Future<void> saveWorkflow(Workflow workflow);

  /// Delete a workflow by ID.
  Future<void> deleteWorkflow(String id);

  /// Check if a workflow exists.
  Future<bool> workflowExists(String id);

  /// Export a workflow to JSON string.
  Future<String?> exportWorkflowToJson(String id);

  /// Import a workflow from JSON string.
  Future<Workflow> importWorkflowFromJson(String json, {bool generateNewId = true});

  /// Log a workflow execution.
  Future<void> logWorkflowExecution({
    required String workflowId,
    required int durationMs,
    required String status,
    String? errorMessage,
    required int nodesExecuted,
    required int totalNodes,
    String? detailsJson,
  });

  /// Get execution history for a workflow.
  Future<List<WorkflowExecutionLog>> getWorkflowExecutionHistory(String workflowId, {int limit = 50});

  /// Get recent workflow executions.
  Future<List<WorkflowExecutionLog>> getRecentWorkflowExecutions({int limit = 20});

  /// Clear execution history for a workflow.
  Future<void> clearWorkflowExecutionHistory(String workflowId);
}
