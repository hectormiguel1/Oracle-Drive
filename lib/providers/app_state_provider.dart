import 'package:oracle_drive/models/app_game_code.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider for the currently selected game.
/// Defaults to FF13_1.
final selectedGameProvider = StateProvider<AppGameCode>((ref) {
  return AppGameCode.ff13_1;
});

/// Provider for the current navigation index (sidebar).
final navigationIndexProvider = StateProvider<int>((ref) {
  return 0;
});

/// Provider for workflow fullscreen mode.
/// When true, the workflow screen is displayed in fullscreen mode
/// without the navigation rail.
final workflowFullscreenProvider = StateProvider<bool>((ref) {
  return false;
});
