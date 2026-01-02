import 'package:logging/logging.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/models/journal_types.dart';
import 'package:oracle_drive/src/isar/journal/journal_repository.dart';
import 'package:oracle_drive/src/isar/settings/settings_models.dart';
import 'package:oracle_drive/src/isar/settings/settings_repository.dart';
import 'package:uuid/uuid.dart';

/// High-level service for recording changes to the journal.
/// Provides batch operation support and retention policy enforcement.
class JournalService {
  final JournalRepository _journalRepository;
  final SettingsRepository _settingsRepository;
  final Logger _logger = Logger('JournalService');
  static const _uuid = Uuid();

  // Current batch state
  String? _currentBatchId;
  String? _currentBatchDescription;
  int _batchEntryCount = 0;

  JournalService(this._journalRepository, this._settingsRepository);

  /// Check if journaling is enabled.
  bool get isEnabled => _settingsRepository.isJournalEnabled();

  /// Check if a batch operation is currently active.
  bool get isBatchActive => _currentBatchId != null;

  /// Get the current batch ID (null if no batch active).
  String? get currentBatchId => _currentBatchId;

  // --- Batch Operations ---

  /// Start a batch operation. All changes recorded until [endBatch] is called
  /// will share the same group ID.
  /// Returns the batch group ID.
  String startBatch({String? description}) {
    if (_currentBatchId != null) {
      _logger.warning('Starting new batch while previous batch is still active');
      endBatch();
    }

    _currentBatchId = _uuid.v4();
    _currentBatchDescription = description;
    _batchEntryCount = 0;
    _logger.fine('Started batch: $_currentBatchId ($description)');
    return _currentBatchId!;
  }

  /// End the current batch operation.
  void endBatch() {
    if (_currentBatchId != null) {
      _logger.fine('Ended batch: $_currentBatchId ($_batchEntryCount entries)');
    }
    _currentBatchId = null;
    _currentBatchDescription = null;
    _batchEntryCount = 0;
  }

  // --- ZTR Change Recording ---

  /// Record a change to a ZTR string entry.
  void recordZtrChange({
    required AppGameCode gameCode,
    required String stringId,
    String? previousValue,
    String? newValue,
    required JournalOperationType operationType,
    String? sourceFile,
    String? description,
  }) {
    if (!isEnabled) return;

    final groupId = _currentBatchId ?? _uuid.v4();
    final desc = description ?? _currentBatchDescription ?? _defaultDescription(operationType, 'string');

    _journalRepository.recordChange(
      dataType: JournalDataType.ztr.value,
      gameCode: gameCode.index,
      sourceFile: sourceFile,
      recordId: stringId,
      columnName: null,
      operationType: operationType.value,
      previousValue: previousValue,
      newValue: newValue,
      groupId: groupId,
      description: desc,
    );

    _batchEntryCount++;
    _logger.fine('Recorded ZTR ${operationType.value}: $stringId');
  }

  // --- WDB Change Recording ---

  /// Record a change to a WDB record field.
  void recordWdbChange({
    required AppGameCode gameCode,
    required String sourceFile,
    required String recordId,
    required String columnName,
    dynamic previousValue,
    dynamic newValue,
    required JournalOperationType operationType,
    String? description,
  }) {
    if (!isEnabled) return;

    final groupId = _currentBatchId ?? _uuid.v4();
    final desc = description ?? _currentBatchDescription ?? _defaultDescription(operationType, columnName);

    _journalRepository.recordChange(
      dataType: JournalDataType.wdb.value,
      gameCode: gameCode.index,
      sourceFile: sourceFile,
      recordId: recordId,
      columnName: columnName,
      operationType: operationType.value,
      previousValue: JournalValueCodec.encode(previousValue),
      newValue: JournalValueCodec.encode(newValue),
      groupId: groupId,
      description: desc,
    );

    _batchEntryCount++;
    _logger.fine('Recorded WDB ${operationType.value}: $recordId.$columnName');
  }

