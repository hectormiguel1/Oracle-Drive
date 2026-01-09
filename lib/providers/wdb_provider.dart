import 'package:oracle_drive/components/wdb/wdb_bulk_update_dialog.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/models/journal_types.dart';
import 'package:oracle_drive/models/wdb_model.dart';
import 'package:oracle_drive/providers/journal_provider.dart';
import 'package:oracle_drive/providers/undo_redo_provider.dart';
import 'package:oracle_drive/src/services/app_database.dart';
import 'package:oracle_drive/src/services/formats/wdb_service.dart';
import 'package:oracle_drive/src/isar/common/lookup_config.dart';
import 'package:oracle_drive/src/isar/common/models.dart';
import 'package:oracle_drive/src/utils/ztr_text_renderer.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

export 'package:oracle_drive/components/wdb/wdb_bulk_update_dialog.dart' show BulkOperation, BulkUpdateResult;

final _logger = Logger('WdbProvider');

// ============================================================
// Basic State Providers
// ============================================================

final wdbPathProvider = StateProvider.family<String?, AppGameCode>(
  (ref, game) => null,
);

final wdbDataProvider = StateProvider.family<WdbData?, AppGameCode>(
  (ref, game) => null,
);

final wdbFilterProvider = StateProvider.family<String, AppGameCode>(
  (ref, game) => '',
);

final wdbIsProcessingProvider = StateProvider.family<bool, AppGameCode>(
  (ref, game) => false,
);

// ============================================================
// Notifier for Business Logic
// ============================================================

final wdbNotifierProvider = Provider.family<WdbNotifier, AppGameCode>(
  (ref, gameCode) => WdbNotifier(ref, gameCode),
);

class WdbNotifier {
  final Ref _ref;
  final AppGameCode _gameCode;

  WdbNotifier(this._ref, this._gameCode);

  WdbData? get data => _ref.read(wdbDataProvider(_gameCode));
  String? get path => _ref.read(wdbPathProvider(_gameCode));
  bool get isLoaded => data != null;

  void setFilter(String filter) {
    _ref.read(wdbFilterProvider(_gameCode).notifier).state = filter;
  }

  Future<void> loadWdb(String filePath) async {
    _ref.read(wdbPathProvider(_gameCode).notifier).state = filePath;
    _ref.read(wdbIsProcessingProvider(_gameCode).notifier).state = true;
    _ref.read(wdbDataProvider(_gameCode).notifier).state = null;
    _ref.read(wdbFilterProvider(_gameCode).notifier).state = '';

    try {
      _logger.info("Parsing WDB: $filePath with game code ${_gameCode.displayName}");
      final data = await WdbService.instance.parse(filePath, _gameCode);
      _ref.read(wdbDataProvider(_gameCode).notifier).state = data;
      _logger.info("Parsed ${data.rows.length} records.");

      // Extract and upsert lookups if this sheet has a LookupConfig
      await _extractAndUpsertLookups(data);
    } catch (e) {
      _logger.severe("Error loading WDB: $e");
      rethrow;
    } finally {
      _ref.read(wdbIsProcessingProvider(_gameCode).notifier).state = false;
    }
  }

  /// Extract lookups from WDB data and upsert to database.
  Future<void> _extractAndUpsertLookups(WdbData data) async {
    final sheetName = data.sheetName;
    final lookupConfig = LookupConfigRegistry.instance.resolve(_gameCode, sheetName);

    if (lookupConfig == null) {
      return; // No lookup config for this sheet
    }

    final lookups = <EntityLookup>[];
    for (final row in data.rows) {
      if (!row.containsKey('record')) continue;
      final record = row['record'] as String;
      final lookup = lookupConfig.extractFromRow(record, row);
      if (lookup != null) {
        lookups.add(lookup);
      }
    }

    if (lookups.isNotEmpty) {
      final repo = AppDatabase.instance.getRepositoryForGame(_gameCode);
      repo.upsertLookups(lookups);
      _logger.info("Upserted ${lookups.length} lookups for sheet $sheetName");
    }
  }

  Future<void> saveWdb(String outputPath) async {
    final wdbData = data;
    if (wdbData == null) return;

    _ref.read(wdbIsProcessingProvider(_gameCode).notifier).state = true;
    try {
      await WdbService.instance.save(outputPath, wdbData);
      _logger.info("Saved WDB to $outputPath");
    } catch (e) {
      _logger.severe("Error saving WDB: $e");
      rethrow;
    } finally {
      _ref.read(wdbIsProcessingProvider(_gameCode).notifier).state = false;
    }
  }

