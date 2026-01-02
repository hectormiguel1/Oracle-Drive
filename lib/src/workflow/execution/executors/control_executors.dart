import '../../../../models/workflow/workflow_models.dart';
import '../execution_context.dart';
import '../node_executor.dart';

/// Executor for the Start node.
class StartExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    return NodeExecutionResult.success(
      logMessage: 'Workflow started',
    );
  }
}

/// Executor for the End node.
class EndExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    return NodeExecutionResult.terminal();
  }
}

/// Executor for the Condition node.
class ConditionExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final expression = getConfig<String>(node, 'expression');
    if (expression == null || expression.isEmpty) {
      return NodeExecutionResult.error('Condition expression is required');
    }

    final evaluator = getEvaluator(context);
    final result = evaluator.evaluateCondition(expression);

    return NodeExecutionResult.success(
      nextPort: result ? 'true' : 'false',
      outputValue: result,
      logMessage: 'Condition evaluated to $result',
    );
  }
}

/// Executor for the Loop node.
class LoopExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final countExpr = getConfig<dynamic>(node, 'count');
    final indexVariable = getConfig<String>(node, 'indexVariable') ?? 'i';

    if (countExpr == null) {
      return NodeExecutionResult.error('Loop count is required');
    }

    final evaluator = getEvaluator(context);
    final maxCount = evaluator.evaluateAsInt(countExpr, defaultValue: 0);

    final currentIndex = context.getLoopIndex(node.id);

    if (currentIndex < maxCount) {
      // Set the index variable
      context.setVariable(indexVariable, currentIndex);
      // Increment for next iteration
      context.incrementLoopIndex(node.id);

      return NodeExecutionResult.success(
        nextPort: 'body',
        logMessage: 'Loop iteration ${currentIndex + 1}/$maxCount',
      );
    } else {
      // Loop complete
      context.resetLoopIndex(node.id);
      context.variables.remove(indexVariable);

      return NodeExecutionResult.success(
        nextPort: 'done',
        logMessage: 'Loop completed after $maxCount iterations',
      );
    }
  }
}

/// Executor for the ForEach node.
class ForEachExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final collectionExpr = getConfig<dynamic>(node, 'collection');
    final itemVariable = getConfig<String>(node, 'itemVariable') ?? 'item';
    final indexVariable = getConfig<String>(node, 'indexVariable') ?? 'index';

    if (collectionExpr == null) {
      return NodeExecutionResult.error('Collection expression is required');
    }

    final evaluator = getEvaluator(context);
    final collection = evaluator.evaluate(collectionExpr);

    if (collection == null) {
      return NodeExecutionResult.success(
        nextPort: 'done',
        logMessage: 'Collection is null, skipping',
      );
    }

    List<dynamic> items;
    if (collection is List) {
      // Bug #44 fix: Copy the list to prevent mutation side effects
      items = List.from(collection);
    } else if (collection is Map) {
      items = collection.entries.toList();
    } else if (collection is Iterable) {
      items = collection.toList();
    } else {
      return NodeExecutionResult.error(
        'Collection must be a list or iterable, got ${collection.runtimeType}',
      );
    }

    if (items.isEmpty) {
      return NodeExecutionResult.success(
        nextPort: 'done',
        logMessage: 'Collection is empty, skipping',
      );
    }

    final currentIndex = context.getLoopIndex(node.id);

    if (currentIndex < items.length) {
      // Set the item and index variables
      context.setVariable(itemVariable, items[currentIndex]);
      context.setVariable(indexVariable, currentIndex);
      // Increment for next iteration
      context.incrementLoopIndex(node.id);

      return NodeExecutionResult.success(
        nextPort: 'body',
        logMessage: 'ForEach iteration ${currentIndex + 1}/${items.length}',
      );
    } else {
      // Loop complete
      context.resetLoopIndex(node.id);
      context.variables.remove(itemVariable);
      context.variables.remove(indexVariable);

      return NodeExecutionResult.success(
        nextPort: 'done',
        logMessage: 'ForEach completed after ${items.length} iterations',
      );
    }
  }
}

/// Executor for the SetVariable node.
class SetVariableExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final name = getConfig<String>(node, 'name');
    final valueExpr = getConfig<dynamic>(node, 'value');

    if (name == null || name.isEmpty) {
      return NodeExecutionResult.error('Variable name is required');
    }

    final evaluator = getEvaluator(context);
    final value = evaluator.evaluate(valueExpr);

    context.setVariable(name, value);

    return NodeExecutionResult.success(
      outputValue: value,
      logMessage: 'Set variable $name = $value',
    );
  }
}

/// Executor for the GetVariable node.
class GetVariableExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final name = getConfig<String>(node, 'name');
    final storeAs = getConfig<String>(node, 'storeAs');

    if (name == null || name.isEmpty) {
      return NodeExecutionResult.error('Variable name is required');
    }

    if (storeAs == null || storeAs.isEmpty) {
      return NodeExecutionResult.error('Store as variable name is required');
    }

    final value = context.getVariable(name);
    context.setVariable(storeAs, value);

    return NodeExecutionResult.success(
      outputValue: value,
      logMessage: 'Got variable $name (stored as $storeAs)',
    );
  }
}

/// Executor for the Expression node.
class ExpressionExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final expression = getConfig<String>(node, 'expression');
    final storeAs = getConfig<String>(node, 'storeAs');

    if (expression == null || expression.isEmpty) {
      return NodeExecutionResult.error('Expression is required');
    }

    final evaluator = getEvaluator(context);
    final result = evaluator.evaluate(expression);

    if (storeAs != null && storeAs.isNotEmpty) {
      context.setVariable(storeAs, result);
    }

    return NodeExecutionResult.success(
      outputValue: result,
      logMessage: 'Expression evaluated to $result',
    );
  }
}

/// Executor for the Fork node.
/// Forks execution into multiple parallel branches.
/// The engine handles the parallel execution; this just signals to continue.
class ForkExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final label = getConfig<String>(node, 'label');
    return NodeExecutionResult.success(
      logMessage: label?.isNotEmpty == true
          ? 'Forking: $label'
          : 'Forking into parallel branches',
    );
  }
}

/// Executor for the Join node.
/// Waits for all incoming parallel branches to complete before continuing.
/// The engine handles the synchronization; this just signals to continue.
class JoinExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final label = getConfig<String>(node, 'label');
    return NodeExecutionResult.success(
      logMessage: label?.isNotEmpty == true
          ? 'Joined: $label'
          : 'All parallel branches joined',
    );
  }
}
