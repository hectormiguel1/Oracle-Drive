import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../models/app_game_code.dart';
import '../../../models/journal_types.dart';
import '../../../models/wdb_model.dart';
import '../../../providers/journal_provider.dart';
import '../../../providers/workflow_provider.dart';

/// Runtime context for workflow execution.
class ExecutionContext {
  final AppGameCode gameCode;
  final Ref ref;
  final bool previewMode;

  /// Workspace directory for resolving relative paths.
  final String? workspaceDir;

  /// Variable values during execution.
  final Map<String, dynamic> variables = {};

  /// Open WDB files keyed by variable name.
  final Map<String, WdbExecutionData> openWdbs = {};

  /// Open ZTR files keyed by variable name.
  final Map<String, ZtrExecutionData> openZtrs = {};

  /// Pending changes for preview mode.
  final List<WorkflowChange> pendingChanges = [];

  /// Journal entries to record when WDB is saved.
  /// Maps WDB variable name to list of changes.
  final Map<String, List<JournalEntryData>> _wdbJournalChanges = {};

  /// Clipboard for copy/paste operations.
  Map<String, dynamic>? clipboard;

  /// Loop state tracking.
  final Map<String, int> loopIndices = {};

  ExecutionContext({
    required this.gameCode,
    required this.ref,
    this.previewMode = false,
    this.workspaceDir,
  }) {
    // Set workspaceDir as a variable so it can be used in expressions
    if (workspaceDir != null) {
      variables['workspaceDir'] = workspaceDir;
    }
  }

  /// Resolve a file path, handling relative paths against the workspace directory.
  /// If the path is absolute, returns it as-is.
  /// If the path is relative and workspaceDir is set, resolves it against workspaceDir.
  /// Supports forward slashes on all platforms.
  String resolvePath(String filePath) {
    if (filePath.isEmpty) return filePath;

    // Normalize path separators
    var normalized = filePath.replaceAll('\\', '/');

    // Check if it's an absolute path
    if (p.isAbsolute(normalized)) {
      return normalized;
    }

    // Bug #46 fix: Check if it contains unresolved variable references like ${workspaceDir}
    // The expression evaluator should have already resolved this, but if not, try to resolve here
    if (normalized.contains('\${') || normalized.contains('\$')) {
      // Try to resolve simple variable references
      normalized = normalized.replaceAllMapped(
        RegExp(r'\$\{([^}]+)\}'),
        (match) {
          final varName = match.group(1);
          if (varName != null && variables.containsKey(varName)) {
            return variables[varName].toString();
          }
          return match.group(0)!; // Keep original if not found
        },
      );
      // If still contains unresolved references, return as-is
      if (normalized.contains('\${')) {
        return normalized;
      }
    }

    // If we have a workspace directory, resolve the relative path
    if (workspaceDir != null && workspaceDir!.isNotEmpty) {
      return p.normalize(p.join(workspaceDir!, normalized));
    }

    // Return as-is if no workspace directory
    return normalized;
  }

  /// Check if a resolved path exists.
  bool pathExists(String filePath) {
    final resolved = resolvePath(filePath);
    return File(resolved).existsSync() || Directory(resolved).existsSync();
  }

  /// Get a variable value.
  dynamic getVariable(String name) => variables[name];

  /// Set a variable value.
  void setVariable(String name, dynamic value) {
    variables[name] = value;
  }

  /// Check if a variable exists.
  bool hasVariable(String name) => variables.containsKey(name);

  /// Get an open WDB by variable name.
  WdbExecutionData? getWdb(String name) => openWdbs[name];

  /// Store an open WDB.
  void setWdb(String name, WdbExecutionData data) {
    openWdbs[name] = data;
    variables[name] = data;
  }

  /// Get an open ZTR by variable name.
  ZtrExecutionData? getZtr(String name) => openZtrs[name];

  /// Store an open ZTR.
  void setZtr(String name, ZtrExecutionData data) {
    openZtrs[name] = data;
    variables[name] = data;
  }

  /// Add a pending change (preview mode only).
  void addChange(WorkflowChange change) {
    if (previewMode) {
      pendingChanges.add(change);
    }
  }

  /// Record a WDB field change for journaling.
  void recordWdbChange({
    required String wdbName,
    required String sourceFile,
    required String recordId,
    required String columnName,
    required dynamic previousValue,
    required dynamic newValue,
  }) {
    if (previewMode) return; // Don't journal in preview mode

    _wdbJournalChanges.putIfAbsent(wdbName, () => []);
    _wdbJournalChanges[wdbName]!.add(JournalEntryData(
      dataType: JournalDataType.wdb,
      gameCode: gameCode.index,
      sourceFile: sourceFile,
      recordId: recordId,
      columnName: columnName,
      operationType: JournalOperationType.update,
      previousValue: previousValue,
      newValue: newValue,
    ));
  }