  /// Record a WDB record addition (whole record).
  void recordWdbRecordAdd({
    required AppGameCode gameCode,
    required String sourceFile,
    required String recordId,
    required Map<String, dynamic> recordData,
    String? description,
  }) {
    if (!isEnabled) return;

    final groupId = _currentBatchId ?? _uuid.v4();
    final desc = description ?? _currentBatchDescription ?? 'Add record';

    _journalRepository.recordChange(
      dataType: JournalDataType.wdb.value,
      gameCode: gameCode.index,
      sourceFile: sourceFile,
      recordId: recordId,
      columnName: null,
      operationType: JournalOperationType.add.value,
      previousValue: null,
      newValue: JournalValueCodec.encode(recordData),
      groupId: groupId,
      description: desc,
    );

    _batchEntryCount++;
    _logger.fine('Recorded WDB add record: $recordId');
  }

  /// Record a WDB record deletion (whole record).
  void recordWdbRecordDelete({
    required AppGameCode gameCode,
    required String sourceFile,
    required String recordId,
    required Map<String, dynamic> recordData,
    String? description,
  }) {
    if (!isEnabled) return;

    final groupId = _currentBatchId ?? _uuid.v4();
    final desc = description ?? _currentBatchDescription ?? 'Delete record';

    _journalRepository.recordChange(
      dataType: JournalDataType.wdb.value,
      gameCode: gameCode.index,
      sourceFile: sourceFile,
      recordId: recordId,
      columnName: null,
      operationType: JournalOperationType.delete.value,
      previousValue: JournalValueCodec.encode(recordData),
      newValue: null,
      groupId: groupId,
      description: desc,
    );

    _batchEntryCount++;
    _logger.fine('Recorded WDB delete record: $recordId');
  }

  /// Record a bulk update operation on WDB records.
  /// Each change is recorded as a separate entry but all share the same group ID.
  void recordWdbBulkUpdate({
    required AppGameCode gameCode,
    required String sourceFile,
    required String columnName,
    required List<BulkChangeRecord> changes,
    required String description,
  }) {
    if (!isEnabled) return;
    if (changes.isEmpty) return;

    final entries = changes.map((c) => JournalEntryData(
          dataType: JournalDataType.wdb,
          gameCode: gameCode.index,
          sourceFile: sourceFile,
          recordId: c.recordId,
          columnName: columnName,
          operationType: JournalOperationType.bulkUpdate,
          previousValue: c.previousValue,
          newValue: c.newValue,
        )).toList();

    _journalRepository.recordBatchChanges(entries, description: description);
    _batchEntryCount += changes.length;
    _logger.info('Recorded WDB bulk update: ${changes.length} changes to $columnName');
  }

  // --- Retention Policy ---

  /// Apply the configured retention policy.
  /// Should be called on app startup and periodically.
  void applyRetentionPolicy() {
    final mode = _settingsRepository.getJournalRetentionMode();

    switch (mode) {
      case JournalRetentionMode.unlimited:
        // No cleanup needed
        break;

      case JournalRetentionMode.days:
        final days = _settingsRepository.getJournalRetentionDays();
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final deleted = _journalRepository.purgeEntriesOlderThan(cutoff);
        if (deleted > 0) {
          _logger.info('Retention policy: purged $deleted entries older than $days days');
        }
        break;

      case JournalRetentionMode.count:
        final count = _settingsRepository.getJournalRetentionCount();
        final deleted = _journalRepository.purgeKeepingLast(count);
        if (deleted > 0) {
          _logger.info('Retention policy: purged $deleted entries (keeping last $count)');
        }
        break;
    }
  }

  // --- Helpers ---

  String _defaultDescription(JournalOperationType op, String field) {
    switch (op) {
      case JournalOperationType.add:
        return 'Add $field';
      case JournalOperationType.update:
        return 'Update $field';
      case JournalOperationType.delete:
        return 'Delete $field';
      case JournalOperationType.bulkUpdate:
        return 'Bulk update $field';
    }
  }

  // --- Stats ---

  /// Get the total number of journal entries.
  int get entryCount => _journalRepository.getEntryCount();

  /// Get the total number of change groups.
  int get groupCount => _journalRepository.getGroupCount();
}
