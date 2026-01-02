import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:flutter/material.dart';

class CrystalProgressBar extends StatelessWidget {
  final double value;
  final String? label;
  final String? valueLabel;

  const CrystalProgressBar({
    super.key,
    required this.value,
    this.label,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (valueLabel != null)
                  Text(
                    valueLabel!,
                    style: TextStyle(
                      color: theme.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black54,
            border: Border.all(color: Colors.white24, width: 0.5),
            borderRadius: BorderRadius.circular(1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: theme.activeBarGradient,
                boxShadow: [
                  BoxShadow(
                    color: theme.accent,
                    blurRadius: 4,
                    spreadRadius: -1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
