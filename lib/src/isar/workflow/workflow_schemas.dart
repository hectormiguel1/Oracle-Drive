import 'package:isar_plus/isar_plus.dart';
import 'workflow_models.dart';

/// Isar schemas for workflow persistence.
final List<IsarGeneratedSchema> workflowSchemas = [
  StoredWorkflowSchema,
  WorkflowExecutionLogSchema,
];

final Map<String, IsarGeneratedSchema> workflowSchemaByName = {
  'StoredWorkflow': StoredWorkflowSchema,
  'WorkflowExecutionLog': WorkflowExecutionLogSchema,
};
