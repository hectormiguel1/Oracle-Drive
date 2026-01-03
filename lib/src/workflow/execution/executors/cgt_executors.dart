import 'dart:convert';
import '../../../../models/crystalium/cgt_file.dart';
import '../../../../models/workflow/workflow_models.dart';
import '../../../services/native_service.dart';
import '../execution_context.dart';
import '../node_executor.dart';

/// Executor for opening a CGT file.
class CgtOpenExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final rawPath = evaluateConfigAsString(node, 'filePath', context);
    final storeAs = getConfig<String>(node, 'storeAs') ?? 'cgt';

    if (rawPath.isEmpty) {
      return NodeExecutionResult.error('File path is required');
    }

    // Resolve relative paths against workspace directory
    final filePath = context.resolvePath(rawPath);

    try {
      final sdkCgt = await NativeService.instance.parseCgt(filePath);
      final cgtData = CgtFile.fromSdk(sdkCgt);

      final execData = CgtExecutionData(
        sourcePath: filePath,
        data: cgtData,
      );

      context.setCgt(storeAs, execData);

      return NodeExecutionResult.success(
        outputValue: execData,
        logMessage: 'Opened CGT: ${cgtData.entries.length} entries, ${cgtData.nodes.length} nodes',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to open CGT: $e');
    }
  }
}

/// Executor for saving a CGT file.
class CgtSaveExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final cgtName = getConfig<String>(node, 'cgtVariable') ?? 'cgt';
    final rawOutputPath = evaluateConfigAsString(node, 'outputPath', context);

    final cgtData = context.getCgt(cgtName);
    if (cgtData == null) {
      return NodeExecutionResult.error('CGT variable "$cgtName" not found');
    }

    // Resolve relative paths against workspace directory
    final savePath = rawOutputPath.isNotEmpty
        ? context.resolvePath(rawOutputPath)
        : cgtData.sourcePath;

    if (context.previewMode) {
      return NodeExecutionResult.success(
        logMessage: 'Would save CGT to: $savePath',
      );
    }

    try {
      // Apply any pending modifications
      cgtData.applyModifications();

      // Convert to SDK format and write
      final sdkCgt = cgtData.data.toSdk();
      await NativeService.instance.writeCgt(sdkCgt, savePath);
      cgtData.modified = false;

      return NodeExecutionResult.success(
        logMessage: 'Saved CGT to: $savePath',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to save CGT: $e');
    }
  }
}

/// Executor for adding an offshoot (branch) to the Crystarium.
class CgtAddOffshootExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final cgtName = getConfig<String>(node, 'cgtVariable') ?? 'cgt';
    final parentNodeIdStr = evaluateConfigAsString(node, 'parentNodeId', context);
    final patternName = getConfig<String>(node, 'patternName') ?? 'test3';
    final stage = getConfig<int>(node, 'stage') ?? 1;
    final roleIdStr = getConfig<String>(node, 'roleId') ?? '0';

    if (parentNodeIdStr.isEmpty) {
      return NodeExecutionResult.error('Parent node ID is required');
    }

    final parentNodeId = int.tryParse(parentNodeIdStr);
    if (parentNodeId == null) {
      return NodeExecutionResult.error('Invalid parent node ID: $parentNodeIdStr');
    }

    final roleId = int.tryParse(roleIdStr) ?? 0;

    final cgtData = context.getCgt(cgtName);
    if (cgtData == null) {
      return NodeExecutionResult.error('CGT variable "$cgtName" not found');
    }

    if (context.previewMode) {
      return NodeExecutionResult.success(
        logMessage: 'Would add offshoot from node $parentNodeId with pattern $patternName',
      );
    }

    try {
      final modifier = cgtData.getModifier();
      final newEntry = modifier.addOffshoot(
        parentNodeId: parentNodeId,
        patternName: patternName,
        stage: stage,
        roleId: roleId,
      );

      if (newEntry == null) {
        return NodeExecutionResult.error('Failed to add offshoot');
      }

      cgtData.modified = true;

      return NodeExecutionResult.success(
        outputValue: newEntry,
        logMessage: 'Added offshoot: entry ${newEntry.index} with ${newEntry.nodeIds.length} nodes',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to add offshoot: $e');
    }
  }
}

