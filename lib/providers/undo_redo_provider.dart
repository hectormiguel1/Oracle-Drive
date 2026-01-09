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

/// Provider for undo availability - derived from notifier state.
final canUndoProvider = Provider<bool>((ref) {
  return ref.watch(undoRedoNotifierProvider.select((s) => s.canUndo));
});

/// Provider for redo availability - derived from notifier state.
final canRedoProvider = Provider<bool>((ref) {
  return ref.watch(undoRedoNotifierProvider.select((s) => s.canRedo));
});

/// Provider for the undo description - derived from notifier state.
final undoDescriptionProvider = Provider<String?>((ref) {
  return ref.watch(undoRedoNotifierProvider.select((s) => s.undoDescription));
});

/// Provider for the redo description - derived from notifier state.
final redoDescriptionProvider = Provider<String?>((ref) {
  return ref.watch(undoRedoNotifierProvider.select((s) => s.redoDescription));
});

/// Provider for undo count - derived from notifier state.
final undoCountProvider = Provider<int>((ref) {
  return ref.watch(undoRedoNotifierProvider.select((s) => s.undoCount));
});

/// Provider for redo count - derived from notifier state.
final redoCountProvider = Provider<int>((ref) {
  return ref.watch(undoRedoNotifierProvider.select((s) => s.redoCount));
});

/// Notifier for managing undo/redo operations.
class UndoRedoNotifier extends StateNotifier<UndoRedoState> {
  final UndoRedoService _service;

  UndoRedoNotifier(this._service) : super(UndoRedoState.initial()) {
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
  /// Derived providers (canUndoProvider, etc.) automatically update via select().
  void _refreshState() {
    state = UndoRedoState(
      canUndo: _service.canUndo,
      canRedo: _service.canRedo,
      undoCount: _service.undoCount,
      redoCount: _service.redoCount,
      undoDescription: _service.getUndoDescription(),
      redoDescription: _service.getRedoDescription(),
    );
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
  return UndoRedoNotifier(service);
});
