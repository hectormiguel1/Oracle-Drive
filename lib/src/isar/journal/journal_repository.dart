import 'package:isar_plus/isar_plus.dart';
import 'package:logging/logging.dart';
import 'package:oracle_drive/models/journal_types.dart';
import 'package:oracle_drive/src/isar/journal/journal_models.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing journal entries in the central database.
class JournalRepository {
  final Isar _database;
  final Logger _logger = Logger('JournalRepository');
  static const _uuid = Uuid();

  JournalRepository(this._database);

  // --- Write Operations ---

  /// Record a single change and return its entry ID.
  String recordChange({
    required String dataType,
    required int gameCode,
    String? sourceFile,
    required String recordId,
    String? columnName,
    required String operationType,
    String? previousValue,
    String? newValue,
    String? groupId,
    String? description,
  }) {
    final entryId = _uuid.v4();
    final effectiveGroupId = groupId ?? _uuid.v4();

    final entry = JournalEntry(
      entryId: entryId,
      groupId: effectiveGroupId,
      dataType: dataType,
      gameCode: gameCode,
      sourceFile: sourceFile,
      recordId: recordId,
      columnName: columnName,
      operationType: operationType,
      previousValue: previousValue,
      newValue: newValue,
      timestamp: DateTime.now(),
      description: description,
    );

    _database.write((db) {
      GetJournalEntryCollection(db).journalEntrys.put(entry);
    });

    _logger.fine('Recorded $operationType on $dataType:$recordId');
    return entryId;
  }

  /// Record multiple changes as a batch with the same group ID.
  /// Returns the group ID.
  String recordBatchChanges(
    List<JournalEntryData> entries, {
    String? description,
  }) {
    if (entries.isEmpty) return '';

    final groupId = _uuid.v4();
    final now = DateTime.now();

    final journalEntries = entries.map((e) => JournalEntry(
          entryId: _uuid.v4(),
          groupId: groupId,
          dataType: e.dataType.value,
          gameCode: e.gameCode,
          sourceFile: e.sourceFile,
          recordId: e.recordId,
          columnName: e.columnName,
          operationType: e.operationType.value,
          previousValue: JournalValueCodec.encode(e.previousValue),
          newValue: JournalValueCodec.encode(e.newValue),
          timestamp: now,
          description: description,
        )).toList();

    _database.write((db) {
      GetJournalEntryCollection(db).journalEntrys.putAll(journalEntries);
    });

    _logger.info('Recorded batch of ${entries.length} changes (group: $groupId)');
    return groupId;
  }

  /// Mark all entries in a group as undone.
  void markUndone(String groupId) {
    _database.write((db) {
      final collection = GetJournalEntryCollection(db).journalEntrys;
      final entries = collection.where().groupIdEqualTo(groupId).findAll();
      for (final entry in entries) {
        entry.isUndone = true;
        collection.put(entry);
      }
    });
    _logger.fine('Marked group $groupId as undone');
  }

  /// Mark all entries in a group as redone (clear isUndone flag).
  void markRedone(String groupId) {
    _database.write((db) {
      final collection = GetJournalEntryCollection(db).journalEntrys;
      final entries = collection.where().groupIdEqualTo(groupId).findAll();
      for (final entry in entries) {
        entry.isUndone = false;
        collection.put(entry);
      }
    });
    _logger.fine('Marked group $groupId as redone');
  }

  /// Delete all entries in a group.
  void deleteGroup(String groupId) {
    _database.write((db) {
      GetJournalEntryCollection(db)
          .journalEntrys
          .where()
          .groupIdEqualTo(groupId)
          .deleteAll();
    });
    _logger.fine('Deleted group $groupId');
  }

  // --- Read Operations ---

  /// Get all entries for a specific game, sorted by timestamp desc.
  List<JournalEntry> getEntriesForGame(
    int gameCode, {
    int limit = 100,
    int offset = 0,
  }) {
    return _database.read((db) {
      final entries = GetJournalEntryCollection(db)
          .journalEntrys
          .where()
          .gameCodeEqualTo(gameCode)
          .sortByTimestampDesc()
          .findAll();

      // Apply offset and limit in Dart
      if (offset >= entries.length) return [];
      final end = (offset + limit).clamp(0, entries.length);
      return entries.sublist(offset, end);
    });
  }

