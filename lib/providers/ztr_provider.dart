import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/models/journal_types.dart';
import 'package:oracle_drive/models/ztr_model.dart';
import 'package:oracle_drive/providers/journal_provider.dart';
import 'package:oracle_drive/providers/undo_redo_provider.dart';
import 'package:oracle_drive/src/services/app_database.dart';
import 'package:oracle_drive/src/services/native_service.dart';
import 'package:fabula_nova_sdk/bridge_generated/modules/ztr/structs.dart'
    as ztr_sdk;
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ZtrProvider');

// ============================================================
// Basic State Providers
// ============================================================

final ztrEntriesProvider = StateProvider.family<List<ZtrEntry>, AppGameCode>(
  (ref, game) => [],
);

final ztrFilterProvider = StateProvider.family<String, AppGameCode>(
  (ref, game) => '',
);

final ztrIsLoadingProvider = StateProvider.family<bool, AppGameCode>(
  (ref, game) => false,
);

final ztrStringCountProvider = StateProvider.family<int, AppGameCode>(
  (ref, game) => 0,
);

/// Available source files in the database.
final ztrSourceFilesProvider = StateProvider.family<List<String>, AppGameCode>(
  (ref, game) => [],
);

/// Currently selected source file filter (null = show all).
final ztrSourceFileFilterProvider = StateProvider.family<String?, AppGameCode>(
  (ref, game) => null,
);

/// Directory loading progress.
final ztrDirectoryProgressProvider =
    StateProvider.family<ztr_sdk.ZtrParseProgress?, AppGameCode>(
  (ref, game) => null,
);

// ============================================================
// Notifier for Business Logic
// ============================================================

final ztrNotifierProvider = Provider.family<ZtrNotifier, AppGameCode>(
  (ref, gameCode) => ZtrNotifier(ref, gameCode),
);

class ZtrNotifier {
  final Ref _ref;
  final AppGameCode _gameCode;

  ZtrNotifier(this._ref, this._gameCode);

  List<ZtrEntry> get entries => _ref.read(ztrEntriesProvider(_gameCode));
  String get filter => _ref.read(ztrFilterProvider(_gameCode));
  bool get isLoading => _ref.read(ztrIsLoadingProvider(_gameCode));
  int get stringCount => _ref.read(ztrStringCountProvider(_gameCode));
  List<String> get sourceFiles => _ref.read(ztrSourceFilesProvider(_gameCode));
  String? get sourceFileFilter =>
      _ref.read(ztrSourceFileFilterProvider(_gameCode));
  ztr_sdk.ZtrParseProgress? get directoryProgress =>
      _ref.read(ztrDirectoryProgressProvider(_gameCode));

  void setFilter(String filter) {
    _ref.read(ztrFilterProvider(_gameCode).notifier).state = filter;
  }

  void setSourceFileFilter(String? sourceFile) {
    _ref.read(ztrSourceFileFilterProvider(_gameCode).notifier).state =
        sourceFile;
  }

  Future<void> fetchStrings() async {
    _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = true;
    _ref.read(ztrEntriesProvider(_gameCode).notifier).state = [];

    try {
      await AppDatabase.ensureInitialized();
      final db = AppDatabase.instance;
      final repo = db.getRepositoryForGame(_gameCode);
      final count = repo.getStringCount();
      _ref.read(ztrStringCountProvider(_gameCode).notifier).state = count;

      if (count > 0) {
        final stream = repo.getStringsWithSource();
        final List<ZtrEntry> allEntries = [];

        await for (final chunk in stream) {
          final newEntries = chunk
              .map((s) => ZtrEntry(s.strResourceId, s.value, sourceFile: s.sourceFile))
              .toList();
          allEntries.addAll(newEntries);
          // Update progressively
          _ref.read(ztrEntriesProvider(_gameCode).notifier).state =
              List.from(allEntries);
        }
        _logger.info("Fetched ${allEntries.length} strings for display.");
      }

      // Refresh source files list
      refreshSourceFiles();
    } catch (e) {
      _logger.severe("Error fetching strings: $e");
      rethrow;
    } finally {
      _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = false;
    }
  }

