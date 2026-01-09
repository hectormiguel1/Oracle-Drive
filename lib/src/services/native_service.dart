import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oracle_drive/src/services/navigation_service.dart';
import 'package:oracle_drive/components/widgets/crystal_dialog.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';

import 'package:oracle_drive/models/wdb_model.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:logging/logging.dart';

import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/ztr/structs.dart'
    as ztr_sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/wct.dart'
    as wct_sdk; // Import WCT enums
import 'package:fabula_nova_sdk/bridge_generated/modules/crystalium/structs.dart'
    as cgt_sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/vfx/structs.dart'
    as vfx_sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/event/structs.dart'
    as event_sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/scd/structs.dart'
    as scd_sdk;
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Uint64List;

import 'package:oracle_drive/src/services/app_database.dart';
import 'package:oracle_drive/src/isar/common/lookup_config.dart';
import 'package:oracle_drive/src/isar/common/models.dart';

enum LogLevel {
  off(0),
  error(1),
  warning(2),
  info(3),
  debug(4),
  trace(5);

  final int level;
  const LogLevel(this.level);
}

class NativeService {
  static NativeService? _instance;
  static NativeService get instance => _instance ??= NativeService._();

  final Logger _logger = Logger('NativeService');
  NativeService._();

  final List<String> _logBuffer = [];
  StreamController<String>? _logStreamController;

  // Timer for polling logs from Rust (hot restart safe)
  Timer? _logPollTimer;
  StreamSubscription<LogRecord>? _dartLogSubscription;

  // Static flag to track Rust SDK initialization (survives hot restart)
  static bool _rustInitialized = false;

  // Track if an error dialog is currently showing to prevent multiple popups
  bool _isErrorDialogShowing = false;

  Stream<String> get logStream {
    _logStreamController ??= StreamController.broadcast();
    return _logStreamController!.stream;
  }

  List<String> get logHistory => List.unmodifiable(_logBuffer);

  void _addLog(String message) {
    if (_logStreamController?.isClosed ?? true) return;
    _logBuffer.add(message);
    if (_logBuffer.length > 1000) {
      _logBuffer.removeAt(0);
    }
    _logStreamController?.add(message);
  }

  /// Reset the service for hot reload support
  static Future<void> reset() async {
    await _instance?._dispose();
    _instance = null;
  }

  Future<void> initialize() async {
    // Cancel existing timer and subscriptions first (for hot reload)
    _logPollTimer?.cancel();
    await _dartLogSubscription?.cancel();

    // Reinitialize stream controller if closed
    if (_logStreamController?.isClosed ?? true) {
      _logStreamController = StreamController.broadcast();
    }

    _logger.info("NativeService initializing...");

    // Only call initApp on first initialization - Rust state persists across hot restart
    if (!_rustInitialized) {
      await sdk.initApp();
      _rustInitialized = true;
    } else {
      // After hot restart, reset the read index to fetch any logs we missed
      await sdk.resetLogReadIndex();
    }

    // Load any buffered logs from Rust (survives hot restart)
    final bufferedLogs = await sdk.getAllBufferedLogs();
    for (final log in bufferedLogs) {
      _addLog(log);
    }

    // Start polling for new logs from Rust (hot restart safe)
    _startLogPolling();

    // Also route our own Dart logs to this stream
    _dartLogSubscription = Logger.root.onRecord.listen((record) {
      final msg = "[DART] ${record.level.name}: ${record.message}";
      _addLog(msg);
    });

    _logger.info("NativeService initialized (using fabula_nova_sdk).");
    await sdk.testLog(message: "NativeService initialized successfully.");
    sdk.setLogLevel(level: LogLevel.info.level);
  }

  /// Poll for new logs from Rust (less frequent in debug mode to reduce overhead)
  void _startLogPolling() {
    // Use longer interval in debug mode to reduce overhead
    final interval = kDebugMode
        ? const Duration(milliseconds: 500)
        : const Duration(milliseconds: 100);

    _logPollTimer = Timer.periodic(interval, (_) async {
      try {
        final newLogs = await sdk.fetchLogs();
        for (final log in newLogs) {
          _addLog(log);
        }
      } catch (e) {
        // Silently ignore polling errors - Rust side may be reinitializing
      }
    });
  }

