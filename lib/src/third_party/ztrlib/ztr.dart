import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/models/ztr_model.dart';
import 'package:oracle_drive/src/services/native_service.dart';
import 'package:oracle_drive/src/third_party/ztrlib/ztr.g.dart' as native;
import 'package:oracle_drive/src/utils/native_result_utils.dart';

class ZtrTool {
  static Future<int> extractDataToDb(String path, AppGameCode game) async {
    return await NativeService.instance.extractZtrData(path, game);
  }

  static Future<int> extractToFile(
    String inZtrPath,
    AppGameCode game, {
    native.ZTREncoding encoding = native.ZTREncoding.ZTR_ENCODING_AUTO,
  }) async {
    return await NativeService.instance.extractZtrToTxt(
      inZtrPath,
      game,
      encoding: encoding,
    );
  }

  static Future<int> convertToZtr(
    String inTxtPath,
    AppGameCode game, {
    native.ZTREncoding encoding = native.ZTREncoding.ZTR_ENCODING_AUTO,
    native.ZTRAction action = native.ZTRAction.ZTR_ACTION_X,
  }) async {
    return await NativeService.instance.convertTxtToZtr(
      inTxtPath,
      game,
      encoding: encoding,
      action: action,
    );
  }

  static Future<int> packFromData(
    ZtrData data,
    String outZtrPath,
    AppGameCode game, {
    native.ZTREncoding encoding = native.ZTREncoding.ZTR_ENCODING_AUTO,
    native.ZTRAction action = native.ZTRAction.ZTR_ACTION_X,
  }) async {
    return await NativeService.instance.packZtrData(
      data,
      outZtrPath,
      game,
      encoding: encoding,
      action: action,
    );
  }

  static Future<int> dumpFromData(ZtrData data, String outTxtPath) async {
    return await NativeService.instance.dumpZtrData(data, outTxtPath);
  }

  static Future<int> packFromDb(
    AppGameCode game,
    String outZtrPath, {
    native.ZTREncoding encoding = native.ZTREncoding.ZTR_ENCODING_AUTO,
    native.ZTRAction action = native.ZTRAction.ZTR_ACTION_C2,
  }) async {
    return await NativeService.instance.dumpZtrFileFromDb(
      game,
      outZtrPath,
      encoding: encoding,
      action: action,
    );
  }

  static Future<int> dumpFromDb(AppGameCode game, String outTxtPath) async {
    return await NativeService.instance.dumpTxtFileFromDb(game, outTxtPath);
  }

  static void init() {
    native.ztr_init();
  }

  // --- Internal handlers for Worker isolate ---

  static Pointer<native.ZtrResultData> allocateZtrData(
    ZtrData data,
    Arena arena,
  ) {
    final ptr = arena<native.ZtrResultData>();

    if (data.entries.isNotEmpty) {
      final entriesPtr = arena<native.ZtrEntry>(data.entries.length);
      for (int i = 0; i < data.entries.length; i++) {
        entriesPtr[i].id = data.entries[i].id
            .toNativeUtf8(allocator: arena)
            .cast();
        entriesPtr[i].text = data.entries[i].text
            .toNativeUtf8(allocator: arena)
            .cast();
      }
      ptr.ref.entries = entriesPtr;
      ptr.ref.entry_count = data.entries.length;
    } else {
      ptr.ref.entries = nullptr;
      ptr.ref.entry_count = 0;
    }

    if (data.mappings.isNotEmpty) {
      final mappingsPtr = arena<native.ZtrKeyMapping>(data.mappings.length);
      for (int i = 0; i < data.mappings.length; i++) {
        mappingsPtr[i].key = data.mappings[i].key
            .toNativeUtf8(allocator: arena)
            .cast();
        mappingsPtr[i].value = data.mappings[i].value
            .toNativeUtf8(allocator: arena)
            .cast();
      }
      ptr.ref.mappings = mappingsPtr;
      ptr.ref.mapping_count = data.mappings.length;
    } else {
      ptr.ref.mappings = nullptr;
      ptr.ref.mapping_count = 0;
    }

    return ptr;
  }

  static Map<String, String> convertFromNative(
    Pointer<native.ZtrResultData> dataPtr,
  ) {
    final data = dataPtr.ref;
    final Map<String, String> strings = {};

    for (int i = 0; i < data.entry_count; i++) {
      final entry = data.entries[i];
      final id = entry.id.cast<Utf8>().toDartString();
      final text = entry.text.cast<Utf8>().toDartString();
      strings[id] = text;
    }
    return strings;
  }

  static Map<String, String> extractData(String path, int gameCodeValue) {
    return using((Arena arena) {
      final pathPtr = path.toNativeUtf8(allocator: arena).cast<Char>();
      final result = native.ztr_extract_data(pathPtr, gameCodeValue, 0);

      return NativeResult.unwrap(
        result,
        native.free_result,
        onSuccess: (res) {
          final dataPtr = res.payload.data.cast<native.ZtrResultData>();
          return convertFromNative(dataPtr);
        },
        failureMessage: "Failed to extract ZTR data: $path",
      );
    });
  }

  static void extractFile(String path, int gameCodeValue, int encodingVal) {
    using((Arena arena) {
      final pathPtr = path.toNativeUtf8(allocator: arena).cast<Char>();
      final result = native.ztr_extract(pathPtr, gameCodeValue, encodingVal);
      NativeResult.check(
        result,
        native.free_result,
        failureMessage: "ZTR Extract File failed",
      );
    });
  }

  static void convert(
    String path,
    int gameCodeValue,
    int encodingVal,
    int actionVal,
  ) {
    using((Arena arena) {
      final pathPtr = path.toNativeUtf8(allocator: arena).cast<Char>();
      final result = native.ztr_convert(
        pathPtr,
        gameCodeValue,
        encodingVal,
        actionVal,
      );
      NativeResult.check(
        result,
        native.free_result,
        failureMessage: "ZTR Convert failed",
      );
    });
  }

  static void packData(
    ZtrData data,
    String path,
    int gameCodeValue,
    int encodingVal,
    int actionVal,
  ) {
    using((Arena arena) {
      final pathPtr = path.toNativeUtf8(allocator: arena).cast<Char>();
      final dataPtr = allocateZtrData(data, arena);

      final result = native.ztr_pack_data(
        dataPtr,
        pathPtr,
        gameCodeValue,
        encodingVal,
        actionVal,
      );

      NativeResult.check(
        result,
        native.free_result,
        failureMessage: "ZTR Pack failed",
      );
    });
  }

  static void dumpData(ZtrData data, String path) {
    using((Arena arena) {
      final pathPtr = path.toNativeUtf8(allocator: arena).cast<Char>();
      final dataPtr = allocateZtrData(data, arena);

      final result = native.ztr_dump_data(dataPtr, pathPtr);
      NativeResult.check(
        result,
        native.free_result,
        failureMessage: "ZTR Dump failed",
      );
    });
  }
}
