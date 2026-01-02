import 'dart:ui';

import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:flutter/material.dart';

/// A glass-morphism styled panel with configurable blur and accent options.
class CrystalPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  /// Blur intensity (sigma). Use [CrystalBlur] presets or custom values.
  /// Set to 0 to disable blur entirely.
  final double blurSigma;

  /// Border radius of the panel.
  final double borderRadius;

  /// Whether to show the accent-colored border glow.
  final bool showAccentBorder;

  /// Custom background color. Defaults to [CrystalColors.panelBackground].
  final Color? backgroundColor;

  /// Background opacity (0.0 - 1.0).
  final double backgroundOpacity;

  /// Whether to show the gradient overlay.
  final bool showGradient;

  const CrystalPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.blurSigma = CrystalBlur.medium,
    this.borderRadius = 4,
    this.showAccentBorder = false,
    this.backgroundColor,
    this.backgroundOpacity = 0.5,
    this.showGradient = true,
  });

  /// Creates a panel with subtle blur for overlays.
  const CrystalPanel.subtle({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 4,
    this.showAccentBorder = false,
    this.backgroundColor,
    this.backgroundOpacity = 0.6,
    this.showGradient = true,
  }) : blurSigma = CrystalBlur.subtle;

  /// Creates a panel with heavy blur for prominent UI elements.
  const CrystalPanel.intense({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 6,
    this.showAccentBorder = false,
    this.backgroundColor,
    this.backgroundOpacity = 0.4,
    this.showGradient = true,
  }) : blurSigma = CrystalBlur.intense;

  /// Creates a panel with accent-colored border.
  const CrystalPanel.accented({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.blurSigma = CrystalBlur.medium,
    this.borderRadius = 4,
    this.backgroundColor,
    this.backgroundOpacity = 0.5,
    this.showGradient = true,
  }) : showAccentBorder = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>();
    final bgColor = backgroundColor ?? CrystalColors.panelBackground;

    final decoration = BoxDecoration(
      color: bgColor.withValues(alpha: backgroundOpacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: showAccentBorder
            ? (theme?.accent ?? Colors.cyan).withValues(alpha: 0.4)
            : Colors.white12,
        width: showAccentBorder ? 1.5 : 1,
      ),
      gradient: showGradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            )
          : null,
      boxShadow: showAccentBorder && theme != null
          ? [
              BoxShadow(
                color: theme.accent.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ]
          : null,
    );

    final content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    // Skip blur if sigma is 0 for better performance
    if (blurSigma <= 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      ),
    );
  }
}

/// Preset blur intensity values for crystal widgets.
abstract class CrystalBlur {
  /// No blur effect.
  static const double none = 0;

  /// Very subtle blur (sigma: 3).
  static const double subtle = 3;

  /// Light blur (sigma: 6).
  static const double light = 6;

  /// Medium blur - default (sigma: 10).
  static const double medium = 10;

  /// Strong blur (sigma: 15).
  static const double strong = 15;

  /// Intense blur for prominent elements (sigma: 20).
  static const double intense = 20;
}
