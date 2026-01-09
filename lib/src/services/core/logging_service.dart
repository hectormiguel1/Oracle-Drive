import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;

/// Log level enum matching Rust SDK log levels.
enum LogLevel {
  off(0),
  error(1),
  warning(2),
  info(3),
  debug(4),
  trace(5);

  final int level;
  const LogLevel(this.level);
}

/// Service for managing logs from both Dart and Rust SDK.
///
/// Provides a unified log stream that aggregates logs from:
/// - Dart's Logger framework
/// - Rust SDK via polling mechanism
///
/// Supports hot restart by using polling instead of direct stream callbacks.
class LoggingService {
  static LoggingService? _instance;
  static LoggingService get instance => _instance ??= LoggingService._();

  final Logger _logger = Logger('LoggingService');

  /// Ring buffer for log history (max 1000 entries).
  final List<String> _logBuffer = [];
  static const int _maxLogBufferSize = 1000;

  StreamController<String>? _logStreamController;

  /// Timer for polling logs from Rust (hot restart safe).
  Timer? _logPollTimer;
  StreamSubscription<LogRecord>? _dartLogSubscription;

  /// Static flag to track Rust SDK initialization (survives hot restart).
  static bool _rustInitialized = false;

  LoggingService._();

  /// Stream of log messages from both Dart and Rust.
  Stream<String> get logStream {
    _logStreamController ??= StreamController.broadcast();
    return _logStreamController!.stream;
  }

  /// Unmodifiable list of recent log messages.
  List<String> get logHistory => List.unmodifiable(_logBuffer);

  /// Whether the Rust SDK has been initialized.
  bool get isRustInitialized => _rustInitialized;

  /// Adds a log message to the buffer and stream.
  void _addLog(String message) {
    if (_logStreamController?.isClosed ?? true) return;
    _logBuffer.add(message);
    if (_logBuffer.length > _maxLogBufferSize) {
      _logBuffer.removeAt(0);
    }
    _logStreamController?.add(message);
  }

  /// Initializes the logging service and Rust SDK.
  ///
  /// Safe to call multiple times (handles hot restart).
  Future<void> initialize() async {
    // Cancel existing timer and subscriptions first (for hot reload)
    _logPollTimer?.cancel();
    await _dartLogSubscription?.cancel();

    // Reinitialize stream controller if closed
    if (_logStreamController?.isClosed ?? true) {
      _logStreamController = StreamController.broadcast();
    }

    _logger.info("LoggingService initializing...");

    // Only call initApp on first initialization - Rust state persists across hot restart
    if (!_rustInitialized) {
      await sdk.initApp();
      _rustInitialized = true;
    } else {
      // After hot restart, reset the read index to fetch any logs we missed
      await sdk.resetLogReadIndex();
    }

    // Load any buffered logs from Rust (survives hot restart)
    final bufferedLogs = await sdk.getAllBufferedLogs();
    for (final log in bufferedLogs) {
      _addLog(log);
    }

    // Start polling for new logs from Rust (hot restart safe)
    _startLogPolling();

    // Also route Dart logs to this stream
    _dartLogSubscription = Logger.root.onRecord.listen((record) {
      final msg = "[DART] ${record.level.name}: ${record.message}";
      _addLog(msg);
    });

    _logger.info("LoggingService initialized.");
  }

  /// Polls for new logs from Rust.
  ///
  /// Uses longer interval in debug mode to reduce overhead.
  void _startLogPolling() {
    final interval = kDebugMode
        ? const Duration(milliseconds: 500)
        : const Duration(milliseconds: 100);

    _logPollTimer = Timer.periodic(interval, (_) async {
      try {
        final newLogs = await sdk.fetchLogs();
        for (final log in newLogs) {
          _addLog(log);
        }
      } catch (e) {
        // Silently ignore polling errors - Rust side may be reinitializing
      }
    });
  }

  /// Sends a test log message to the Rust SDK.
  Future<void> testLog(String message) async {
    await sdk.testLog(message: message);
  }

  /// Sets the log level for the Rust logger.
  void setLogLevel(LogLevel level) {
    sdk.setLogLevel(level: level.level);
  }

  /// Gets the current log level from the Rust logger.
  Future<LogLevel> getLogLevel() async {
    final level = await sdk.getLogLevel();
    return LogLevel.values.firstWhere(
      (l) => l.level == level,
      orElse: () => LogLevel.info,
    );
  }

  /// Clears all logs from the buffer.
  void clearLogs() {
    _logBuffer.clear();
  }

  /// Resets the service for hot reload support.
  static Future<void> reset() async {
    await _instance?._dispose();
    _instance = null;
  }

  Future<void> _dispose() async {
    _logPollTimer?.cancel();
    await _dartLogSubscription?.cancel();
    _logPollTimer = null;
    _dartLogSubscription = null;

    if (!(_logStreamController?.isClosed ?? true)) {
      await _logStreamController?.close();
    }
    _logStreamController = null;
  }

  /// Disposes of the logging service.
  Future<void> dispose() async {
    await _dispose();
  }
}
