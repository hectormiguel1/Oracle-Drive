import '../../../models/app_game_code.dart';
import '../../../models/wdb_model.dart';
import '../../../models/ztr_model.dart';
import '../../services/native_service.dart';
import 'file_service.dart';
import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;

/// Implementation of [IFileService] using the NativeService.
class NativeFileService implements IFileService {
  final NativeService _native;

  NativeFileService([NativeService? native])
      : _native = native ?? NativeService.instance;

  @override
  Future<WdbData> loadWdb(String path, AppGameCode gameCode) {
    return _native.parseWdb(path, gameCode);
  }

  @override
  Future<void> saveWdb(String path, AppGameCode gameCode, WdbData data) {
    return _native.saveWdb(path, gameCode, data);
  }

  @override
  Future<ZtrData> loadZtr(String path, AppGameCode gameCode) async {
    final sdkData = await sdk.ztrParse(inFile: path, gameCode: gameCode.index);
    return ZtrData(
      entries: sdkData.entries
          .map((e) => ZtrEntry(e.id, e.text))
          .toList(),
      mappings: sdkData.mappings
          .map((m) => ZtrKeyMapping(m.key, m.value))
          .toList(),
    );
  }

  @override
  Future<void> saveZtr(String path, AppGameCode gameCode, ZtrData data) async {
    final entries = data.entries
        .map((e) => (e.id, e.text))
        .toList();
    await sdk.ztrPackFromData(entries: entries, outFile: path, gameCode: gameCode.index);
  }
}

/// Implementation of [IArchiveService] using the NativeService.
class NativeArchiveService implements IArchiveService {
  final NativeService _native;

  NativeArchiveService([NativeService? native])
      : _native = native ?? NativeService.instance;

  @override
  Future<int> unpackWpd(
    String archivePath,
    String outputDir,
    AppGameCode gameCode,
  ) async {
    await _native.unpackWpd(archivePath, outputDir);
    return 0; // The SDK doesn't return count, we could count files in outputDir
  }

  @override
  Future<void> repackWpd(
    String sourceDir,
    String archivePath,
    AppGameCode gameCode,
  ) {
    return _native.repackWpd(sourceDir, archivePath);
  }

  @override
  Future<List<String>> loadWbtFileList(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
  ) async {
    final entries = await _native.getWbtFileList(gameCode, fileListPath, binPath);
    return entries.map((e) => e.path).toList();
  }

  @override
  Future<int> extractWbtByIndices(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
    List<int> indices,
    String outputDir,
  ) {
    return _native.extractWbtByIndices(
      gameCode,
      fileListPath,
      binPath,
      indices,
      outputDir,
    );
  }

  @override
  Future<void> repackWbt(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
    String sourceDir,
  ) {
    return _native.repackWbtAll(gameCode, fileListPath, binPath, sourceDir);
  }
}

/// Implementation of [IImageService] using the NativeService.
class NativeImageService implements IImageService {
  final NativeService _native;

  NativeImageService([NativeService? native])
      : _native = native ?? NativeService.instance;

  @override
  Future<int> extractTextures(
    String archivePath,
    String outputDir,
    AppGameCode gameCode,
  ) async {
    // The native service uses header + imgb pattern
    // archivePath should be the header, and imgb is derived
    final imgbPath = archivePath.replaceAll('.imag', '.imgb');
    await _native.unpackImg(archivePath, imgbPath, outputDir);
    return 1; // Return count of extracted textures
  }

  @override
  Future<void> repackTextures(
    String sourceDir,
    String archivePath,
    AppGameCode gameCode,
  ) async {
    final imgbPath = archivePath.replaceAll('.imag', '.imgb');
    await _native.repackImg(archivePath, imgbPath, sourceDir);
  }
}
