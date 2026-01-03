import 'dart:ui';
import 'package:logging/logging.dart';
import 'node_type.dart';
import 'workflow_connection.dart';
import '../../src/workflow/utils/deep_copy.dart';

final _logger = Logger('WorkflowNode');

/// A single node in a workflow graph.
class WorkflowNode {
  final String id;
  NodeType type;
  Offset position;
  Map<String, dynamic> config;
  String? label;

  /// Child nodes for container types (Loop, ForEach).
  /// Only applicable when [type.isContainer] is true.
  List<WorkflowNode>? children;

  /// Connections between child nodes within this container.
  /// Only applicable when [type.isContainer] is true.
  List<WorkflowConnection>? childConnections;

  WorkflowNode({
    required this.id,
    required this.type,
    required this.position,
    Map<String, dynamic>? config,
    this.label,
    this.children,
    this.childConnections,
  }) : config = config ?? type.configSchema.defaultConfig;

  /// Whether this node is an entry point (no inputs).
  bool get isEntry => type.isEntryNode;

  /// Whether this node is terminal (no outputs).
  bool get isTerminal => type.isTerminalNode;

  /// Display name for the node.
  String get displayName => label ?? type.displayName;

  /// Input port IDs for this node.
  List<String> get inputPortIds => type.inputPorts.map((p) => p.id).toList();

  /// Output port IDs for this node.
  List<String> get outputPortIds => type.outputPorts.map((p) => p.id).toList();

  /// Get a configuration value.
  T? getConfig<T>(String key) {
    final value = config[key];
    return value is T ? value : null;
  }

  /// Set a configuration value.
  void setConfig(String key, dynamic value) {
    config[key] = value;
  }

  WorkflowNode copyWith({
    String? id,
    NodeType? type,
    Offset? position,
    Map<String, dynamic>? config,
    String? label,
    List<WorkflowNode>? children,
    List<WorkflowConnection>? childConnections,
  }) {
    return WorkflowNode(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      // Bug #50 fix: Use deep copy to avoid shared references
      config: config ?? DeepCopyUtils.copyConfig(this.config),
      label: label ?? this.label,
      // Deep copy children to avoid shared references
      children: children ?? this.children?.map((c) => c.copyWith()).toList(),
      childConnections: childConnections ??
          this.childConnections?.map((c) => c.copyWith()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'position': {'x': position.dx, 'y': position.dy},
        'config': config,
        if (label != null) 'label': label,
        if (children != null && children!.isNotEmpty)
          'children': children!.map((c) => c.toJson()).toList(),
        if (childConnections != null && childConnections!.isNotEmpty)
          'childConnections': childConnections!.map((c) => c.toJson()).toList(),
      };

  factory WorkflowNode.fromJson(Map<String, dynamic> json) {
    final posJson = json['position'] as Map<String, dynamic>;
    final typeStr = json['type'] as String?;
    // Bug #54 fix: Log warning for unknown node types
    final type = NodeType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () {
        _logger.warning('Unknown node type "$typeStr", defaulting to start');
        return NodeType.start;
      },
    );

    // Parse children for container nodes
    final childrenJson = json['children'] as List?;
    final childConnectionsJson = json['childConnections'] as List?;

    return WorkflowNode(
      id: json['id'] as String,
      type: type,
      position: Offset(
        (posJson['x'] as num).toDouble(),
        (posJson['y'] as num).toDouble(),
      ),
      config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
      label: json['label'] as String?,
      children: childrenJson
          ?.map((c) => WorkflowNode.fromJson(c as Map<String, dynamic>))
          .toList(),
      childConnections: childConnectionsJson
          ?.map((c) => WorkflowConnection.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WorkflowNode && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