  Future<void> testLog(String msg) async {
    await sdk.testLog(message: msg);
  }

  // ========================================================================
  // Public API
  // ========================================================================

  Future<WdbData> parseWdb(String path, AppGameCode game) async {
    try {
      final sdkWdbData = await sdk.wdbParse(inFile: path, gameCode: game.index);
      final wdbData = WdbData.fromSdk(sdkWdbData);
      final sheetName = wdbData.sheetName;
      final repo = AppDatabase.instance.getRepositoryForGame(game);

      _logger.info(
        "WDB parseWdb: sheetName='$sheetName', rows=${wdbData.rows.length}",
      );

      // Check if this sheet has a LookupConfig and upsert lookups
      final lookupConfig = LookupConfigRegistry.instance.resolve(
        game,
        sheetName,
      );
      if (lookupConfig != null) {
        final lookups = <EntityLookup>[];
        for (final row in wdbData.rows) {
          if (!row.containsKey('record')) continue;
          final record = row['record'] as String;
          final lookup = lookupConfig.extractFromRow(record, row);
          if (lookup != null) {
            lookups.add(lookup);
          }
        }

        if (lookups.isNotEmpty) {
          repo.upsertLookups(lookups);
          _logger.info(
            "WDB parseWdb: Upserted ${lookups.length} lookups via LookupConfig",
          );
        }
      }

      _logger.info(
        "SheetName ${wdbData.sheetName}: Columns: ${wdbData.columns.map((c) => c.originalName).toList()}",
      );

      return wdbData;
    } catch (e) {
      _showErrorDialog("WDB Parse Error", e.toString());
      rethrow;
    }
  }

  Future<void> saveWdb(String path, AppGameCode game, WdbData data) async {
    try {
      final sdkWdbData = data.toSdk();
      await sdk.wdbRepack(data: sdkWdbData, outFile: path);
      _logger.info("WDB saved successfully to $path");
    } catch (e) {
      _showErrorDialog("WDB Save Error", e.toString());
      rethrow;
    }
  }

  Future<void> saveWdbJson(String path, WdbData data) async {
    try {
      final sdkWdbData = data.toSdk();
      final json = await sdk.wdbToJson(data: sdkWdbData);
      await File(path).writeAsString(json);
      _logger.info("WDB JSON saved successfully to $path");
    } catch (e) {
      _showErrorDialog("WDB JSON Save Error", e.toString());
      rethrow;
    }
  }

  Future<void> unpackWbt(
    AppGameCode gameCode,
    String fileListPath,
    String binPath, {
    String? outputDir,
    void Function(double)? onProgress,
  }) async {
    // Note: The new SDK wbtExtract extracts EVERYTHING.
    // If we want to unpack specific entries, we might need a new SDK function
    // or just use wbtExtract if that's acceptable.
    // For now, let's use wbtExtract for all.
    try {
      if (outputDir == null) throw "Output directory is required";
      await sdk.wbtExtract(
        filelistPath: fileListPath,
        containerPath: binPath,
        outDir: outputDir,
        gameCode: gameCode.index,
      );
    } catch (e) {
      _showErrorDialog("WBT Unpack Error", e.toString());
      rethrow;
    }
  }

  /// Repacks all files from a directory into a WBT archive.
  Future<void> repackWbtAll(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
    String extractDir,
  ) async {
    try {
      await sdk.wbtRepack(
        filelistPath: fileListPath,
        containerPath: binPath,
        extractedDir: extractDir,
        gameCode: gameCode.index,
      );
    } catch (e) {
      _showErrorDialog("WBT Repack Error", e.toString());
      rethrow;
    }
  }

  /// Repacks a single file into a WBT archive.
  /// [targetPathInArchive] is the virtual path in the archive (e.g., "chr/c000/model.trb")
  /// [fileToInject] is the path to the file on disk to inject.
  Future<void> repackWbtSingle(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
    String targetPathInArchive,
    String fileToInject,
  ) async {
    try {
      await sdk.wbtRepackSingle(
        filelistPath: fileListPath,
        containerPath: binPath,
        targetPathInArchive: targetPathInArchive,
        fileToInject: fileToInject,
        gameCode: gameCode.index,
      );
    } catch (e) {
      _showErrorDialog("WBT Repack Single Error", e.toString());
      rethrow;
    }
  }

