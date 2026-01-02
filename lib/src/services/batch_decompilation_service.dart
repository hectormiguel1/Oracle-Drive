import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/src/services/java_decompiler_service.dart';
import 'package:oracle_drive/src/services/native_service.dart';
import 'package:path/path.dart' as p;
import 'package:fabula_nova_sdk/bridge_generated/modules/wct.dart' as wct_sdk;

/// Progress information during batch decompilation
class BatchDecompilationProgress {
  final int totalFiles;
  final int processedFiles;
  final int successCount;
  final int errorCount;
  final String currentFile;
  final String currentStage;
  final List<DecompilationFileError> errors;

  BatchDecompilationProgress({
    required this.totalFiles,
    required this.processedFiles,
    required this.successCount,
    required this.errorCount,
    required this.currentFile,
    required this.currentStage,
    required this.errors,
  });

  double get progress => totalFiles > 0 ? processedFiles / totalFiles : 0;
}

/// Result of batch decompilation
class BatchDecompilationResult {
  final int totalProcessed;
  final int successCount;
  final int skippedCount;
  final List<DecompilationFileError> errors;
  final String projectPath;

  BatchDecompilationResult({
    required this.totalProcessed,
    required this.successCount,
    required this.skippedCount,
    required this.errors,
    required this.projectPath,
  });

  int get errorCount => errors.length;
}

/// Error information for a single file
class DecompilationFileError {
  final String filePath;
  final String stage;
  final String message;
  final DateTime timestamp;

