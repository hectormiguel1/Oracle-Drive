import 'dart:ui';

import '../../../models/app_game_code.dart';
import '../../../models/wdb_model.dart';
import '../../../models/ztr_model.dart';
import '../../../models/workflow/workflow_models.dart';
import '../execution/execution_context.dart';
import '../execution/expression_evaluator.dart';
import '../services/file_service.dart';
import 'execution_context_builder.dart';

/// Mock file service for testing.
class MockFileService implements IFileService {
  final Map<String, WdbData> _wdbFiles = {};
  final Map<String, ZtrData> _ztrFiles = {};

  final List<String> loadWdbCalls = [];
  final List<String> saveWdbCalls = [];
  final List<String> loadZtrCalls = [];
  final List<String> saveZtrCalls = [];

  void mockWdbFile(String path, WdbData data) {
    _wdbFiles[path] = data;
  }

  void mockZtrFile(String path, ZtrData data) {
    _ztrFiles[path] = data;
  }

  @override
  Future<WdbData> loadWdb(String path, AppGameCode gameCode) async {
    loadWdbCalls.add(path);
    final data = _wdbFiles[path];
    if (data == null) {
      throw Exception('Mock WDB file not found: $path');
    }
    return data;
  }

  @override
  Future<void> saveWdb(String path, AppGameCode gameCode, WdbData data) async {
    saveWdbCalls.add(path);
    _wdbFiles[path] = data;
  }

  @override
  Future<ZtrData> loadZtr(String path, AppGameCode gameCode) async {
    loadZtrCalls.add(path);
    final data = _ztrFiles[path];
    if (data == null) {
      throw Exception('Mock ZTR file not found: $path');
    }
    return data;
  }

  @override
  Future<void> saveZtr(String path, AppGameCode gameCode, ZtrData data) async {
    saveZtrCalls.add(path);
    _ztrFiles[path] = data;
  }

  void reset() {
    _wdbFiles.clear();
    _ztrFiles.clear();
    loadWdbCalls.clear();
    saveWdbCalls.clear();
    loadZtrCalls.clear();
    saveZtrCalls.clear();
  }
}

/// Mock archive service for testing.
class MockArchiveService implements IArchiveService {
  final List<String> unpackWpdCalls = [];
  final List<String> repackWpdCalls = [];
  final List<String> loadWbtFileListCalls = [];
  final List<String> extractWbtCalls = [];
  final List<String> repackWbtCalls = [];

  final Map<String, List<String>> _wbtFileLists = {};

  void mockWbtFileList(String fileListPath, List<String> files) {
    _wbtFileLists[fileListPath] = files;
  }

  @override
  Future<int> unpackWpd(
    String archivePath,
    String outputDir,
    AppGameCode gameCode,
  ) async {
    unpackWpdCalls.add('$archivePath -> $outputDir');
    return 10; // Return mock count
  }

  @override
  Future<void> repackWpd(
    String sourceDir,
    String archivePath,
    AppGameCode gameCode,
  ) async {
    repackWpdCalls.add('$sourceDir -> $archivePath');
  }

  @override
  Future<List<String>> loadWbtFileList(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
  ) async {
    loadWbtFileListCalls.add(fileListPath);
    return _wbtFileLists[fileListPath] ?? [];
  }

  @override
  Future<int> extractWbtByIndices(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
    List<int> indices,
    String outputDir,
  ) async {
    extractWbtCalls.add('$fileListPath: ${indices.length} files -> $outputDir');
    return indices.length;
  }

  @override
  Future<void> repackWbt(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
    String sourceDir,
  ) async {
    repackWbtCalls.add('$sourceDir -> $fileListPath');
  }

  void reset() {
    unpackWpdCalls.clear();
    repackWpdCalls.clear();
    loadWbtFileListCalls.clear();
    extractWbtCalls.clear();
    repackWbtCalls.clear();
    _wbtFileLists.clear();
  }
}

/// Test harness for executor unit tests.
///
/// Provides a controlled environment for testing individual node executors
/// with mock services and pre-configured contexts.
class ExecutorTestHarness {
  late MockFileService mockFileService;
  late MockArchiveService mockArchiveService;
  late TestExecutionContext context;
  late ExpressionEvaluator evaluator;

  int _nodeCounter = 0;

  ExecutorTestHarness() {
    reset();
  }

  /// Reset the harness to initial state.
  void reset() {
    mockFileService = MockFileService();
    mockArchiveService = MockArchiveService();
    context = ExecutionContextBuilder()
        .withGameCode(AppGameCode.ff13_1)
        .withWorkspaceDir('/test/workspace')
        .buildForTesting();
    _nodeCounter = 0;
  }

  /// Configure the context with a builder.
  void configureContext(void Function(ExecutionContextBuilder) configure) {
    final builder = ExecutionContextBuilder()
        .withGameCode(AppGameCode.ff13_1)
        .withWorkspaceDir('/test/workspace');
    configure(builder);
    context = builder.buildForTesting();
  }

  /// Create a test node with the given type and config.
  WorkflowNode createNode(
    NodeType type, {
    Map<String, dynamic>? config,
    String? id,
    Offset position = Offset.zero,
  }) {
    return WorkflowNode(
      id: id ?? 'test-node-${_nodeCounter++}',
      type: type,
      position: position,
      config: config ?? {},
    );
  }

