import 'package:logging/logging.dart';

final _logger = Logger('WorkflowVariable');

/// Sentinel value for copyWith to distinguish between "not provided" and "null"
const _unset = Object();

/// Types of variables that can be used in workflows.
enum VariableType {
  string('String'),
  int('Integer'),
  double('Decimal'),
  bool('Boolean'),
  list('List'),
  wdbData('WDB Data'),
  wdbRow('WDB Row'),
  ztrData('ZTR Data'),
  ztrEntry('ZTR Entry');

  final String displayName;
  const VariableType(this.displayName);

  dynamic get defaultValue => switch (this) {
        VariableType.string => '',
        VariableType.int => 0,
        VariableType.double => 0.0,
        VariableType.bool => false,
        VariableType.list => <dynamic>[],
        VariableType.wdbData => null,
        VariableType.wdbRow => null,
        VariableType.ztrData => null,
        VariableType.ztrEntry => null,
      };
}

/// A variable that can be used across the workflow.
class WorkflowVariable {
  final String name;
  final VariableType type;
  final dynamic defaultValue;
  final String? description;

  WorkflowVariable({
    required this.name,
    required this.type,
    this.defaultValue,
    this.description,
  });

  /// Bug #52 fix: Use sentinel pattern to allow setting defaultValue to null.
  WorkflowVariable copyWith({
    String? name,
    VariableType? type,
    Object? defaultValue = _unset,
    String? description,
  }) {
    return WorkflowVariable(
      name: name ?? this.name,
      type: type ?? this.type,
      defaultValue: identical(defaultValue, _unset) ? this.defaultValue : defaultValue,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        'defaultValue': _serializeValue(defaultValue),
        if (description != null) 'description': description,
      };

  factory WorkflowVariable.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    // Bug #53 fix: Log warning for unknown variable types
    final type = VariableType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () {
        _logger.warning('Unknown variable type "$typeStr", defaulting to string');
        return VariableType.string;
      },
    );
    return WorkflowVariable(
      name: json['name'] as String,
      type: type,
      defaultValue: json['defaultValue'],
      description: json['description'] as String?,
    );
  }

  static dynamic _serializeValue(dynamic value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;
    if (value is List) return value.map(_serializeValue).toList();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _serializeValue(v)));
    }
    return value.toString();
  }
}
