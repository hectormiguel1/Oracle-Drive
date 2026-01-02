import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/models/journal_types.dart';
import 'package:oracle_drive/src/isar/generic_repository.dart';
import 'package:oracle_drive/src/isar/journal/journal_models.dart';
import 'package:oracle_drive/src/isar/journal/journal_repository.dart';

/// Callback type for applying data changes during undo/redo.
typedef ApplyWdbChange = void Function(
  AppGameCode gameCode,
  String sourceFile,
  String recordId,
  String? columnName,
  dynamic value,
);

/// Callback type for applying ZTR changes during undo/redo.
typedef ApplyZtrChange = void Function(
  AppGameCode gameCode,
  String stringId,
  String? value,
  String? sourceFile,
);

/// Service for managing undo/redo operations.
/// Uses the journal to track changes and revert/reapply them.
class UndoRedoService {
  final JournalRepository _journalRepository;
  final GameRepository Function(AppGameCode) _getRepository;
  final Logger _logger = Logger('UndoRedoService');

  // In-memory stacks for fast access (group IDs)
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  // Maximum stack size to prevent memory issues
  static const int maxStackSize = 100;

  // Callbacks for applying changes (set by providers)
  ApplyWdbChange? onApplyWdbChange;
  ApplyZtrChange? onApplyZtrChange;

  UndoRedoService(this._journalRepository, this._getRepository);

  /// Initialize the undo/redo stacks from the database.
  void initialize() {
    _undoStack.clear();
    _redoStack.clear();

    // Load recent non-undone groups into undo stack
    final recentGroups = _journalRepository.getRecentGroupIds(
      limit: maxStackSize,
      excludeUndone: true,
    );
    _undoStack.addAll(recentGroups.reversed);

    // Load undone groups into redo stack
    final undoneGroups = _journalRepository.getUndoneGroupIds(limit: maxStackSize);
    _redoStack.addAll(undoneGroups.reversed);

    _logger.info('Initialized undo stack: ${_undoStack.length} groups, '
        'redo stack: ${_redoStack.length} groups');
  }

  /// Check if undo is available.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Check if redo is available.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Get the number of undoable operations.
  int get undoCount => _undoStack.length;

  /// Get the number of redoable operations.
  int get redoCount => _redoStack.length;

  /// Get the description of the next undo operation.
  String? getUndoDescription() {
    if (_undoStack.isEmpty) return null;
    return _journalRepository.getGroupDescription(_undoStack.last);
  }

  /// Get the description of the next redo operation.
  String? getRedoDescription() {
    if (_redoStack.isEmpty) return null;
    return _journalRepository.getGroupDescription(_redoStack.last);
  }

  /// Push a new group to the undo stack.
  /// Called when new changes are recorded.
  void pushToUndoStack(String groupId) {
    // Clear redo stack when new changes are made
    if (_redoStack.isNotEmpty) {
      _logger.fine('Clearing redo stack (${_redoStack.length} groups)');
      _redoStack.clear();
    }

    _undoStack.add(groupId);

    // Trim if exceeds max size
    while (_undoStack.length > maxStackSize) {
      _undoStack.removeAt(0);
    }

    _logger.fine('Pushed to undo stack: $groupId');
  }

  /// Clear the redo stack.
  /// Called when new changes are made that invalidate the redo history.
  void clearRedoStack() {
    if (_redoStack.isNotEmpty) {
      _logger.fine('Clearing redo stack (${_redoStack.length} groups)');
      _redoStack.clear();
    }
  }

