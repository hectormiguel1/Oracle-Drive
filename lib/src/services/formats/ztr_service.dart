import 'dart:io';
import 'package:logging/logging.dart';
import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/ztr/structs.dart'
    as ztr_sdk;
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/src/services/core/error_handler.dart';

/// Service for ZTR (Text Resource) file operations.
///
/// ZTR files contain localized text strings used in the FF13 trilogy.
/// This service provides pure file operations - database integration
/// should be handled at the provider layer.
class ZtrService with NativeErrorHandler {
  static ZtrService? _instance;
  static ZtrService get instance => _instance ??= ZtrService._();

  final Logger _logger = Logger('ZtrService');

  @override
  Logger get logger => _logger;

  ZtrService._();

  /// Parses a ZTR file and returns its contents.
  ///
  /// # Arguments
  /// * [path] - Path to the ZTR file.
  /// * [gameCode] - The game version (FF13, FF13-2, or LR).
  ///
  /// # Returns
  /// Parsed ZTR data with entries and mappings.
  ///
  /// # Throws
  /// [NativeError] if parsing fails.
  Future<ztr_sdk.ZtrData> parse(String path, AppGameCode gameCode) async {
    return safeCall('ZTR Parse', () async {
      final ztrData = await sdk.ztrParse(inFile: path, gameCode: gameCode.index);
      _logger.info("ZTR parsed: ${ztrData.entries.length} entries from $path");
      return ztrData;
    });
  }

  /// Parses all ZTR files in a directory and returns a stream of progress updates.
  ///
  /// This is the streaming version that provides progress updates during parsing.
  ///
  /// # Arguments
  /// * [dirPath] - Path to the directory to scan.
  /// * [gameCode] - The game version (FF13, FF13-2, or LR).
  ///
  /// # Yields
  /// Progress updates during parsing.
  Stream<ztr_sdk.ZtrParseProgress> parseDirectoryWithProgress(
    String dirPath,
    AppGameCode gameCode,
  ) {
    return sdk.ztrParseDirectory(
      dirPath: dirPath,
      gameCode: gameCode.index,
    );
  }

  /// Parses all ZTR files in a directory and returns the complete result.
  ///
  /// This is the simpler version without streaming progress updates.
  ///
  /// # Arguments
  /// * [dirPath] - Path to the directory to scan.
  /// * [gameCode] - The game version (FF13, FF13-2, or LR).
  ///
  /// # Returns
  /// Complete result with all entries and any failed files.
  Future<ztr_sdk.ZtrDirectoryResult> parseDirectory(
    String dirPath,
    AppGameCode gameCode,
  ) async {
    return safeCall('ZTR Parse Directory', () async {
      return await sdk.ztrParseDirectorySimple(
        dirPath: dirPath,
        gameCode: gameCode.index,
      );
    });
  }

  /// Packs string entries into a ZTR file.
  ///
  /// # Arguments
  /// * [entries] - List of (id, text) pairs to pack.
  /// * [outPath] - Output file path.
  /// * [gameCode] - The game version (FF13, FF13-2, or LR).
  ///
  /// # Throws
  /// [NativeError] if packing fails.
  Future<void> packToFile(
    List<(String, String)> entries,
    String outPath,
    AppGameCode gameCode,
  ) async {
    return safeCall('ZTR Pack', () async {
      await sdk.ztrPackFromData(
        entries: entries,
        outFile: outPath,
        gameCode: gameCode.index,
      );
    });
  }

  /// Converts ZTR data to a text string representation.
  ///
  /// # Arguments
  /// * [data] - The ZTR data to convert.
  ///
  /// # Returns
  /// Text representation of the ZTR data.
  Future<String> toTextString(ztr_sdk.ZtrData data) async {
    return safeCall('ZTR To Text', () async {
      return await sdk.ztrToTextString(data: data);
    });
  }

  /// Exports entries to a text file.
  ///
  /// # Arguments
  /// * [entries] - List of ZTR entries to export.
  /// * [outPath] - Output file path.
  ///
  /// # Throws
  /// [NativeError] if export fails.
  Future<void> exportToTextFile(
    List<ztr_sdk.ZtrEntry> entries,
    String outPath,
  ) async {
    return safeCall('ZTR Export Text', () async {
      final ztrData = ztr_sdk.ZtrData(entries: entries, mappings: []);
      final text = await sdk.ztrToTextString(data: ztrData);
      await File(outPath).writeAsString(text);
    });
  }

  /// Exports string map to a text file.
  ///
  /// Convenience method that takes a Map instead of ZtrEntry list.
  ///
  /// # Arguments
  /// * [strings] - Map of id -> text.
  /// * [outPath] - Output file path.
  Future<void> exportMapToTextFile(
    Map<String, String> strings,
    String outPath,
  ) async {
    final entries = strings.entries
        .map((e) => ztr_sdk.ZtrEntry(id: e.key, text: e.value))
        .toList();
    return exportToTextFile(entries, outPath);
  }

  /// Creates ZtrEntry list from a list of (id, text) tuples.
  ///
  /// Utility method for converting tuple format to ZtrEntry format.
  List<ztr_sdk.ZtrEntry> entriesToZtrEntries(List<(String, String)> entries) {
    return entries
        .map((e) => ztr_sdk.ZtrEntry(id: e.$1, text: e.$2))
        .toList();
  }

  /// Converts ZtrData entries to a Map.
  ///
  /// Utility method for converting ZTR data to a string map.
  Map<String, String> ztrDataToMap(ztr_sdk.ZtrData data) {
    return {
      for (final entry in data.entries) entry.id: entry.text,
    };
  }
}
