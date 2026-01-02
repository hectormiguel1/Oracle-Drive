import 'package:flutter/material.dart';
import 'package:oracle_drive/components/widgets/crystal_ribbon.dart';

/// Shows a crystal-styled snackbar with the given message and type.
///
/// The snackbar uses [CrystalRibbon] internally with a transparent container
/// for the glass-morphism effect.
///
/// [type] determines the visual styling:
/// - [CrystalSnackBarType.info] - Game accent color (default)
/// - [CrystalSnackBarType.success] - Green accent
/// - [CrystalSnackBarType.error] - Red accent
/// - [CrystalSnackBarType.warning] - Orange accent
///
/// [duration] defaults to 3 seconds for info/success, 4 seconds for error/warning.
void showCrystalSnackBar(
  BuildContext context,
  String message, {
  CrystalSnackBarType type = CrystalSnackBarType.info,
  Duration? duration,
  Widget? icon,
}) {
  final effectiveDuration = duration ??
      (type == CrystalSnackBarType.error || type == CrystalSnackBarType.warning
          ? const Duration(seconds: 4)
          : const Duration(seconds: 3));

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: CrystalRibbon(
        message: message,
        type: type,
        icon: icon,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: effectiveDuration,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Extension on BuildContext for convenient snackbar access.
extension CrystalSnackBarContext on BuildContext {
  /// Shows an info snackbar with the game's accent color.
  void showInfoSnackBar(String message, {Duration? duration, Widget? icon}) {
    showCrystalSnackBar(
      this,
      message,
      type: CrystalSnackBarType.info,
      duration: duration,
      icon: icon,
    );
  }

  /// Shows a success snackbar with green accent.
  void showSuccessSnackBar(String message, {Duration? duration, Widget? icon}) {
    showCrystalSnackBar(
      this,
      message,
      type: CrystalSnackBarType.success,
      duration: duration,
      icon: icon,
    );
  }

  /// Shows an error snackbar with red accent.
  void showErrorSnackBar(String message, {Duration? duration, Widget? icon}) {
    showCrystalSnackBar(
      this,
      message,
      type: CrystalSnackBarType.error,
      duration: duration,
      icon: icon,
    );
  }

  /// Shows a warning snackbar with orange accent.
  void showWarningSnackBar(String message, {Duration? duration, Widget? icon}) {
    showCrystalSnackBar(
      this,
      message,
      type: CrystalSnackBarType.warning,
      duration: duration,
      icon: icon,
    );
  }
}
