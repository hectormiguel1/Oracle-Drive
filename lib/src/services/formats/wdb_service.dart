import 'dart:io';
import 'package:logging/logging.dart';
import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/wdb/structs.dart'
    as wdb_sdk;
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/models/wdb_model.dart';
import 'package:oracle_drive/src/services/core/error_handler.dart';

/// Service for WDB (Game Database) file operations.
///
/// WDB files are binary database files used in the FF13 trilogy
/// for storing structured game data like enemy stats, items, etc.
///
/// This service provides pure file operations - lookup/registry
/// integration should be handled at the provider layer.
class WdbService with NativeErrorHandler {
  static WdbService? _instance;
  static WdbService get instance => _instance ??= WdbService._();

  final Logger _logger = Logger('WdbService');

  @override
  Logger get logger => _logger;

  WdbService._();

  /// Parses a WDB file from disk.
  ///
  /// # Arguments
  /// * [path] - Path to the WDB file.
  /// * [gameCode] - The game version (FF13, FF13-2, or LR).
  ///
  /// # Returns
  /// Parsed WDB data with columns and rows.
  ///
  /// # Throws
  /// [NativeError] if parsing fails.
  Future<WdbData> parse(String path, AppGameCode gameCode) async {
    return safeCall('WDB Parse', () async {
      final sdkWdbData = await sdk.wdbParse(inFile: path, gameCode: gameCode.index);
      final wdbData = WdbData.fromSdk(sdkWdbData);
      _logger.info(
        "WDB parsed: sheetName='${wdbData.sheetName}', rows=${wdbData.rows.length}",
      );
      return wdbData;
    });
  }

  /// Parses a WDB file and returns the raw SDK data.
  ///
  /// Use this when you need the raw SDK type instead of the Dart model.
  Future<wdb_sdk.WdbData> parseRaw(String path, AppGameCode gameCode) async {
    return safeCall('WDB Parse Raw', () async {
      return await sdk.wdbParse(inFile: path, gameCode: gameCode.index);
    });
  }

  /// Saves WDB data to a file.
  ///
  /// # Arguments
  /// * [path] - Output file path.
  /// * [data] - WDB data to save.
  ///
  /// # Throws
  /// [NativeError] if saving fails.
  Future<void> save(String path, WdbData data) async {
    return safeCall('WDB Save', () async {
      final sdkWdbData = data.toSdk();
      await sdk.wdbRepack(data: sdkWdbData, outFile: path);
      _logger.info("WDB saved successfully to $path");
    });
  }

  /// Saves WDB data from raw SDK type.
  Future<void> saveRaw(String path, wdb_sdk.WdbData data) async {
    return safeCall('WDB Save Raw', () async {
      await sdk.wdbRepack(data: data, outFile: path);
      _logger.info("WDB saved successfully to $path");
    });
  }

  /// Exports WDB data to JSON format.
  ///
  /// # Arguments
  /// * [data] - WDB data to export.
  ///
  /// # Returns
  /// JSON string representation of the WDB data.
  Future<String> toJson(WdbData data) async {
    return safeCall('WDB To JSON', () async {
      final sdkWdbData = data.toSdk();
      return await sdk.wdbToJson(data: sdkWdbData);
    });
  }

  /// Saves WDB data as JSON to a file.
  ///
  /// # Arguments
  /// * [path] - Output file path.
  /// * [data] - WDB data to save.
  ///
  /// # Throws
  /// [NativeError] if saving fails.
  Future<void> saveAsJson(String path, WdbData data) async {
    return safeCall('WDB Save JSON', () async {
      final json = await toJson(data);
      await File(path).writeAsString(json);
      _logger.info("WDB JSON saved successfully to $path");
    });
  }

  /// Parses WDB data from JSON string.
  ///
  /// # Arguments
  /// * [json] - JSON string to parse.
  ///
  /// # Returns
  /// Parsed WDB data.
  Future<wdb_sdk.WdbData> fromJson(String json) async {
    return safeCall('WDB From JSON', () async {
      return await sdk.wdbFromJson(json: json);
    });
  }
}
