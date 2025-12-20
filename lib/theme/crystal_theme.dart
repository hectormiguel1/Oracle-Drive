import 'package:ff13_mod_resource/models/app_game_code.dart';
import 'package:flutter/material.dart';

@immutable
class CrystalTheme extends ThemeExtension<CrystalTheme> {
  final Color accent;
  final LinearGradient activeBarGradient;

  const CrystalTheme({
    required this.accent,
    required this.activeBarGradient,
  });

  @override
  CrystalTheme copyWith({
    Color? accent,
    LinearGradient? activeBarGradient,
  }) {
    return CrystalTheme(
      accent: accent ?? this.accent,
      activeBarGradient: activeBarGradient ?? this.activeBarGradient,
    );
  }

  @override
  ThemeExtension<CrystalTheme> lerp(ThemeExtension<CrystalTheme>? other, double t) {
    if (other is! CrystalTheme) {
      return this;
    }
    return CrystalTheme(
      accent: Color.lerp(accent, other.accent, t)!,
      activeBarGradient: LinearGradient.lerp(activeBarGradient, other.activeBarGradient, t)!,
    );
  }

  static CrystalTheme fromGame(AppGameCode game) {
    Color accentColor;
    switch (game) {
      case AppGameCode.ff13_1:
        accentColor = const Color(0xFF5bfdfd); // Cyan
        break;
      case AppGameCode.ff13_2:
        accentColor = const Color(0xFFFF69B4); // Hot Pink
        break;
      case AppGameCode.ff13_lr:
        accentColor = const Color(0xFFFF0000); // Red
        break;
    }

    return CrystalTheme(
      accent: accentColor,
      activeBarGradient: LinearGradient(
        colors: [
          accentColor.withValues(alpha: 0.4), // Darker shade approximation
          accentColor,
          Colors.white
        ],
        stops: const [0.0, 0.85, 1.0],
      ),
    );
  }
}
