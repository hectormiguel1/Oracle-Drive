import 'dart:convert';

import '../../../components/workflow/wbt_file_selector.dart';
import 'execution_context.dart';

/// Evaluates expressions in workflow configurations.
///
/// Supports:
/// - Variable references: ${varName}
/// - Nested property access: ${wdb.rows.length}
/// - String literals (no $)
/// - Numeric literals
/// - Boolean literals
class ExpressionEvaluator {
  final ExecutionContext context;

  ExpressionEvaluator(this.context);

  /// Evaluate an expression and return the result.
  dynamic evaluate(dynamic expression) {
    if (expression == null) return null;

    if (expression is! String) return expression;

    final str = expression.trim();

    // Check for boolean literals
    if (str == 'true') return true;
    if (str == 'false') return false;

    // Check for numeric literals
    final numValue = num.tryParse(str);
    if (numValue != null) return numValue;

    // Check for variable interpolation
    if (str.contains(r'${')) {
      return _evaluateInterpolated(str);
    }

    // Check for simple variable reference (no ${})
    if (context.hasVariable(str)) {
      return context.getVariable(str);
    }

    // Check for JSON array or object literals
    if ((str.startsWith('[') && str.endsWith(']')) ||
        (str.startsWith('{') && str.endsWith('}'))) {
      try {
        return json.decode(str);
      } catch (_) {
        // Not valid JSON, return as string
      }
    }

    // Return as string literal
    return str;
  }

  /// Evaluate a string with ${...} interpolations.
  dynamic _evaluateInterpolated(String str) {
    // If the entire string is a single variable reference, return the value directly
    final singleVarMatch = RegExp(r'^\$\{([^}]+)\}$').firstMatch(str);
    if (singleVarMatch != null) {
      return _evaluateVariableExpression(singleVarMatch.group(1)!);
    }

    // Otherwise, interpolate into a string
    return str.replaceAllMapped(RegExp(r'\$\{([^}]+)\}'), (match) {
      final expr = match.group(1)!;
      final value = _evaluateVariableExpression(expr);
      return value?.toString() ?? '';
    });
  }

  /// Evaluate a variable expression like "wdb.rows.length" or "item.sName".
  dynamic _evaluateVariableExpression(String expr) {
    final parts = _parsePropertyPath(expr);
    if (parts.isEmpty) return null;

    dynamic current = context.getVariable(parts.first);
    if (current == null) return null;

    for (int i = 1; i < parts.length; i++) {
      current = _getProperty(current, parts[i]);
      if (current == null) return null;
    }

    return current;
  }

  /// Parse a property path like "wdb.rows[0].sName" into parts.
  List<String> _parsePropertyPath(String path) {
    final parts = <String>[];
    final buffer = StringBuffer();
    var inBracket = false;

    for (int i = 0; i < path.length; i++) {
      final char = path[i];

      if (char == '[') {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
        inBracket = true;
      } else if (char == ']') {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
        inBracket = false;
      } else if (char == '.' && !inBracket) {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts;
  }

  /// Get a property from an object.
  dynamic _getProperty(dynamic obj, String property) {
    // Handle list index access
    if (obj is List) {
      final index = int.tryParse(property);
      if (index != null && index >= 0 && index < obj.length) {
        return obj[index];
      }
      // Special properties for lists
      if (property == 'length') return obj.length;
      if (property == 'first' && obj.isNotEmpty) return obj.first;
      if (property == 'last' && obj.isNotEmpty) return obj.last;
      if (property == 'isEmpty') return obj.isEmpty;
      if (property == 'isNotEmpty') return obj.isNotEmpty;
      return null;
    }

    // Handle map access
    if (obj is Map) {
      if (obj.containsKey(property)) {
        return obj[property];
      }
      // Special properties for maps
      if (property == 'length') return obj.length;
      if (property == 'keys') return obj.keys.toList();
      if (property == 'values') return obj.values.toList();
      if (property == 'isEmpty') return obj.isEmpty;
      if (property == 'isNotEmpty') return obj.isNotEmpty;
      return null;
    }

    // Handle WdbExecutionData
    if (obj is WdbExecutionData) {
      switch (property) {
        case 'rows':
          return obj.data.rows;
        case 'columns':
          return obj.data.columns;
        case 'sheetName':
          return obj.data.sheetName;
        case 'rowCount':
          return obj.data.rows.length;
        case 'sourcePath':
          return obj.sourcePath;
        case 'recordIds':
          return obj.recordIds;
      }
      return null;
    }

    // Handle ZtrExecutionData
    if (obj is ZtrExecutionData) {
      switch (property) {
        case 'entries':
          return obj.entries;
        case 'entryCount':
          return obj.entries.length;
        case 'sourcePath':
          return obj.sourcePath;
      }
      return null;
    }

    // Handle ZtrExecutionEntry
    if (obj is ZtrExecutionEntry) {
      switch (property) {
        case 'id':
          return obj.id;
        case 'text':
          return obj.text;
      }
      return null;
    }

    // Bug #13 fix: Handle WbtFileListData
    if (obj is WbtFileListData) {
      switch (property) {
        case 'entries':
          return obj.entries;
        case 'entryCount':
          return obj.entries.length;
        case 'fileListPath':
          return obj.fileListPath;
        case 'binPath':
          return obj.binPath;
      }
      return null;
    }

    // Handle String properties
    if (obj is String) {
      switch (property) {
        case 'length':
          return obj.length;
        case 'isEmpty':
          return obj.isEmpty;
        case 'isNotEmpty':
          return obj.isNotEmpty;
      }
      return null;
    }

    return null;
  }

  /// Evaluate a boolean condition.
  bool evaluateCondition(dynamic expression) {
    final result = evaluate(expression);

    if (result is bool) return result;
    if (result is num) return result != 0;
    if (result is String) return result.isNotEmpty;
    if (result is List) return result.isNotEmpty;
    if (result is Map) return result.isNotEmpty;

    return result != null;
  }

  /// Evaluate an expression and convert to string.
  String evaluateAsString(dynamic expression) {
    final result = evaluate(expression);
    return result?.toString() ?? '';
  }

  /// Evaluate an expression and convert to int.
  int evaluateAsInt(dynamic expression, {int defaultValue = 0}) {
    final result = evaluate(expression);
    if (result is int) return result;
    if (result is double) return result.round();
    if (result is String) return int.tryParse(result) ?? defaultValue;
    return defaultValue;
  }

  /// Evaluate an expression and convert to double.
  double evaluateAsDouble(dynamic expression, {double defaultValue = 0.0}) {
    final result = evaluate(expression);
    if (result is double) return result;
    if (result is int) return result.toDouble();
    if (result is String) return double.tryParse(result) ?? defaultValue;
    return defaultValue;
  }
}