  /// Repacks multiple specific files into a WBT archive.
  /// [filesToPatch] is a list of (targetPathInArchive, fileToInject) pairs.
  Future<void> repackWbtMultiple(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
    List<(String, String)> filesToPatch,
  ) async {
    try {
      await sdk.wbtRepackMultiple(
        filelistPath: fileListPath,
        containerPath: binPath,
        filesToPatch: filesToPatch,
        gameCode: gameCode.index,
      );
    } catch (e) {
      _showErrorDialog("WBT Repack Multiple Error", e.toString());
      rethrow;
    }
  }

  // Keeping old method name for backwards compatibility
  Future<void> repackMultipleWbt(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
    String extractDir,
  ) async {
    return repackWbtAll(gameCode, fileListPath, binPath, extractDir);
  }

  /// Gets the file list from a WBT archive without extracting.
  Future<List<sdk.WbtFileEntry>> getWbtFileList(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
  ) async {
    try {
      return await sdk.wbtGetFileList(
        filelistPath: fileListPath,
        gameCode: gameCode.index,
      );
    } catch (e) {
      _showErrorDialog("WBT File List Error", e.toString());
      rethrow;
    }
  }

  /// Extracts specific files from a WBT archive by their indices.
  Future<int> extractWbtByIndices(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
    List<int> indices,
    String outputDir,
  ) async {
    try {
      final uint64Indices = Uint64List.fromList(indices.map((i) => i).toList());
      final count = await sdk.wbtExtractFilesByIndices(
        filelistPath: fileListPath,
        containerPath: binPath,
        indices: uint64Indices,
        outputDir: outputDir,
        gameCode: gameCode.index,
      );
      return count.toInt();
    } catch (e) {
      _showErrorDialog("WBT Extract Error", e.toString());
      rethrow;
    }
  }

  Future<void> unpackWpd(String inputWdpFile, String outputDir) async {
    try {
      await sdk.wpdUnpack(inFile: inputWdpFile, outDir: outputDir);
    } catch (e) {
      _showErrorDialog("WPD Unpack Error", e.toString());
      rethrow;
    }
  }

  Future<void> repackWpd(String inputWpdDir, String outputFile) async {
    try {
      await sdk.wpdRepack(inDir: inputWpdDir, outFile: outputFile);
    } catch (e) {
      _showErrorDialog("WPD Repack Error", e.toString());
      rethrow;
    }
  }

  Future<void> unpackImg(
    String headerPath,
    String imgbPath,
    String outputDdsPath,
  ) async {
    try {
      await sdk.imgUnpack(
        headerFile: headerPath,
        imgbFile: imgbPath,
        outDds: outputDdsPath,
      );
    } catch (e) {
      _showErrorDialog("IMG Unpack Error", e.toString());
      rethrow;
    }
  }

  Future<void> repackImg(
    String headerPath,
    String imgbPath,
    String inputDdsPath,
  ) async {
    try {
      await sdk.imgRepackStrict(
        headerFile: headerPath,
        imgbFile: imgbPath,
        inDds: inputDdsPath,
      );
    } catch (e) {
      _showErrorDialog("IMG Repack Error", e.toString());
      rethrow;
    }
  }

  Future<void> processWct(
    String inputFile,
    wct_sdk.TargetType target,
    wct_sdk.Action action,
  ) async {
    try {
      await sdk.wctProcess(
        target: target,
        action: action,
        inputFile: inputFile,
      );
    } catch (e) {
      _showErrorDialog("WCT Process Error", e.toString());
      rethrow;
    }
  }

  Future<void> extractZtrData(String path, AppGameCode game) async {
    try {
      final ztrData = await sdk.ztrParse(inFile: path, gameCode: game.index);
      _logger.info("ZTR parsed: ${ztrData.entries.length} entries from $path");

      final Map<String, String> strings = {};
      for (final entry in ztrData.entries) {
        strings[entry.id] = entry.text;
      }

      if (strings.isNotEmpty) {
        final count = AppDatabase.instance
            .getRepositoryForGame(game)
            .insertStringData(strings);
        _logger.info(
          "ZTR inserted $count strings into ${game.displayName} database",
        );
      } else {
        _logger.warning("ZTR parsed but no strings found!");
      }
    } catch (e) {
      _showErrorDialog("ZTR Extract Error", e.toString());
      rethrow;
    }
  }

