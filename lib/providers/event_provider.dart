import 'package:fabula_nova_sdk/bridge_generated/modules/event/structs.dart'
    as event_sdk;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:oracle_drive/src/services/native_service.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _logger = Logger('EventProvider');

// ============================================================
// Event State
// ============================================================

/// Current event file path being viewed.
final eventPathProvider = StateProvider<String?>((ref) => null);

/// Whether event is currently loading.
final eventIsLoadingProvider = StateProvider<bool>((ref) => false);

/// Loaded event metadata.
final eventDataProvider = StateProvider<event_sdk.EventMetadata?>((ref) => null);

/// Error message if loading failed.
final eventErrorProvider = StateProvider<String?>((ref) => null);

/// Selected tab index (0=Actors, 1=Blocks, 2=Resources, 3=Dialogue, 4=Sound).
final eventSelectedTabProvider = StateProvider<int>((ref) => 0);

/// Selected item index within the current tab.
final eventSelectedItemProvider = StateProvider<int?>((ref) => null);

// ============================================================
// Event Notifier
// ============================================================

final eventNotifierProvider = Provider<EventNotifier>((ref) => EventNotifier(ref));

class EventNotifier {
  final Ref _ref;

  EventNotifier(this._ref);

  String? get path => _ref.read(eventPathProvider);
  bool get isLoading => _ref.read(eventIsLoadingProvider);
  event_sdk.EventMetadata? get data => _ref.read(eventDataProvider);
  String? get error => _ref.read(eventErrorProvider);
  int get selectedTab => _ref.read(eventSelectedTabProvider);
  int? get selectedItem => _ref.read(eventSelectedItemProvider);

  /// Load an event file from the given path.
  Future<void> loadEvent(String filePath) async {
    _ref.read(eventIsLoadingProvider.notifier).state = true;
    _ref.read(eventErrorProvider.notifier).state = null;
    _ref.read(eventDataProvider.notifier).state = null;
    _ref.read(eventPathProvider.notifier).state = filePath;
    _ref.read(eventSelectedItemProvider.notifier).state = null;

    try {
      _logger.info("Loading Event: $filePath");
      final data = await NativeService.instance.parseEvent(filePath);
      _ref.read(eventDataProvider.notifier).state = data;
      _logger.info(
        "Event loaded: ${data.actors.length} actors, "
        "${data.blocks.length} blocks, "
        "${data.dialogueEntries.length} dialogue entries",
      );
    } catch (e, stack) {
      _logger.severe("Error loading event: $e\n$stack");
      _ref.read(eventErrorProvider.notifier).state = e.toString();
    } finally {
      _ref.read(eventIsLoadingProvider.notifier).state = false;
    }
  }

  /// Load an event from a directory (including DataSet if present).
  ///
  /// This is preferred when loading from the full event folder structure.
  Future<void> loadEventDirectory(String dirPath) async {
    _ref.read(eventIsLoadingProvider.notifier).state = true;
    _ref.read(eventErrorProvider.notifier).state = null;
    _ref.read(eventDataProvider.notifier).state = null;
    _ref.read(eventPathProvider.notifier).state = dirPath;
    _ref.read(eventSelectedItemProvider.notifier).state = null;

    try {
      _logger.info("Loading Event Directory: $dirPath");
      final data = await NativeService.instance.parseEventDirectory(dirPath);
      _ref.read(eventDataProvider.notifier).state = data;

      final datasetInfo = data.dataset != null
          ? ", ${data.dataset!.motionBlocks.length} motion blocks, "
            "${data.dataset!.cameraBlocks.length} camera blocks"
          : "";

      _logger.info(
        "Event loaded: ${data.actors.length} actors, "
        "${data.blocks.length} blocks, "
        "${data.dialogueEntries.length} dialogue entries$datasetInfo",
      );
    } catch (e, stack) {
      _logger.severe("Error loading event directory: $e\n$stack");
      _ref.read(eventErrorProvider.notifier).state = e.toString();
    } finally {
      _ref.read(eventIsLoadingProvider.notifier).state = false;
    }
  }

