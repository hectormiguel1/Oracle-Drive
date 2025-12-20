import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:oracle_drive/src/services/navigation_service.dart';
import 'package:oracle_drive/components/widgets/crystal_dialog.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';

import 'package:oracle_drive/models/wdb_model.dart';
import 'package:oracle_drive/src/third_party/wbtlib/wbt.g.dart' as wbt_native;
import 'package:oracle_drive/src/third_party/wbtlib/wbt.dart'; // For FileEntry, WhiteBinTools

import 'package:oracle_drive/src/third_party/wdb/wdb.g.dart' as wdb_native;
import 'package:oracle_drive/src/third_party/wpdlib/wpd.g.dart' as wpd_native;
import 'package:oracle_drive/src/third_party/ztrlib/ztr.g.dart' as ztr_native;
import 'package:oracle_drive/src/services/app_database.dart';
import 'package:oracle_drive/models/ztr_model.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'package:oracle_drive/src/third_party/wdb/wdb.dart';
import 'package:oracle_drive/src/third_party/wpdlib/wpd.dart';
import 'package:oracle_drive/src/third_party/ztrlib/ztr.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/schema_registry.dart'; // Import the WdbSchemaRegistry
import 'package:oracle_drive/models/wdb_entities/wdb_entity.dart'; // Import base WdbEntity

class NativeService {
  static final NativeService instance = NativeService._();
  final Logger _logger = Logger('NativeService');
  NativeService._();

  Isolate? _workerIsolate;
  SendPort? _workerSendPort;
  final ReceivePort _mainReceivePort = ReceivePort();

  final Map<int, Completer<dynamic>> _pendingRequests = {};
  int _nextRequestId = 0;

  final StreamController<String> _logStreamController =
      StreamController.broadcast();
  Stream<String> get logStream => _logStreamController.stream;

