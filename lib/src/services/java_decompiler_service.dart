import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class JavaDecompilerService {
  static final JavaDecompilerService instance = JavaDecompilerService._();
  final Logger _logger = Logger('JavaDecompilerService');

  JavaDecompilerService._();

  String? _cfrJarPath;
  bool? _javaAvailable;

  /// Check if Java is available on the system
  Future<bool> isJavaAvailable() async {
    if (_javaAvailable != null) return _javaAvailable!;

    try {
      final result = await Process.run('java', ['-version']);
      _javaAvailable = result.exitCode == 0;
      if (_javaAvailable!) {
        _logger.info('Java is available on the system');
      } else {
        _logger.warning('Java not found (exit code: ${result.exitCode})');
      }
    } catch (e) {
      _logger.warning('Java not found: $e');
      _javaAvailable = false;
    }

    return _javaAvailable!;
  }

  /// Get the path to the CFR jar file, extracting from assets if necessary
  Future<String> _getCfrJarPath() async {
    if (_cfrJarPath != null && File(_cfrJarPath!).existsSync()) {
      return _cfrJarPath!;
    }

    // First, try the development path (direct file access)
    final devPath = p.join(
      Directory.current.path,
      'assets',
      'cfr',
      'cfr-0.152.jar',
    );
    if (File(devPath).existsSync()) {
      _cfrJarPath = devPath;
      _logger.info('Using CFR jar from development path: $_cfrJarPath');
      return _cfrJarPath!;
    }

    // For bundled apps, extract from assets to temp directory
    final tempDir = await getTemporaryDirectory();
    final extractedPath = p.join(tempDir.path, 'cfr', 'cfr-0.152.jar');
    final extractedFile = File(extractedPath);

    if (!extractedFile.existsSync()) {
      _logger.info('Extracting CFR jar to: $extractedPath');
      await extractedFile.parent.create(recursive: true);

      try {
        final bytes = await rootBundle.load('assets/cfr/cfr-0.152.jar');
        await extractedFile.writeAsBytes(bytes.buffer.asUint8List());
        _logger.info('CFR jar extracted successfully');
      } catch (e) {
        _logger.severe('Failed to extract CFR jar: $e');
        rethrow;
      }
    }

    _cfrJarPath = extractedPath;
    return _cfrJarPath!;
  }

  /// Decompile a .class file to Java source code
  /// Returns the decompiled Java source code as a string
  /// Throws an exception if Java is not available or decompilation fails
  Future<String> decompileClass(String classFilePath) async {
    // Check Java availability
    if (!await isJavaAvailable()) {
      throw JavaNotFoundError(
        'Java is not installed or not in PATH. '
        'Please install Java to use the decompiler feature.',
      );
    }

    // Validate input file
    final classFile = File(classFilePath);
    if (!classFile.existsSync()) {
      throw DecompilationError('Class file not found: $classFilePath');
    }

    // Get CFR jar path
    final cfrPath = await _getCfrJarPath();

    // Run CFR decompiler
    _logger.info('Decompiling: $classFilePath');

    try {
      final result = await Process.run(
        'java',
        ['-jar', cfrPath, classFilePath],
        workingDirectory: classFile.parent.path,
      );

      if (result.exitCode != 0) {
        final error = result.stderr.toString().trim();
        _logger.severe('CFR decompilation failed: $error');
        throw DecompilationError(
          'Decompilation failed: ${error.isNotEmpty ? error : 'Unknown error'}',
        );
      }

      final output = result.stdout.toString();
      if (output.isEmpty) {
        throw DecompilationError('Decompilation produced no output');
      }

      _logger.info('Decompilation successful');
      return output;
    } catch (e) {
      if (e is JavaNotFoundError || e is DecompilationError) rethrow;
      _logger.severe('Error running CFR: $e');
      throw DecompilationError('Failed to run decompiler: $e');
    }
  }

  /// Decompile a .class file and save the result to a .java file
  /// Returns the path to the generated .java file
  Future<String> decompileAndSave(String classFilePath) async {
    final source = await decompileClass(classFilePath);

    // Generate output path: replace .class with .java
    final outputPath = classFilePath.replaceAll(
      RegExp(r'\.class$', caseSensitive: false),
      '.java',
    );

    await File(outputPath).writeAsString(source);
    _logger.info('Saved decompiled source to: $outputPath');

    return outputPath;
  }
}

/// Error thrown when Java is not found on the system
class JavaNotFoundError implements Exception {
  final String message;
  JavaNotFoundError(this.message);

  @override
  String toString() => message;
}

/// Error thrown when decompilation fails
class DecompilationError implements Exception {
  final String message;
  DecompilationError(this.message);

  @override
  String toString() => message;
}
