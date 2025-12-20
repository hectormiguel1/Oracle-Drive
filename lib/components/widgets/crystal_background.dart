// --- BACKGROUND HELPERS ---
import 'package:ff13_mod_resource/theme/crystal_theme.dart';
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
      child: CustomPaint(painter: CrystalGridPainter()),
    );
  }
}

class CrystalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
          .withValues(alpha: 0.08) // Increased from 0.05
      ..strokeWidth = 1;
    for (double i = 0; i < size.height; i += 60) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
