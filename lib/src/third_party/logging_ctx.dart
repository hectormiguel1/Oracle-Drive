import 'dart:async';
import 'package:ff13_mod_resource/src/services/native_service.dart';

// ignore: constant_identifier_names
enum LogLevel { Finest, Fine, Info, Warning, Error }

class LoggingCtx {
  static StreamSubscription<String>? _subscription;

  static void registerLoggingCallback(
    void Function(String) callback, [
    LogLevel level = LogLevel.Info,
  ]) {
    _subscription?.cancel();
    _subscription = NativeService.instance.logStream.listen((msg) {
      callback(msg);
    });
  }
}