  Future<void> saveJson(String outputPath) async {
    final wdbData = data;
    if (wdbData == null) return;

    _ref.read(wdbIsProcessingProvider(_gameCode).notifier).state = true;
    try {
      await WdbService.instance.saveAsJson(outputPath, wdbData);
      _logger.info("Saved JSON to $outputPath");
    } catch (e) {
      _logger.severe("Error saving JSON: $e");
      rethrow;
    } finally {
      _ref.read(wdbIsProcessingProvider(_gameCode).notifier).state = false;
    }
  }

  void addNewRecord() {
    final wdbData = data;
    if (wdbData == null) return;

    final newRow = <String, dynamic>{};
    for (var col in wdbData.columns) {
      if (col.type == WdbColumnType.string) {
        newRow[col.originalName] = "";
      } else if (col.type == WdbColumnType.float) {
        newRow[col.originalName] = 0.0;
      } else {
        newRow[col.originalName] = 0;
      }
    }

    final newRows = List<Map<String, dynamic>>.from(wdbData.rows);
    final newIndex = newRows.length;
    newRows.add(newRow);

    // Record in journal
    final journalService = _ref.read(journalServiceProvider);
    journalService.recordWdbRecordAdd(
      gameCode: _gameCode,
      sourceFile: path ?? 'unknown',
      recordId: _getRecordId(newRow, newIndex),
      recordData: newRow,
      description: 'Add new record',
    );

    // Notify undo/redo service
    if (!journalService.isBatchActive) {
      _ref.read(undoRedoNotifierProvider.notifier).clearRedoStack();
    }

    _ref.read(wdbDataProvider(_gameCode).notifier).state = WdbData(
      sheetName: wdbData.sheetName,
      columns: wdbData.columns,
      rows: newRows,
      header: wdbData.header,
    );
  }

  void cloneRecord(int originalIndex, Map<String, dynamic> rowToCopy) {
    final wdbData = data;
    if (wdbData == null) return;

    final newRow = Map<String, dynamic>.from(rowToCopy);
    final newRows = List<Map<String, dynamic>>.from(wdbData.rows);
    final newIndex = originalIndex + 1;
    newRows.insert(newIndex, newRow);

    // Record in journal
    final journalService = _ref.read(journalServiceProvider);
    journalService.recordWdbRecordAdd(
      gameCode: _gameCode,
      sourceFile: path ?? 'unknown',
      recordId: _getRecordId(newRow, newIndex),
      recordData: newRow,
      description: 'Clone record',
    );

    // Notify undo/redo service
    if (!journalService.isBatchActive) {
      _ref.read(undoRedoNotifierProvider.notifier).clearRedoStack();
    }

    _ref.read(wdbDataProvider(_gameCode).notifier).state = WdbData(
      sheetName: wdbData.sheetName,
      columns: wdbData.columns,
      rows: newRows,
      header: wdbData.header,
    );
  }

  /// Apply bulk update to rows and return the count of updated rows
  int applyBulkUpdate({
    required WdbColumn column,
    required BulkOperation operation,
    required double value,
    required bool applyToFiltered,
    required bool treatZeroAsOne,
    required bool onlyIfGreater,
  }) {
    final wdbData = data;
    final filteredData = _ref.read(filteredWdbDataProvider(_gameCode));
    if (wdbData == null || filteredData == null) return 0;

    final rowsToUpdate = applyToFiltered ? filteredData.rows : wdbData.rows;
    final journalService = _ref.read(journalServiceProvider);

    // Build description for the bulk operation
    final opName = operation.name;
    final description = 'Bulk $opName ${column.displayName} by $value';

    // Start a batch for all changes
    journalService.startBatch(description: description);

    final changes = <BulkChangeRecord>[];
    int updatedCount = 0;
    int rowIndex = 0;

    for (final row in rowsToUpdate) {
      final currentValue = row[column.originalName];
      if (currentValue == null) {
        rowIndex++;
        continue;
      }

      num numValue;
      if (currentValue is int) {
        numValue = currentValue;
      } else if (currentValue is double) {
        numValue = currentValue;
      } else {
        rowIndex++;
        continue;
      }

      if (treatZeroAsOne && numValue == 0) {
        numValue = 1;
      }

      final double newValue;
      switch (operation) {
        case BulkOperation.multiply:
          newValue = numValue * value;
        case BulkOperation.divide:
          newValue = numValue / value;
        case BulkOperation.add:
          newValue = numValue + value;
        case BulkOperation.subtract:
          newValue = numValue - value;
        case BulkOperation.set:
          newValue = value;
      }

      if (onlyIfGreater && numValue <= newValue) {
        rowIndex++;
        continue;
      }

      final previousValue = currentValue;
      final actualNewValue = column.type == WdbColumnType.int
          ? newValue.round()
          : newValue;

      row[column.originalName] = actualNewValue;

      // Record this change
      changes.add(BulkChangeRecord(
        recordId: _getRecordId(row, rowIndex),
        previousValue: previousValue,
        newValue: actualNewValue,
      ));

      updatedCount++;
      rowIndex++;
    }

    // Record all changes as a bulk update
    if (changes.isNotEmpty) {
      journalService.recordWdbBulkUpdate(
        gameCode: _gameCode,
        sourceFile: path ?? 'unknown',
        columnName: column.originalName,
        changes: changes,
        description: description,
      );
    }

    journalService.endBatch();

    // Notify undo/redo service
    _ref.read(undoRedoNotifierProvider.notifier).clearRedoStack();

    // Trigger update
    _ref.read(wdbDataProvider(_gameCode).notifier).state = WdbData(
      sheetName: wdbData.sheetName,
      columns: wdbData.columns,
      rows: wdbData.rows,
      header: wdbData.header,
    );

    return updatedCount;
  }

