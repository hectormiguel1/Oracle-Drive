import '../../../models/workflow/workflow_models.dart';
import 'node_executor.dart';

/// Registry for mapping node types to their executors.
///
/// This abstraction allows for:
/// - Decoupled executor registration
/// - Easier testing with mock executors
/// - Plugin-style extension of node types
abstract class ExecutorRegistry {
  /// Register an executor for a node type.
  void register(NodeType type, NodeExecutor executor);

  /// Get the executor for a node type.
  NodeExecutor? getExecutor(NodeType type);

  /// Check if an executor is registered for a node type.
  bool hasExecutor(NodeType type);

  /// Get all registered node types.
  Iterable<NodeType> get registeredTypes;

  /// Get the count of registered executors.
  int get count;
}

/// Default implementation of [ExecutorRegistry].
class DefaultExecutorRegistry implements ExecutorRegistry {
  final Map<NodeType, NodeExecutor> _executors = {};

  @override
  void register(NodeType type, NodeExecutor executor) {
    _executors[type] = executor;
  }

  @override
  NodeExecutor? getExecutor(NodeType type) => _executors[type];

  @override
  bool hasExecutor(NodeType type) => _executors.containsKey(type);

  @override
  Iterable<NodeType> get registeredTypes => _executors.keys;

  @override
  int get count => _executors.length;

  /// Clear all registered executors.
  void clear() {
    _executors.clear();
  }

  /// Remove an executor for a node type.
  void unregister(NodeType type) {
    _executors.remove(type);
  }
}

/// Module-based executor registration.
///
/// Each executor module can provide a registration function that
/// registers its executors with the registry.
typedef ExecutorRegistrationFn = void Function(ExecutorRegistry registry);

/// Factory for creating and configuring executor registries.
class ExecutorRegistryFactory {
  final List<ExecutorRegistrationFn> _registrations = [];

  /// Add a registration function.
  void addRegistration(ExecutorRegistrationFn fn) {
    _registrations.add(fn);
  }

  /// Create a new registry with all registered executors.
  ExecutorRegistry create() {
    final registry = DefaultExecutorRegistry();
    for (final fn in _registrations) {
      fn(registry);
    }
    return registry;
  }
}