  Future<void> loadZtrFile(String filePath) async {
    _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = true;

    try {
      await AppDatabase.ensureInitialized();
      _logger.info("Extracting ZTR: $filePath for game ${_gameCode.displayName}");
      await NativeService.instance.extractZtrData(filePath, _gameCode);
      _logger.info("ZTR extracted and loaded into database.");
      await fetchStrings();
    } catch (e, stack) {
      _logger.severe("Error loading ZTR: $e\n$stack");
      rethrow;
    } finally {
      _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = false;
    }
  }

  Future<void> dumpZtrFile(String outputPath) async {
    if (stringCount == 0) {
      throw Exception("No strings in database to dump.");
    }

    _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = true;

    try {
      await AppDatabase.ensureInitialized();
      _logger.info("Dumping ZTR data from DB to $outputPath for game ${_gameCode.displayName}");
      await NativeService.instance.dumpZtrFileFromDb(_gameCode, outputPath);
      _logger.info("ZTR data dumped successfully.");
    } catch (e, stack) {
      _logger.severe("Error dumping ZTR: $e\n$stack");
      rethrow;
    } finally {
      _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = false;
    }
  }

  Future<void> dumpTxtFile(String outputPath) async {
    if (stringCount == 0) {
      throw Exception("No strings in database to dump.");
    }

    _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = true;

    try {
      await AppDatabase.ensureInitialized();
      _logger.info("Dumping ZTR data from DB to $outputPath as text for game ${_gameCode.displayName}");
      await NativeService.instance.dumpTxtFileFromDb(_gameCode, outputPath);
      _logger.info("ZTR data dumped to text successfully.");
    } catch (e, stack) {
      _logger.severe("Error dumping ZTR to text: $e\n$stack");
      rethrow;
    } finally {
      _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = false;
    }
  }

  Future<void> updateEntry(ZtrEntry updatedEntry) async {
    _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = true;

    try {
      await AppDatabase.ensureInitialized();
      final repo = AppDatabase.instance.getRepositoryForGame(_gameCode);

      // Get previous value for journal
      final previousValue = repo.resolveStringId(updatedEntry.id);

      // Perform the update
      repo.updateString(updatedEntry.id, updatedEntry.text);
      _logger.info("Entry '${updatedEntry.id}' updated.");

      // Record in journal
      final journalService = _ref.read(journalServiceProvider);
      journalService.recordZtrChange(
        gameCode: _gameCode,
        stringId: updatedEntry.id,
        previousValue: previousValue,
        newValue: updatedEntry.text,
        operationType: JournalOperationType.update,
        sourceFile: updatedEntry.sourceFile,
      );

      // Notify undo/redo service
      if (!journalService.isBatchActive) {
        _ref.read(undoRedoNotifierProvider.notifier).clearRedoStack();
      }

      await fetchStrings();
    } catch (e) {
      _logger.severe("Error updating entry: $e");
      rethrow;
    } finally {
      _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = false;
    }
  }

  Future<void> addEntry(String id, String text) async {
    _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = true;

    try {
      await AppDatabase.ensureInitialized();
      AppDatabase.instance
          .getRepositoryForGame(_gameCode)
          .addString(id, text);
      _logger.info("Entry '$id' added.");

      // Record in journal
      final journalService = _ref.read(journalServiceProvider);
      journalService.recordZtrChange(
        gameCode: _gameCode,
        stringId: id,
        previousValue: null,
        newValue: text,
        operationType: JournalOperationType.add,
      );

      // Notify undo/redo service
      if (!journalService.isBatchActive) {
        _ref.read(undoRedoNotifierProvider.notifier).clearRedoStack();
      }

      await fetchStrings();
    } catch (e) {
      _logger.severe("Error adding entry: $e");
      rethrow;
    } finally {
      _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = false;
    }
  }

  Future<void> deleteEntry(String entryId) async {
    _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = true;

    try {
      await AppDatabase.ensureInitialized();
      final repo = AppDatabase.instance.getRepositoryForGame(_gameCode);

      // Get previous value for journal
      final previousValue = repo.resolveStringId(entryId);

      // Get source file from current entries if available
      final currentEntries = entries;
      final matchingEntry = currentEntries.cast<ZtrEntry?>().firstWhere(
        (e) => e?.id == entryId,
        orElse: () => null,
      );
      final sourceFile = matchingEntry?.sourceFile;

      // Perform the deletion
      repo.deleteString(entryId);
      _logger.info("Entry '$entryId' deleted.");

      // Record in journal
      final journalService = _ref.read(journalServiceProvider);
      journalService.recordZtrChange(
        gameCode: _gameCode,
        stringId: entryId,
        previousValue: previousValue,
        newValue: null,
        operationType: JournalOperationType.delete,
        sourceFile: sourceFile,
      );

      // Notify undo/redo service
      if (!journalService.isBatchActive) {
        _ref.read(undoRedoNotifierProvider.notifier).clearRedoStack();
      }

      await fetchStrings();
    } catch (e) {
      _logger.severe("Error deleting entry: $e");
      rethrow;
    } finally {
      _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = false;
    }
  }