  /// Get a quick summary of an event file.
  Future<event_sdk.EventSummary?> getSummary(String filePath) async {
    try {
      return await NativeService.instance.getEventSummary(filePath);
    } catch (e) {
      _logger.severe("Error getting event summary: $e");
      return null;
    }
  }

  /// Export event data to JSON.
  Future<String?> exportToJson(String filePath) async {
    try {
      return await NativeService.instance.exportEventJson(filePath);
    } catch (e) {
      _logger.severe("Error exporting event to JSON: $e");
      return null;
    }
  }

  /// Extract event file to directory.
  Future<event_sdk.ExtractedEvent?> extractEvent(
    String inFile,
    String outDir,
  ) async {
    try {
      _logger.info("Extracting event to: $outDir");
      final result = await NativeService.instance.extractEvent(inFile, outDir);
      _logger.info("Extracted ${result.extractedFiles.length} files");
      return result;
    } catch (e) {
      _logger.severe("Error extracting event: $e");
      return null;
    }
  }

  /// Set the selected tab.
  void setSelectedTab(int index) {
    _ref.read(eventSelectedTabProvider.notifier).state = index;
    _ref.read(eventSelectedItemProvider.notifier).state = null;
  }

  /// Set the selected item within current tab.
  void setSelectedItem(int? index) {
    _ref.read(eventSelectedItemProvider.notifier).state = index;
  }

  /// Clear the current event data.
  void clear() {
    _ref.read(eventPathProvider.notifier).state = null;
    _ref.read(eventDataProvider.notifier).state = null;
    _ref.read(eventErrorProvider.notifier).state = null;
    _ref.read(eventSelectedTabProvider.notifier).state = 0;
    _ref.read(eventSelectedItemProvider.notifier).state = null;
  }
}

// ============================================================
// Derived Providers
// ============================================================

/// Display name of the current event file.
final eventDisplayNameProvider = Provider<String>((ref) {
  final path = ref.watch(eventPathProvider);
  if (path == null) return 'No Event loaded';
  String name = p.basename(path);
  // Remove .white.win32.xwb suffix
  if (name.contains('.white')) {
    name = name.substring(0, name.indexOf('.white'));
  }
  return name;
});

/// Actor count in loaded event.
final eventActorCountProvider = Provider<int>((ref) {
  final data = ref.watch(eventDataProvider);
  return data?.actors.length ?? 0;
});

/// Block count in loaded event.
final eventBlockCountProvider = Provider<int>((ref) {
  final data = ref.watch(eventDataProvider);
  return data?.blocks.length ?? 0;
});

/// Resource count in loaded event.
final eventResourceCountProvider = Provider<int>((ref) {
  final data = ref.watch(eventDataProvider);
  return data?.resources.length ?? 0;
});

/// Dialogue count in loaded event.
final eventDialogueCountProvider = Provider<int>((ref) {
  final data = ref.watch(eventDataProvider);
  return data?.dialogueEntries.length ?? 0;
});

/// Sound block count in loaded event.
final eventSoundBlockCountProvider = Provider<int>((ref) {
  final data = ref.watch(eventDataProvider);
  return data?.soundBlocks.length ?? 0;
});

/// WPD record count in loaded event.
final eventWpdRecordCountProvider = Provider<int>((ref) {
  final data = ref.watch(eventDataProvider);
  return data?.wpdRecords.length ?? 0;
});

/// External resource count in loaded event.
final eventExternalResourceCountProvider = Provider<int>((ref) {
  final data = ref.watch(eventDataProvider);
  return data?.externalResources.length ?? 0;
});

/// Sound reference count in loaded event.
final eventSoundReferenceCountProvider = Provider<int>((ref) {
  final data = ref.watch(eventDataProvider);
  return data?.soundReferences.length ?? 0;
});

/// Combined sound count (blocks + references).
final eventSoundCountProvider = Provider<int>((ref) {
  final data = ref.watch(eventDataProvider);
  if (data == null) return 0;
  return data.soundBlocks.length + data.soundReferences.length;
});

/// Total duration in seconds (sum of block durations).
final eventTotalDurationProvider = Provider<double>((ref) {
  final data = ref.watch(eventDataProvider);
  if (data == null) return 0.0;
  return data.blocks.fold<double>(0.0, (sum, b) => sum + b.durationSeconds);
});

