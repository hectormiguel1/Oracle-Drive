import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/ztr/structs.dart' as ztr_sdk;
import '../../../../models/workflow/workflow_models.dart';
import '../../../../providers/workflow_provider.dart';
import '../execution_context.dart';
import '../node_executor.dart';

/// Executor for opening a ZTR file.
class ZtrOpenExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final rawPath = evaluateConfigAsString(node, 'filePath', context);
    final storeAs = getConfig<String>(node, 'storeAs') ?? 'ztr';

    if (rawPath.isEmpty) {
      return NodeExecutionResult.error('File path is required');
    }

    // Resolve relative paths against workspace directory
    final filePath = context.resolvePath(rawPath);

    try {
      final ztrData = await sdk.ztrParse(
        inFile: filePath,
        gameCode: context.gameCode.index,
      );

      // Convert to mutable entries
      final entries = ztrData.entries.map((e) => ZtrExecutionEntry(
        id: e.id,
        text: e.text,
      )).toList();

      final execData = ZtrExecutionData(
        sourcePath: filePath,
        entries: entries,
      );

      context.setZtr(storeAs, execData);

      return NodeExecutionResult.success(
        outputValue: execData,
        logMessage: 'Opened ZTR: ${entries.length} entries',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to open ZTR: $e');
    }
  }
}

/// Executor for saving a ZTR file.
class ZtrSaveExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final ztrName = getConfig<String>(node, 'ztrVariable') ?? 'ztr';
    final rawOutputPath = evaluateConfigAsString(node, 'outputPath', context);

    final ztrData = context.getZtr(ztrName);
    if (ztrData == null) {
      return NodeExecutionResult.error('ZTR variable "$ztrName" not found');
    }

    // Resolve relative paths against workspace directory
    final savePath = rawOutputPath.isNotEmpty
        ? context.resolvePath(rawOutputPath)
        : ztrData.sourcePath;

    if (context.previewMode) {
      return NodeExecutionResult.success(
        logMessage: 'Would save ZTR to: $savePath',
      );
    }

    try {
      // Convert to SDK format
      final sdkEntries = ztrData.entries.map((e) => ztr_sdk.ZtrEntry(
        id: e.id,
        text: e.text,
      )).toList();

      final sdkData = ztr_sdk.ZtrData(
        entries: sdkEntries,
        mappings: [],
      );

      await sdk.ztrPackFromStruct(
        data: sdkData,
        outFile: savePath,
        gameCode: context.gameCode.index,
      );
      ztrData.modified = false;

      return NodeExecutionResult.success(
        logMessage: 'Saved ZTR to: $savePath',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to save ZTR: $e');
    }
  }
}

/// Executor for finding a ZTR entry.
class ZtrFindEntryExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final ztrName = getConfig<String>(node, 'ztrVariable') ?? 'ztr';
    final entryId = evaluateConfigAsString(node, 'entryId', context);
    final storeAs = getConfig<String>(node, 'storeAs') ?? 'entry';

    if (entryId.isEmpty) {
      return NodeExecutionResult.error('Entry ID is required');
    }

    final ztrData = context.getZtr(ztrName);
    if (ztrData == null) {
      return NodeExecutionResult.error('ZTR variable "$ztrName" not found');
    }

    final entry = ztrData.findEntry(entryId);
    if (entry == null) {
      return NodeExecutionResult.success(
        nextPort: 'notFound',
        logMessage: 'Entry "$entryId" not found',
      );
    }

    context.setVariable(storeAs, entry);

    return NodeExecutionResult.success(
      nextPort: 'found',
      outputValue: entry,
      logMessage: 'Found entry: $entryId',
    );
  }
}