  Future<void> dumpZtrFileFromDb(AppGameCode game, String outPath) async {
    try {
      final Map<String, String> strings = {};
      final stream = AppDatabase.instance
          .getRepositoryForGame(game)
          .getStrings();
      await for (final chunk in stream) {
        strings.addAll(chunk);
      }

      final List<(String, String)> entries = strings.entries
          .map((e) => (e.key, e.value))
          .toList();
      await sdk.ztrPackFromData(
        entries: entries,
        outFile: outPath,
        gameCode: game.index,
      );
    } catch (e) {
      _showErrorDialog("ZTR Dump Error", e.toString());
      rethrow;
    }
  }

  Future<void> dumpTxtFileFromDb(AppGameCode game, String outPath) async {
    try {
      final Map<String, String> strings = {};
      final stream = AppDatabase.instance
          .getRepositoryForGame(game)
          .getStrings();
      await for (final chunk in stream) {
        strings.addAll(chunk);
      }

      final sdkEntries = strings.entries
          .map((e) => ztr_sdk.ZtrEntry(id: e.key, text: e.value))
          .toList();
      final ztrData = ztr_sdk.ZtrData(entries: sdkEntries, mappings: []);
      final text = await sdk.ztrToTextString(data: ztrData);

      await File(outPath).writeAsString(text);
    } catch (e) {
      _showErrorDialog("ZTR Text Dump Error", e.toString());
      rethrow;
    }
  }

  /// Dumps a list of ZTR entries to a text file.
  /// Used for exporting filtered/searched entries.
  Future<void> dumpFilteredTxtFile(
    List<(String id, String text)> entries,
    String outPath,
  ) async {
    try {
      final sdkEntries = entries
          .map((e) => ztr_sdk.ZtrEntry(id: e.$1, text: e.$2))
          .toList();
      final ztrData = ztr_sdk.ZtrData(entries: sdkEntries, mappings: []);
      final text = await sdk.ztrToTextString(data: ztrData);

      await File(outPath).writeAsString(text);
    } catch (e) {
      _showErrorDialog("ZTR Text Dump Error", e.toString());
      rethrow;
    }
  }

  /// Dumps a list of ZTR entries to a ZTR file.
  /// Used for exporting filtered/searched entries.
  Future<void> dumpFilteredZtrFile(
    List<(String id, String text)> entries,
    String outPath,
    AppGameCode game,
  ) async {
    try {
      await sdk.ztrPackFromData(
        entries: entries,
        outFile: outPath,
        gameCode: game.index,
      );
    } catch (e) {
      _showErrorDialog("ZTR Dump Error", e.toString());
      rethrow;
    }
  }

  /// Loads all ZTR files from a directory recursively.
  /// Returns a stream of progress updates.
  /// When complete, inserts all strings into the database.
  /// [filePattern] - Optional pattern to filter files (e.g., "_us.ztr" for US region only)
  Stream<ztr_sdk.ZtrParseProgress> extractZtrDirectory(
    String dirPath,
    AppGameCode game, {
    String? filePattern,
  }) async* {
    try {
      _logger.info(
        "Starting ZTR directory scan: $dirPath"
        "${filePattern != null ? ' (filter: $filePattern)' : ''}",
      );

      // Stream progress updates from Rust
      final progressStream = sdk.ztrParseDirectory(
        dirPath: dirPath,
        gameCode: game.index,
      );

      await for (final progress in progressStream) {
        yield progress;

        // When complete, the simple version will have all entries
        if (progress.stage == "complete") {
          _logger.info(
            "ZTR directory scan complete: ${progress.successCount} files, "
            "${progress.errorCount} errors",
          );
        }
      }

      // Now load the full result and insert into database
      final result = await sdk.ztrParseDirectorySimple(
        dirPath: dirPath,
        gameCode: game.index,
      );

      if (result.entries.isNotEmpty) {
        final repo = AppDatabase.instance.getRepositoryForGame(game);

        // Filter entries by file pattern if specified
        var entriesToInsert = result.entries;
        if (filePattern != null && filePattern.isNotEmpty) {
          entriesToInsert = result.entries
              .where((e) => e.sourceFile.endsWith(filePattern))
              .toList();
          _logger.info(
            "Filtered entries: ${entriesToInsert.length} of ${result.entries.length} "
            "(pattern: $filePattern)",
          );
        }

        if (entriesToInsert.isNotEmpty) {
          final stringsToInsert = entriesToInsert
              .map(
                (e) => Strings(
                  strResourceId: e.id,
                  value: e.text,
                  sourceFile: e.sourceFile,
                ),
              )
              .toList();

          repo.insertStringsWithSource(stringsToInsert);
          _logger.info(
            "Inserted ${stringsToInsert.length} strings from filtered files",
          );
        }
      }

      if (result.failedFiles.isNotEmpty) {
        _logger.warning(
          "Failed to parse ${result.failedFiles.length} files: "
          "${result.failedFiles.map((e) => e.filePath).join(', ')}",
        );
      }
    } catch (e) {
      _showErrorDialog("ZTR Directory Load Error", e.toString());
      rethrow;
    }
  }