/// Currently selected WPD record (if on info tab and item selected).
final eventSelectedWpdRecordProvider = Provider<event_sdk.WpdRecordInfo?>((ref) {
  final data = ref.watch(eventDataProvider);
  final tab = ref.watch(eventSelectedTabProvider);
  final index = ref.watch(eventSelectedItemProvider);
  if (data == null || tab != 0 || index == null) return null;
  if (index < 0 || index >= data.wpdRecords.length) return null;
  return data.wpdRecords[index];
});

/// Currently selected actor (if on actor tab and item selected).
final eventSelectedActorProvider = Provider<event_sdk.EventActor?>((ref) {
  final data = ref.watch(eventDataProvider);
  final tab = ref.watch(eventSelectedTabProvider);
  final index = ref.watch(eventSelectedItemProvider);
  if (data == null || tab != 1 || index == null) return null;
  if (index < 0 || index >= data.actors.length) return null;
  return data.actors[index];
});

/// Currently selected block (if on block tab and item selected).
final eventSelectedBlockProvider = Provider<event_sdk.EventBlock?>((ref) {
  final data = ref.watch(eventDataProvider);
  final tab = ref.watch(eventSelectedTabProvider);
  final index = ref.watch(eventSelectedItemProvider);
  if (data == null || tab != 2 || index == null) return null;
  if (index < 0 || index >= data.blocks.length) return null;
  return data.blocks[index];
});

/// Currently selected external resource (if on external tab and item selected).
final eventSelectedExternalResourceProvider = Provider<event_sdk.ExternalResource?>((ref) {
  final data = ref.watch(eventDataProvider);
  final tab = ref.watch(eventSelectedTabProvider);
  final index = ref.watch(eventSelectedItemProvider);
  if (data == null || tab != 3 || index == null) return null;
  if (index < 0 || index >= data.externalResources.length) return null;
  return data.externalResources[index];
});

/// Currently selected resource (if on resource tab and item selected).
final eventSelectedResourceProvider = Provider<event_sdk.EventResource?>((ref) {
  final data = ref.watch(eventDataProvider);
  final tab = ref.watch(eventSelectedTabProvider);
  final index = ref.watch(eventSelectedItemProvider);
  if (data == null || tab != 4 || index == null) return null;
  if (index < 0 || index >= data.resources.length) return null;
  return data.resources[index];
});

/// Currently selected dialogue entry (if on dialogue tab and item selected).
final eventSelectedDialogueProvider = Provider<event_sdk.DialogueEntry?>((ref) {
  final data = ref.watch(eventDataProvider);
  final tab = ref.watch(eventSelectedTabProvider);
  final index = ref.watch(eventSelectedItemProvider);
  if (data == null || tab != 5 || index == null) return null;
  if (index < 0 || index >= data.dialogueEntries.length) return null;
  return data.dialogueEntries[index];
});

/// Currently selected sound block (if on sound tab and item selected).
final eventSelectedSoundBlockProvider = Provider<event_sdk.SoundBlock?>((ref) {
  final data = ref.watch(eventDataProvider);
  final tab = ref.watch(eventSelectedTabProvider);
  final index = ref.watch(eventSelectedItemProvider);
  if (data == null || tab != 6 || index == null) return null;
  // Sound tab shows blocks first, then references
  final blockCount = data.soundBlocks.length;
  if (index < blockCount) {
    return data.soundBlocks[index];
  }
  return null;
});

/// Currently selected sound reference (if on sound tab and item selected).
final eventSelectedSoundReferenceProvider = Provider<event_sdk.SoundReference?>((ref) {
  final data = ref.watch(eventDataProvider);
  final tab = ref.watch(eventSelectedTabProvider);
  final index = ref.watch(eventSelectedItemProvider);
  if (data == null || tab != 6 || index == null) return null;
  // Sound tab shows blocks first, then references
  final blockCount = data.soundBlocks.length;
  if (index >= blockCount && index < blockCount + data.soundReferences.length) {
    return data.soundReferences[index - blockCount];
  }
  return null;
});
