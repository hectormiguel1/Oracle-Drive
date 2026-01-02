import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/app_game_code.dart';
import '../../../models/wdb_model.dart';
import '../execution/execution_context.dart';

/// Builder for creating [ExecutionContext] instances for testing.
///
/// Provides a fluent API for configuring test contexts with
/// pre-set variables, WDB data, ZTR data, and other state.
class ExecutionContextBuilder {
  AppGameCode _gameCode = AppGameCode.ff13_1;
  bool _previewMode = false;
  String? _workspaceDir;

  final Map<String, dynamic> _variables = {};
  final Map<String, WdbExecutionData> _wdbs = {};
  final Map<String, ZtrExecutionData> _ztrs = {};
  final Map<String, int> _loopIndices = {};
  Map<String, dynamic>? _clipboard;

  Ref? _ref;

  ExecutionContextBuilder();

  /// Set the game code.
  ExecutionContextBuilder withGameCode(AppGameCode gameCode) {
    _gameCode = gameCode;
    return this;
  }

  /// Set preview mode.
  ExecutionContextBuilder withPreviewMode([bool preview = true]) {
    _previewMode = preview;
    return this;
  }

  /// Set the workspace directory.
  ExecutionContextBuilder withWorkspaceDir(String? dir) {
    _workspaceDir = dir;
    return this;
  }

  /// Add a variable.
  ExecutionContextBuilder withVariable(String name, dynamic value) {
    _variables[name] = value;
    return this;
  }

  /// Add multiple variables.
  ExecutionContextBuilder withVariables(Map<String, dynamic> variables) {
    _variables.addAll(variables);
    return this;
  }

  /// Add a WDB data source.
  ExecutionContextBuilder withWdb(String name, WdbExecutionData data) {
    _wdbs[name] = data;
    return this;
  }

  /// Add a WDB from raw data.
  ExecutionContextBuilder withWdbData({
    required String name,
    required String sourcePath,
    required String sheetName,
    required List<WdbColumn> columns,
    required List<Map<String, dynamic>> rows,
  }) {
    final data = WdbData(
      sheetName: sheetName,
      columns: columns,
      rows: rows,
    );
    _wdbs[name] = WdbExecutionData(
      sourcePath: sourcePath,
      data: data,
    );
    return this;
  }

  /// Add a ZTR data source.
  ExecutionContextBuilder withZtr(String name, ZtrExecutionData data) {
    _ztrs[name] = data;
    return this;
  }

  /// Add a ZTR from raw entries.
  ExecutionContextBuilder withZtrData({
    required String name,
    required String sourcePath,
    required List<ZtrExecutionEntry> entries,
  }) {
    _ztrs[name] = ZtrExecutionData(
      sourcePath: sourcePath,
      entries: entries,
    );
    return this;
  }

  /// Set a loop index.
  ExecutionContextBuilder withLoopIndex(String loopId, int index) {
    _loopIndices[loopId] = index;
    return this;
  }

  /// Set the clipboard contents.
  ExecutionContextBuilder withClipboard(Map<String, dynamic>? data) {
    _clipboard = data;
    return this;
  }

  /// Set the Riverpod ref (required for actual execution).
  ExecutionContextBuilder withRef(Ref ref) {
    _ref = ref;
    return this;
  }

  /// Build the execution context.
  ///
  /// Note: A Ref must be provided for actual execution.
  /// For testing without Ref, use [buildForTesting].
  ExecutionContext build() {
    if (_ref == null) {
      throw StateError(
        'Ref is required. Use withRef() or buildForTesting() for tests.',
      );
    }

    final context = ExecutionContext(
      gameCode: _gameCode,
      ref: _ref!,
      previewMode: _previewMode,
      workspaceDir: _workspaceDir,
    );

    _applyState(context);
    return context;
  }

  /// Build a test context that doesn't require a Ref.
  ///
  /// This creates a mock-friendly context for unit testing executors.
  TestExecutionContext buildForTesting() {
    final context = TestExecutionContext(
      gameCode: _gameCode,
      previewMode: _previewMode,
      workspaceDir: _workspaceDir,
    );

    _applyState(context);
    return context;
  }

  void _applyState(dynamic context) {
    _variables.forEach((k, v) => context.setVariable(k, v));
    _wdbs.forEach((k, v) {
      context.openWdbs[k] = v;
      context.variables[k] = v;
    });
    _ztrs.forEach((k, v) {
      context.openZtrs[k] = v;
      context.variables[k] = v;
    });
    _loopIndices.forEach((k, v) => context.loopIndices[k] = v);
    if (_clipboard != null) {
      context.clipboard = _clipboard;
    }
  }

  /// Create a copy of this builder.
  ExecutionContextBuilder copy() {
    return ExecutionContextBuilder()
      .._gameCode = _gameCode
      .._previewMode = _previewMode
      .._workspaceDir = _workspaceDir
      .._variables.addAll(_variables)
      .._wdbs.addAll(_wdbs)
      .._ztrs.addAll(_ztrs)
      .._loopIndices.addAll(_loopIndices)
      .._clipboard = _clipboard != null ? Map.from(_clipboard!) : null
      .._ref = _ref;
  }
}

/// A test-friendly execution context that doesn't require Riverpod.
class TestExecutionContext {
  final AppGameCode gameCode;
  final bool previewMode;
  final String? workspaceDir;

  final Map<String, dynamic> variables = {};
  final Map<String, WdbExecutionData> openWdbs = {};
  final Map<String, ZtrExecutionData> openZtrs = {};
  final Map<String, int> loopIndices = {};
  Map<String, dynamic>? clipboard;
  final List<dynamic> pendingChanges = [];

  TestExecutionContext({
    required this.gameCode,
    this.previewMode = false,
    this.workspaceDir,
  }) {
    if (workspaceDir != null) {
      variables['workspaceDir'] = workspaceDir;
    }
  }

  dynamic getVariable(String name) => variables[name];

  void setVariable(String name, dynamic value) {
    variables[name] = value;
  }

  bool hasVariable(String name) => variables.containsKey(name);

  WdbExecutionData? getWdb(String name) => openWdbs[name];

  void setWdb(String name, WdbExecutionData data) {
    openWdbs[name] = data;
    variables[name] = data;
  }

  ZtrExecutionData? getZtr(String name) => openZtrs[name];

  void setZtr(String name, ZtrExecutionData data) {
    openZtrs[name] = data;
    variables[name] = data;
  }

  int getLoopIndex(String loopId) => loopIndices[loopId] ?? 0;

  int incrementLoopIndex(String loopId) {
    final current = loopIndices[loopId] ?? 0;
    loopIndices[loopId] = current + 1;
    return current + 1;
  }

  void resetLoopIndex(String loopId) {
    loopIndices.remove(loopId);
  }

  void addChange(dynamic change) {
    if (previewMode) {
      pendingChanges.add(change);
    }
  }

  String resolvePath(String filePath) {
    if (filePath.isEmpty) return filePath;

    var normalized = filePath.replaceAll('\\', '/');

    // Handle variable interpolation
    normalized = normalized.replaceAllMapped(
      RegExp(r'\$\{([^}]+)\}'),
      (match) {
        final varName = match.group(1);
        if (varName != null && variables.containsKey(varName)) {
          return variables[varName].toString();
        }
        return match.group(0)!;
      },
    );

    // Make absolute if workspace is set
    if (workspaceDir != null && !normalized.startsWith('/')) {
      return '$workspaceDir/$normalized';
    }

    return normalized;
  }
}
