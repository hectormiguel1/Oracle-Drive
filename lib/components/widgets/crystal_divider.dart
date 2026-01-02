import 'package:flutter/material.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';

/// A horizontal divider with crystal-themed styling.
///
/// Features gradient fade, optional accent color, and glow effects.
class CrystalDivider extends StatelessWidget {
  /// Thickness of the divider line.
  final double thickness;

  /// Horizontal padding/indentation from edges.
  final double indent;

  /// Vertical spacing around the divider.
  final double height;

  /// Whether to use the accent color from the theme.
  final bool useAccent;

  /// Whether to show a subtle glow effect.
  final bool showGlow;

  /// Custom color override.
  final Color? color;

  const CrystalDivider({
    super.key,
    this.thickness = 1,
    this.indent = 0,
    this.height = 16,
    this.useAccent = false,
    this.showGlow = false,
    this.color,
  });

  /// Creates a divider with accent color and glow.
  const CrystalDivider.accented({
    super.key,
    this.thickness = 1.5,
    this.indent = 0,
    this.height = 16,
    this.color,
  })  : useAccent = true,
        showGlow = true;

  /// Creates a subtle, minimal divider.
  const CrystalDivider.subtle({
    super.key,
    this.indent = 0,
    this.height = 8,
    this.color,
  })  : thickness = 0.5,
        useAccent = false,
        showGlow = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>();
    final dividerColor = color ??
        (useAccent
            ? (theme?.accent ?? Colors.cyan).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.12));

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: indent),
      alignment: Alignment.center,
      child: Container(
        height: thickness,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              dividerColor.withValues(alpha: 0),
              dividerColor,
              dividerColor,
              dividerColor.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.15, 0.85, 1.0],
          ),
          boxShadow: showGlow && useAccent
              ? [
                  BoxShadow(
                    color: dividerColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// A vertical divider with crystal-themed styling.
///
/// Features gradient fade, optional accent color, and glow effects.
class CrystalVerticalDivider extends StatelessWidget {
  /// Thickness of the divider line.
  final double thickness;

  /// Vertical padding/indentation from edges.
  final double indent;

  /// Horizontal width including spacing.
  final double width;

  /// Whether to use the accent color from the theme.
  final bool useAccent;

  /// Whether to show a subtle glow effect.
  final bool showGlow;

  /// Custom color override.
  final Color? color;

  const CrystalVerticalDivider({
    super.key,
    this.thickness = 1,
    this.indent = 0,
    this.width = 16,
    this.useAccent = false,
    this.showGlow = false,
    this.color,
  });

  /// Creates a divider with accent color and glow.
  const CrystalVerticalDivider.accented({
    super.key,
    this.thickness = 1.5,
    this.indent = 0,
    this.width = 16,
    this.color,
  })  : useAccent = true,
        showGlow = true;

  /// Creates a subtle, minimal divider.
  const CrystalVerticalDivider.subtle({
    super.key,
    this.indent = 0,
    this.width = 8,
    this.color,
  })  : thickness = 0.5,
        useAccent = false,
        showGlow = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>();
    final dividerColor = color ??
        (useAccent
            ? (theme?.accent ?? Colors.cyan).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.12));

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: indent),
      alignment: Alignment.center,
      child: Container(
        width: thickness,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              dividerColor.withValues(alpha: 0),
              dividerColor,
              dividerColor,
              dividerColor.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.15, 0.85, 1.0],
          ),
          boxShadow: showGlow && useAccent
              ? [
                  BoxShadow(
                    color: dividerColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
