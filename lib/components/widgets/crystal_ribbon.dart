import 'dart:ui';
import 'package:ff13_mod_resource/components/widgets/style.dart';
import 'package:flutter/material.dart';

class CrystalRibbon extends StatelessWidget {
  final String message;
  final Widget? icon;

  const CrystalRibbon({super.key, required this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: CrystalColors.panelBackground.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.0,
              ),
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.0,
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: 0.05),
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
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 12)],
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