/// Executor for modifying ZTR entry text.
class ZtrModifyTextExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final ztrName = getConfig<String>(node, 'ztrVariable') ?? 'ztr';
    final entryId = evaluateConfigAsString(node, 'entryId', context);
    // Bug #4 fix: Use correct config key 'newText' (not 'text')
    final newText = evaluateConfigAsString(node, 'newText', context);

    if (entryId.isEmpty) {
      return NodeExecutionResult.error('Entry ID is required');
    }

    final ztrData = context.getZtr(ztrName);
    if (ztrData == null) {
      return NodeExecutionResult.error('ZTR variable "$ztrName" not found');
    }

    final entry = ztrData.findEntry(entryId);
    if (entry == null) {
      return NodeExecutionResult.error('Entry "$entryId" not found');
    }

    final oldText = entry.text;

    // Bug #39 fix: Add early return for preview mode
    if (context.previewMode) {
      context.addChange(ZtrTextChange(
        entryId: entryId,
        oldText: oldText,
        newText: newText,
      ));
      return NodeExecutionResult.success(
        outputValue: entry,
        logMessage: 'Would modify entry: $entryId',
      );
    }

    entry.text = newText;
    ztrData.modified = true;

    return NodeExecutionResult.success(
      outputValue: entry,
      logMessage: 'Modified entry: $entryId',
    );
  }
}

/// Executor for adding a new ZTR entry.
class ZtrAddEntryExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final ztrName = getConfig<String>(node, 'ztrVariable') ?? 'ztr';
    final entryId = evaluateConfigAsString(node, 'entryId', context);
    final text = evaluateConfigAsString(node, 'text', context);
    final afterEntryId = evaluateConfigAsString(node, 'afterEntryId', context);

    if (entryId.isEmpty) {
      return NodeExecutionResult.error('Entry ID is required');
    }

    final ztrData = context.getZtr(ztrName);
    if (ztrData == null) {
      return NodeExecutionResult.error('ZTR variable "$ztrName" not found');
    }

    // Check if entry already exists
    if (ztrData.findEntry(entryId) != null) {
      return NodeExecutionResult.error('Entry "$entryId" already exists');
    }

    final newEntry = ZtrExecutionEntry(
      id: entryId,
      text: text,
    );

    // Find insertion position
    int insertIndex = ztrData.entries.length;
    if (afterEntryId.isNotEmpty) {
      final afterIndex = ztrData.findEntryIndex(afterEntryId);
      if (afterIndex >= 0) {
        insertIndex = afterIndex + 1;
      }
    }

    // Bug #39 fix: Add early return for preview mode
    if (context.previewMode) {
      context.addChange(ZtrTextChange(
        entryId: entryId,
        oldText: null,
        newText: text,
      ));
      return NodeExecutionResult.success(
        outputValue: newEntry,
        logMessage: 'Would add entry: $entryId',
      );
    }

    ztrData.entries.insert(insertIndex, newEntry);
    ztrData.modified = true;

    return NodeExecutionResult.success(
      outputValue: newEntry,
      logMessage: 'Added entry: $entryId',
    );
  }
}

/// Executor for deleting a ZTR entry.
class ZtrDeleteEntryExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final ztrName = getConfig<String>(node, 'ztrVariable') ?? 'ztr';
    final entryId = evaluateConfigAsString(node, 'entryId', context);

    if (entryId.isEmpty) {
      return NodeExecutionResult.error('Entry ID is required');
    }

    final ztrData = context.getZtr(ztrName);
    if (ztrData == null) {
      return NodeExecutionResult.error('ZTR variable "$ztrName" not found');
    }

    final index = ztrData.findEntryIndex(entryId);
    if (index < 0) {
      return NodeExecutionResult.error('Entry "$entryId" not found');
    }

    // Bug #39 fix: Add early return for preview mode
    if (context.previewMode) {
      context.addChange(ZtrTextChange(
        entryId: entryId,
        oldText: ztrData.entries[index].text,
        newText: '(deleted)',
      ));
      return NodeExecutionResult.success(
        logMessage: 'Would delete entry: $entryId',
      );
    }

    ztrData.entries.removeAt(index);
    ztrData.modified = true;

    return NodeExecutionResult.success(
      logMessage: 'Deleted entry: $entryId',
    );
  }
}