  /// Dumps ZTR strings from database filtered by source file.
  Future<void> dumpZtrFileFromDbBySource(
    AppGameCode game,
    String sourceFile,
    String outPath,
  ) async {
    try {
      final repo = AppDatabase.instance.getRepositoryForGame(game);
      final strings = repo.getStringsBySourceFile(sourceFile);

      final List<(String, String)> entries = strings.entries
          .map((e) => (e.key, e.value))
          .toList();

      await sdk.ztrPackFromData(
        entries: entries,
        outFile: outPath,
        gameCode: game.index,
      );
      _logger.info(
        "Dumped ${entries.length} strings from $sourceFile to $outPath",
      );
    } catch (e) {
      _showErrorDialog("ZTR Dump By Source Error", e.toString());
      rethrow;
    }
  }

  /// Gets all unique source files in the database.
  List<String> getZtrSourceFiles(AppGameCode game) {
    return AppDatabase.instance
        .getRepositoryForGame(game)
        .getDistinctSourceFiles();
  }

  // ============================================================
  // Crystalium (CGT/MCP) Operations
  // ============================================================

  /// Parse a CGT file from memory
  Future<cgt_sdk.CgtFile> parseCgtFromMemory(Uint8List bytes) async {
    try {
      return await sdk.cgtParseFromMemory(data: bytes);
    } catch (e) {
      _showErrorDialog("CGT Parse Error", e.toString());
      rethrow;
    }
  }

  /// Parse a CGT file from disk
  Future<cgt_sdk.CgtFile> parseCgt(String filePath) async {
    try {
      return await sdk.cgtParse(inFile: filePath);
    } catch (e) {
      _showErrorDialog("CGT Parse Error", e.toString());
      rethrow;
    }
  }

  /// Write a CGT file to memory
  Future<Uint8List> writeCgtToMemory(cgt_sdk.CgtFile cgt) async {
    try {
      return await sdk.cgtWriteToMemory(cgt: cgt);
    } catch (e) {
      _showErrorDialog("CGT Write Error", e.toString());
      rethrow;
    }
  }

  /// Write a CGT file to disk
  Future<void> writeCgt(cgt_sdk.CgtFile cgt, String filePath) async {
    try {
      await sdk.cgtWrite(cgt: cgt, outFile: filePath);
    } catch (e) {
      _showErrorDialog("CGT Write Error", e.toString());
      rethrow;
    }
  }

  /// Parse an MCP file from memory
  Future<cgt_sdk.McpFile> parseMcpFromMemory(Uint8List bytes) async {
    try {
      return await sdk.mcpParseFromMemory(data: bytes);
    } catch (e) {
      _showErrorDialog("MCP Parse Error", e.toString());
      rethrow;
    }
  }

  /// Parse an MCP file from disk
  Future<cgt_sdk.McpFile> parseMcp(String filePath) async {
    try {
      return await sdk.mcpParse(inFile: filePath);
    } catch (e) {
      _showErrorDialog("MCP Parse Error", e.toString());
      rethrow;
    }
  }

  /// Validate a CGT file
  Future<List<String>> validateCgt(cgt_sdk.CgtFile cgt) async {
    try {
      return await sdk.cgtValidate(cgt: cgt);
    } catch (e) {
      _showErrorDialog("CGT Validation Error", e.toString());
      rethrow;
    }
  }