  /// Perform undo operation.
  UndoResult undo() {
    if (!canUndo) {
      return UndoResult.failure('Nothing to undo');
    }

    final groupId = _undoStack.removeLast();
    final entries = _journalRepository.getEntriesByGroup(groupId);

    if (entries.isEmpty) {
      return UndoResult.failure('No entries found for group');
    }

    try {
      // Apply reverse changes in reverse order (last in, first out)
      for (final entry in entries.reversed) {
        _revertEntry(entry);
      }

      // Mark entries as undone in the journal
      _journalRepository.markUndone(groupId);

      // Move to redo stack
      _redoStack.add(groupId);

      final description = entries.first.description;
      _logger.info('Undid: $description (${entries.length} changes)');

      return UndoResult.success(
        entriesReverted: entries.length,
        description: description,
        groupId: groupId,
      );
    } catch (e) {
      _logger.severe('Undo failed: $e');
      // Put the group back on undo stack
      _undoStack.add(groupId);
      return UndoResult.failure('Undo failed: $e');
    }
  }

  /// Perform redo operation.
  RedoResult redo() {
    if (!canRedo) {
      return RedoResult.failure('Nothing to redo');
    }

    final groupId = _redoStack.removeLast();
    final entries = _journalRepository.getEntriesByGroup(groupId);

    if (entries.isEmpty) {
      return RedoResult.failure('No entries found for group');
    }

    try {
      // Reapply changes in original order
      for (final entry in entries) {
        _reapplyEntry(entry);
      }

      // Mark entries as not undone
      _journalRepository.markRedone(groupId);

      // Move to undo stack
      _undoStack.add(groupId);

      final description = entries.first.description;
      _logger.info('Redid: $description (${entries.length} changes)');

      return RedoResult.success(
        entriesReapplied: entries.length,
        description: description,
        groupId: groupId,
      );
    } catch (e) {
      _logger.severe('Redo failed: $e');
      // Put the group back on redo stack
      _redoStack.add(groupId);
      return RedoResult.failure('Redo failed: $e');
    }
  }

  /// Revert a single journal entry (undo).
  void _revertEntry(JournalEntry entry) {
    final gameCode = AppGameCode.values[entry.gameCode];

    if (entry.dataType == 'ztr') {
      _revertZtrEntry(entry, gameCode);
    } else if (entry.dataType == 'wdb') {
      _revertWdbEntry(entry, gameCode);
    }
  }

  /// Reapply a single journal entry (redo).
  void _reapplyEntry(JournalEntry entry) {
    final gameCode = AppGameCode.values[entry.gameCode];

    if (entry.dataType == 'ztr') {
      _reapplyZtrEntry(entry, gameCode);
    } else if (entry.dataType == 'wdb') {
      _reapplyWdbEntry(entry, gameCode);
    }
  }

  void _revertZtrEntry(JournalEntry entry, AppGameCode gameCode) {
    final repo = _getRepository(gameCode);
    final op = JournalOperationType.fromString(entry.operationType);

    switch (op) {
      case JournalOperationType.update:
        // Restore previous value
        if (entry.previousValue != null) {
          repo.updateString(entry.recordId, entry.previousValue!);
        }
        break;

      case JournalOperationType.add:
        // Delete the added string
        repo.deleteString(entry.recordId);
        break;

      case JournalOperationType.delete:
        // Re-add the deleted string
        if (entry.previousValue != null) {
          repo.addString(entry.recordId, entry.previousValue!);
        }
        break;

      case JournalOperationType.bulkUpdate:
        // Same as update for ZTR
        if (entry.previousValue != null) {
          repo.updateString(entry.recordId, entry.previousValue!);
        }
        break;
    }

    // Notify callback if set
    onApplyZtrChange?.call(
      gameCode,
      entry.recordId,
      entry.previousValue,
      entry.sourceFile,
    );
  }