  Future<void> initialize() async {
    if (_workerIsolate != null) return;

    _logger.info("Initializing NativeService worker...");
    final token = ServicesBinding.rootIsolateToken;
    if (token == null) {
      throw Exception('Root isolate token is null');
    }
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    final initCompleter = Completer<void>();

    _mainReceivePort.listen((message) {
      if (message is SendPort) {
        _workerSendPort = message;
        initCompleter.complete();
      } else if (message is _NativeResponse) {
        final completer = _pendingRequests.remove(message.id);
        _progressCallbacks.remove(message.id);
        if (completer != null) {
          if (message.error != null) {
            if (navigatorKey.currentContext != null) {
              showDialog(
                context: navigatorKey.currentContext!,
                builder: (context) => CrystalDialog(
                  title: 'Native Error',
                  content: SingleChildScrollView(
                    child: Text(message.error.toString()),
                  ),
                  actions: [
                    CrystalButton(
                      label: 'OK',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            }
            completer.completeError(message.error!);
          } else {
            completer.complete(message.data);
          }
        }
      } else if (message is _NativeProgress) {
        final callback = _progressCallbacks[message.id];
        if (callback != null) {
          callback(message.progress);
        }
      } else if (message is List<String>) {
        // Log batch
        for (final log in message) {
          _logStreamController.add(log);
        }
      }
    });

    _workerIsolate = await Isolate.spawn(
      _nativeWorker,
      _WorkerArgs(_mainReceivePort.sendPort, ServicesBinding.rootIsolateToken),
    );

    await initCompleter.future;
    _logger.info("NativeService initialized.");
  }

  final Map<int, void Function(double)> _progressCallbacks = {};

  Future<T> _sendRequest<T>(
    String type,
    dynamic args, {
    void Function(double)? onProgress,
  }) {
    if (_workerSendPort == null) {
      throw Exception('NativeService not initialized');
    }
    final id = _nextRequestId++;
    final completer = Completer<T>();
    _pendingRequests[id] = completer;
    if (onProgress != null) {
      _progressCallbacks[id] = onProgress;
    }
    _workerSendPort!.send(_NativeRequest(id, type, args));
    return completer.future;
  }

  // ========================================================================
  // Public API
  // ========================================================================

  Future<dynamic> parseWdb(String path, wbt_native.GameCode game) {
    return _sendRequest('wdb_parse', {'path': path, 'game': game.index});
  }

  Future<void> saveWdb(
    String path,
    wbt_native.GameCode game,
    WdbData data,
  ) async {
    await _sendRequest('wdb_save', {
      'path': path,
      'game': game.index,
      'data': data,
    });
  }

  Future<void> saveWdbJson(String path, WdbData data) async {
    // Placeholder for JSON saving
    // await _sendRequest('wdb_save_json', {'path': path, 'data': data});
    _logger.info("JSON saving is not yet implemented.");
  }

  Future<dynamic> parseWbtFileEntries(
    wbt_native.GameCode game,
    String fileListPath,
  ) {
    return _sendRequest('wbt_parse_entries', {
      'game': game.index,
      'fileListPath': fileListPath,
    });
  }

  Future<int> unpackWbt(
    wbt_native.GameCode gameCode,
    String fileListPath,
    String binPath,
    List<FileEntry> entries, {
    String? outputDir,
    void Function(double)? onProgress,
  }) async {
    // We need to serialize FileEntry list or pass necessary data
    // Since FileEntry is a Dart class, we can pass it if it's sendable.
    // FileEntry contains Strings and ints, so it is sendable.
    // However, the NativeWorker needs to reconstruct the calls.
    // Actually, `unpack_single` takes paths.
    // The `_unpackInternal` logic iterates and calls native.
    // We should pass the list of entries to the worker.
    final result = await _sendRequest('wbt_unpack', {
      'game': gameCode.index,
      'fileListPath': fileListPath,
      'binPath': binPath,
      'entries': entries,
      'outputDir': outputDir,
    }, onProgress: onProgress);
    return result as int;
  }

  Future<int> unpackAllWbt(
    wbt_native.GameCode gameCode,
    String fileListPath,
    String binPath, {
    String? outputDir,
  }) async {
    final result = await _sendRequest('wbt_unpack_all', {
      'game': gameCode.index,
      'fileListPath': fileListPath,
      'binPath': binPath,
      'outputDir': outputDir,
    });
    return result as int;
  }

  Future<int> repackMultipleWbt(
    wbt_native.GameCode gameCode,
    String fileListPath,
    String binPath,
    String extractDir, {
    bool makeBackup = true,
  }) async {
    final result = await _sendRequest('wbt_repack_multiple', {
      'game': gameCode.index,
      'fileListPath': fileListPath,
      'binPath': binPath,
      'extractDir': extractDir,
      'makeBackup': makeBackup,
    });
    return result as int;
  }

  Future<int> repackWpd(String inputWpdDir) async {
    final result = await _sendRequest('wpd_repack', {
      'inputWpdDir': inputWpdDir,
    });
    return result as int;
  }

  Future<int> unpackWpd(String inputWdpFile) async {
    final result = await _sendRequest('wpd_unpack', {
      'inputWdpFile': inputWdpFile,
    });
    return result as int;
  }

  Future<int> extractZtrData(String path, AppGameCode game) async {
    final result = await _sendRequest('ztr_extract_data', {
      'path': path,
      'game': game.index,
    });
    return result as int;
  }

  Future<int> extractZtrToTxt(
    String inZtrPath,
    AppGameCode game, {
    ztr_native.ZTREncoding encoding = ztr_native.ZTREncoding.ZTR_ENCODING_AUTO,
  }) async {
    return (await _sendRequest('ztr_extract_file', {
          'path': inZtrPath,
          'game': game.index,
          'encoding': encoding.value,
        }))
        as int;
  }

  Future<int> convertTxtToZtr(
    String inTxtPath,
    AppGameCode game, {
    ztr_native.ZTREncoding encoding = ztr_native.ZTREncoding.ZTR_ENCODING_AUTO,
    ztr_native.ZTRAction action = ztr_native.ZTRAction.ZTR_ACTION_X,
  }) async {
    return (await _sendRequest('ztr_convert', {
          'path': inTxtPath,
          'game': game.index,
          'encoding': encoding.value,
          'action': action.value,
        }))
        as int;
  }

  Future<int> packZtrData(
    ZtrData data,
    String outZtrPath,
    AppGameCode game, {
    ztr_native.ZTREncoding encoding = ztr_native.ZTREncoding.ZTR_ENCODING_AUTO,
    ztr_native.ZTRAction action = ztr_native.ZTRAction.ZTR_ACTION_X,
  }) async {
    return (await _sendRequest('ztr_pack', {
          'data': data,
          'path': outZtrPath,
          'game': game.index,
          'encoding': encoding.value,
          'action': action.value,
        }))
        as int;
  }

  Future<int> dumpZtrData(ZtrData data, String outTxtPath) async {
    return (await _sendRequest('ztr_dump', {'data': data, 'path': outTxtPath}))
        as int;
  }

  Future<int> dumpZtrFileFromDb(
    AppGameCode game,
    String outZtrPath, {
    ztr_native.ZTREncoding encoding = ztr_native.ZTREncoding.ZTR_ENCODING_AUTO,
    ztr_native.ZTRAction action = ztr_native.ZTRAction.ZTR_ACTION_C2,
  }) async {
    return (await _sendRequest('ztr_pack_from_db', {
          'game': game.index,
          'path': outZtrPath,
          'encoding': encoding.value,
          'action': action.value,
        }))
        as int;
  }

  Future<int> dumpTxtFileFromDb(AppGameCode game, String outTxtPath) async {
    return (await _sendRequest('ztr_dump_from_db', {
          'game': game.index,
          'path': outTxtPath,
        }))
        as int;
  }

  void dispose() {
    _workerSendPort?.send('stop');
    _workerIsolate?.kill();
    _workerIsolate = null;
    _workerSendPort = null;
    _mainReceivePort.close();
    _logStreamController.close();
  }
}

// ========================================================================
// Worker Definitions
// ========================================================================

class _WorkerArgs {
  final SendPort mainSendPort;
  final RootIsolateToken? rootIsolateToken;
  _WorkerArgs(this.mainSendPort, this.rootIsolateToken);
}

class _NativeRequest {
  final int id;
  final String type;
  final dynamic args;
  _NativeRequest(this.id, this.type, this.args);
}

class _NativeResponse {
  final int id;
  final dynamic data;
  final dynamic error;
  _NativeResponse(this.id, this.data, this.error);
}

class _NativeProgress {
  final int id;
  final double progress;
  _NativeProgress(this.id, this.progress);
}

// ========================================================================
// Worker Implementation
// ========================================================================

void _nativeWorker(_WorkerArgs args) {
  // Ensure that Flutter plugins can be used in this background isolate.
  // This is required for plugins like path_provider which drift_flutter uses.
  if (args.rootIsolateToken != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(args.rootIsolateToken!);
  }

  final sendPort = args.mainSendPort;
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  // Initialize AppDatabase in the worker isolate.
  // This is crucial for database operations in the worker.
  AppDatabase.ensureInitialized();

  // --- Logging Setup ---
  final List<String> logBuffer = [];
  const int maxAllocatedStrings = 2000;

  // We need 3 separate lists to be safe across potentially different heaps
  final List<Pointer<Char>> wdbLogsToFree = [];
  final List<Pointer<Char>> wpdLogsToFree = [];
  final List<Pointer<Char>> wbtLogsToFree = [];
  final List<Pointer<Char>> ztrLogsToFree = [];

  void flushSpecific(
    List<Pointer<Char>> list,
    void Function(Pointer<Pointer<Void>>, int) freeFunc,
  ) {
    if (list.isEmpty) return;
    final ptrArray = calloc<Pointer<Void>>(list.length);
    for (int i = 0; i < list.length; i++) {
      ptrArray[i] = Pointer.fromAddress(list[i].address);
    }
    freeFunc(ptrArray, list.length);
    calloc.free(ptrArray);
    list.clear();
  }

  void flushAllLogs() {
    flushSpecific(wdbLogsToFree, wdb_native.free_log_memory_batch);
    flushSpecific(wpdLogsToFree, wpd_native.free_log_memory_batch);
    flushSpecific(wbtLogsToFree, wbt_native.free_log_memory_batch);
    // ZTR currently shares logging mechanism or we assume it has its own if exported
    // The ZTR generated bindings have free_log_memory_batch, check if it's distinct?
    // It imports common.g.dart, so likely they share the same logging infra if linked together.
    // However, the bindings might be separate libraries (DLLs/SOs).
    // If they are separate shared objects, they might have separate memory managers.
    // Assuming ZTR has its own free_log_memory_batch wrapper in ztr.g.dart
    flushSpecific(ztrLogsToFree, ztr_native.free_log_memory_batch);
  }

  Timer.periodic(const Duration(milliseconds: 100), (timer) {
    if (logBuffer.isNotEmpty) {
      sendPort.send(List<String>.from(logBuffer));
      logBuffer.clear();
    }
    flushAllLogs();
  });

  // --- Register Callbacks ---
  final wdbListener = NativeCallable<Void Function(Pointer<Char>)>.listener((
    Pointer<Char> messagePtr,
  ) {
    if (messagePtr == nullptr) return;
    try {
      logBuffer.add(messagePtr.cast<Utf8>().toDartString());
    } finally {
      wdbLogsToFree.add(messagePtr);
      if (wdbLogsToFree.length >= maxAllocatedStrings) {
        flushSpecific(wdbLogsToFree, wdb_native.free_log_memory_batch);
      }
    }
  });
  wdb_native.register_async_callback_with_level(
    wdbListener.nativeFunction,
    wdb_native.LogLevel.Info,
  );

  final wpdListener = NativeCallable<Void Function(Pointer<Char>)>.listener((
    Pointer<Char> messagePtr,
  ) {
    if (messagePtr == nullptr) return;
    try {
      logBuffer.add(messagePtr.cast<Utf8>().toDartString());
    } finally {
      wpdLogsToFree.add(messagePtr);
      if (wpdLogsToFree.length >= maxAllocatedStrings) {
        flushSpecific(wpdLogsToFree, wpd_native.free_log_memory_batch);
      }
    }
  });
  wpd_native.register_async_callback_with_level(
    wpdListener.nativeFunction,
    wpd_native.LogLevel.Info,
  );

  final wbtListener = NativeCallable<Void Function(Pointer<Char>)>.listener((
    Pointer<Char> messagePtr,
  ) {
    if (messagePtr == nullptr) return;
    try {
      logBuffer.add(messagePtr.cast<Utf8>().toDartString());
    } finally {
      wbtLogsToFree.add(messagePtr);
      if (wbtLogsToFree.length >= maxAllocatedStrings) {
        flushSpecific(wbtLogsToFree, wbt_native.free_log_memory_batch);
      }
    }
  });
  wbt_native.register_async_callback_with_level(
    wbtListener.nativeFunction,
    wbt_native.LogLevel.Info,
  );

  final ztrListener = NativeCallable<Void Function(Pointer<Char>)>.listener((
    Pointer<Char> messagePtr,
  ) {
    if (messagePtr == nullptr) return;
    try {
      logBuffer.add(messagePtr.cast<Utf8>().toDartString());
    } finally {
      ztrLogsToFree.add(messagePtr);
      if (ztrLogsToFree.length >= maxAllocatedStrings) {
        flushSpecific(ztrLogsToFree, ztr_native.free_log_memory_batch);
      }
    }
  });
  ztr_native.register_async_callback_with_level(
    ztrListener.nativeFunction,
    ztr_native.LogLevel.Finest,
  );

  // Initialize ZTR
  ZtrTool.init();

  // --- Request Handler ---
  receivePort.listen((message) async {
    if (message == 'stop') {
      wdbListener.close();
      wpdListener.close();
      wbtListener.close();
      ztrListener.close();
      flushAllLogs();
      receivePort.close();
      Isolate.current.kill();
      return;
    }

    if (message is _NativeRequest) {
      try {
        dynamic result;
        switch (message.type) {
          case 'wdb_parse':
            result = _handleWdbParse(message.args);
            break;
          case 'wdb_save':
            result = _handleWdbSave(message.args);
            break;
          case 'wbt_parse_entries':
            result = _handleWbtParseEntries(message.args);
            break;
          case 'wbt_unpack':
            result = _handleWbtUnpack(message.id, sendPort, message.args);
            break;
          case 'wbt_unpack_all':
            result = _handleWbtUnpackAll(message.args);
            break;
          case 'wbt_repack_multiple':
            result = _handleWbtRepackMultiple(message.args);
            break;
          case 'wpd_repack':
            result = _handleWpdRepack(message.args);
            break;
          case 'wpd_unpack':
            result = _handleWpdUnpack(message.args);
            break;
          case 'ztr_extract_data':
            result = _handleZtrExtractData(message.args);
            break;
          case 'ztr_extract_file':
            result = _handleZtrExtractFile(message.args);
            break;
          case 'ztr_convert':
            result = _handleZtrConvert(message.args);
            break;
          case 'ztr_pack':
            result = _handleZtrPack(message.args);
            break;
          case 'ztr_dump':
            result = _handleZtrDump(message.args);
            break;
          case 'ztr_pack_from_db':
            result = _handleZtrPackFromDb(message.args);
            break;
          case 'ztr_dump_from_db':
            result = _handleZtrDumpFromDb(message.args);
            break;
          default:
            throw "Unknown request type: ${message.type}";
        }

        final data = result is Future ? await result : result;
        sendPort.send(_NativeResponse(message.id, data, null));
      } catch (e, stack) {
        sendPort.send(_NativeResponse(message.id, null, "$e\n$stack"));
      }
    }
  });
}

// ========================================================================
// Request Handlers
// ========================================================================

Future<WdbData> _handleWdbParse(Map<String, dynamic> args) async {
  final path = args['path'] as String;
  final gameIndex = args['game'] as int;
  final gameCode = AppGameCode.values[gameIndex];
  final nativeGameCode = wbt_native.GameCode.values[gameIndex];

  final wdbData = WdbTool.parseFile(path, nativeGameCode);

  // Convert WdbData rows to WdbEntity instances
  final Map<String, WdbEntity> wdbEntities = {};
  final sheetName = wdbData.sheetName; // Get sheetName for createEntity
  WdbEntity? createEntityFunction(Map<String, dynamic> row) =>
      WdbSchemaRegistry.createEntity(sheetName, row);

  if (wdbData.entities != null) {
    for (int i = 0; i < wdbData.rows.length; i++) {
      if (wdbData.columns.any((col) => col.originalName == "record") == false) {
        // If there's no "record" column, we cannot create entities reliably.
        // Skip this sheet.
        continue;
      }

      final row = wdbData.rows[i];

      wdbEntities[row['record'] as String] = wdbData.entities != null
          ? wdbData.entities![i]
          : createEntityFunction(row)!;
    }

    // Upsert the WDB data into the database
    if (wdbEntities.isNotEmpty) {
      await AppDatabase.instance
          .getRepositoryForGame(gameCode)
          .upsertWdbEntities(wdbData.sheetName, wdbEntities);
    }
  }

  return wdbData;
}

Future<void> _handleWdbSave(Map<String, dynamic> args) async {
  final path = args['path'] as String;
  final gameIndex = args['game'] as int;
  final WdbData data = args['data'];
  final nativeGameCode = wbt_native.GameCode.values[gameIndex];

  WdbTool.writeFile(path, nativeGameCode, data);
}

Future<int> _handleZtrExtractData(Map<String, dynamic> args) async {
  final path = args['path'] as String;
  final gameIndex = args['game'] as int;
  final gameCode = AppGameCode.values[gameIndex];
  final ztrGameCodeValue = ztr_native.ZTRGameCode.values[gameIndex].value;

  final strings = ZtrTool.extractData(path, ztrGameCodeValue);

  // Insert into DB
  if (strings.isNotEmpty) {
    AppDatabase.instance
        .getRepositoryForGame(gameCode)
        .insertStringData(strings);
  }

  return 0; // Success
}

Future<int> _handleZtrExtractFile(Map<String, dynamic> args) async {
  final path = args['path'] as String;
  final gameIndex = args['game'] as int;
  final encodingVal = args['encoding'] as int;
  final ztrGameCodeValue = ztr_native.ZTRGameCode.values[gameIndex].value;

  ZtrTool.extractFile(path, ztrGameCodeValue, encodingVal);
  return 0;
}

Future<int> _handleZtrConvert(Map<String, dynamic> args) async {
  final path = args['path'] as String;
  final gameIndex = args['game'] as int;
  final encodingVal = args['encoding'] as int;
  final actionVal = args['action'] as int;
  final ztrGameCodeValue = ztr_native.ZTRGameCode.values[gameIndex].value;

  ZtrTool.convert(path, ztrGameCodeValue, encodingVal, actionVal);
  return 0;
}

Future<int> _handleZtrPack(Map<String, dynamic> args) async {
  final ZtrData data = args['data'];
  final path = args['path'] as String;
  final gameIndex = args['game'] as int;
  final encodingVal = args['encoding'] as int;
  final actionVal = args['action'] as int;
  final ztrGameCodeValue = ztr_native.ZTRGameCode.values[gameIndex].value;

  ZtrTool.packData(data, path, ztrGameCodeValue, encodingVal, actionVal);
  return 0;
}

Future<int> _handleZtrDump(Map<String, dynamic> args) async {
  final ZtrData data = args['data'];
  final path = args['path'] as String;

  ZtrTool.dumpData(data, path);
  return 0;
}

Future<int> _handleZtrPackFromDb(Map<String, dynamic> args) async {
  final gameIndex = args['game'] as int;
  final gameCode = AppGameCode.values[gameIndex];
  final path = args['path'] as String;
  final encodingVal = args['encoding'] as int;
  final actionVal = args['action'] as int;
  final ztrGameCodeValue = ztr_native.ZTRGameCode.values[gameIndex].value;

  final stream = AppDatabase.instance
      .getRepositoryForGame(gameCode)
      .getStrings();
  final Map<String, String> stringsMap = {};
  await for (final chunk in stream) {
    stringsMap.addAll(chunk);
  }
  final entries = stringsMap.entries
      .map((e) => ZtrEntry(e.key, e.value))
      .toList();
  final ztrData = ZtrData(entries: entries);

  ZtrTool.packData(ztrData, path, ztrGameCodeValue, encodingVal, actionVal);
  return 0;
}

Future<int> _handleZtrDumpFromDb(Map<String, dynamic> args) async {
  final gameIndex = args['game'] as int;
  final gameCode = AppGameCode.values[gameIndex];
  final path = args['path'] as String;

  final stream = AppDatabase.instance
      .getRepositoryForGame(gameCode)
      .getStrings();
  final Map<String, String> stringsMap = {};
  await for (final chunk in stream) {
    stringsMap.addAll(chunk);
  }
  final entries = stringsMap.entries
      .map((e) => ZtrEntry(e.key, e.value))
      .toList();
  final ztrData = ZtrData(entries: entries);

  ZtrTool.dumpData(ztrData, path);
  return 0;
}

Future<List<FileEntry>> _handleWbtParseEntries(
  Map<String, dynamic> args,
) async {
  final gameIndex = args['game'] as int;
  final fileListPath = args['fileListPath'] as String;
  final gameCode = wbt_native.GameCode.values[gameIndex];

  return WhiteBinTools.getMetadata(gameCode, fileListPath);
}

Future<int> _handleWbtUnpack(
  int requestId,
  SendPort sendPort,
  Map<String, dynamic> args,
) async {
  final gameIndex = args['game'] as int;
  final fileListPath = args['fileListPath'] as String;
  final binPath = args['binPath'] as String;
  final outputDir = args['outputDir'] as String?;
  final entries = args['entries'] as List<dynamic>;
  final gameCode = wbt_native.GameCode.values[gameIndex];

  for (int i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final String virtualPath = entry.chunkInfo.virtualPath;
    WhiteBinTools.unpackSingle(
      gameCode,
      fileListPath,
      binPath,
      virtualPath,
      outputDir: outputDir,
    );
    sendPort.send(_NativeProgress(requestId, (i + 1) / entries.length));
  }
  return 0;
}

Future<int> _handleWbtUnpackAll(Map<String, dynamic> args) async {
  final gameIndex = args['game'] as int;
  final fileListPath = args['fileListPath'] as String;
  final binPath = args['binPath'] as String;
  final outputDir = args['outputDir'] as String?;
  final gameCode = wbt_native.GameCode.values[gameIndex];

  WhiteBinTools.unpackAll(
    gameCode,
    fileListPath,
    binPath,
    outputDir: outputDir,
  );
  return 0;
}

Future<int> _handleWbtRepackMultiple(Map<String, dynamic> args) async {
  final gameIndex = args['game'] as int;
  final fileListPath = args['fileListPath'] as String;
  final binPath = args['binPath'] as String;
  final extractDir = args['extractDir'] as String;
  final makeBackup = args['makeBackup'] as bool;
  final gameCode = wbt_native.GameCode.values[gameIndex];

  WhiteBinTools.repackMultipleInternal(
    gameCode,
    fileListPath,
    binPath,
    extractDir,
    makeBackup: makeBackup,
  );
  return 0;
}

Future<int> _handleWpdRepack(Map<String, dynamic> args) async {
  final inputWpdDir = args['inputWpdDir'] as String;
  return WpdTool.repack(inputWpdDir);
}

Future<int> _handleWpdUnpack(Map<String, dynamic> args) async {
  final inputWdpFile = args['inputWdpFile'] as String;
  return WpdTool.unpack(inputWdpFile);
}
