import 'package:json_annotation/json_annotation.dart';

class BoolIntConverter implements JsonConverter<bool, dynamic> {
  const BoolIntConverter();

  @override
  bool fromJson(dynamic json) {
    if (json is bool) return json;
    if (json is int) return json == 1;
    if (json is String) {
      final lower = json.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  @override
  dynamic toJson(bool object) {
    // WDB usually expects strict types back.
    // If the original field was u1 (int), we should probably write back an int?
    // However, the Writer logic in NativeService might handle type conversion.
    // For safety, let's keep it as bool, assuming the Native writer handles bool->int if needed,
    // OR we might need to know the target type.
    // Given we are creating DTOs, let's stick to standard JSON types (bool).
    return object;
  }
}