  // ============================================================
  // VFX (Visual Effects) Operations
  // ============================================================

  /// Parse a VFX XFV file
  Future<vfx_sdk.VfxData> parseVfx(String filePath) async {
    try {
      return await sdk.vfxParse(inFile: filePath);
    } catch (e) {
      _showErrorDialog("VFX Parse Error", e.toString());
      rethrow;
    }
  }

  /// Get a quick summary of VFX file contents
  Future<vfx_sdk.VfxSummary> getVfxSummary(String filePath) async {
    try {
      return await sdk.vfxGetSummary(inFile: filePath);
    } catch (e) {
      _showErrorDialog("VFX Summary Error", e.toString());
      rethrow;
    }
  }

  /// List all effect names in a VFX file
  Future<List<String>> listVfxEffects(String filePath) async {
    try {
      return await sdk.vfxListEffects(inFile: filePath);
    } catch (e) {
      _showErrorDialog("VFX List Effects Error", e.toString());
      rethrow;
    }
  }

  /// List all textures in a VFX file
  Future<List<vfx_sdk.VfxTexture>> listVfxTextures(String filePath) async {
    try {
      return await sdk.vfxListTextures(inFile: filePath);
    } catch (e) {
      _showErrorDialog("VFX List Textures Error", e.toString());
      rethrow;
    }
  }

  /// Export VFX data to JSON string
  Future<String> exportVfxJson(String filePath) async {
    try {
      return await sdk.vfxExportJson(inFile: filePath);
    } catch (e) {
      _showErrorDialog("VFX Export Error", e.toString());
      rethrow;
    }
  }

  /// Extract VFX textures to DDS files
  Future<List<String>> extractVfxTextures(String xfvPath, String outputDir) async {
    try {
      return await sdk.vfxExtractTextures(xfvPath: xfvPath, outputDir: outputDir);
    } catch (e) {
      _showErrorDialog("VFX Extract Textures Error", e.toString());
      rethrow;
    }
  }

  /// Extracts a single VFX texture as PNG bytes in memory.
  /// Returns ((width, height), pngBytes) - ready for Image.memory() display.
  Future<((int, int), Uint8List)> extractVfxTextureAsPng(
    String xfvPath,
    String textureName,
  ) async {
    try {
      final result = await sdk.vfxExtractTextureAsPng(
        xfvPath: xfvPath,
        textureName: textureName,
      );
      return (
        (result.$1.$1.toInt(), result.$1.$2.toInt()),
        Uint8List.fromList(result.$2),
      );
    } catch (e) {
      _showErrorDialog("VFX Texture Extract Error", e.toString());
      rethrow;
    }
  }

  // ============================================================
  // DDS to PNG Conversion
  // ============================================================

  /// Converts a DDS file to PNG format
  Future<(int, int)> convertDdsToPng(String ddsPath, String pngPath) async {
    try {
      final result = await sdk.convertDdsToPng(ddsPath: ddsPath, pngPath: pngPath);
      return (result.$1.toInt(), result.$2.toInt());
    } catch (e) {
      _showErrorDialog("DDS Convert Error", e.toString());
      rethrow;
    }
  }

  /// Converts a DDS file to PNG and returns the bytes
  Future<((int, int), Uint8List)> convertDdsToPngBytes(String ddsPath) async {
    try {
      final result = await sdk.convertDdsToPngBytes(ddsPath: ddsPath);
      return ((result.$1.$1.toInt(), result.$1.$2.toInt()), Uint8List.fromList(result.$2));
    } catch (e) {
      _showErrorDialog("DDS Convert Error", e.toString());
      rethrow;
    }
  }

  // ============================================================
  // Event (Cutscene) Operations
  // ============================================================

  /// Parse an event file and extract metadata (in-memory)
  Future<event_sdk.EventMetadata> parseEvent(String filePath) async {
    try {
      return await sdk.eventParse(inFile: filePath);
    } catch (e) {
      _showErrorDialog("Event Parse Error", e.toString());
      rethrow;
    }
  }

  /// Get a quick summary of event file contents
  Future<event_sdk.EventSummary> getEventSummary(String filePath) async {
    try {
      return await sdk.eventGetSummary(inFile: filePath);
    } catch (e) {
      _showErrorDialog("Event Summary Error", e.toString());
      rethrow;
    }
  }

