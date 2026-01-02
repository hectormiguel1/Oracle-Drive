/// A connection between two nodes in a workflow.
class WorkflowConnection {
  final String id;
  final String sourceNodeId;
  final String sourcePort;
  final String targetNodeId;
  final String targetPort;

  WorkflowConnection({
    required this.id,
    required this.sourceNodeId,
    required this.sourcePort,
    required this.targetNodeId,
    required this.targetPort,
  });

  /// Create a connection ID from source and target.
  static String createId(
    String sourceNodeId,
    String sourcePort,
    String targetNodeId,
    String targetPort,
  ) {
    return '${sourceNodeId}:$sourcePort->${targetNodeId}:$targetPort';
  }

  WorkflowConnection copyWith({
    String? id,
    String? sourceNodeId,
    String? sourcePort,
    String? targetNodeId,
    String? targetPort,
  }) {
    return WorkflowConnection(
      id: id ?? this.id,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      sourcePort: sourcePort ?? this.sourcePort,
      targetNodeId: targetNodeId ?? this.targetNodeId,
      targetPort: targetPort ?? this.targetPort,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceNodeId': sourceNodeId,
        'sourcePort': sourcePort,
        'targetNodeId': targetNodeId,
        'targetPort': targetPort,
      };

  factory WorkflowConnection.fromJson(Map<String, dynamic> json) {
    // Bug #51 fix: Add null safety checks with meaningful error messages
    final id = json['id'] as String?;
    final sourceNodeId = json['sourceNodeId'] as String?;
    final sourcePort = json['sourcePort'] as String?;
    final targetNodeId = json['targetNodeId'] as String?;
    final targetPort = json['targetPort'] as String?;

    if (id == null || sourceNodeId == null || sourcePort == null ||
        targetNodeId == null || targetPort == null) {
      final missing = <String>[];
      if (id == null) missing.add('id');
      if (sourceNodeId == null) missing.add('sourceNodeId');
      if (sourcePort == null) missing.add('sourcePort');
      if (targetNodeId == null) missing.add('targetNodeId');
      if (targetPort == null) missing.add('targetPort');
      throw FormatException(
        'Invalid connection JSON: missing required fields: ${missing.join(", ")}',
      );
    }

    return WorkflowConnection(
      id: id,
      sourceNodeId: sourceNodeId,
      sourcePort: sourcePort,
      targetNodeId: targetNodeId,
      targetPort: targetPort,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WorkflowConnection && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