  DecompilationFileError({
    required this.filePath,
    required this.stage,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => '[$stage] $filePath: $message';
}

/// Configuration for batch decompilation
class BatchDecompileConfig {
  final String outputPath;
  final bool processBinContainers;
  final bool cleanUpIntermediateFiles;
  final bool generateGradleProject;

  const BatchDecompileConfig({
    required this.outputPath,
    this.processBinContainers = true,
    this.cleanUpIntermediateFiles = true,
    this.generateGradleProject = false,
  });
}

/// Service for batch decompiling CLB files into a Java project structure
class BatchDecompilationService {
  static final BatchDecompilationService instance = BatchDecompilationService._();

  final Logger _logger = Logger('BatchDecompilationService');

  BatchDecompilationService._();

  // Progress stream controller
  StreamController<BatchDecompilationProgress>? _progressController;
  bool _isCancelled = false;

  /// Stream of progress updates during decompilation
  Stream<BatchDecompilationProgress> get progressStream {
    _progressController ??= StreamController.broadcast();
    return _progressController!.stream;
  }

  /// Cancel the current decompilation operation
  void cancel() {
    _isCancelled = true;
  }

  /// Extract package name from Java source code
  static String? extractPackageName(String javaSource) {
    final packageRegex = RegExp(r'^\s*package\s+([\w.]+)\s*;', multiLine: true);
    final match = packageRegex.firstMatch(javaSource);
    return match?.group(1);
  }

  /// Extract class name from Java source code
  static String? extractClassName(String javaSource) {
    // Match public class/interface/enum declaration
    final classRegex = RegExp(
      r'(?:public\s+)?(?:abstract\s+)?(?:final\s+)?(?:class|interface|enum)\s+(\w+)',
      multiLine: true,
    );
    final match = classRegex.firstMatch(javaSource);
    return match?.group(1);
  }

  /// Main entry point for batch decompilation
  Future<BatchDecompilationResult> decompileGameDirectory({
    required String gameRootPath,
    required BatchDecompileConfig config,
    required AppGameCode gameCode,
  }) async {
    _isCancelled = false;
    _progressController?.close();
    _progressController = StreamController.broadcast();

    final errors = <DecompilationFileError>[];
    int successCount = 0;
    int skippedCount = 0;
    final processedClbPaths = <String>{};
    final tempDirs = <Directory>[];

    try {
      // Check Java availability first
      if (!await JavaDecompilerService.instance.isJavaAvailable()) {
        throw JavaNotFoundError(
          'Java is required for decompilation. Please install Java and ensure it is in your PATH.',
        );
      }

      final rootDir = Directory(gameRootPath);
      if (!rootDir.existsSync()) {
        throw ArgumentError('Game root directory does not exist: $gameRootPath');
      }

      // Create output project structure
      final projectDir = Directory(config.outputPath);
      final srcDir = Directory(p.join(projectDir.path, 'src', 'main', 'java'));
      await srcDir.create(recursive: true);

      // Stage 1: Scan for all CLB and BIN files
      _emitProgress(0, 0, 0, 0, 'Scanning...', 'scanning', errors);

      final clbFiles = <File>[];
      final binFiles = <File>[];

      await _scanDirectory(rootDir, clbFiles, binFiles, config.processBinContainers);

      _logger.info('Found ${clbFiles.length} CLB files and ${binFiles.length} BIN files');

      // Stage 2: Unpack BIN containers to find more CLBs
      if (config.processBinContainers && binFiles.isNotEmpty) {
        _emitProgress(0, binFiles.length, 0, 0, 'Unpacking containers...', 'unpacking', errors);

        for (int i = 0; i < binFiles.length && !_isCancelled; i++) {
          final binFile = binFiles[i];
          _emitProgress(
            i,
            binFiles.length,
            0,
            0,
            p.basename(binFile.path),
            'unpacking',
            errors,
          );

          try {
            final extractedClbs = await _unpackBinContainer(binFile, tempDirs);
            clbFiles.addAll(extractedClbs);
          } catch (e) {
            errors.add(DecompilationFileError(
              filePath: binFile.path,
              stage: 'unpack',
              message: e.toString(),
            ));
          }
        }

        _logger.info('After unpacking: ${clbFiles.length} total CLB files');
      }

      if (_isCancelled) {
        return _buildResult(0, skippedCount, errors, config.outputPath);
      }

      // Stage 3 & 4: Convert CLB -> .class -> .java and organize
      final totalFiles = clbFiles.length;

      for (int i = 0; i < clbFiles.length && !_isCancelled; i++) {
        final clbFile = clbFiles[i];

        // Skip if we've already processed this CLB (e.g., duplicate in nested containers)
        if (processedClbPaths.contains(clbFile.path)) {
          skippedCount++;
          continue;
        }
        processedClbPaths.add(clbFile.path);

        _emitProgress(
          i,
          totalFiles,
          successCount,
          errors.length,
          p.basename(clbFile.path),
          'decompiling',
          errors,
        );

        try {
          final success = await _processClbFile(
            clbFile,
            srcDir,
            config.cleanUpIntermediateFiles,
            errors,
          );

          if (success) {
            successCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          errors.add(DecompilationFileError(
            filePath: clbFile.path,
            stage: 'process',
            message: e.toString(),
          ));
        }
      }

      // Stage 5: Generate Gradle files if requested
      if (config.generateGradleProject && !_isCancelled) {
        await _generateGradleFiles(projectDir, gameCode);
      }

      // Stage 6: Clean up temp directories
      for (final tempDir in tempDirs) {
        try {
          if (tempDir.existsSync()) {
            await tempDir.delete(recursive: true);
          }
        } catch (e) {
          _logger.warning('Failed to clean up temp dir: ${tempDir.path}');
        }
      }

      _emitProgress(
        totalFiles,
        totalFiles,
        successCount,
        errors.length,
        'Complete',
        'complete',
        errors,
      );

      return _buildResult(successCount + errors.length + skippedCount, successCount, errors, config.outputPath);
    } finally {
      await _progressController?.close();
      _progressController = null;
    }
  }

  Future<void> _scanDirectory(
    Directory dir,
    List<File> clbFiles,
    List<File> binFiles,
    bool collectBins,
  ) async {
    try {
      final entities = dir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.clb') {
            clbFiles.add(entity);
          } else if (collectBins && ext == '.bin') {
            binFiles.add(entity);
          }
        }
      }
    } catch (e) {
      _logger.warning('Error scanning directory ${dir.path}: $e');
    }
  }