  /// Flush journal changes for a WDB to the journal service.
  /// Called after WDB is saved successfully.
  void flushWdbJournalChanges(String wdbName, String description) {
    final changes = _wdbJournalChanges[wdbName];
    if (changes == null || changes.isEmpty) return;

    final journalService = ref.read(journalServiceProvider);
    journalService.recordWdbBulkUpdate(
      gameCode: gameCode,
      sourceFile: openWdbs[wdbName]?.sourcePath ?? wdbName,
      columnName: 'multiple',
      changes: changes.map((e) => BulkChangeRecord(
        recordId: e.recordId,
        previousValue: e.previousValue,
        newValue: e.newValue,
      )).toList(),
      description: description,
    );

    // Clear recorded changes after flushing
    _wdbJournalChanges.remove(wdbName);
  }

  /// Get count of pending journal changes for a WDB.
  int getWdbJournalChangeCount(String wdbName) {
    return _wdbJournalChanges[wdbName]?.length ?? 0;
  }

  /// Get or initialize a loop index.
  int getLoopIndex(String loopId) => loopIndices[loopId] ?? 0;

  /// Increment and return the new loop index.
  int incrementLoopIndex(String loopId) {
    final current = loopIndices[loopId] ?? 0;
    loopIndices[loopId] = current + 1;
    return current + 1;
  }

  /// Reset a loop index.
  void resetLoopIndex(String loopId) {
    loopIndices.remove(loopId);
  }

  /// Bug #8 fix: Create an isolated copy of this context for parallel branch execution.
  /// Variables and loop indices are copied to prevent race conditions.
  /// Open WDBs and ZTRs are shared (intentionally) as they represent the same file handles.
  ExecutionContext fork() {
    final forked = ExecutionContext(
      gameCode: gameCode,
      ref: ref,
      previewMode: previewMode,
      workspaceDir: workspaceDir,
    );

    // Deep copy variables to prevent race conditions
    forked.variables.addAll(Map<String, dynamic>.from(variables));

    // Copy loop indices
    forked.loopIndices.addAll(Map<String, int>.from(loopIndices));

    // Share clipboard (it's meant to be shared across operations)
    forked.clipboard = clipboard;

    // Share open file handles (they represent the same files)
    forked.openWdbs.addAll(openWdbs);
    forked.openZtrs.addAll(openZtrs);

    // Share journal changes (they should be merged back)
    for (final entry in _wdbJournalChanges.entries) {
      forked._wdbJournalChanges[entry.key] = List.from(entry.value);
    }

    return forked;
  }

  /// Merge results from a forked branch back into this context.
  /// Used after parallel branches complete to consolidate state.
  void merge(ExecutionContext other) {
    // Merge new variables (prefer other's values for variables modified in the branch)
    for (final entry in other.variables.entries) {
      if (!variables.containsKey(entry.key) ||
          variables[entry.key] != entry.value) {
        variables[entry.key] = entry.value;
      }
    }

    // Merge pending changes
    pendingChanges.addAll(other.pendingChanges);

    // Update clipboard if changed
    if (other.clipboard != null) {
      clipboard = other.clipboard;
    }

    // Merge any new open files
    openWdbs.addAll(other.openWdbs);
    openZtrs.addAll(other.openZtrs);

    // Merge journal changes
    for (final entry in other._wdbJournalChanges.entries) {
      _wdbJournalChanges.putIfAbsent(entry.key, () => []);
      _wdbJournalChanges[entry.key]!.addAll(entry.value);
    }
  }
}

/// Wrapper for WDB data during execution.
class WdbExecutionData {
  final String sourcePath;
  final WdbData data;
  bool modified = false;

  WdbExecutionData({
    required this.sourcePath,
    required this.data,
  });

  /// Find a record by its ID.
  Map<String, dynamic>? findRecord(String recordId) {
    for (final row in data.rows) {
      if (row['record'] == recordId) {
        return row;
      }
    }
    return null;
  }

  /// Find the index of a record by ID.
  int findRecordIndex(String recordId) {
    for (int i = 0; i < data.rows.length; i++) {
      if (data.rows[i]['record'] == recordId) {
        return i;
      }
    }
    return -1;
  }

  /// Get all record IDs.
  List<String> get recordIds =>
      data.rows.map((r) => r['record'] as String).toList();
}

/// Mutable ZTR entry for execution.
class ZtrExecutionEntry {
  String id;
  String text;

  ZtrExecutionEntry({required this.id, required this.text});
}

/// Wrapper for ZTR data during execution.
class ZtrExecutionData {
  final String sourcePath;
  final List<ZtrExecutionEntry> entries;
  bool modified = false;

  ZtrExecutionData({
    required this.sourcePath,
    required this.entries,
  });

  /// Find an entry by ID.
  ZtrExecutionEntry? findEntry(String entryId) {
    for (final entry in entries) {
      if (entry.id == entryId) {
        return entry;
      }
    }
    return null;
  }

  /// Find the index of an entry by ID.
  int findEntryIndex(String entryId) {
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].id == entryId) {
        return i;
      }
    }
    return -1;
  }
}
