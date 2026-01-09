import 'package:logging/logging.dart';
import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Uint64List;
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/src/services/core/error_handler.dart';

/// Service for WBT (WhiteBin Archive) file operations.
///
/// WBT archives are the primary archive format used in the FF13 trilogy.
/// They consist of:
/// - A filelist file (filelistu.win32.bin) containing the directory structure
/// - A container file (white_imgu.win32.bin) containing the actual file data
///
/// This service provides methods to extract, repack, and query WBT archives.
class WbtService with NativeErrorHandler {
  static WbtService? _instance;
  static WbtService get instance => _instance ??= WbtService._();

  final Logger _logger = Logger('WbtService');

  @override
  Logger get logger => _logger;

  WbtService._();

  /// Extracts all files from a WBT archive.
  ///
  /// # Arguments
  /// * [gameCode] - The game version (FF13, FF13-2, or LR).
  /// * [fileListPath] - Path to the filelist file.
  /// * [containerPath] - Path to the container file.
  /// * [outputDir] - Directory where files will be extracted.
  ///
  /// # Throws
  /// [NativeError] if the operation fails.
  Future<void> extract(
    AppGameCode gameCode,
    String fileListPath,
    String containerPath,
    String outputDir,
  ) async {
    return safeCall('WBT Extract', () async {
      await sdk.wbtExtract(
        filelistPath: fileListPath,
        containerPath: containerPath,
        outDir: outputDir,
        gameCode: gameCode.index,
      );
    });
  }

  /// Repacks all files from a directory into a WBT archive.
  ///
  /// # Arguments
  /// * [gameCode] - The game version (FF13, FF13-2, or LR).
  /// * [fileListPath] - Path to the filelist file.
  /// * [containerPath] - Path to the container file.
  /// * [extractedDir] - Directory containing files to repack.
  ///
  /// # Throws
  /// [NativeError] if the operation fails.
  Future<void> repack(
    AppGameCode gameCode,
    String fileListPath,
    String containerPath,
    String extractedDir,
  ) async {
    return safeCall('WBT Repack', () async {
      await sdk.wbtRepack(
        filelistPath: fileListPath,
        containerPath: containerPath,
        extractedDir: extractedDir,
        gameCode: gameCode.index,
      );
    });
  }

  /// Repacks a single file into a WBT archive.
  ///
  /// # Arguments
  /// * [gameCode] - The game version (FF13, FF13-2, or LR).
  /// * [fileListPath] - Path to the filelist file.
  /// * [containerPath] - Path to the container file.
  /// * [targetPathInArchive] - Virtual path in the archive (e.g., "chr/c000/model.trb").
  /// * [fileToInject] - Path to the file on disk to inject.
  ///
  /// # Throws
  /// [NativeError] if the operation fails.
  Future<void> repackSingle(
    AppGameCode gameCode,
    String fileListPath,
    String containerPath,
    String targetPathInArchive,
    String fileToInject,
  ) async {
    return safeCall('WBT Repack Single', () async {
      await sdk.wbtRepackSingle(
        filelistPath: fileListPath,
        containerPath: containerPath,
        targetPathInArchive: targetPathInArchive,
        fileToInject: fileToInject,
        gameCode: gameCode.index,
      );
    });
  }

  /// Repacks multiple files into a WBT archive.
  ///
  /// # Arguments
  /// * [gameCode] - The game version (FF13, FF13-2, or LR).
  /// * [fileListPath] - Path to the filelist file.
  /// * [containerPath] - Path to the container file.
  /// * [filesToPatch] - List of (targetPathInArchive, fileToInject) pairs.
  ///
  /// # Throws
  /// [NativeError] if the operation fails.
  Future<void> repackMultiple(
    AppGameCode gameCode,
    String fileListPath,
    String containerPath,
    List<(String, String)> filesToPatch,
  ) async {
    return safeCall('WBT Repack Multiple', () async {
      await sdk.wbtRepackMultiple(
        filelistPath: fileListPath,
        containerPath: containerPath,
        filesToPatch: filesToPatch,
        gameCode: gameCode.index,
      );
    });
  }

  /// Gets the file list from a WBT archive without extracting.
  ///
  /// Use this to display a file tree in the UI without extracting files.
  ///
  /// # Arguments
  /// * [gameCode] - The game version (FF13, FF13-2, or LR).
  /// * [fileListPath] - Path to the filelist file.
  ///
  /// # Returns
  /// List of file entries with metadata.
  ///
  /// # Throws
  /// [NativeError] if the operation fails.
  Future<List<sdk.WbtFileEntry>> getFileList(
    AppGameCode gameCode,
    String fileListPath,
  ) async {
    return safeCall('WBT Get File List', () async {
      return await sdk.wbtGetFileList(
        filelistPath: fileListPath,
        gameCode: gameCode.index,
      );
    });
  }

  /// Extracts specific files from a WBT archive by their indices.
  ///
  /// # Arguments
  /// * [gameCode] - The game version (FF13, FF13-2, or LR).
  /// * [fileListPath] - Path to the filelist file.
  /// * [containerPath] - Path to the container file.
  /// * [indices] - List of file indices to extract.
  /// * [outputDir] - Directory where files will be extracted.
  ///
  /// # Returns
  /// Number of files extracted.
  ///
  /// # Throws
  /// [NativeError] if the operation fails.
  Future<int> extractByIndices(
    AppGameCode gameCode,
    String fileListPath,
    String containerPath,
    List<int> indices,
    String outputDir,
  ) async {
    return safeCall('WBT Extract By Indices', () async {
      final uint64Indices = Uint64List.fromList(indices.map((i) => i).toList());
      final count = await sdk.wbtExtractFilesByIndices(
        filelistPath: fileListPath,
        containerPath: containerPath,
        indices: uint64Indices,
        outputDir: outputDir,
        gameCode: gameCode.index,
      );
      return count.toInt();
    });
  }
}
