import 'package:flutter/material.dart';

class CrystalColors {
  static const Color background = Color(0xFF050505);
  static const Color panelBackground = Color(0xFF020b19);
}

class CrystalStyles {
  static TextStyle get title => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 2.0,
    fontStyle: FontStyle.italic,
    shadows: [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4)],
  );

  static TextStyle get sectionHeader => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
  );

  static TextStyle get label => const TextStyle(
    fontSize: 14,
    color: Colors.white54,
    fontWeight: FontWeight.bold,
  );
}
