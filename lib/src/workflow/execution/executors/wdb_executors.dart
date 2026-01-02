import '../../../../models/workflow/workflow_models.dart';
import '../../../../providers/workflow_provider.dart';
import '../../../../src/services/native_service.dart';
import '../../utils/deep_copy.dart';
import '../execution_context.dart';
import '../node_executor.dart';

/// Executor for opening a WDB file.
class WdbOpenExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final rawPath = evaluateConfigAsString(node, 'filePath', context);
    final storeAs = getConfig<String>(node, 'storeAs') ?? 'wdb';

    if (rawPath.isEmpty) {
      return NodeExecutionResult.error('File path is required');
    }

    // Resolve relative paths against workspace directory
    final filePath = context.resolvePath(rawPath);

    try {
      final wdbData = await NativeService.instance.parseWdb(
        filePath,
        context.gameCode,
      );

      final execData = WdbExecutionData(
        sourcePath: filePath,
        data: wdbData,
      );

      context.setWdb(storeAs, execData);

      return NodeExecutionResult.success(
        outputValue: execData,
        logMessage: 'Opened WDB: ${wdbData.sheetName} (${wdbData.rows.length} records)',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to open WDB: $e');
    }
  }
}

/// Executor for saving a WDB file.
class WdbSaveExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final wdbName = getConfig<String>(node, 'wdbVariable') ?? 'wdb';
    final rawOutputPath = evaluateConfigAsString(node, 'outputPath', context);

    final wdbData = context.getWdb(wdbName);
    if (wdbData == null) {
      return NodeExecutionResult.error('WDB variable "$wdbName" not found');
    }

    // Resolve relative paths against workspace directory
    final savePath = rawOutputPath.isNotEmpty
        ? context.resolvePath(rawOutputPath)
        : wdbData.sourcePath;

    if (context.previewMode) {
      // In preview mode, just record the change
      return NodeExecutionResult.success(
        logMessage: 'Would save WDB to: $savePath',
      );
    }

    try {
      await NativeService.instance.saveWdb(
        savePath,
        context.gameCode,
        wdbData.data,
      );
      wdbData.modified = false;

      // Flush journal changes after successful save
      final changeCount = context.getWdbJournalChangeCount(wdbName);
      if (changeCount > 0) {
        context.flushWdbJournalChanges(
          wdbName,
          'Workflow: Saved $changeCount changes to ${savePath.split('/').last}',
        );
      }

      return NodeExecutionResult.success(
        logMessage: 'Saved WDB to: $savePath',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to save WDB: $e');
    }
  }
}

/// Executor for finding a record in a WDB.
class WdbFindRecordExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final wdbName = getConfig<String>(node, 'wdbVariable') ?? 'wdb';
    final recordId = evaluateConfigAsString(node, 'recordId', context);
    final storeAs = getConfig<String>(node, 'storeAs') ?? 'record';

    if (recordId.isEmpty) {
      return NodeExecutionResult.error('Record ID is required');
    }

    final wdbData = context.getWdb(wdbName);
    if (wdbData == null) {
      return NodeExecutionResult.error('WDB variable "$wdbName" not found');
    }

    final record = wdbData.findRecord(recordId);
    if (record == null) {
      return NodeExecutionResult.success(
        nextPort: 'notFound',
        logMessage: 'Record "$recordId" not found',
      );
    }

    context.setVariable(storeAs, record);

    return NodeExecutionResult.success(
      nextPort: 'found',
      outputValue: record,
      logMessage: 'Found record: $recordId',
    );
  }
}

/// Executor for copying a record to the clipboard.
class WdbCopyRecordExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final wdbName = getConfig<String>(node, 'wdbVariable') ?? 'wdb';
    // Bug #3 fix: Use correct config key 'sourceRecordId' (not 'recordId')
    final recordId = evaluateConfigAsString(node, 'sourceRecordId', context);

    if (recordId.isEmpty) {
      return NodeExecutionResult.error('Record ID is required');
    }

    final wdbData = context.getWdb(wdbName);
    if (wdbData == null) {
      return NodeExecutionResult.error('WDB variable "$wdbName" not found');
    }

    final record = wdbData.findRecord(recordId);
    if (record == null) {
      return NodeExecutionResult.error('Record "$recordId" not found');
    }

    // Store as variable for downstream use (Bug #41 fix)
    final storeAs = getConfig<String>(node, 'storeAs') ?? 'copiedRecord';

    // Deep copy the record (Bug #43 fix)
    final copiedRecord = DeepCopyUtils.copyRecord(record);
    context.setVariable(storeAs, copiedRecord);

    // Also keep in clipboard for backwards compatibility
    context.clipboard = copiedRecord;

    return NodeExecutionResult.success(
      outputValue: copiedRecord,
      logMessage: 'Copied record: $recordId to variable "$storeAs"',
    );
  }
}