  void notifyDataChanged() {
    final wdbData = data;
    if (wdbData == null) return;

    _ref.read(wdbDataProvider(_gameCode).notifier).state = WdbData(
      sheetName: wdbData.sheetName,
      columns: wdbData.columns,
      rows: wdbData.rows,
      header: wdbData.header,
    );
  }

  /// Record a single field change (called from WdbRecordEditor).
  void recordFieldChange({
    required int rowIndex,
    required String columnName,
    required dynamic previousValue,
    required dynamic newValue,
    Map<String, dynamic>? row,
  }) {
    final journalService = _ref.read(journalServiceProvider);
    final recordId = row != null
        ? _getRecordId(row, rowIndex)
        : 'row_$rowIndex';

    journalService.recordWdbChange(
      gameCode: _gameCode,
      sourceFile: path ?? 'unknown',
      recordId: recordId,
      columnName: columnName,
      previousValue: previousValue,
      newValue: newValue,
      operationType: JournalOperationType.update,
    );

    // Notify undo/redo service
    if (!journalService.isBatchActive) {
      _ref.read(undoRedoNotifierProvider.notifier).clearRedoStack();
    }
  }

  /// Generate a record ID for journaling purposes.
  /// Tries to use a meaningful ID column if available, falls back to index.
  String _getRecordId(Map<String, dynamic> row, int index) {
    // Try common ID column names
    final idColumns = ['id', 'sId', 'uId', 'iId', 'recordId', 'ID'];
    for (final col in idColumns) {
      if (row.containsKey(col) && row[col] != null) {
        return row[col].toString();
      }
    }
    // Fall back to row index
    return 'row_$index';
  }
}

// ============================================================
// Filtered Data Provider
// ============================================================

final filteredWdbDataProvider = Provider.family<WdbData?, AppGameCode>((
  ref,
  gameCode,
) {
  final data = ref.watch(wdbDataProvider(gameCode));
  final filterText = ref.watch(wdbFilterProvider(gameCode));

  if (data == null) return null;
  if (filterText.isEmpty) return data;

  final filter = filterText.toLowerCase();
  final originalRows = data.rows;

  final List<Map<String, dynamic>> filteredRows = [];
  final repo = AppDatabase.instance.getRepositoryForGame(gameCode);

  for (int i = 0; i < originalRows.length; i++) {
    final row = originalRows[i];

    bool match = false;
    for (var col in data.columns) {
      final val = row[col.originalName];

      // Handle enum columns - display enum name for filtering
      if (val is CrystalRole || val is CrystalNodeType) {
        // Dart enums have a .name property
        final enumVal = val as Enum;
        if (enumVal.name.toLowerCase().contains(filter)) {
          match = true;
          break;
        }
      }

      if (val.toString().toLowerCase().contains(filter)) {
        match = true;
        break;
      }

      if (val is String && val.isNotEmpty) {
        // Try to resolve string IDs for searching
        final resolved = repo.resolveStringId(val);
        if (resolved != null) {
          final stripped = ZtrTextRenderer.stripTags(resolved);
          if (stripped.toLowerCase().contains(filter)) {
            match = true;
            break;
          }
        }
      }
    }

    if (match) {
      filteredRows.add(row);
    }
  }

  return WdbData(
    sheetName: data.sheetName,
    columns: data.columns,
    rows: filteredRows,
  );
});
