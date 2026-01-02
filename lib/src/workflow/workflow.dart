/// Workflow system exports.
///
/// This library provides a modular workflow execution engine for
/// automating multi-step operations in the FF13 modding toolkit.
library;

// Core execution
export 'execution/execution_context.dart';
export 'execution/expression_evaluator.dart';
export 'execution/node_executor.dart';
export 'execution/workflow_engine.dart';
export 'execution/executor_registry.dart';
export 'execution/immediate_executor.dart';
export 'execution/immediate_executor_v2.dart';

// Executors
export 'execution/executors/control_executors.dart';
export 'execution/executors/wdb_executors.dart';
export 'execution/executors/ztr_executors.dart';
export 'execution/executors/wpd_executors.dart';
export 'execution/executors/wbt_executors.dart';
export 'execution/executors/img_executors.dart';

// Utilities
export 'utils/deep_copy.dart';
export 'utils/path_resolver.dart';

// Services
export 'services/file_service.dart';
export 'services/native_file_service.dart';

// Caching
export 'cache/metadata_cache.dart';
export 'cache/batch_writer.dart';
export 'cache/workflow_cache.dart';

// State management
export 'state/workflow_state_machine.dart';

// Migration
export 'migration/workflow_migration.dart';

// Testing utilities
export 'testing/execution_context_builder.dart';
export 'testing/executor_test_harness.dart';
