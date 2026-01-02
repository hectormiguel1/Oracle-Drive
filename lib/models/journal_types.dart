import 'dart:convert';

/// Data types that can be journaled.
enum JournalDataType {
  ztr('ztr'),
  wdb('wdb');

  final String value;
  const JournalDataType(this.value);

  static JournalDataType fromString(String s) =>
      JournalDataType.values.firstWhere((e) => e.value == s);
}

/// Operation types for journal entries.
enum JournalOperationType {
  update('update'),
  add('add'),
  delete('delete'),
  bulkUpdate('bulk_update');

  final String value;
  const JournalOperationType(this.value);

  static JournalOperationType fromString(String s) =>
      JournalOperationType.values.firstWhere((e) => e.value == s);
}

/// Data for creating a journal entry (before it gets an ID/timestamp).
class JournalEntryData {
  final JournalDataType dataType;
  final int gameCode;
  final String? sourceFile;
  final String recordId;
  final String? columnName;
  final JournalOperationType operationType;
  final dynamic previousValue;
  final dynamic newValue;

  const JournalEntryData({
    required this.dataType,
    required this.gameCode,
    this.sourceFile,
    required this.recordId,
    this.columnName,
    required this.operationType,
    this.previousValue,
    this.newValue,
  });
}

/// A record of a single field change within a bulk update.
class BulkChangeRecord {
  final String recordId;
  final dynamic previousValue;
  final dynamic newValue;

  const BulkChangeRecord({
    required this.recordId,
    required this.previousValue,
    required this.newValue,
  });
}

/// Result of an undo operation.
class UndoResult {
  final bool success;
  final String? errorMessage;
  final int entriesReverted;
  final String? description;
  final String? groupId;

  const UndoResult({
    required this.success,
    this.errorMessage,
    this.entriesReverted = 0,
    this.description,
    this.groupId,
  });

  factory UndoResult.success({
    required int entriesReverted,
    String? description,
    String? groupId,
  }) =>
      UndoResult(
        success: true,
        entriesReverted: entriesReverted,
        description: description,
        groupId: groupId,
      );

  factory UndoResult.failure(String message) => UndoResult(
        success: false,
        errorMessage: message,
      );
}

/// Result of a redo operation.
class RedoResult {
  final bool success;
  final String? errorMessage;
  final int entriesReapplied;
  final String? description;
  final String? groupId;

  const RedoResult({
    required this.success,
    this.errorMessage,
    this.entriesReapplied = 0,
    this.description,
    this.groupId,
  });

  factory RedoResult.success({
    required int entriesReapplied,
    String? description,
    String? groupId,
  }) =>
      RedoResult(
        success: true,
        entriesReapplied: entriesReapplied,
        description: description,
        groupId: groupId,
      );

  factory RedoResult.failure(String message) => RedoResult(
        success: false,
        errorMessage: message,
      );
}

/// Utilities for encoding/decoding journal values.
class JournalValueCodec {
  JournalValueCodec._();

  /// Encode a value for storage in the journal.
  static String? encode(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    if (value is List || value is Map) return jsonEncode(value);
    if (value is Enum) return '${value.runtimeType}.${value.name}';
    return value.toString();
  }

  /// Decode a journal value back to its original type.
  /// For simple types, you may need to provide type hints.
  static dynamic decode(String? encoded, {Type? hint}) {
    if (encoded == null) return null;

    // Try parsing as number
    if (hint == int) return int.tryParse(encoded);
    if (hint == double) return double.tryParse(encoded);
    if (hint == bool) return encoded == 'true';

    // Try parsing as JSON
    if (encoded.startsWith('[') || encoded.startsWith('{')) {
      try {
        return jsonDecode(encoded);
      } catch (_) {
        return encoded;
      }
    }

    return encoded;
  }
}
