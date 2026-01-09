import 'package:logging/logging.dart';
import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/event/structs.dart'
    as event_sdk;
import 'package:oracle_drive/src/services/core/error_handler.dart';

/// Service for Event (Cutscene) file operations.
///
/// Event files contain cutscene data including actor positioning,
/// dialogue references, camera movements, and timing information.
class EventService with NativeErrorHandler {
  static EventService? _instance;
  static EventService get instance => _instance ??= EventService._();

  final Logger _logger = Logger('EventService');

  @override
  Logger get logger => _logger;

  EventService._();

  /// Parses an event file and extracts metadata.
  ///
  /// This loads the file, parses the structure, and returns actors,
  /// blocks, resources, and dialogue entry references.
  ///
  /// # Arguments
  /// * [filePath] - Path to the event file (.white.win32.xwb).
  ///
  /// # Returns
  /// Complete event metadata.
  ///
  /// # Throws
  /// [NativeError] if parsing fails.
  Future<event_sdk.EventMetadata> parse(String filePath) async {
    return safeCall('Event Parse', () async {
      return await sdk.eventParse(inFile: filePath);
    });
  }

  /// Gets a quick summary of event file contents.
  ///
  /// # Arguments
  /// * [filePath] - Path to the event file.
  ///
  /// # Returns
  /// Summary with counts and total duration.
  Future<event_sdk.EventSummary> getSummary(String filePath) async {
    return safeCall('Event Summary', () async {
      return await sdk.eventGetSummary(inFile: filePath);
    });
  }

  /// Extracts an event file to a directory and returns metadata.
  ///
  /// This combines WPD extraction with metadata parsing, giving you
  /// both the extracted files and the parsed structure.
  ///
  /// # Arguments
  /// * [inFile] - Path to the event file.
  /// * [outDir] - Output directory for extracted files.
  ///
  /// # Returns
  /// Extracted event with metadata and file paths.
  Future<event_sdk.ExtractedEvent> extract(
    String inFile,
    String outDir,
  ) async {
    return safeCall('Event Extract', () async {
      return await sdk.eventExtract(inFile: inFile, outDir: outDir);
    });
  }

  /// Exports event metadata to JSON string.
  ///
  /// # Arguments
  /// * [filePath] - Path to the event file.
  ///
  /// # Returns
  /// JSON representation of the event metadata.
  Future<String> exportJson(String filePath) async {
    return safeCall('Event Export JSON', () async {
      return await sdk.eventExportJson(inFile: filePath);
    });
  }

  /// Parses an event from a directory structure.
  ///
  /// This parses the full event directory including:
  /// - bin/*.xwb - Main schedule
  /// - DataSet/*.bin - Motion and camera control blocks
  ///
  /// # Arguments
  /// * [dirPath] - Path to the event directory.
  ///
  /// # Returns
  /// Complete event metadata from directory.
  Future<event_sdk.EventMetadata> parseDirectory(String dirPath) async {
    return safeCall('Event Parse Directory', () async {
      return await sdk.eventParseDirectory(dirPath: dirPath);
    });
  }
}
