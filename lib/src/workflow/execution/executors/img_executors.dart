import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../models/workflow/workflow_models.dart';
import '../../../../providers/workflow_provider.dart';
import '../../../../src/services/native_service.dart';
import '../execution_context.dart';
import '../node_executor.dart';

/// Executor for extracting IMG textures to DDS format.
class ImgExtractExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final rawHeaderPath = evaluateConfigAsString(node, 'headerPath', context);
    final rawImgbPath = evaluateConfigAsString(node, 'imgbPath', context);
    final rawOutputDdsPath = evaluateConfigAsString(node, 'outputDdsPath', context);
    final storeAs = getConfig<String>(node, 'storeAs') ?? 'extractedDds';

    if (rawHeaderPath.isEmpty) {
      return NodeExecutionResult.error('Header file path is required');
    }

    if (rawImgbPath.isEmpty) {
      return NodeExecutionResult.error('IMGB data file path is required');
    }

    if (rawOutputDdsPath.isEmpty) {
      return NodeExecutionResult.error('Output DDS path is required');
    }

    // Resolve paths
    final headerPath = context.resolvePath(rawHeaderPath);
    final imgbPath = context.resolvePath(rawImgbPath);
    final outputDdsPath = context.resolvePath(rawOutputDdsPath);

    // Validate files exist
    if (!File(headerPath).existsSync()) {
      return NodeExecutionResult.error('Header file not found: $headerPath');
    }

    if (!File(imgbPath).existsSync()) {
      return NodeExecutionResult.error('IMGB file not found: $imgbPath');
    }

    if (context.previewMode) {
      context.addChange(ImgChange(
        type: 'extract',
        headerPath: headerPath,
        imgbPath: imgbPath,
        ddsPath: outputDdsPath,
      ));
      context.setVariable(storeAs, outputDdsPath);
      return NodeExecutionResult.success(
        outputValue: outputDdsPath,
        logMessage: 'Would extract texture from ${p.basename(imgbPath)} to ${p.basename(outputDdsPath)}',
      );
    }

    try {
      await NativeService.instance.unpackImg(headerPath, imgbPath, outputDdsPath);

      // Store the output path for use in subsequent nodes
      context.setVariable(storeAs, outputDdsPath);

      return NodeExecutionResult.success(
        outputValue: outputDdsPath,
        logMessage: 'Extracted texture to ${p.basename(outputDdsPath)}',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to extract IMG: $e');
    }
  }
}

/// Executor for repacking DDS textures back into IMG format.
class ImgRepackExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final rawHeaderPath = evaluateConfigAsString(node, 'headerPath', context);
    final rawImgbPath = evaluateConfigAsString(node, 'imgbPath', context);
    final rawInputDdsPath = evaluateConfigAsString(node, 'inputDdsPath', context);

    if (rawHeaderPath.isEmpty) {
      return NodeExecutionResult.error('Header file path is required');
    }

    if (rawImgbPath.isEmpty) {
      return NodeExecutionResult.error('IMGB data file path is required');
    }

    if (rawInputDdsPath.isEmpty) {
      return NodeExecutionResult.error('Input DDS path is required');
    }

    // Resolve paths
    final headerPath = context.resolvePath(rawHeaderPath);
    final imgbPath = context.resolvePath(rawImgbPath);
    final inputDdsPath = context.resolvePath(rawInputDdsPath);

    // Validate files exist
    if (!File(headerPath).existsSync()) {
      return NodeExecutionResult.error('Header file not found: $headerPath');
    }

    if (!File(imgbPath).existsSync()) {
      return NodeExecutionResult.error('IMGB file not found: $imgbPath');
    }

    if (!File(inputDdsPath).existsSync()) {
      return NodeExecutionResult.error('DDS file not found: $inputDdsPath');
    }

    if (context.previewMode) {
      context.addChange(ImgChange(
        type: 'repack',
        headerPath: headerPath,
        imgbPath: imgbPath,
        ddsPath: inputDdsPath,
      ));
      return NodeExecutionResult.success(
        logMessage: 'Would inject ${p.basename(inputDdsPath)} into ${p.basename(imgbPath)}',
      );
    }

    try {
      await NativeService.instance.repackImg(headerPath, imgbPath, inputDdsPath);

      return NodeExecutionResult.success(
        logMessage: 'Injected ${p.basename(inputDdsPath)} into ${p.basename(imgbPath)}',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to repack IMG: $e');
    }
  }
}