/// Executor for pasting a record.
class WdbPasteRecordExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final wdbName = getConfig<String>(node, 'wdbVariable') ?? 'wdb';
    final afterRecordId = evaluateConfigAsString(node, 'afterRecordId', context);
    final newRecordId = evaluateConfigAsString(node, 'newRecordId', context);

    // Bug #41 fix: Use recordVariable config instead of clipboard
    final recordVarName = getConfig<String>(node, 'recordVariable') ?? 'copiedRecord';

    final wdbData = context.getWdb(wdbName);
    if (wdbData == null) {
      return NodeExecutionResult.error('WDB variable "$wdbName" not found');
    }

    // Try to get record from variable first, fall back to clipboard for backwards compatibility
    var recordData = context.getVariable(recordVarName);
    // Fallback to clipboard for backwards compatibility
    recordData ??= context.clipboard;

    if (recordData == null) {
      return NodeExecutionResult.error(
        'Variable "$recordVarName" not found and no record in clipboard',
      );
    }

    if (recordData is! Map<String, dynamic>) {
      return NodeExecutionResult.error(
        'Variable "$recordVarName" is not a valid record (got ${recordData.runtimeType})',
      );
    }

    // Bug #43 fix: Deep copy the record
    final newRecord = DeepCopyUtils.copyRecord(recordData);
    if (newRecordId.isNotEmpty) {
      newRecord['record'] = newRecordId;
    }

    // Find insertion position
    int insertIndex = wdbData.data.rows.length;
    if (afterRecordId.isNotEmpty) {
      final afterIndex = wdbData.findRecordIndex(afterRecordId);
      if (afterIndex >= 0) {
        insertIndex = afterIndex + 1;
      }
    }

    // Bug #39 fix: Add early return for preview mode
    if (context.previewMode) {
      context.addChange(WdbFieldChange(
        wdbName: wdbName,
        recordId: newRecord['record'] as String? ?? 'unknown',
        column: '(new record)',
        oldValue: null,
        newValue: 'paste after $afterRecordId',
      ));
      return NodeExecutionResult.success(
        outputValue: newRecord,
        logMessage: 'Would paste record at index $insertIndex',
      );
    }

    wdbData.data.rows.insert(insertIndex, newRecord);
    wdbData.modified = true;

    return NodeExecutionResult.success(
      outputValue: newRecord,
      logMessage: 'Pasted record at index $insertIndex',
    );
  }
}

/// Executor for renaming a record.
class WdbRenameRecordExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final wdbName = getConfig<String>(node, 'wdbVariable') ?? 'wdb';
    final oldRecordId = evaluateConfigAsString(node, 'recordId', context);
    final newRecordId = evaluateConfigAsString(node, 'newRecordId', context);

    if (oldRecordId.isEmpty || newRecordId.isEmpty) {
      return NodeExecutionResult.error('Both old and new record IDs are required');
    }

    final wdbData = context.getWdb(wdbName);
    if (wdbData == null) {
      return NodeExecutionResult.error('WDB variable "$wdbName" not found');
    }

    final record = wdbData.findRecord(oldRecordId);
    if (record == null) {
      return NodeExecutionResult.error('Record "$oldRecordId" not found');
    }

    // Bug #39 fix: Add early return for preview mode
    if (context.previewMode) {
      context.addChange(WdbFieldChange(
        wdbName: wdbName,
        recordId: oldRecordId,
        column: 'record',
        oldValue: oldRecordId,
        newValue: newRecordId,
      ));
      return NodeExecutionResult.success(
        outputValue: record,
        logMessage: 'Would rename record: $oldRecordId → $newRecordId',
      );
    }

    record['record'] = newRecordId;
    wdbData.modified = true;

    return NodeExecutionResult.success(
      outputValue: record,
      logMessage: 'Renamed record: $oldRecordId → $newRecordId',
    );
  }
}