  void _reapplyZtrEntry(JournalEntry entry, AppGameCode gameCode) {
    final repo = _getRepository(gameCode);
    final op = JournalOperationType.fromString(entry.operationType);

    switch (op) {
      case JournalOperationType.update:
      case JournalOperationType.bulkUpdate:
        // Apply new value
        if (entry.newValue != null) {
          repo.updateString(entry.recordId, entry.newValue!);
        }
        break;

      case JournalOperationType.add:
        // Re-add the string
        if (entry.newValue != null) {
          repo.addString(entry.recordId, entry.newValue!);
        }
        break;

      case JournalOperationType.delete:
        // Delete again
        repo.deleteString(entry.recordId);
        break;
    }

    // Notify callback if set
    onApplyZtrChange?.call(
      gameCode,
      entry.recordId,
      entry.newValue,
      entry.sourceFile,
    );
  }

  void _revertWdbEntry(JournalEntry entry, AppGameCode gameCode) {
    final op = JournalOperationType.fromString(entry.operationType);

    // For WDB, we use callbacks since the data is in-memory in providers
    if (onApplyWdbChange == null) {
      _logger.warning('No WDB change callback set, skipping WDB undo');
      return;
    }

    switch (op) {
      case JournalOperationType.update:
      case JournalOperationType.bulkUpdate:
        // Restore previous value
        final previousValue = entry.previousValue != null
            ? _decodeWdbValue(entry.previousValue!)
            : null;
        onApplyWdbChange!(
          gameCode,
          entry.sourceFile ?? '',
          entry.recordId,
          entry.columnName,
          previousValue,
        );
        break;

      case JournalOperationType.add:
        // Mark for deletion (callback handles this)
        onApplyWdbChange!(
          gameCode,
          entry.sourceFile ?? '',
          entry.recordId,
          null, // null columnName indicates whole record operation
          null, // null value indicates delete
        );
        break;

      case JournalOperationType.delete:
        // Re-add the record
        final recordData = entry.previousValue != null
            ? _decodeWdbValue(entry.previousValue!)
            : null;
        onApplyWdbChange!(
          gameCode,
          entry.sourceFile ?? '',
          entry.recordId,
          null,
          recordData,
        );
        break;
    }
  }

  void _reapplyWdbEntry(JournalEntry entry, AppGameCode gameCode) {
    final op = JournalOperationType.fromString(entry.operationType);

    if (onApplyWdbChange == null) {
      _logger.warning('No WDB change callback set, skipping WDB redo');
      return;
    }

    switch (op) {
      case JournalOperationType.update:
      case JournalOperationType.bulkUpdate:
        // Apply new value
        final newValue = entry.newValue != null
            ? _decodeWdbValue(entry.newValue!)
            : null;
        onApplyWdbChange!(
          gameCode,
          entry.sourceFile ?? '',
          entry.recordId,
          entry.columnName,
          newValue,
        );
        break;

      case JournalOperationType.add:
        // Re-add the record
        final recordData = entry.newValue != null
            ? _decodeWdbValue(entry.newValue!)
            : null;
        onApplyWdbChange!(
          gameCode,
          entry.sourceFile ?? '',
          entry.recordId,
          null,
          recordData,
        );
        break;

      case JournalOperationType.delete:
        // Delete again
        onApplyWdbChange!(
          gameCode,
          entry.sourceFile ?? '',
          entry.recordId,
          null,
          null,
        );
        break;
    }
  }

  dynamic _decodeWdbValue(String encoded) {
    // Try JSON first
    if (encoded.startsWith('[') || encoded.startsWith('{')) {
      try {
        return jsonDecode(encoded);
      } catch (_) {}
    }

    // Try number
    if (int.tryParse(encoded) != null) return int.parse(encoded);
    if (double.tryParse(encoded) != null) return double.parse(encoded);

    // Try bool
    if (encoded == 'true') return true;
    if (encoded == 'false') return false;

    // Return as string
    return encoded;
  }

  /// Get a summary of the current undo/redo state.
  Map<String, dynamic> getState() {
    return {
      'canUndo': canUndo,
      'canRedo': canRedo,
      'undoCount': undoCount,
      'redoCount': redoCount,
      'undoDescription': getUndoDescription(),
      'redoDescription': getRedoDescription(),
    };
  }
}