  Future<List<File>> _unpackBinContainer(File binFile, List<Directory> tempDirs) async {
    final clbFiles = <File>[];

    // Create output directory in same location as bin file
    final outputDir = Directory(p.join(
      binFile.parent.path,
      '_${p.basenameWithoutExtension(binFile.path)}_extracted',
    ));

    try {
      await NativeService.instance.unpackWpd(binFile.path, outputDir.path);
      tempDirs.add(outputDir);

      // Scan extracted directory for CLB files
      if (outputDir.existsSync()) {
        final entities = outputDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File && p.extension(entity.path).toLowerCase() == '.clb') {
            clbFiles.add(entity);
          }
        }
      }
    } catch (e) {
      _logger.warning('Failed to unpack bin container ${binFile.path}: $e');
      rethrow;
    }

    return clbFiles;
  }

  Future<bool> _processClbFile(
    File clbFile,
    Directory srcDir,
    bool cleanUpIntermediate,
    List<DecompilationFileError> errors,
  ) async {
    File? classFile;

    try {
      // Step 1: Convert CLB to .class
      await NativeService.instance.processWct(
        clbFile.path,
        wct_sdk.TargetType.clb,
        wct_sdk.Action.clbToJava,
      );

      // The .class file should be created in the same directory
      final classPath = clbFile.path.replaceAll(
        RegExp(r'\.clb$', caseSensitive: false),
        '.class',
      );
      classFile = File(classPath);

      if (!classFile.existsSync()) {
        errors.add(DecompilationFileError(
          filePath: clbFile.path,
          stage: 'convert',
          message: 'Class file not created',
        ));
        return false;
      }

      // Step 2: Decompile .class to Java source
      final javaSource = await JavaDecompilerService.instance.decompileClass(classPath);

      if (javaSource.isEmpty) {
        errors.add(DecompilationFileError(
          filePath: clbFile.path,
          stage: 'decompile',
          message: 'Decompilation produced empty output',
        ));
        return false;
      }

      // Step 3: Extract package and class name
      final packageName = extractPackageName(javaSource);
      String className = extractClassName(javaSource) ??
          p.basenameWithoutExtension(clbFile.path);

      // Step 4: Determine output path and write file
      String outputPath;
      if (packageName != null && packageName.isNotEmpty) {
        final packagePath = packageName.replaceAll('.', Platform.pathSeparator);
        final packageDir = Directory(p.join(srcDir.path, packagePath));
        await packageDir.create(recursive: true);
        outputPath = p.join(packageDir.path, '$className.java');
      } else {
        // No package - put in default package
        final defaultDir = Directory(p.join(srcDir.path, 'default_package'));
        await defaultDir.create(recursive: true);
        outputPath = p.join(defaultDir.path, '$className.java');
      }

      // Handle duplicate class names by appending a number
      var finalPath = outputPath;
      var counter = 1;
      while (File(finalPath).existsSync()) {
        final baseName = p.basenameWithoutExtension(outputPath);
        final dir = p.dirname(outputPath);
        finalPath = p.join(dir, '${baseName}_$counter.java');
        counter++;
      }

      await File(finalPath).writeAsString(javaSource);
      _logger.fine('Written: $finalPath');

      // Step 5: Clean up intermediate .class file if requested
      if (cleanUpIntermediate && classFile.existsSync()) {
        try {
          await classFile.delete();
        } catch (e) {
          _logger.fine('Failed to delete intermediate class file: $e');
        }
      }

      return true;
    } catch (e) {
      errors.add(DecompilationFileError(
        filePath: clbFile.path,
        stage: 'process',
        message: e.toString(),
      ));

      // Clean up intermediate file on error
      if (cleanUpIntermediate && classFile != null && classFile.existsSync()) {
        try {
          await classFile.delete();
        } catch (_) {}
      }

      return false;
    }
  }

  Future<void> _generateGradleFiles(Directory projectDir, AppGameCode gameCode) async {
    final gameName = gameCode.displayName.replaceAll(' ', '_').toLowerCase();

    // build.gradle
    final buildGradle = '''
plugins {
    id 'java'
}

group = 'com.squareenix.$gameName'
version = '1.0'

java {
    sourceCompatibility = JavaVersion.VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_1_8
}

repositories {
    mavenCentral()
}

dependencies {
    // Add dependencies as needed
}
''';

    await File(p.join(projectDir.path, 'build.gradle')).writeAsString(buildGradle);

    // settings.gradle
    final settingsGradle = '''
rootProject.name = '${gameName}_decompiled'
''';

    await File(p.join(projectDir.path, 'settings.gradle')).writeAsString(settingsGradle);
  }

  void _emitProgress(
    int processed,
    int total,
    int success,
    int errorCount,
    String currentFile,
    String stage,
    List<DecompilationFileError> errors,
  ) {
    if (_progressController?.isClosed ?? true) return;

    _progressController!.add(BatchDecompilationProgress(
      totalFiles: total,
      processedFiles: processed,
      successCount: success,
      errorCount: errorCount,
      currentFile: currentFile,
      currentStage: stage,
      errors: List.unmodifiable(errors),
    ));
  }

  BatchDecompilationResult _buildResult(
    int total,
    int success,
    List<DecompilationFileError> errors,
    String projectPath,
  ) {
    return BatchDecompilationResult(
      totalProcessed: total,
      successCount: success,
      skippedCount: total - success - errors.length,
      errors: List.unmodifiable(errors),
      projectPath: projectPath,
    );
  }
}
