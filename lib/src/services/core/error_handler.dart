import 'package:logging/logging.dart';

/// Represents an error from native/SDK operations.
///
/// This class decouples error handling from UI concerns.
/// The service layer throws [NativeError], and the UI layer
/// decides how to display it (dialog, snackbar, etc.).
class NativeError implements Exception {
  /// Error code for categorization (e.g., 'WDB_PARSE_ERROR').
  final String code;

  /// Human-readable error message.
  final String message;

  /// Original exception/error object, if available.
  final Object? cause;

  /// Stack trace at the point of error, if available.
  final StackTrace? stackTrace;

  NativeError({
    required this.code,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  /// Creates a [NativeError] from an exception.
  ///
  /// The [operation] is used to generate the error code.
  factory NativeError.fromException(
    String operation,
    Object exception, [
    StackTrace? stackTrace,
  ]) {
    final code = '${operation.toUpperCase().replaceAll(' ', '_')}_ERROR';
    return NativeError(
      code: code,
      message: exception.toString(),
      cause: exception,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() => 'NativeError($code): $message';
}

/// Mixin providing standardized error handling for service classes.
///
/// Usage:
/// ```dart
/// class WdbService with NativeErrorHandler {
///   Future<WdbData> parseWdb(String path) async {
///     return safeCall('WDB Parse', () async {
///       return await sdk.wdbParse(inFile: path);
///     });
///   }
/// }
/// ```
mixin NativeErrorHandler {
  /// Logger for this service. Override to customize the logger name.
  Logger get logger => Logger('NativeService');

  /// Wraps an async operation with logging and error transformation.
  ///
  /// If the operation fails, logs the error and throws a [NativeError].
  Future<T> safeCall<T>(String operation, Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e, st) {
      logger.severe('$operation failed: $e');
      throw NativeError.fromException(operation, e, st);
    }
  }

  /// Wraps a synchronous operation with logging and error transformation.
  T safeCallSync<T>(String operation, T Function() fn) {
    try {
      return fn();
    } catch (e, st) {
      logger.severe('$operation failed: $e');
      throw NativeError.fromException(operation, e, st);
    }
  }
}

/// Extension to check if an exception is a [NativeError].
extension NativeErrorCheck on Object {
  bool get isNativeError => this is NativeError;

  NativeError? get asNativeError => this is NativeError ? this as NativeError : null;
}
