import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/scd/structs.dart'
    as scd_sdk;
import 'package:oracle_drive/src/services/core/error_handler.dart';

/// Service for SCD (Sound Container Data) file operations.
///
/// SCD files are audio containers used in the FF13 trilogy.
/// They contain encoded audio streams (typically Vorbis format)
/// that can be decoded to WAV for playback.
class ScdService with NativeErrorHandler {
  static ScdService? _instance;
  static ScdService get instance => _instance ??= ScdService._();

  final Logger _logger = Logger('ScdService');

  @override
  Logger get logger => _logger;

  ScdService._();

  /// Parses SCD file metadata without decoding audio.
  ///
  /// This is fast and returns information about the audio streams
  /// without decoding the actual audio data.
  ///
  /// # Arguments
  /// * [filePath] - Path to the SCD file.
  ///
  /// # Returns
  /// SCD metadata with stream information.
  ///
  /// # Throws
  /// [NativeError] if parsing fails.
  Future<scd_sdk.ScdMetadata> parse(String filePath) async {
    return safeCall('SCD Parse', () async {
      return await sdk.scdParse(inFile: filePath);
    });
  }

  /// Decodes all audio streams from an SCD file.
  ///
  /// # Arguments
  /// * [filePath] - Path to the SCD file.
  ///
  /// # Returns
  /// Result containing all decoded audio streams.
  ///
  /// # Throws
  /// [NativeError] if decoding fails.
  Future<scd_sdk.ScdExtractResult> decode(String filePath) async {
    return safeCall('SCD Decode', () async {
      return await sdk.scdDecode(inFile: filePath);
    });
  }

  /// Decodes a specific audio stream from an SCD file.
  ///
  /// # Arguments
  /// * [filePath] - Path to the SCD file.
  /// * [streamIndex] - Index of the stream to decode (0-based).
  ///
  /// # Returns
  /// Decoded audio data for the specified stream.
  ///
  /// # Throws
  /// [NativeError] if decoding fails.
  Future<scd_sdk.DecodedAudio> decodeStream(
    String filePath,
    int streamIndex,
  ) async {
    return safeCall('SCD Decode Stream', () async {
      return await sdk.scdDecodeStream(
        inFile: filePath,
        streamIndex: streamIndex,
      );
    });
  }

  /// Converts an SCD file to WAV bytes in memory.
  ///
  /// Decodes the first audio stream and returns complete WAV file
  /// data ready for playback.
  ///
  /// # Arguments
  /// * [filePath] - Path to the SCD file.
  ///
  /// # Returns
  /// Complete WAV file data.
  ///
  /// # Throws
  /// [NativeError] if conversion fails.
  Future<Uint8List> toWav(String filePath) async {
    return safeCall('SCD To WAV', () async {
      return await sdk.scdToWav(inFile: filePath);
    });
  }

  /// Extracts an SCD file to a WAV file on disk.
  ///
  /// # Arguments
  /// * [scdPath] - Path to the input SCD file.
  /// * [wavPath] - Path for the output WAV file.
  ///
  /// # Throws
  /// [NativeError] if extraction fails.
  Future<void> extractToWav(String scdPath, String wavPath) async {
    return safeCall('SCD Extract To WAV', () async {
      await sdk.scdExtractToWav(scdPath: scdPath, wavPath: wavPath);
    });
  }

  /// Converts a WAV file to SCD format.
  ///
  /// # Arguments
  /// * [wavPath] - Path to the input WAV file.
  /// * [scdPath] - Path for the output SCD file.
  ///
  /// # Throws
  /// [NativeError] if conversion fails.
  Future<void> fromWav(String wavPath, String scdPath) async {
    return safeCall('WAV To SCD', () async {
      await sdk.wavToScd(wavPath: wavPath, scdPath: scdPath);
    });
  }
}
