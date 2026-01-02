import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:oracle_drive/models/journal_types.dart';
import 'package:oracle_drive/src/isar/journal/journal_repository.dart';
import 'package:oracle_drive/src/services/app_database.dart';
import 'package:oracle_drive/src/services/undo_redo_service.dart';

/// Provider for the undo/redo service.
final undoRedoServiceProvider = Provider<UndoRedoService>((ref) {
  final journalRepo = ref.read(_journalRepositoryProvider);
  return UndoRedoService(
    journalRepo,
    (gameCode) => AppDatabase.instance.getRepositoryForGame(gameCode),
  );
});

/// Internal provider for journal repository.
final _journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return AppDatabase.instance.journalRepository;
});

/// Provider for undo availability.
final canUndoProvider = StateProvider<bool>((ref) {
  final service = ref.watch(undoRedoServiceProvider);
  return service.canUndo;
});

/// Provider for redo availability.
final canRedoProvider = StateProvider<bool>((ref) {
  final service = ref.watch(undoRedoServiceProvider);
  return service.canRedo;
});

/// Provider for the undo description.
final undoDescriptionProvider = StateProvider<String?>((ref) {
  final service = ref.watch(undoRedoServiceProvider);
  return service.getUndoDescription();
});

/// Provider for the redo description.
final redoDescriptionProvider = StateProvider<String?>((ref) {
  final service = ref.watch(undoRedoServiceProvider);
  return service.getRedoDescription();
});

/// Provider for undo count.
final undoCountProvider = StateProvider<int>((ref) {
  final service = ref.watch(undoRedoServiceProvider);
  return service.undoCount;
});

/// Provider for redo count.
final redoCountProvider = StateProvider<int>((ref) {
  final service = ref.watch(undoRedoServiceProvider);
  return service.redoCount;
});

/// Notifier for managing undo/redo operations.
class UndoRedoNotifier extends StateNotifier<UndoRedoState> {
  final UndoRedoService _service;
  final Ref _ref;

  UndoRedoNotifier(this._service, this._ref) : super(UndoRedoState.initial()) {
    // Initialize the service on creation
    _service.initialize();
    _refreshState();
  }

  /// Initialize the undo/redo stacks.
  void initialize() {
    _service.initialize();
    _refreshState();
  }

  /// Perform undo.
  UndoResult undo() {
    final result = _service.undo();
    _refreshState();
    return result;
  }

  /// Perform redo.
  RedoResult redo() {
    final result = _service.redo();
    _refreshState();
    return result;
  }

  /// Push a group to the undo stack.
  /// Called after recording new changes.
  void pushToUndoStack(String groupId) {
    _service.pushToUndoStack(groupId);
    _refreshState();
  }

  /// Clear the redo stack.
  void clearRedoStack() {
    _service.clearRedoStack();
    _refreshState();
  }

  /// Refresh the state from the service.
  void _refreshState() {
    state = UndoRedoState(
      canUndo: _service.canUndo,
      canRedo: _service.canRedo,
      undoCount: _service.undoCount,
      redoCount: _service.redoCount,
      undoDescription: _service.getUndoDescription(),
      redoDescription: _service.getRedoDescription(),
    );

    // Also update the simple providers
    _ref.read(canUndoProvider.notifier).state = _service.canUndo;
    _ref.read(canRedoProvider.notifier).state = _service.canRedo;
    _ref.read(undoDescriptionProvider.notifier).state = _service.getUndoDescription();
    _ref.read(redoDescriptionProvider.notifier).state = _service.getRedoDescription();
    _ref.read(undoCountProvider.notifier).state = _service.undoCount;
    _ref.read(redoCountProvider.notifier).state = _service.redoCount;
  }

  /// Set callback for applying WDB changes during undo/redo.
  void setWdbChangeCallback(ApplyWdbChange callback) {
    _service.onApplyWdbChange = callback;
  }

  /// Set callback for applying ZTR changes during undo/redo.
  void setZtrChangeCallback(ApplyZtrChange callback) {
    _service.onApplyZtrChange = callback;
  }
}

/// State for undo/redo operations.
class UndoRedoState {
  final bool canUndo;
  final bool canRedo;
  final int undoCount;
  final int redoCount;
  final String? undoDescription;
  final String? redoDescription;

  const UndoRedoState({
    required this.canUndo,
    required this.canRedo,
    required this.undoCount,
    required this.redoCount,
    this.undoDescription,
    this.redoDescription,
  });

  factory UndoRedoState.initial() => const UndoRedoState(
        canUndo: false,
        canRedo: false,
        undoCount: 0,
        redoCount: 0,
      );

  UndoRedoState copyWith({
    bool? canUndo,
    bool? canRedo,
    int? undoCount,
    int? redoCount,
    String? undoDescription,
    String? redoDescription,
  }) {
    return UndoRedoState(
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      undoCount: undoCount ?? this.undoCount,
      redoCount: redoCount ?? this.redoCount,
      undoDescription: undoDescription ?? this.undoDescription,
      redoDescription: redoDescription ?? this.redoDescription,
    );
  }
}

/// Provider for the undo/redo notifier.
final undoRedoNotifierProvider =
    StateNotifierProvider<UndoRedoNotifier, UndoRedoState>((ref) {
  final service = ref.read(undoRedoServiceProvider);
  return UndoRedoNotifier(service, ref);
});
