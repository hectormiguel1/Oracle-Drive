import 'package:oracle_drive/models/app_game_code.dart';
import 'package:flutter/material.dart';

@immutable
class CrystalTheme extends ThemeExtension<CrystalTheme> {
  final Color accent;
  final LinearGradient activeBarGradient;

  const CrystalTheme({required this.accent, required this.activeBarGradient});

  @override
  CrystalTheme copyWith({Color? accent, LinearGradient? activeBarGradient}) {
    return CrystalTheme(
      accent: accent ?? this.accent,
      activeBarGradient: activeBarGradient ?? this.activeBarGradient,
    );
  }

  @override
  ThemeExtension<CrystalTheme> lerp(
    ThemeExtension<CrystalTheme>? other,
    double t,
  ) {
    if (other is! CrystalTheme) {
      return this;
    }
    return CrystalTheme(
      accent: Color.lerp(accent, other.accent, t)!,
      activeBarGradient: LinearGradient.lerp(
        activeBarGradient,
        other.activeBarGradient,
        t,
      )!,
    );
  }

  static CrystalTheme fromGame(AppGameCode game) {
    Color accentColor;
    switch (game) {
      case AppGameCode.ff13_1:
        // FF13: Light cyan/aqua - the iconic crystalline blue-cyan UI
        accentColor = const Color(0xFF00E5FF); // Bright cyan
        break;
      case AppGameCode.ff13_2:
        // FF13-2: Deep blue/indigo - darker, more mysterious tone
        accentColor = const Color(0xFF3D5AFE); // Deep indigo blue
        break;
      case AppGameCode.ff13_lr:
        // Lightning Returns: Rose/magenta pink - Lightning's signature color
        accentColor = const Color(0xFFEC407A); // Rose pink
        break;
    }

    return CrystalTheme(
      accent: accentColor,
      activeBarGradient: LinearGradient(
        colors: [
          accentColor.withValues(alpha: 0.4),
          accentColor,
          Colors.white,
        ],
        stops: const [0.0, 0.85, 1.0],
      ),
    );
  }
}
