import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:ff13_mod_resource/src/third_party/common.g.dart' as common;

class NativeResult {
  /// Unwraps a Result, freeing it afterwards using the provided [freeFunction].
  ///
  /// [result] is the native Result struct.
  /// [freeFunction] is the library-specific function to free the result.
  /// [onSuccess] is a callback invoked when the result is Ok or OkInline.
  ///             It receives the [common.Result] and can extract data from it.
  /// [onError] is an optional callback invoked when the result is Err.
  ///           It receives the error message string.
  ///           If [onError] is provided, it is called and the function returns the result of [onError] (if T allows null, or if onError throws).
  ///           If [onError] is NOT provided, the function THROWS an exception with the error message.
  /// [failureMessage] is a prefix for the error message when throwing.
  static T unwrap<T>(
    common.Result result,
    void Function(common.Result) freeFunction, {
    required T Function(common.Result result) onSuccess,
    T Function(String msg)? onError,
    String failureMessage = "Native operation failed",
  }) {
    try {
      if (result.type == common.Type.Ok ||
          result.type == common.Type.OkInline) {
        return onSuccess(result);
      } else if (result.type == common.Type.Err) {
        String msg = failureMessage;
        final errPtr = result.payload.err;
        if (errPtr != nullptr) {
          final nativeMsg = errPtr.ref.error_message;
          if (nativeMsg != nullptr) {
            final nativeError = nativeMsg.cast<Utf8>().toDartString();
            msg += ": $nativeError";
          }
        }

        if (onError != null) {
          return onError(msg);
        } else {
          throw msg;
        }
      } else {
        throw "$failureMessage: Unknown Result Type (${result.type})";
      }
    } finally {
      if (result.type != common.Type.OkInline) {
        freeFunction(result);
      }
    }
  }

  /// Helper for when we just want to verify success and throw on error,
  /// with no return value needed.
  static void check(
    common.Result result,
    void Function(common.Result) freeFunction, {
    String failureMessage = "Native operation failed",
  }) {
    unwrap<void>(
      result,
      freeFunction,
      onSuccess: (_) {},
      failureMessage: failureMessage,
    );
  }
}
