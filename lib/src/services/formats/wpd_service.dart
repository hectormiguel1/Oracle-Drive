import 'package:logging/logging.dart';
import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:oracle_drive/src/services/core/error_handler.dart';

/// Service for WPD (Package Data) file operations.
///
/// WPD files are archive containers used in the FF13 trilogy.
/// This service provides methods to unpack and repack WPD archives.
class WpdService with NativeErrorHandler {
  static WpdService? _instance;
  static WpdService get instance => _instance ??= WpdService._();

  final Logger _logger = Logger('WpdService');

  @override
  Logger get logger => _logger;

  WpdService._();

  /// Unpacks a WPD archive to a directory.
  ///
  /// # Arguments
  /// * [inputWpdFile] - Path to the WPD file to unpack.
  /// * [outputDir] - Directory where files will be extracted.
  ///
  /// # Throws
  /// [NativeError] if the operation fails.
  Future<void> unpack(String inputWpdFile, String outputDir) async {
    return safeCall('WPD Unpack', () async {
      await sdk.wpdUnpack(inFile: inputWpdFile, outDir: outputDir);
    });
  }

  /// Repacks a directory into a WPD archive.
  ///
  /// # Arguments
  /// * [inputDir] - Directory containing files to pack.
  /// * [outputFile] - Path where the WPD file will be written.
  ///
  /// # Throws
  /// [NativeError] if the operation fails.
  Future<void> repack(String inputDir, String outputFile) async {
    return safeCall('WPD Repack', () async {
      await sdk.wpdRepack(inDir: inputDir, outFile: outputFile);
    });
  }
}
