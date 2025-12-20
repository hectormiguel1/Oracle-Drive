import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:flutter/material.dart';

class CrystalBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const CrystalBadge({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final themeColor =
        color ?? Theme.of(context).extension<CrystalTheme>()!.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.15),
        border: Border.all(color: themeColor.withValues(alpha: 0.6), width: 1),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: themeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
