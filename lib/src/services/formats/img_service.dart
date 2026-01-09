import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/img/structs.dart'
    as img_sdk;
import 'package:oracle_drive/src/services/core/error_handler.dart';

/// Service for IMG (Texture) file operations.
///
/// IMG files are texture containers used in the FF13 trilogy.
/// This service provides methods to extract and repack IMG textures,
/// as well as DDS to PNG conversion utilities.
class ImgService with NativeErrorHandler {
  static ImgService? _instance;
  static ImgService get instance => _instance ??= ImgService._();

  final Logger _logger = Logger('ImgService');

  @override
  Logger get logger => _logger;

  ImgService._();

  /// Extracts an IMG texture to a DDS file.
  ///
  /// # Arguments
  /// * [headerPath] - Path to the XGR/IMG header file.
  /// * [imgbPath] - Path to the IMGB container file.
  /// * [outputDdsPath] - Output DDS file path.
  ///
  /// # Returns
  /// IMG metadata about the extracted texture.
  ///
  /// # Throws
  /// [NativeError] if extraction fails.
  Future<img_sdk.ImgData> unpack(
    String headerPath,
    String imgbPath,
    String outputDdsPath,
  ) async {
    return safeCall('IMG Unpack', () async {
      return await sdk.imgUnpack(
        headerFile: headerPath,
        imgbFile: imgbPath,
        outDds: outputDdsPath,
      );
    });
  }

  /// Extracts an IMG texture to memory.
  ///
  /// # Arguments
  /// * [headerPath] - Path to the XGR/IMG header file.
  /// * [imgbPath] - Path to the IMGB container file.
  ///
  /// # Returns
  /// Tuple of (IMG metadata, DDS bytes).
  ///
  /// # Throws
  /// [NativeError] if extraction fails.
  Future<(img_sdk.ImgData, Uint8List)> unpackToMemory(
    String headerPath,
    String imgbPath,
  ) async {
    return safeCall('IMG Unpack To Memory', () async {
      final result = await sdk.imgUnpackToMemory(
        headerFile: headerPath,
        imgbFile: imgbPath,
      );
      return (result.$1, Uint8List.fromList(result.$2));
    });
  }

  /// Repacks a DDS file back into an IMG container (strict size parity).
  ///
  /// The DDS file must match the original texture dimensions.
  ///
  /// # Arguments
  /// * [headerPath] - Path to the XGR/IMG header file.
  /// * [imgbPath] - Path to the IMGB container file.
  /// * [inputDdsPath] - Input DDS file path.
  ///
  /// # Throws
  /// [NativeError] if repacking fails or size mismatch.
  Future<void> repack(
    String headerPath,
    String imgbPath,
    String inputDdsPath,
  ) async {
    return safeCall('IMG Repack', () async {
      await sdk.imgRepackStrict(
        headerFile: headerPath,
        imgbFile: imgbPath,
        inDds: inputDdsPath,
      );
    });
  }

  /// Converts a DDS file to PNG format.
  ///
  /// # Arguments
  /// * [inputDdsPath] - Input DDS file path.
  /// * [outputPngPath] - Output PNG file path.
  ///
  /// # Returns
  /// Tuple of (width, height) of the converted image.
  ///
  /// # Throws
  /// [NativeError] if conversion fails.
  Future<(int, int)> convertDdsToPng(
      String inputDdsPath, String outputPngPath) async {
    return safeCall('DDS To PNG', () async {
      final result = await sdk.convertDdsToPng(
        ddsPath: inputDdsPath,
        pngPath: outputPngPath,
      );
      return (result.$1, result.$2);
    });
  }

  /// Converts a DDS file to PNG bytes in memory.
  ///
  /// # Arguments
  /// * [ddsPath] - Input DDS file path.
  ///
  /// # Returns
  /// Tuple of ((width, height), pngBytes).
  ///
  /// # Throws
  /// [NativeError] if conversion fails.
  Future<((int, int), Uint8List)> convertDdsToPngBytes(String ddsPath) async {
    return safeCall('DDS To PNG Bytes', () async {
      final result = await sdk.convertDdsToPngBytes(ddsPath: ddsPath);
      return ((result.$1.$1, result.$1.$2), Uint8List.fromList(result.$2));
    });
  }
}
