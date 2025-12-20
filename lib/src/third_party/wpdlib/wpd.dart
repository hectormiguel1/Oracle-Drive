import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:oracle_drive/src/services/native_service.dart';
import 'package:oracle_drive/src/third_party/wpdlib/wpd.g.dart' as native;
import 'package:oracle_drive/src/utils/native_result_utils.dart';

class WpdTool {
  static Future<int> unpackFile(String inputWdpFile) async {
    return await NativeService.instance.unpackWpd(inputWdpFile);
  }

  static Future<int> repackDir(String inputWpdDir) async {
    return await NativeService.instance.repackWpd(inputWpdDir);
  }

  // --- Internal handlers for Worker isolate ---

  static int repack(String inputWpdDir) {
    return using((Arena arena) {
      final dirPtr = inputWpdDir.toNativeUtf8(allocator: arena).cast<Char>();
      final result = native.wpd_repack(dirPtr);

      NativeResult.check(
        result,
        native.free_result,
        failureMessage: "WPD Repack failed",
      );
      return 0;
    });
  }

  static int unpack(String inputWdpFile) {
    return using((Arena arena) {
      final filePtr = inputWdpFile.toNativeUtf8(allocator: arena).cast<Char>();
      final result = native.wpd_unpack(filePtr);

      NativeResult.check(
        result,
        native.free_result,
        failureMessage: "WPD Unpack failed",
      );
      return 0;
    });
  }
}