/// Executor for setting a field value.
class WdbSetFieldExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final wdbName = getConfig<String>(node, 'wdbVariable') ?? 'wdb';
    final recordId = evaluateConfigAsString(node, 'recordId', context);
    final column = getConfig<String>(node, 'column');
    final value = evaluateConfig(node, 'value', context);

    if (recordId.isEmpty) {
      return NodeExecutionResult.error('Record ID is required');
    }

    if (column == null || column.isEmpty) {
      return NodeExecutionResult.error('Column name is required');
    }

    final wdbData = context.getWdb(wdbName);
    if (wdbData == null) {
      return NodeExecutionResult.error('WDB variable "$wdbName" not found');
    }

    final record = wdbData.findRecord(recordId);
    if (record == null) {
      return NodeExecutionResult.error('Record "$recordId" not found');
    }

    final oldValue = record[column];

    // Bug #39 fix: Add early return for preview mode
    if (context.previewMode) {
      context.addChange(WdbFieldChange(
        wdbName: wdbName,
        recordId: recordId,
        column: column,
        oldValue: oldValue,
        newValue: value,
      ));
      return NodeExecutionResult.success(
        outputValue: value,
        logMessage: 'Would set $recordId.$column = $value',
      );
    }

    record[column] = value;
    wdbData.modified = true;

    // Record change for journaling
    context.recordWdbChange(
      wdbName: wdbName,
      sourceFile: wdbData.sourcePath,
      recordId: recordId,
      columnName: column,
      previousValue: oldValue,
      newValue: value,
    );

    return NodeExecutionResult.success(
      outputValue: value,
      logMessage: 'Set $recordId.$column = $value',
    );
  }
}

/// Executor for deleting a record.
class WdbDeleteRecordExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final wdbName = getConfig<String>(node, 'wdbVariable') ?? 'wdb';
    final recordId = evaluateConfigAsString(node, 'recordId', context);

    if (recordId.isEmpty) {
      return NodeExecutionResult.error('Record ID is required');
    }

    final wdbData = context.getWdb(wdbName);
    if (wdbData == null) {
      return NodeExecutionResult.error('WDB variable "$wdbName" not found');
    }

    final index = wdbData.findRecordIndex(recordId);
    if (index < 0) {
      return NodeExecutionResult.error('Record "$recordId" not found');
    }

    // Bug #39 fix: Add early return for preview mode
    if (context.previewMode) {
      context.addChange(WdbFieldChange(
        wdbName: wdbName,
        recordId: recordId,
        column: '(delete)',
        oldValue: 'exists',
        newValue: null,
      ));
      return NodeExecutionResult.success(
        logMessage: 'Would delete record: $recordId',
      );
    }

    wdbData.data.rows.removeAt(index);
    wdbData.modified = true;

    return NodeExecutionResult.success(
      logMessage: 'Deleted record: $recordId',
    );
  }
}

/// Executor for bulk updating records.
class WdbBulkUpdateExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final wdbName = getConfig<String>(node, 'wdbVariable') ?? 'wdb';
    final column = getConfig<String>(node, 'column');
    final operation = getConfig<String>(node, 'operation') ?? 'set';
    final value = evaluateConfig(node, 'value', context);
    final filterExpr = getConfig<String>(node, 'filter');

    if (column == null || column.isEmpty) {
      return NodeExecutionResult.error('Column name is required');
    }

    final wdbData = context.getWdb(wdbName);
    if (wdbData == null) {
      return NodeExecutionResult.error('WDB variable "$wdbName" not found');
    }

    int updatedCount = 0;
    final evaluator = getEvaluator(context);

    // Bug #39 fix: Collect changes in preview mode, only apply in non-preview mode
    final changesToApply = <Map<String, dynamic>>[];

    for (final row in wdbData.data.rows) {
      // Apply filter if specified
      if (filterExpr != null && filterExpr.isNotEmpty) {
        // Temporarily set 'row' variable for filter evaluation
        context.setVariable('__internal_row', row);
        final shouldInclude = evaluator.evaluateCondition(filterExpr);
        context.variables.remove('__internal_row');
        if (!shouldInclude) continue;
      }

      final oldValue = row[column];
      dynamic newValue;

      switch (operation) {
        case 'set':
          newValue = value;
          break;
        case 'add':
          if (oldValue is num && value is num) {
            newValue = oldValue + value;
          } else {
            continue;
          }
          break;
        case 'subtract':
          if (oldValue is num && value is num) {
            newValue = oldValue - value;
          } else {
            continue;
          }
          break;
        case 'multiply':
          if (oldValue is num && value is num) {
            newValue = oldValue * value;
          } else {
            continue;
          }
          break;
        case 'divide':
          if (oldValue is num && value is num && value != 0) {
            newValue = oldValue / value;
          } else {
            continue;
          }
          break;
        default:
          newValue = value;
      }

      if (context.previewMode) {
        context.addChange(WdbFieldChange(
          wdbName: wdbName,
          recordId: row['record'] as String? ?? 'unknown',
          column: column,
          oldValue: oldValue,
          newValue: newValue,
        ));
        updatedCount++;
      } else {
        // Queue the change for application
        changesToApply.add({
          'row': row,
          'oldValue': oldValue,
          'newValue': newValue,
          'recordId': row['record'] as String? ?? 'unknown',
        });
      }
    }

    // Bug #39 fix: Return early in preview mode without modifying data
    if (context.previewMode) {
      return NodeExecutionResult.success(
        outputValue: updatedCount,
        logMessage: 'Would bulk update $updatedCount records',
      );
    }

    // Apply all changes and record to journal
    for (final change in changesToApply) {
      final row = change['row'] as Map<String, dynamic>;
      row[column] = change['newValue'];

      // Record change for journaling
      context.recordWdbChange(
        wdbName: wdbName,
        sourceFile: wdbData.sourcePath,
        recordId: change['recordId'] as String,
        columnName: column,
        previousValue: change['oldValue'],
        newValue: change['newValue'],
      );

      updatedCount++;
    }

    if (updatedCount > 0) {
      wdbData.modified = true;
    }

    return NodeExecutionResult.success(
      outputValue: updatedCount,
      logMessage: 'Bulk updated $updatedCount records',
    );
  }
}

