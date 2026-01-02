import 'dart:ui';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:flutter/material.dart';

/// Types of snackbar/ribbon messages with distinct visual states.
enum CrystalSnackBarType {
  /// Informational message - uses game accent color
  info,

  /// Success message - green accent
  success,

  /// Error message - red accent
  error,

  /// Warning message - orange accent
  warning,
}

extension CrystalSnackBarTypeX on CrystalSnackBarType {
  Color get color {
    switch (this) {
      case CrystalSnackBarType.info:
        return Colors.cyan; // Will be overridden by theme accent
      case CrystalSnackBarType.success:
        return const Color(0xFF4CAF50); // Green
      case CrystalSnackBarType.error:
        return const Color(0xFFE53935); // Red
      case CrystalSnackBarType.warning:
        return const Color(0xFFFF9800); // Orange
    }
  }

  IconData get icon {
    switch (this) {
      case CrystalSnackBarType.info:
        return Icons.info_outline;
      case CrystalSnackBarType.success:
        return Icons.check_circle_outline;
      case CrystalSnackBarType.error:
        return Icons.error_outline;
      case CrystalSnackBarType.warning:
        return Icons.warning_amber_outlined;
    }
  }
}

class CrystalRibbon extends StatelessWidget {
  final String message;
  final Widget? icon;
  final CrystalSnackBarType type;

  const CrystalRibbon({
    super.key,
    required this.message,
    this.icon,
    this.type = CrystalSnackBarType.info,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>();
    final accentColor =
        type == CrystalSnackBarType.info ? (theme?.accent ?? Colors.cyan) : type.color;

    final effectiveIcon = icon ??
        Icon(
          type.icon,
          color: accentColor,
          size: 20,
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: CrystalColors.panelBackground.withValues(alpha: 0.95),
            border: Border(
              left: BorderSide(
                color: accentColor,
                width: 3.0,
              ),
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.0,
              ),
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.0,
              ),
              right: BorderSide(
                color: accentColor.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                accentColor.withValues(alpha: 0.1),
                Colors.transparent,
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              effectiveIcon,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
