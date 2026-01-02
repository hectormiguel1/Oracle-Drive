import 'dart:convert';
import 'dart:ui';
import 'package:uuid/uuid.dart';
import '../app_game_code.dart';
import 'node_type.dart';
import 'workflow_connection.dart';
import 'workflow_node.dart';
import 'workflow_variable.dart';

/// A complete workflow that can be executed.
class Workflow {
  final String id;
  String name;
  String description;
  final AppGameCode gameCode;
  final DateTime createdAt;
  DateTime modifiedAt;
  List<WorkflowNode> nodes;
  List<WorkflowConnection> connections;
  Map<String, WorkflowVariable> variables;

  /// Local workspace directory path for this workflow.
  /// This is persisted in the database but NOT included in JSON exports.
  String? workspacePath;

  Workflow({
    required this.id,
    required this.name,
    this.description = '',
    required this.gameCode,
    required this.createdAt,
    required this.modifiedAt,
    List<WorkflowNode>? nodes,
    List<WorkflowConnection>? connections,
    Map<String, WorkflowVariable>? variables,
    this.workspacePath,
  })  : nodes = nodes ?? [],
        connections = connections ?? [],
        variables = variables ?? {};

  /// Create a new empty workflow with a start node.
  factory Workflow.create({
    required String name,
    required AppGameCode gameCode,
    String description = '',
  }) {
    const uuid = Uuid();
    final now = DateTime.now();
    final workflow = Workflow(
      id: uuid.v4(),
      name: name,
      description: description,
      gameCode: gameCode,
      createdAt: now,
      modifiedAt: now,
    );

    // Add a start node
    workflow.nodes.add(WorkflowNode(
      id: uuid.v4(),
      type: NodeType.start,
      position: const Offset(100, 200),
    ));

    return workflow;
  }

  /// Get the entry (start) node.
  WorkflowNode? get entryNode =>
      nodes.where((n) => n.type == NodeType.start).firstOrNull;

  /// Get all terminal (end) nodes.
  List<WorkflowNode> get terminalNodes =>
      nodes.where((n) => n.type == NodeType.end).toList();

  /// Find a node by ID.
  WorkflowNode? findNode(String id) =>
      nodes.where((n) => n.id == id).firstOrNull;

  /// Find connections from a node.
  List<WorkflowConnection> findConnectionsFrom(String nodeId) =>
      connections.where((c) => c.sourceNodeId == nodeId).toList();

  /// Find connections to a node.
  List<WorkflowConnection> findConnectionsTo(String nodeId) =>
      connections.where((c) => c.targetNodeId == nodeId).toList();

  /// Find a connection from a specific port.
  WorkflowConnection? findConnectionFromPort(String nodeId, String port) =>
      connections
          .where((c) => c.sourceNodeId == nodeId && c.sourcePort == port)
          .firstOrNull;

  /// Add a node to the workflow.
  void addNode(WorkflowNode node) {
    nodes.add(node);
    modifiedAt = DateTime.now();
  }

  /// Remove a node and its connections.
  void removeNode(String nodeId) {
    nodes.removeWhere((n) => n.id == nodeId);
    connections.removeWhere(
        (c) => c.sourceNodeId == nodeId || c.targetNodeId == nodeId);
    modifiedAt = DateTime.now();
  }

  /// Add a connection between nodes.
  void addConnection(WorkflowConnection connection) {
    // Check if the source node allows multiple output connections
    final sourceNode = findNode(connection.sourceNodeId);
    final allowMultipleOutputs = sourceNode?.type.allowsMultipleOutputConnections ?? false;

    // Check if the target port allows multiple input connections
    final targetNode = findNode(connection.targetNodeId);
    final targetPortDef = targetNode?.type.inputPorts
        .where((p) => p.id == connection.targetPort)
        .firstOrNull;
    final allowMultipleInputs = targetPortDef?.allowMultiple ?? false;

    // Remove existing connections only if multiple are not allowed
    if (!allowMultipleOutputs) {
      connections.removeWhere((c) =>
          c.sourceNodeId == connection.sourceNodeId &&
          c.sourcePort == connection.sourcePort);
    }

    // For non-multi-input ports, remove existing connection to that port
    if (!allowMultipleInputs) {
      connections.removeWhere((c) =>
          c.targetNodeId == connection.targetNodeId &&
          c.targetPort == connection.targetPort);
    }

    connections.add(connection);
    modifiedAt = DateTime.now();
  }

  /// Remove a connection.
  void removeConnection(String connectionId) {
    connections.removeWhere((c) => c.id == connectionId);
    modifiedAt = DateTime.now();
  }

  /// Add or update a variable.
  void setVariable(String name, WorkflowVariable variable) {
    variables[name] = variable;
    modifiedAt = DateTime.now();
  }

  /// Remove a variable.
  void removeVariable(String name) {
    variables.remove(name);
    modifiedAt = DateTime.now();
  }

