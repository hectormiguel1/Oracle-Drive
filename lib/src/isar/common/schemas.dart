import 'package:oracle_drive/src/isar/common/models.dart';
import 'package:oracle_drive/src/isar/workflow/workflow_models.dart';
import 'package:isar_plus/isar_plus.dart';

/// Schemas for game-specific databases (ff13, ff13_2, ff13_lr).
/// Each game database contains: Strings, EntityLookup, StoredWorkflow, WorkflowExecutionLog.
final List<IsarGeneratedSchema> schemas = [
  StringsSchema,
  EntityLookupSchema,
  StoredWorkflowSchema,
  WorkflowExecutionLogSchema,
];

final Map<String, IsarGeneratedSchema> schemaByName = {
  'Strings': StringsSchema,
  'EntityLookup': EntityLookupSchema,
  'StoredWorkflow': StoredWorkflowSchema,
  'WorkflowExecutionLog': WorkflowExecutionLogSchema,
};