/// Executor for adding a chain of entries to the Crystarium.
class CgtAddChainExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final cgtName = getConfig<String>(node, 'cgtVariable') ?? 'cgt';
    final parentNodeIdStr = evaluateConfigAsString(node, 'parentNodeId', context);
    final chainDefStr = evaluateConfigAsString(node, 'chainDefinition', context);

    if (parentNodeIdStr.isEmpty) {
      return NodeExecutionResult.error('Parent node ID is required');
    }

    if (chainDefStr.isEmpty) {
      return NodeExecutionResult.error('Chain definition is required');
    }

    final parentNodeId = int.tryParse(parentNodeIdStr);
    if (parentNodeId == null) {
      return NodeExecutionResult.error('Invalid parent node ID: $parentNodeIdStr');
    }

    final cgtData = context.getCgt(cgtName);
    if (cgtData == null) {
      return NodeExecutionResult.error('CGT variable "$cgtName" not found');
    }

    // Parse chain definition (JSON array)
    List<({String patternName, int stage, int roleId})> chainDef;
    try {
      final parsed = jsonDecode(chainDefStr) as List;
      chainDef = parsed.map((item) {
        final map = item as Map<String, dynamic>;
        return (
          patternName: map['pattern'] as String? ?? 'test3',
          stage: map['stage'] as int? ?? 1,
          roleId: map['role'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      return NodeExecutionResult.error('Invalid chain definition JSON: $e');
    }

    if (context.previewMode) {
      return NodeExecutionResult.success(
        logMessage: 'Would add chain of ${chainDef.length} entries from node $parentNodeId',
      );
    }

    try {
      final modifier = cgtData.getModifier();
      final newEntries = modifier.addChain(
        parentNodeId: parentNodeId,
        chainDefinition: chainDef,
      );

      cgtData.modified = true;

      return NodeExecutionResult.success(
        outputValue: newEntries,
        logMessage: 'Added chain: ${newEntries.length} entries',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to add chain: $e');
    }
  }
}

/// Executor for updating a Crystarium entry's properties.
class CgtUpdateEntryExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final cgtName = getConfig<String>(node, 'cgtVariable') ?? 'cgt';
    final entryIndexStr = evaluateConfigAsString(node, 'entryIndex', context);
    final stageValue = getConfig<int>(node, 'stage');
    final roleIdStr = getConfig<String>(node, 'roleId');

    if (entryIndexStr.isEmpty) {
      return NodeExecutionResult.error('Entry index is required');
    }

    final entryIndex = int.tryParse(entryIndexStr);
    if (entryIndex == null) {
      return NodeExecutionResult.error('Invalid entry index: $entryIndexStr');
    }

    final cgtData = context.getCgt(cgtName);
    if (cgtData == null) {
      return NodeExecutionResult.error('CGT variable "$cgtName" not found');
    }

    // Parse role ID (empty string means keep current)
    int? roleId;
    if (roleIdStr != null && roleIdStr.isNotEmpty) {
      roleId = int.tryParse(roleIdStr);
    }

    if (context.previewMode) {
      return NodeExecutionResult.success(
        logMessage: 'Would update entry $entryIndex',
      );
    }

    try {
      final modifier = cgtData.getModifier();
      final success = modifier.updateEntry(
        entryIndex: entryIndex,
        stage: stageValue,
        roleId: roleId,
      );

      if (!success) {
        return NodeExecutionResult.error('Failed to update entry $entryIndex');
      }

      cgtData.modified = true;

      return NodeExecutionResult.success(
        logMessage: 'Updated entry $entryIndex',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to update entry: $e');
    }
  }
}

/// Executor for updating a Crystarium node's name.
class CgtUpdateNodeNameExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final cgtName = getConfig<String>(node, 'cgtVariable') ?? 'cgt';
    final nodeIdStr = evaluateConfigAsString(node, 'nodeId', context);
    final newName = evaluateConfigAsString(node, 'newName', context);

    if (nodeIdStr.isEmpty) {
      return NodeExecutionResult.error('Node ID is required');
    }

    if (newName.isEmpty) {
      return NodeExecutionResult.error('New name is required');
    }

    final nodeId = int.tryParse(nodeIdStr);
    if (nodeId == null) {
      return NodeExecutionResult.error('Invalid node ID: $nodeIdStr');
    }

    final cgtData = context.getCgt(cgtName);
    if (cgtData == null) {
      return NodeExecutionResult.error('CGT variable "$cgtName" not found');
    }

    if (context.previewMode) {
      return NodeExecutionResult.success(
        logMessage: 'Would rename node $nodeId to "$newName"',
      );
    }

    try {
      final modifier = cgtData.getModifier();
      final success = modifier.updateNodeName(nodeId, newName);

      if (!success) {
        return NodeExecutionResult.error('Node $nodeId not found');
      }

      cgtData.modified = true;

      return NodeExecutionResult.success(
        logMessage: 'Renamed node $nodeId to "$newName"',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to rename node: $e');
    }
  }
}

/// Executor for finding a Crystarium entry by node ID.
class CgtFindEntryExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final cgtName = getConfig<String>(node, 'cgtVariable') ?? 'cgt';
    final nodeIdStr = evaluateConfigAsString(node, 'nodeId', context);
    final storeAs = getConfig<String>(node, 'storeAs') ?? 'foundEntry';

    if (nodeIdStr.isEmpty) {
      return NodeExecutionResult.error('Node ID is required');
    }

    final nodeId = int.tryParse(nodeIdStr);
    if (nodeId == null) {
      return NodeExecutionResult.error('Invalid node ID: $nodeIdStr');
    }

    final cgtData = context.getCgt(cgtName);
    if (cgtData == null) {
      return NodeExecutionResult.error('CGT variable "$cgtName" not found');
    }

    // Find the entry containing this node
    final entryIndex = cgtData.findEntryForNode(nodeId);
    if (entryIndex == null) {
      return NodeExecutionResult.success(
        nextPort: 'notFound',
        logMessage: 'Node $nodeId not found in any entry',
      );
    }

    final entry = cgtData.data.entries[entryIndex];

    // Store both entry and its index for convenience
    context.setVariable(storeAs, {
      'entryIndex': entryIndex,
      'entry': entry,
      'nodeId': nodeId,
      'patternName': entry.patternName,
      'stage': entry.stage,
      'roleId': entry.roleId,
    });

    return NodeExecutionResult.success(
      nextPort: 'found',
      outputValue: entry,
      logMessage: 'Found node $nodeId in entry $entryIndex',
    );
  }
}

/// Executor for deleting a Crystarium entry.
class CgtDeleteEntryExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final cgtName = getConfig<String>(node, 'cgtVariable') ?? 'cgt';
    final entryIndexStr = evaluateConfigAsString(node, 'entryIndex', context);

    if (entryIndexStr.isEmpty) {
      return NodeExecutionResult.error('Entry index is required');
    }

    final entryIndex = int.tryParse(entryIndexStr);
    if (entryIndex == null) {
      return NodeExecutionResult.error('Invalid entry index: $entryIndexStr');
    }

    final cgtData = context.getCgt(cgtName);
    if (cgtData == null) {
      return NodeExecutionResult.error('CGT variable "$cgtName" not found');
    }

    if (context.previewMode) {
      return NodeExecutionResult.success(
        logMessage: 'Would delete entry $entryIndex',
      );
    }

    try {
      final modifier = cgtData.getModifier();
      final success = modifier.deleteEntry(entryIndex);

      if (!success) {
        return NodeExecutionResult.error(
          'Failed to delete entry $entryIndex - it may have child nodes',
        );
      }

      cgtData.modified = true;

      return NodeExecutionResult.success(
        logMessage: 'Deleted entry $entryIndex',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to delete entry: $e');
    }
  }
}