  /// Get entries for a specific source file.
  List<JournalEntry> getEntriesForFile(String sourceFile, {int limit = 100}) {
    return _database.read((db) {
      final entries = GetJournalEntryCollection(db)
          .journalEntrys
          .where()
          .sourceFileEqualTo(sourceFile)
          .sortByTimestampDesc()
          .findAll();

      // Apply limit in Dart
      return entries.take(limit).toList();
    });
  }

  /// Get entries for a specific record.
  List<JournalEntry> getEntriesForRecord(String dataType, String recordId) {
    return _database.read((db) {
      // Get all entries of this data type, then filter by recordId in Dart
      final entries = GetJournalEntryCollection(db)
          .journalEntrys
          .where()
          .dataTypeEqualTo(dataType)
          .sortByTimestampDesc()
          .findAll();

      return entries.where((e) => e.recordId == recordId).toList();
    });
  }

  /// Get the most recent group IDs (for undo stack).
  /// Excludes undone groups by default.
  List<String> getRecentGroupIds({int limit = 50, bool excludeUndone = true}) {
    return _database.read((db) {
      final entries = GetJournalEntryCollection(db)
          .journalEntrys
          .where()
          .sortByTimestampDesc()
          .findAll();

      // Filter by undone status in Dart if needed
      final filtered = excludeUndone
          ? entries.where((e) => !e.isUndone)
          : entries;

      // Extract unique group IDs preserving order
      final seen = <String>{};
      final groupIds = <String>[];
      for (final entry in filtered) {
        if (seen.add(entry.groupId)) {
          groupIds.add(entry.groupId);
          if (groupIds.length >= limit) break;
        }
      }
      return groupIds;
    });
  }

  /// Get all entries in a specific group.
  List<JournalEntry> getEntriesByGroup(String groupId) {
    return _database.read((db) {
      return GetJournalEntryCollection(db)
          .journalEntrys
          .where()
          .groupIdEqualTo(groupId)
          .sortByTimestamp()
          .findAll();
    });
  }

  /// Get undone group IDs (for redo stack).
  List<String> getUndoneGroupIds({int limit = 50}) {
    return _database.read((db) {
      final entries = GetJournalEntryCollection(db)
          .journalEntrys
          .where()
          .sortByTimestampDesc()
          .findAll();

      // Filter by isUndone in Dart
      final undoneEntries = entries.where((e) => e.isUndone);

      // Extract unique group IDs preserving order
      final seen = <String>{};
      final groupIds = <String>[];
      for (final entry in undoneEntries) {
        if (seen.add(entry.groupId)) {
          groupIds.add(entry.groupId);
          if (groupIds.length >= limit) break;
        }
      }
      return groupIds;
    });
  }

  /// Get the description of a group (from the first entry).
  String? getGroupDescription(String groupId) {
    return _database.read((db) {
      final entry = GetJournalEntryCollection(db)
          .journalEntrys
          .where()
          .groupIdEqualTo(groupId)
          .findFirst();
      return entry?.description;
    });
  }

  // --- Maintenance ---

  /// Purge entries older than the specified date.
  int purgeEntriesOlderThan(DateTime cutoff) {
    return _database.write((db) {
      return GetJournalEntryCollection(db)
          .journalEntrys
          .where()
          .timestampLessThan(cutoff)
          .deleteAll();
    });
  }

  /// Purge entries keeping only the last N entries.
  int purgeKeepingLast(int count) {
    return _database.write((db) {
      final collection = GetJournalEntryCollection(db).journalEntrys;
      final totalCount = collection.count();

      if (totalCount <= count) return 0;

      // Get the oldest entries to delete
      final toDelete = totalCount - count;
      final oldestEntries = collection
          .where()
          .sortByTimestamp()
          .findAll();

      // Take only the oldest entries (first toDelete entries)
      final entriesToDelete = oldestEntries.take(toDelete).toList();

      for (final entry in entriesToDelete) {
        collection.delete(entry.id);
      }

      _logger.info('Purged $toDelete journal entries');
      return toDelete;
    });
  }

  /// Get total entry count.
  int getEntryCount() {
    return _database.read((db) {
      return GetJournalEntryCollection(db).journalEntrys.count();
    });
  }

  /// Get distinct group count.
  int getGroupCount() {
    return _database.read((db) {
      final entries = GetJournalEntryCollection(db).journalEntrys.where().findAll();
      return entries.map((e) => e.groupId).toSet().length;
    });
  }

  /// Clear all journal entries.
  void clearAll() {
    _database.write((db) {
      GetJournalEntryCollection(db).journalEntrys.clear();
    });
    _logger.info('Cleared all journal entries');
  }
}
