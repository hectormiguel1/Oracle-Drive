import 'package:isar_plus/isar_plus.dart';

part 'journal_models.g.dart';

/// FNV-1a 64bit hash algorithm optimized for Dart Strings
int _fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}

/// A single journal entry tracking a modification to ZTR or WDB data.
/// Entries with the same [groupId] belong to the same batch operation.
@Collection()
class JournalEntry {
  /// Unique entry ID (UUID)
  @Index()
  String entryId;

  /// Group ID for batch operations (same for all entries in a bulk operation)
  @Index()
  String groupId;

  /// Data type: 'ztr' or 'wdb'
  @Index()
  String dataType;

  /// Game code index (0=FF13, 1=FF13-2, 2=FF13-LR)
  @Index()
  int gameCode;

  /// Source file path context
  @Index()
  String? sourceFile;

  /// Record identifier (ZTR: strResourceId, WDB: record column value or row index)
  @Index()
  String recordId;

  /// Column/field name that changed (null for add/delete of entire record)
  String? columnName;

  /// Operation type: 'update', 'add', 'delete', 'bulk_update'
  String operationType;

  /// Previous value (JSON-encoded for complex types, null for 'add')
  String? previousValue;

  /// New value (JSON-encoded for complex types, null for 'delete')
  String? newValue;

  /// Timestamp of the change
  @Index()
  DateTime timestamp;

  /// Optional description (e.g., "Bulk multiply HP by 2")
  String? description;

  /// Whether this entry has been undone (for redo stack tracking)
  bool isUndone;

  JournalEntry({
    required this.entryId,
    required this.groupId,
    required this.dataType,
    required this.gameCode,
    this.sourceFile,
    required this.recordId,
    this.columnName,
    required this.operationType,
    this.previousValue,
    this.newValue,
    required this.timestamp,
    this.description,
    this.isUndone = false,
  });

  int get id => _fastHash(entryId);

  @override
  String toString() {
    final col = columnName != null ? '.$columnName' : '';
    return 'JournalEntry($dataType:$recordId$col, $operationType, undone=$isUndone)';
  }
}
