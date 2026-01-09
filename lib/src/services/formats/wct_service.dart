import 'package:logging/logging.dart';
import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/wct.dart' as wct_sdk;
import 'package:oracle_drive/src/services/core/error_handler.dart';

/// Service for WCT (Encryption/Decryption) operations.
///
/// WCT provides encryption/decryption for file types used in FF13 trilogy:
/// - FileList files (archive directory structures)
/// - CLB files (Crystal Logic Bytecode)
class WctService with NativeErrorHandler {
  static WctService? _instance;
  static WctService get instance => _instance ??= WctService._();

  final Logger _logger = Logger('WctService');

  @override
  Logger get logger => _logger;

  WctService._();

  /// Processes a file with encryption or decryption.
  ///
  /// # Arguments
  /// * [target] - Target file type (FileList or CLB).
  /// * [action] - Crypt action (Decrypt or Encrypt).
  /// * [inputFile] - Path to the file to process.
  ///
  /// # Throws
  /// [NativeError] if processing fails.
  Future<void> process(
    wct_sdk.TargetType target,
    wct_sdk.Action action,
    String inputFile,
  ) async {
    return safeCall('WCT Process', () async {
      await sdk.wctProcess(
        target: target,
        action: action,
        inputFile: inputFile,
      );
      _logger.info(
        "WCT processed: ${action.name} ${target.name} at $inputFile",
      );
    });
  }

  /// Decrypts a FileList file.
  Future<void> decryptFileList(String inputFile) async {
    return process(
      wct_sdk.TargetType.fileList,
      wct_sdk.Action.decrypt,
      inputFile,
    );
  }

  /// Encrypts a FileList file.
  Future<void> encryptFileList(String inputFile) async {
    return process(
      wct_sdk.TargetType.fileList,
      wct_sdk.Action.encrypt,
      inputFile,
    );
  }

  /// Decrypts a CLB file.
  Future<void> decryptClb(String inputFile) async {
    return process(
      wct_sdk.TargetType.clb,
      wct_sdk.Action.decrypt,
      inputFile,
    );
  }

  /// Encrypts a CLB file.
  Future<void> encryptClb(String inputFile) async {
    return process(
      wct_sdk.TargetType.clb,
      wct_sdk.Action.encrypt,
      inputFile,
    );
  }
}
