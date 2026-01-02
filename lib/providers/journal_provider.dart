import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/models/journal_types.dart';
import 'package:oracle_drive/src/isar/journal/journal_models.dart';
import 'package:oracle_drive/src/isar/journal/journal_repository.dart';
import 'package:oracle_drive/src/services/app_database.dart';
import 'package:oracle_drive/src/services/journal_service.dart';

/// Provider for the journal repository.
final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return AppDatabase.instance.journalRepository;
});

/// Provider for the journal service.
final journalServiceProvider = Provider<JournalService>((ref) {
  final journalRepo = ref.read(journalRepositoryProvider);
  final settingsRepo = AppDatabase.instance.settingsRepository;
  return JournalService(journalRepo, settingsRepo);
});

/// Provider for the total journal entry count.
final journalEntryCountProvider = StateProvider<int>((ref) {
  final repo = ref.read(journalRepositoryProvider);
  return repo.getEntryCount();
});

/// Provider for the total journal group count.
final journalGroupCountProvider = StateProvider<int>((ref) {
  final repo = ref.read(journalRepositoryProvider);
  return repo.getGroupCount();
});

/// Provider for fetching journal entries for a specific game.
final journalEntriesProvider = FutureProvider.family<List<JournalEntry>, JournalQuery>(
  (ref, query) async {
    final repo = ref.read(journalRepositoryProvider);
    return repo.getEntriesForGame(
      query.gameCode.index,
      limit: query.limit,
      offset: query.offset,
    );
  },
);

/// Provider for fetching journal entries for a specific file.
final journalEntriesForFileProvider = FutureProvider.family<List<JournalEntry>, String>(
  (ref, sourceFile) async {
    final repo = ref.read(journalRepositoryProvider);
    return repo.getEntriesForFile(sourceFile);
  },
);

/// Provider for fetching journal entries for a specific record.
final journalEntriesForRecordProvider =
    FutureProvider.family<List<JournalEntry>, RecordQuery>(
  (ref, query) async {
    final repo = ref.read(journalRepositoryProvider);
    return repo.getEntriesForRecord(query.dataType.value, query.recordId);
  },
);

/// Query parameters for fetching journal entries.
class JournalQuery {
  final AppGameCode gameCode;
  final int limit;
  final int offset;

  const JournalQuery({
    required this.gameCode,
    this.limit = 100,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalQuery &&
          runtimeType == other.runtimeType &&
          gameCode == other.gameCode &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(gameCode, limit, offset);
}

/// Query parameters for fetching journal entries for a specific record.
class RecordQuery {
  final JournalDataType dataType;
  final String recordId;

  const RecordQuery({
    required this.dataType,
    required this.recordId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordQuery &&
          runtimeType == other.runtimeType &&
          dataType == other.dataType &&
          recordId == other.recordId;

  @override
  int get hashCode => Object.hash(dataType, recordId);
}

/// Notifier for managing journal-related actions.
class JournalNotifier extends StateNotifier<JournalState> {
  final JournalService _service;
  final JournalRepository _repository;
  final Ref _ref;

  JournalNotifier(this._service, this._repository, this._ref)
      : super(JournalState.initial());

  /// Apply retention policy.
  void applyRetentionPolicy() {
    _service.applyRetentionPolicy();
    _refreshCounts();
  }

  /// Clear all journal entries.
  void clearAll() {
    _repository.clearAll();
    _refreshCounts();
    state = state.copyWith(entries: []);
  }

  /// Refresh the entry and group counts.
  void _refreshCounts() {
    _ref.read(journalEntryCountProvider.notifier).state = _repository.getEntryCount();
    _ref.read(journalGroupCountProvider.notifier).state = _repository.getGroupCount();
  }

  /// Load entries for a specific game.
  void loadEntriesForGame(AppGameCode gameCode, {int limit = 100, int offset = 0}) {
    final entries = _repository.getEntriesForGame(
      gameCode.index,
      limit: limit,
      offset: offset,
    );
    state = state.copyWith(entries: entries, isLoading: false);
  }

  /// Start a batch operation.
  String startBatch({String? description}) {
    final groupId = _service.startBatch(description: description);
    state = state.copyWith(currentBatchId: groupId);
    return groupId;
  }

  /// End the current batch operation.
  void endBatch() {
    _service.endBatch();
    _refreshCounts();
    state = state.copyWith(currentBatchId: null);
  }
}

/// State for the journal notifier.
class JournalState {
  final List<JournalEntry> entries;
  final bool isLoading;
  final String? currentBatchId;

  const JournalState({
    required this.entries,
    required this.isLoading,
    this.currentBatchId,
  });

  factory JournalState.initial() => const JournalState(
        entries: [],
        isLoading: false,
      );

  JournalState copyWith({
    List<JournalEntry>? entries,
    bool? isLoading,
    String? currentBatchId,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      currentBatchId: currentBatchId,
    );
  }
}

/// Provider for the journal notifier.
final journalNotifierProvider =
    StateNotifierProvider<JournalNotifier, JournalState>((ref) {
  final service = ref.read(journalServiceProvider);
  final repository = ref.read(journalRepositoryProvider);
  return JournalNotifier(service, repository, ref);
});
