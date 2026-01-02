/// Utilities for deep copying nested data structures.
///
/// This module provides functions to create deep copies of Maps and Lists,
/// ensuring that nested structures are also copied and not shared by reference.
class DeepCopyUtils {
  DeepCopyUtils._();

  /// Deep copy a map with nested structures.
  ///
  /// Recursively copies nested Maps and Lists to ensure complete isolation
  /// from the source data structure.
  ///
  /// Example:
  /// ```dart
  /// final original = {'a': {'b': 1}, 'c': [1, 2, 3]};
  /// final copy = DeepCopyUtils.copyMap(original);
  /// // Modifying copy won't affect original
  /// ```
  static Map<String, dynamic> copyMap(Map<String, dynamic>? source) {
    if (source == null) return {};
    return source.map((key, value) => MapEntry(key, _deepCopyValue(value)));
  }

  /// Deep copy a list with nested structures.
  ///
  /// Recursively copies nested Maps and Lists to ensure complete isolation
  /// from the source data structure.
  static List<dynamic> copyList(List<dynamic>? source) {
    if (source == null) return [];
    return source.map(_deepCopyValue).toList();
  }

  /// Deep copy any value, handling Maps, Lists, and primitives.
  static dynamic copyValue(dynamic value) => _deepCopyValue(value);

  static dynamic _deepCopyValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return copyMap(value);
    } else if (value is Map) {
      // Handle Map<dynamic, dynamic> by converting to Map<String, dynamic>
      return value.map(
        (key, val) => MapEntry(key.toString(), _deepCopyValue(val)),
      );
    } else if (value is List) {
      return copyList(value);
    }
    // Primitives (String, int, double, bool, null) are immutable
    return value;
  }

  /// Create a deep copy of workflow node configuration.
  ///
  /// This is a specialized alias for [copyMap] used in workflow node operations.
  static Map<String, dynamic> copyConfig(Map<String, dynamic>? config) {
    return copyMap(config);
  }

  /// Create a deep copy of a WDB record.
  ///
  /// This is a specialized alias for [copyMap] used in WDB operations.
  static Map<String, dynamic> copyRecord(Map<String, dynamic>? record) {
    return copyMap(record);
  }
}
