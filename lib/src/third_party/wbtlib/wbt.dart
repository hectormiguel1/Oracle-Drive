import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:ff13_mod_resource/src/services/native_service.dart';
import 'package:ff13_mod_resource/src/third_party/wbtlib/wbt.g.dart'
    as native;
import 'package:ff13_mod_resource/src/third_party/common.g.dart' as common;
import 'package:ff13_mod_resource/src/utils/native_result_utils.dart';
import 'package:logging/logging.dart';

class WhiteBinTools {
  static final Logger logger = Logger('WhiteBinTools');

  static List<FileEntry> getMetadata(
    native.GameCode gameCode,
    String fileListPath,
  ) {
    List<FileEntry> entries = [];
    using((Arena arena) {
      final fileListPathPtr =
          fileListPath.toNativeUtf8(allocator: arena).cast<Char>();
      final result = native.get_file_metadata(gameCode, fileListPathPtr);

      NativeResult.unwrap(
        result,
        native.free_result,
        onSuccess: (res) {
          final fileEntryListPtr = res.payload.data.cast<native.FileEntryList>();
          if (fileEntryListPtr == nullptr) {
            return;
          }

          final count = fileEntryListPtr.ref.count;
          if (count == 0) {
            return;
          }

          final itemsPtr = fileEntryListPtr.ref.items;
          for (int i = 0; i < count; i++) {
            final item = itemsPtr[i];
            final filePath = item.file_path.cast<Utf8>().toDartString();
            final chunkInfoSections = filePath.split(":");
            if (chunkInfoSections.length < 4) {
              continue;
            }
            final binChunkIndex = int.parse("0x${chunkInfoSections[0]}") * 0x800;
            final uncompressedSize = int.parse("0x${chunkInfoSections[1]}");
            final compressedSize = int.parse("0x${chunkInfoSections[2]}");
            final virtualPath = chunkInfoSections[3];
            final fileName = virtualPath.split("/").last;
            entries.add(
              FileEntry(
                chunkIndex: item.chunk_index,
                fileCode: item.file_code,
                fileTypeId: item.file_type_id,
                chunkInfo: ChunkInfo(
                  binChunkIndex: binChunkIndex,
                  uncompressedSize: uncompressedSize,
                  compressedSize: compressedSize,
                  virtualPath: virtualPath,
                ),
                fileName: fileName,
              ),
            );
          }
        },
        onError: (msg) {},
      );
    });

    return entries;
  }

  static void unpackSingle(
    native.GameCode gameCode,
    String fileListPath,
    String binPath,
    String virtualPath, {
    String? outputDir,
  }) {
    using((Arena arena) {
      final fileListPathPtr =
          fileListPath.toNativeUtf8(allocator: arena).cast<Char>();
      final binPathPtr = binPath.toNativeUtf8(allocator: arena).cast<Char>();
      final targetPtr = virtualPath.toNativeUtf8(allocator: arena).cast<Char>();

      common.Result result;
      if (outputDir != null) {
        final outputDirPtr =
            outputDir.toNativeUtf8(allocator: arena).cast<Char>();
        result = native.unpack_single_to_path(
          gameCode,
          fileListPathPtr,
          binPathPtr,
          targetPtr,
          outputDirPtr,
        );
      } else {
        result = native.unpack_single(
          gameCode,
          fileListPathPtr,
          binPathPtr,
          targetPtr,
        );
      }

      NativeResult.check(
        result,
        native.free_result,
        failureMessage: "Unpack failed for $virtualPath",
      );
    });
  }

  static void unpackAll(
    native.GameCode gameCode,
    String fileListPath,
    String binPath, {
    String? outputDir,
  }) {
    using((Arena arena) {
      final fileListPathPtr =
          fileListPath.toNativeUtf8(allocator: arena).cast<Char>();
      final binPathPtr = binPath.toNativeUtf8(allocator: arena).cast<Char>();

      common.Result result;

      if (outputDir != null) {
        final outputDirPtr =
            outputDir.toNativeUtf8(allocator: arena).cast<Char>();
        result = native.unpack_all_to_path(
          gameCode,
          fileListPathPtr,
          binPathPtr,
          outputDirPtr,
        );
      } else {
        result = native.unpack_all(gameCode, fileListPathPtr, binPathPtr);
      }

      NativeResult.check(
        result,
        native.free_result,
        failureMessage: "Unpack all failed",
      );
    });
  }

  static void repackMultipleInternal(
    native.GameCode gameCode,
    String fileListPath,
    String binPath,
    String extractDir, {
    bool makeBackup = true,
  }) {
    using((Arena arena) {
      final fileListPtr =
          fileListPath.toNativeUtf8(allocator: arena).cast<Char>();
      final binPtr = binPath.toNativeUtf8(allocator: arena).cast<Char>();
      final dirPtr = extractDir.toNativeUtf8(allocator: arena).cast<Char>();

      final result = native.repack_multiple(
        gameCode,
        fileListPtr,
        binPtr,
        dirPtr,
        makeBackup,
      );

      NativeResult.check(
        result,
        native.free_result,
        failureMessage: "Repack multiple failed",
      );
    });
  }

  static Future<List<FileEntry>> parseFileEntries(
    native.GameCode gameCode,
    String fileListPath,
  ) {
    return NativeService.instance
        .parseWbtFileEntries(gameCode, fileListPath)
        .then((value) => (value as List).cast<FileEntry>());
  }

  /// Helper used by NativeService worker.

  static Future<int> unpack(
    native.GameCode gameCode,
    String fileListPath,
    String binPath,
    List<FileEntry> entries, {
    String? outputDir,
    void Function(double)? onProgress,
  }) async {
    return await NativeService.instance.unpackWbt(
      gameCode,
      fileListPath,
      binPath,
      entries,
      outputDir: outputDir,
      onProgress: onProgress,
    );
  }

  static Future<int> unpackAllFiles(
    native.GameCode gameCode,
    String fileListPath,
    String binPath, {
    String? outputDir,
  }) async {
    return await NativeService.instance.unpackAllWbt(
      gameCode,
      fileListPath,
      binPath,
      outputDir: outputDir,
    );
  }

  static Future<int> repackMultiple(
    native.GameCode gameCode,
    String fileListPath,
    String binPath,
    String extractDir, {
    bool makeBackup = true,
  }) async {
    return await NativeService.instance.repackMultipleWbt(
      gameCode,
      fileListPath,
      binPath,
      extractDir,
      makeBackup: makeBackup,
    );
  }
}

class FileEntry {
  final int chunkIndex;
  final int fileCode;
  final int fileTypeId;
  final ChunkInfo chunkInfo;
  final String fileName;

  FileEntry({
    required this.chunkIndex,
    required this.fileCode,
    required this.fileTypeId,
    required this.chunkInfo,
    required this.fileName,
  });
}

class ChunkInfo {
  final int binChunkIndex;
  final int uncompressedSize;
  final int compressedSize;
  final String virtualPath;

  ChunkInfo({
    required this.binChunkIndex,
    required this.uncompressedSize,
    required this.compressedSize,
    required this.virtualPath,
  });
}