  /// Validate the workflow.
  List<WorkflowValidationError> validate() {
    final errors = <WorkflowValidationError>[];

    // Check for start node
    if (entryNode == null) {
      errors.add(WorkflowValidationError(
        type: ValidationErrorType.missingStartNode,
        message: 'Workflow must have a Start node',
      ));
    }

    // Check for end node
    if (terminalNodes.isEmpty) {
      errors.add(WorkflowValidationError(
        type: ValidationErrorType.missingEndNode,
        message: 'Workflow must have at least one End node',
      ));
    }

    // Check for disconnected nodes (except start/end)
    for (final node in nodes) {
      if (node.type == NodeType.start) continue;
      if (node.type == NodeType.end) continue;

      final hasInput = connections.any((c) => c.targetNodeId == node.id);
      final hasOutput = connections.any((c) => c.sourceNodeId == node.id);

      if (!hasInput) {
        errors.add(WorkflowValidationError(
          type: ValidationErrorType.disconnectedNode,
          nodeId: node.id,
          message: '${node.displayName} has no input connection',
        ));
      }

      if (!hasOutput) {
        errors.add(WorkflowValidationError(
          type: ValidationErrorType.disconnectedNode,
          nodeId: node.id,
          message: '${node.displayName} has no output connection',
        ));
      }
    }

    // Validate node configurations
    for (final node in nodes) {
      final configErrors = node.type.configSchema.validate(node.config);
      for (final error in configErrors) {
        errors.add(WorkflowValidationError(
          type: ValidationErrorType.invalidConfig,
          nodeId: node.id,
          message: '${node.displayName}: $error',
        ));
      }
    }

    // Bug #11 fix: Check for cycles using DFS
    // Note: Intentional loops (Loop/ForEach connecting back) are not counted as cycles
    // since they are handled specially by the engine
    final cycleError = _detectCycle();
    if (cycleError != null) {
      errors.add(cycleError);
    }

    return errors;
  }

  /// Bug #11 fix: Detect cycles in the workflow graph using DFS.
  /// Returns a validation error if a cycle is found, null otherwise.
  /// Excludes Loop and ForEach nodes from cycle detection since they're expected to loop.
  WorkflowValidationError? _detectCycle() {
    final visited = <String>{};
    final recursionStack = <String>{};
    final pathStack = <String>[];

    bool dfs(String nodeId) {
      visited.add(nodeId);
      recursionStack.add(nodeId);
      pathStack.add(nodeId);

      // Get all outgoing connections from this node
      final outgoing = connections.where((c) => c.sourceNodeId == nodeId);

      for (final conn in outgoing) {
        final targetId = conn.targetNodeId;

        // Skip if the source is a Loop or ForEach node connecting to its body
        // These are intentional loops handled by the engine
        final sourceNode = findNode(nodeId);
        if (sourceNode != null &&
            (sourceNode.type == NodeType.loop || sourceNode.type == NodeType.forEach) &&
            conn.sourcePort == 'body') {
          continue;
        }

        if (!visited.contains(targetId)) {
          if (dfs(targetId)) return true;
        } else if (recursionStack.contains(targetId)) {
          // Found a cycle
          return true;
        }
      }

      recursionStack.remove(nodeId);
      pathStack.removeLast();
      return false;
    }

    // Start DFS from all nodes (in case graph is disconnected)
    for (final node in nodes) {
      if (!visited.contains(node.id)) {
        if (dfs(node.id)) {
          return WorkflowValidationError(
            type: ValidationErrorType.cyclicDependency,
            message: 'Workflow contains a cycle which would cause infinite execution',
          );
        }
      }
    }

    return null;
  }

  /// Create a deep copy of the workflow.
  Workflow copy() {
    return Workflow(
      id: id,
      name: name,
      description: description,
      gameCode: gameCode,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      nodes: nodes.map((n) => n.copyWith()).toList(),
      connections: connections.map((c) => c.copyWith()).toList(),
      variables:
          Map.fromEntries(variables.entries.map((e) => MapEntry(e.key, e.value.copyWith()))),
      workspacePath: workspacePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'gameCode': gameCode.name,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'connections': connections.map((c) => c.toJson()).toList(),
        'variables':
            variables.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory Workflow.fromJson(Map<String, dynamic> json) {
    return Workflow(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      gameCode: AppGameCode.values.firstWhere(
        (g) => g.name == json['gameCode'],
        orElse: () => AppGameCode.ff13_1,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      nodes: (json['nodes'] as List)
          .map((n) => WorkflowNode.fromJson(n as Map<String, dynamic>))
          .toList(),
      connections: (json['connections'] as List)
          .map((c) => WorkflowConnection.fromJson(c as Map<String, dynamic>))
          .toList(),
      variables: (json['variables'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              WorkflowVariable.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
    );
  }

  /// Export to JSON string.
  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Import from JSON string.
  factory Workflow.fromJsonString(String jsonString) {
    return Workflow.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }
}

/// Types of validation errors.
enum ValidationErrorType {
  missingStartNode,
  missingEndNode,
  disconnectedNode,
  invalidConfig,
  cyclicDependency,
}

/// A validation error in a workflow.
class WorkflowValidationError {
  final ValidationErrorType type;
  final String? nodeId;
  final String message;

  WorkflowValidationError({
    required this.type,
    this.nodeId,
    required this.message,
  });
}