  /// Create a test WDB with sample data.
  WdbExecutionData createTestWdb({
    String sourcePath = '/test/test.wdb',
    String sheetName = 'TestSheet',
    List<String> columnNames = const ['id', 'name', 'value'],
    List<Map<String, dynamic>>? rows,
  }) {
    final columns = columnNames
        .map((name) => WdbColumn(
              originalName: name,
              displayName: WdbColumn.formatColumnName(name),
              type: WdbColumnType.string,
            ))
        .toList();

    final data = WdbData(
      sheetName: sheetName,
      columns: columns,
      rows: rows ??
          [
            {'record': 'record1', 'id': '1', 'name': 'Item 1', 'value': 100},
            {'record': 'record2', 'id': '2', 'name': 'Item 2', 'value': 200},
            {'record': 'record3', 'id': '3', 'name': 'Item 3', 'value': 300},
          ],
    );

    return WdbExecutionData(
      sourcePath: sourcePath,
      data: data,
    );
  }

  /// Create a test ZTR with sample data.
  ZtrExecutionData createTestZtr({
    String sourcePath = '/test/test.ztr',
    List<ZtrExecutionEntry>? entries,
  }) {
    return ZtrExecutionData(
      sourcePath: sourcePath,
      entries: entries ??
          [
            ZtrExecutionEntry(id: 'MSG_001', text: 'Hello, World!'),
            ZtrExecutionEntry(id: 'MSG_002', text: 'Goodbye, World!'),
            ZtrExecutionEntry(id: 'MSG_003', text: 'Testing...'),
          ],
    );
  }

  /// Add a WDB to the context.
  void addWdb(String name, WdbExecutionData wdb) {
    context.setWdb(name, wdb);
  }

  /// Add a ZTR to the context.
  void addZtr(String name, ZtrExecutionData ztr) {
    context.setZtr(name, ztr);
  }

  /// Add a variable to the context.
  void addVariable(String name, dynamic value) {
    context.setVariable(name, value);
  }

  /// Verify that a WDB was modified.
  bool isWdbModified(String name) {
    return context.getWdb(name)?.modified ?? false;
  }

  /// Get a variable from the context.
  dynamic getVariable(String name) {
    return context.getVariable(name);
  }

  /// Get a WDB from the context.
  WdbExecutionData? getWdb(String name) {
    return context.getWdb(name);
  }

  /// Get a ZTR from the context.
  ZtrExecutionData? getZtr(String name) {
    return context.getZtr(name);
  }

  /// Get the pending changes (preview mode).
  List<dynamic> get pendingChanges => context.pendingChanges;

  /// Verify no pending changes.
  bool get hasNoPendingChanges => context.pendingChanges.isEmpty;

  /// Mock a WDB file for the file service.
  void mockWdbFile(String path, WdbExecutionData wdb) {
    mockFileService.mockWdbFile(path, wdb.data);
  }
}

/// Extension methods for test assertions.
extension ExecutorTestAssertions on ExecutorTestHarness {
  /// Assert that a variable has a specific value.
  void assertVariable(String name, dynamic expected) {
    final actual = getVariable(name);
    if (actual != expected) {
      throw AssertionError(
        'Variable "$name": expected $expected but got $actual',
      );
    }
  }

  /// Assert that a variable exists.
  void assertVariableExists(String name) {
    if (!context.hasVariable(name)) {
      throw AssertionError('Variable "$name" does not exist');
    }
  }

  /// Assert that a WDB exists.
  void assertWdbExists(String name) {
    if (getWdb(name) == null) {
      throw AssertionError('WDB "$name" does not exist');
    }
  }

  /// Assert that a WDB has a specific number of records.
  void assertWdbRecordCount(String name, int expected) {
    final wdb = getWdb(name);
    if (wdb == null) {
      throw AssertionError('WDB "$name" does not exist');
    }
    final actual = wdb.data.rows.length;
    if (actual != expected) {
      throw AssertionError(
        'WDB "$name" record count: expected $expected but got $actual',
      );
    }
  }

  /// Assert that a WDB was modified.
  void assertWdbModified(String name) {
    if (!isWdbModified(name)) {
      throw AssertionError('WDB "$name" was not modified');
    }
  }

  /// Assert that a WDB was not modified.
  void assertWdbNotModified(String name) {
    if (isWdbModified(name)) {
      throw AssertionError('WDB "$name" was unexpectedly modified');
    }
  }

  /// Assert that there are no pending changes.
  void assertNoPendingChanges() {
    if (!hasNoPendingChanges) {
      throw AssertionError(
        'Expected no pending changes but got ${pendingChanges.length}',
      );
    }
  }

  /// Assert that there are pending changes.
  void assertHasPendingChanges() {
    if (hasNoPendingChanges) {
      throw AssertionError('Expected pending changes but got none');
    }
  }

  /// Assert that the file service loaded a WDB.
  void assertWdbLoaded(String path) {
    if (!mockFileService.loadWdbCalls.contains(path)) {
      throw AssertionError('WDB "$path" was not loaded');
    }
  }

  /// Assert that the file service saved a WDB.
  void assertWdbSaved(String path) {
    if (!mockFileService.saveWdbCalls.contains(path)) {
      throw AssertionError('WDB "$path" was not saved');
    }
  }
}
