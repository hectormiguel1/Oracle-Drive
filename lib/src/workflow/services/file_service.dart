import '../../../models/app_game_code.dart';
import '../../../models/wdb_model.dart';
import '../../../models/ztr_model.dart';

/// Abstract interface for file operations in workflow execution.
///
/// This interface abstracts the native file service operations, allowing
/// for easier testing and potential alternative implementations.
abstract class IFileService {
  /// Load a WDB file from the given path.
  Future<WdbData> loadWdb(String path, AppGameCode gameCode);

  /// Save a WDB file to the given path.
  Future<void> saveWdb(String path, AppGameCode gameCode, WdbData data);

  /// Load a ZTR file from the given path.
  Future<ZtrData> loadZtr(String path, AppGameCode gameCode);

  /// Save a ZTR file to the given path.
  Future<void> saveZtr(String path, AppGameCode gameCode, ZtrData data);
}

/// Abstract interface for archive operations in workflow execution.
abstract class IArchiveService {
  /// Unpack a WPD archive to the output directory.
  Future<int> unpackWpd(
    String archivePath,
    String outputDir,
    AppGameCode gameCode,
  );

  /// Repack files into a WPD archive.
  Future<void> repackWpd(
    String sourceDir,
    String archivePath,
    AppGameCode gameCode,
  );

  /// Load a WBT file list.
  Future<List<String>> loadWbtFileList(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
  );

  /// Extract files from a WBT archive by indices.
  Future<int> extractWbtByIndices(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
    List<int> indices,
    String outputDir,
  );

  /// Repack files into a WBT archive.
  Future<void> repackWbt(
    AppGameCode gameCode,
    String fileListPath,
    String binPath,
    String sourceDir,
  );
}

/// Abstract interface for image operations in workflow execution.
abstract class IImageService {
  /// Extract textures from an image archive.
  Future<int> extractTextures(
    String archivePath,
    String outputDir,
    AppGameCode gameCode,
  );

  /// Repack textures into an image archive.
  Future<void> repackTextures(
    String sourceDir,
    String archivePath,
    AppGameCode gameCode,
  );
}
