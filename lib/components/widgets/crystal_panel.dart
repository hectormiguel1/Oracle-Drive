import 'dart:ui';

import 'package:oracle_drive/components/widgets/style.dart';
import 'package:flutter/material.dart';

class CrystalPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const CrystalPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: CrystalColors.panelBackground.withValues(alpha: 0.5),
            border: Border.all(color: Colors.white12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