  Future<void> resetDatabase() async {
    _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = true;

    try {
      await AppDatabase.ensureInitialized();
      final db = AppDatabase.instance;
      db.getRepositoryForGame(_gameCode).clearDatabase();
      _logger.info("Database reset for ${_gameCode.displayName}");
      await fetchStrings();
    } catch (e) {
      _logger.severe("Error resetting database: $e");
      rethrow;
    } finally {
      _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = false;
    }
  }

  /// Loads all ZTR files from a directory recursively.
  /// Streams progress updates and inserts entries into database when complete.
  /// [filePattern] - Optional pattern to filter files (e.g., "_us.ztr" for US region only)
  Future<void> loadZtrDirectory(String dirPath, {String? filePattern}) async {
    _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = true;
    _ref.read(ztrDirectoryProgressProvider(_gameCode).notifier).state = null;

    try {
      await AppDatabase.ensureInitialized();
      _logger.info(
        "Loading ZTR directory: $dirPath for game ${_gameCode.displayName}"
        "${filePattern != null ? ' (filter: $filePattern)' : ''}",
      );

      // Stream progress updates from Rust
      final progressStream = NativeService.instance.extractZtrDirectory(
        dirPath,
        _gameCode,
        filePattern: filePattern,
      );

      await for (final progress in progressStream) {
        _ref.read(ztrDirectoryProgressProvider(_gameCode).notifier).state =
            progress;
      }

      _logger.info("ZTR directory loaded and entries inserted into database.");
      await fetchStrings();
    } catch (e, stack) {
      _logger.severe("Error loading ZTR directory: $e\n$stack");
      rethrow;
    } finally {
      _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = false;
      _ref.read(ztrDirectoryProgressProvider(_gameCode).notifier).state = null;
    }
  }

  /// Dumps ZTR strings filtered by source file.
  Future<void> dumpZtrFileBySource(String sourceFile, String outputPath) async {
    _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = true;

    try {
      await AppDatabase.ensureInitialized();
      await NativeService.instance.dumpZtrFileFromDbBySource(
        _gameCode,
        sourceFile,
        outputPath,
      );
      _logger.info("Dumped ZTR from source $sourceFile to $outputPath");
    } catch (e, stack) {
      _logger.severe("Error dumping ZTR by source: $e\n$stack");
      rethrow;
    } finally {
      _ref.read(ztrIsLoadingProvider(_gameCode).notifier).state = false;
    }
  }

  /// Refreshes the list of available source files.
  void refreshSourceFiles() {
    final files = NativeService.instance.getZtrSourceFiles(_gameCode);
    _ref.read(ztrSourceFilesProvider(_gameCode).notifier).state = files;
  }
}

// ============================================================
// Filtered Data Provider
// ============================================================

final filteredZtrEntriesProvider = Provider.family<List<ZtrEntry>, AppGameCode>((
  ref,
  gameCode,
) {
  final entries = ref.watch(ztrEntriesProvider(gameCode));
  final filter = ref.watch(ztrFilterProvider(gameCode));
  final sourceFileFilter = ref.watch(ztrSourceFileFilterProvider(gameCode));

  var filtered = entries;

  // Filter by source file if set
  if (sourceFileFilter != null && sourceFileFilter.isNotEmpty) {
    filtered = filtered
        .where((entry) => entry.sourceFile == sourceFileFilter)
        .toList();
  }

  // Filter by text query
  if (filter.isNotEmpty) {
    final queryLower = filter.toLowerCase();
    filtered = filtered.where((entry) {
      return entry.id.toLowerCase().contains(queryLower) ||
          entry.text.toLowerCase().contains(queryLower);
    }).toList();
  }

  return filtered;
});