  /// Extract event file to directory and return metadata
  Future<event_sdk.ExtractedEvent> extractEvent(
    String inFile,
    String outDir,
  ) async {
    try {
      return await sdk.eventExtract(inFile: inFile, outDir: outDir);
    } catch (e) {
      _showErrorDialog("Event Extract Error", e.toString());
      rethrow;
    }
  }

  /// Export event metadata to JSON string
  Future<String> exportEventJson(String filePath) async {
    try {
      return await sdk.eventExportJson(inFile: filePath);
    } catch (e) {
      _showErrorDialog("Event Export Error", e.toString());
      rethrow;
    }
  }

  /// Parse an event from a directory (including DataSet if present)
  ///
  /// This parses the full event directory structure including:
  /// - bin/*.xwb - Main schedule
  /// - DataSet/*.bin - Motion and camera control blocks
  Future<event_sdk.EventMetadata> parseEventDirectory(String dirPath) async {
    try {
      return await sdk.eventParseDirectory(dirPath: dirPath);
    } catch (e) {
      _showErrorDialog("Event Directory Parse Error", e.toString());
      rethrow;
    }
  }

  // ============================================================
  // SCD (Sound Container) Operations
  // ============================================================

  /// Parse SCD file metadata without decoding audio
  Future<scd_sdk.ScdMetadata> parseScd(String filePath) async {
    try {
      return await sdk.scdParse(inFile: filePath);
    } catch (e) {
      _showErrorDialog("SCD Parse Error", e.toString());
      rethrow;
    }
  }

  /// Decode all audio streams from an SCD file
  Future<scd_sdk.ScdExtractResult> decodeScd(String filePath) async {
    try {
      return await sdk.scdDecode(inFile: filePath);
    } catch (e) {
      _showErrorDialog("SCD Decode Error", e.toString());
      rethrow;
    }
  }

  /// Decode a specific audio stream from an SCD file
  Future<scd_sdk.DecodedAudio> decodeScdStream(
    String filePath,
    int streamIndex,
  ) async {
    try {
      return await sdk.scdDecodeStream(
        inFile: filePath,
        streamIndex: streamIndex,
      );
    } catch (e) {
      _showErrorDialog("SCD Decode Error", e.toString());
      rethrow;
    }
  }

  /// Convert SCD file to WAV bytes (first stream)
  /// Returns complete WAV file data ready for playback
  Future<Uint8List> scdToWav(String filePath) async {
    try {
      return await sdk.scdToWav(inFile: filePath);
    } catch (e) {
      _showErrorDialog("SCD Convert Error", e.toString());
      rethrow;
    }
  }

  /// Extract SCD to WAV file on disk
  Future<void> extractScdToWav(String scdPath, String wavPath) async {
    try {
      await sdk.scdExtractToWav(scdPath: scdPath, wavPath: wavPath);
    } catch (e) {
      _showErrorDialog("SCD Extract Error", e.toString());
      rethrow;
    }
  }

  /// Convert WAV file to SCD format
  Future<void> convertWavToScd(String wavPath, String scdPath) async {
    try {
      await sdk.wavToScd(wavPath: wavPath, scdPath: scdPath);
    } catch (e) {
      _showErrorDialog("WAV to SCD Error", e.toString());
      rethrow;
    }
  }

  void _showErrorDialog(String title, String message) {
    // Prevent multiple error dialogs from stacking
    if (_isErrorDialogShowing) {
      _logger.warning('Suppressing duplicate error dialog: $title');
      return;
    }

    if (navigatorKey.currentContext != null) {
      _isErrorDialogShowing = true;
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) => CrystalDialog(
          title: title,
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            CrystalButton(
              label: 'OK',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ).then((_) {
        _isErrorDialogShowing = false;
      });
    }
  }

  Future<void> _dispose() async {
    _logPollTimer?.cancel();
    await _dartLogSubscription?.cancel();
    _logPollTimer = null;
    _dartLogSubscription = null;

    if (!(_logStreamController?.isClosed ?? true)) {
      await _logStreamController?.close();
    }
    _logStreamController = null;
  }

  void dispose() {
    _dispose();
  }
}
