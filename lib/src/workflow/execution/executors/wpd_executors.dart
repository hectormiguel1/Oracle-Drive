import 'package:path/path.dart' as p;

import '../../../../models/workflow/workflow_models.dart';
import '../../../../providers/workflow_provider.dart';
import '../../../../src/services/native_service.dart';
import '../execution_context.dart';
import '../node_executor.dart';

/// Executor for unpacking a WPD archive.
class WpdUnpackExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final rawInputPath = evaluateConfigAsString(node, 'inputFile', context);
    final rawOutputDir = evaluateConfigAsString(node, 'outputDir', context);
    final storeAs = getConfig<String>(node, 'storeAs') ?? 'extractedDir';

    if (rawInputPath.isEmpty) {
      return NodeExecutionResult.error('WPD file path is required');
    }

    // Resolve paths
    final inputPath = context.resolvePath(rawInputPath);

    // Default output directory: same location as WPD file, named after the file
    final outputDir = rawOutputDir.isNotEmpty
        ? context.resolvePath(rawOutputDir)
        : p.join(
            p.dirname(inputPath),
            p.basenameWithoutExtension(inputPath),
          );

    if (context.previewMode) {
      context.addChange(WpdChange(
        type: 'unpack',
        inputPath: inputPath,
        outputPath: outputDir,
      ));
      context.setVariable(storeAs, outputDir);
      return NodeExecutionResult.success(
        outputValue: outputDir,
        logMessage: 'Would unpack ${p.basename(inputPath)} to $outputDir',
      );
    }

    try {
      await NativeService.instance.unpackWpd(inputPath, outputDir);

      // Store the output directory path for use in subsequent nodes
      context.setVariable(storeAs, outputDir);

      return NodeExecutionResult.success(
        outputValue: outputDir,
        logMessage: 'Unpacked ${p.basename(inputPath)} to $outputDir',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to unpack WPD: $e');
    }
  }
}

/// Executor for repacking a directory into a WPD archive.
class WpdRepackExecutor extends NodeExecutor {
  @override
  Future<NodeExecutionResult> execute(
    WorkflowNode node,
    ExecutionContext context,
  ) async {
    final rawInputDir = evaluateConfigAsString(node, 'inputDir', context);
    final rawOutputFile = evaluateConfigAsString(node, 'outputFile', context);
    final storeAs = getConfig<String>(node, 'storeAs') ?? 'packedFile';

    if (rawInputDir.isEmpty) {
      return NodeExecutionResult.error('Input directory path is required');
    }

    // Resolve paths
    final inputDir = context.resolvePath(rawInputDir);

    // Default output file: same location as input dir, with .wpd extension
    final outputFile = rawOutputFile.isNotEmpty
        ? context.resolvePath(rawOutputFile)
        : '$inputDir.wpd';

    if (context.previewMode) {
      context.addChange(WpdChange(
        type: 'repack',
        inputPath: inputDir,
        outputPath: outputFile,
      ));
      context.setVariable(storeAs, outputFile);
      return NodeExecutionResult.success(
        outputValue: outputFile,
        logMessage: 'Would repack $inputDir to ${p.basename(outputFile)}',
      );
    }

    try {
      await NativeService.instance.repackWpd(inputDir, outputFile);

      // Store the output file path for use in subsequent nodes
      context.setVariable(storeAs, outputFile);

      return NodeExecutionResult.success(
        outputValue: outputFile,
        logMessage: 'Repacked ${p.basename(inputDir)} to ${p.basename(outputFile)}',
      );
    } catch (e) {
      return NodeExecutionResult.error('Failed to repack WPD: $e');
    }
  }
}