/// Executor for WDB Transform - combines open, multiple operations, and save.
class WdbTransformExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final rawPath = evaluateConfigAsString(node, 'filePath', context);
    final rawOutputPath = evaluateConfigAsString(node, 'outputPath', context);
    final operationsJson = node.config['operations'] as List<dynamic>? ?? [];

    if (rawPath.isEmpty) {
      return NodeExecutionResult.error('File path is required');
    }

    if (operationsJson.isEmpty) {
      return NodeExecutionResult.error('At least one operation is required');
    }

    // Resolve paths
    final filePath = context.resolvePath(rawPath);
    final outputPath = rawOutputPath.isNotEmpty
        ? context.resolvePath(rawOutputPath)
        : filePath;

    // Parse operations
    final operations = operationsJson
        .map((o) => WdbOperation.fromJson(o as Map<String, dynamic>))
        .toList();

    try {
      // Open the WDB file
      final wdbData = await NativeService.instance.parseWdb(
        filePath,
        context.gameCode,
      );

      final execData = WdbExecutionData(
        sourcePath: filePath,
        data: wdbData,
      );

      // Execute each operation
      final logMessages = <String>[];
      Map<String, dynamic>? clipboard;

      for (int i = 0; i < operations.length; i++) {
        final op = operations[i];
        final opResult = _executeOperation(op, execData, context, clipboard);

        if (!opResult.success) {
          return NodeExecutionResult.error(
            'Operation ${i + 1} (${op.type.displayName}) failed: ${opResult.error}',
          );
        }

        logMessages.add(opResult.message);
        if (opResult.clipboard != null) {
          clipboard = opResult.clipboard;
        }
      }

      // Save if not preview mode
      if (context.previewMode) {
        return NodeExecutionResult.success(
          logMessage: 'Preview: ${operations.length} operations on ${_getFileName(filePath)}',
        );
      }

      await NativeService.instance.saveWdb(
        outputPath,
        context.gameCode,
        execData.data,
      );

      return NodeExecutionResult.success(
        logMessage: '${operations.length} operations on ${_getFileName(filePath)}: ${logMessages.join(", ")}',
      );
    } catch (e) {
      return NodeExecutionResult.error('Transform failed: $e');
    }
  }

  String _getFileName(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.isNotEmpty ? parts.last : path;
  }

  _OpResult _executeOperation(
    WdbOperation op,
    WdbExecutionData wdbData,
    ExecutionContext context,
    Map<String, dynamic>? clipboard,
  ) {
    switch (op.type) {
      case WdbOperationType.copy:
        final recordId = _evalParam(op.params['sourceRecordId'], context);
        if (recordId.isEmpty) {
          return _OpResult.fail('Source record ID is required');
        }
        final record = wdbData.findRecord(recordId);
        if (record == null) {
          return _OpResult.fail('Record "$recordId" not found');
        }
        return _OpResult.ok(
          'Copied $recordId',
          clipboard: Map<String, dynamic>.from(record),
        );

      case WdbOperationType.paste:
        if (clipboard == null) {
          return _OpResult.fail('Nothing in clipboard');
        }
        final afterRecordId = _evalParam(op.params['afterRecordId'], context);
        final newRecordId = _evalParam(op.params['newRecordId'], context);

        final newRecord = Map<String, dynamic>.from(clipboard);
        if (newRecordId.isNotEmpty) {
          newRecord['record'] = newRecordId;
        }

        int insertIndex = wdbData.data.rows.length;
        if (afterRecordId.isNotEmpty) {
          final afterIndex = wdbData.findRecordIndex(afterRecordId);
          if (afterIndex >= 0) {
            insertIndex = afterIndex + 1;
          }
        }

        if (context.previewMode) {
          context.addChange(WdbFieldChange(
            wdbName: _getFileName(wdbData.sourcePath),
            recordId: newRecord['record'] as String? ?? 'unknown',
            column: '(new record)',
            oldValue: null,
            newValue: 'paste after $afterRecordId',
          ));
        }

        wdbData.data.rows.insert(insertIndex, newRecord);
        wdbData.modified = true;
        return _OpResult.ok('Pasted as ${newRecord['record']}');

      case WdbOperationType.rename:
        final recordId = _evalParam(op.params['recordId'], context);
        final newRecordId = _evalParam(op.params['newRecordId'], context);
        if (recordId.isEmpty || newRecordId.isEmpty) {
          return _OpResult.fail('Both record IDs are required');
        }
        final record = wdbData.findRecord(recordId);
        if (record == null) {
          return _OpResult.fail('Record "$recordId" not found');
        }

        if (context.previewMode) {
          context.addChange(WdbFieldChange(
            wdbName: _getFileName(wdbData.sourcePath),
            recordId: recordId,
            column: 'record',
            oldValue: recordId,
            newValue: newRecordId,
          ));
        }

        record['record'] = newRecordId;
        wdbData.modified = true;
        return _OpResult.ok('Renamed $recordId → $newRecordId');

      case WdbOperationType.setField:
        final recordId = _evalParam(op.params['recordId'], context);
        final column = op.params['column'] as String? ?? '';
        final value = _evalParamValue(op.params['value'], context);

        if (recordId.isEmpty || column.isEmpty) {
          return _OpResult.fail('Record ID and column are required');
        }

        final record = wdbData.findRecord(recordId);
        if (record == null) {
          return _OpResult.fail('Record "$recordId" not found');
        }

        final oldValue = record[column];

        if (context.previewMode) {
          context.addChange(WdbFieldChange(
            wdbName: _getFileName(wdbData.sourcePath),
            recordId: recordId,
            column: column,
            oldValue: oldValue,
            newValue: value,
          ));
        }

        record[column] = value;
        wdbData.modified = true;
        return _OpResult.ok('Set $recordId.$column = $value');

      case WdbOperationType.delete:
        final recordId = _evalParam(op.params['recordId'], context);
        if (recordId.isEmpty) {
          return _OpResult.fail('Record ID is required');
        }

        final index = wdbData.findRecordIndex(recordId);
        if (index < 0) {
          return _OpResult.fail('Record "$recordId" not found');
        }

        if (context.previewMode) {
          context.addChange(WdbFieldChange(
            wdbName: _getFileName(wdbData.sourcePath),
            recordId: recordId,
            column: '(delete)',
            oldValue: 'exists',
            newValue: null,
          ));
        }

        wdbData.data.rows.removeAt(index);
        wdbData.modified = true;
        return _OpResult.ok('Deleted $recordId');
    }
  }

  String _evalParam(dynamic value, ExecutionContext context) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(r'${')) {
      final evaluator = getEvaluator(context);
      return evaluator.evaluate(str)?.toString() ?? str;
    }
    return str;
  }

  dynamic _evalParamValue(dynamic value, ExecutionContext context) {
    if (value == null) return null;
    if (value is num || value is bool) return value;
    final str = value.toString();
    if (str.contains(r'${')) {
      final evaluator = getEvaluator(context);
      return evaluator.evaluate(str);
    }
    // Try to parse as number
    final numVal = num.tryParse(str);
    if (numVal != null) return numVal;
    return str;
  }
}

class _OpResult {
  final bool success;
  final String message;
  final String? error;
  final Map<String, dynamic>? clipboard;

  const _OpResult._({
    required this.success,
    required this.message,
    this.error,
    this.clipboard,
  });

  factory _OpResult.ok(String message, {Map<String, dynamic>? clipboard}) {
    return _OpResult._(success: true, message: message, clipboard: clipboard);
  }

  factory _OpResult.fail(String error) {
    return _OpResult._(success: false, message: '', error: error);
  }
}
