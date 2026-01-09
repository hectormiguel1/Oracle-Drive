// --- BACKGROUND HELPERS ---
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:flutter/material.dart';

class CrystalBackgroundGrid extends StatelessWidget {
  const CrystalBackgroundGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>()!;
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            theme.accent.withValues(alpha: 0.15), // Brightened from 0.1
            Color(0xFF050505).withValues(alpha: 0.15),
          ], // Brightened from 0xFF1a2639 and 0xFF000000
        ),
      ),
      child: const CustomPaint(painter: CrystalGridPainter()),
    );
  }
}

class CrystalGridPainter extends CustomPainter {
  // Static Paint object to avoid recreating on every frame
  static final _paint = Paint()
    ..color = Colors.white.withValues(alpha: 0.08)
    ..strokeWidth = 1;

  static const _gridSize = 60.0;

  const CrystalGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Horizontal lines
    for (double i = 0; i < size.height; i += _gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), _paint);
    }
    // Vertical lines
    for (double i = 0; i < size.width; i += _gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), _paint);
    }
  }

  @override
  bool shouldRepaint(covariant CrystalGridPainter oldDelegate) => false;
}
