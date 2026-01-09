import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/vfx/structs.dart'
    as vfx_sdk;
import 'package:oracle_drive/src/services/core/error_handler.dart';

/// Service for VFX (Visual Effects) file operations.
///
/// VFX files (XFV format) contain visual effect data including
/// textures, models, animations, and effect definitions.
///
/// Note: This service provides file operations only. The VFX player
/// (GPU rendering) has been removed due to stability issues.
class VfxService with NativeErrorHandler {
  static VfxService? _instance;
  static VfxService get instance => _instance ??= VfxService._();

  final Logger _logger = Logger('VfxService');

  @override
  Logger get logger => _logger;

  VfxService._();

  /// Parses a VFX XFV file.
  ///
  /// # Arguments
  /// * [filePath] - Path to the XFV file.
  ///
  /// # Returns
  /// Complete VFX data including textures, models, animations, and effects.
  ///
  /// # Throws
  /// [NativeError] if parsing fails.
  Future<vfx_sdk.VfxData> parse(String filePath) async {
    return safeCall('VFX Parse', () async {
      return await sdk.vfxParse(inFile: filePath);
    });
  }

  /// Gets a quick summary of VFX file contents.
  ///
  /// # Arguments
  /// * [filePath] - Path to the XFV file.
  ///
  /// # Returns
  /// Summary with counts of textures, models, effects, etc.
  Future<vfx_sdk.VfxSummary> getSummary(String filePath) async {
    return safeCall('VFX Summary', () async {
      return await sdk.vfxGetSummary(inFile: filePath);
    });
  }

  /// Lists all effect names in a VFX file.
  ///
  /// # Arguments
  /// * [filePath] - Path to the XFV file.
  ///
  /// # Returns
  /// List of effect names.
  Future<List<String>> listEffects(String filePath) async {
    return safeCall('VFX List Effects', () async {
      return await sdk.vfxListEffects(inFile: filePath);
    });
  }

  /// Lists all textures in a VFX file.
  ///
  /// # Arguments
  /// * [filePath] - Path to the XFV file.
  ///
  /// # Returns
  /// List of texture information.
  Future<List<vfx_sdk.VfxTexture>> listTextures(String filePath) async {
    return safeCall('VFX List Textures', () async {
      return await sdk.vfxListTextures(inFile: filePath);
    });
  }

  /// Exports VFX data to JSON string.
  ///
  /// # Arguments
  /// * [filePath] - Path to the XFV file.
  ///
  /// # Returns
  /// JSON representation of the VFX data.
  Future<String> exportJson(String filePath) async {
    return safeCall('VFX Export JSON', () async {
      return await sdk.vfxExportJson(inFile: filePath);
    });
  }

  /// Extracts VFX textures to DDS files.
  ///
  /// # Arguments
  /// * [xfvPath] - Path to the XFV file.
  /// * [outputDir] - Output directory for DDS files.
  ///
  /// # Returns
  /// List of extracted file paths.
  Future<List<String>> extractTextures(
    String xfvPath,
    String outputDir,
  ) async {
    return safeCall('VFX Extract Textures', () async {
      return await sdk.vfxExtractTextures(
        xfvPath: xfvPath,
        outputDir: outputDir,
      );
    });
  }

  /// Extracts a single VFX texture as PNG bytes in memory.
  ///
  /// Ready for `Image.memory()` display in Flutter.
  ///
  /// # Arguments
  /// * [xfvPath] - Path to the XFV file.
  /// * [textureName] - Name of the texture to extract.
  ///
  /// # Returns
  /// Tuple of ((width, height), pngBytes).
  Future<((int, int), Uint8List)> extractTextureAsPng(
    String xfvPath,
    String textureName,
  ) async {
    return safeCall('VFX Extract Texture As PNG', () async {
      final result = await sdk.vfxExtractTextureAsPng(
        xfvPath: xfvPath,
        textureName: textureName,
      );
      return (
        (result.$1.$1.toInt(), result.$1.$2.toInt()),
        Uint8List.fromList(result.$2),
      );
    });
  }
}
