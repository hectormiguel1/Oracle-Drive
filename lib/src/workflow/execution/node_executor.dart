import '../../../models/workflow/workflow_models.dart';
import 'execution_context.dart';
import 'expression_evaluator.dart';

/// Result of executing a node.
class NodeExecutionResult {
  /// Whether execution succeeded.
  final bool success;

  /// Which output port to follow (e.g., 'output', 'true', 'false', 'body', 'done').
  final String? nextPort;

  /// Output value from the node (optional).
  final dynamic outputValue;

  /// Error message if execution failed.
  final String? errorMessage;

  /// Message for logging purposes.
  final String? logMessage;

  const NodeExecutionResult({
    required this.success,
    this.nextPort,
    this.outputValue,
    this.errorMessage,
    this.logMessage,
  });

  factory NodeExecutionResult.success({
    String nextPort = 'output',
    dynamic outputValue,
    String? logMessage,
  }) {
    return NodeExecutionResult(
      success: true,
      nextPort: nextPort,
      outputValue: outputValue,
      logMessage: logMessage,
    );
  }

  factory NodeExecutionResult.error(String message) {
    return NodeExecutionResult(
      success: false,
      errorMessage: message,
    );
  }

  factory NodeExecutionResult.terminal() {
    return const NodeExecutionResult(
      success: true,
      nextPort: null, // No next node
    );
  }
}

/// Base class for node executors.
abstract class NodeExecutor {
  // Bug #37 fix: Cache evaluator per context to avoid creating new instances on each call
  final Map<ExecutionContext, ExpressionEvaluator> _evaluatorCache = {};

  /// Execute the node and return the result.
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  );

  /// Helper to get the expression evaluator.
  /// Caches the evaluator per context for efficiency.
  ExpressionEvaluator getEvaluator(ExecutionContext context) {
    return _evaluatorCache.putIfAbsent(context, () => ExpressionEvaluator(context));
  }

  /// Helper to get a required config value.
  T? getConfig<T>(WorkflowNode node, String key) {
    return node.config[key] as T?;
  }

  /// Helper to evaluate a config value as an expression.
  dynamic evaluateConfig(
    WorkflowNode node,
    String key,
    ExecutionContext context,
  ) {
    final value = node.config[key];
    if (value == null) return null;
    return getEvaluator(context).evaluate(value);
  }

  /// Helper to evaluate a config value as a string.
  String evaluateConfigAsString(
    WorkflowNode node,
    String key,
    ExecutionContext context, {
    String defaultValue = '',
  }) {
    final value = node.config[key];
    if (value == null) return defaultValue;
    return getEvaluator(context).evaluateAsString(value);
  }
}
