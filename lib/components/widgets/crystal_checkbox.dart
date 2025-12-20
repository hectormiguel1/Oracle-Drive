import 'package:oracle_drive/components/widgets/crystal_container.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:flutter/material.dart';

class CrystalCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  const CrystalCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).extension<CrystalTheme>()!.accent;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CrystalContainer(
            skew: 0,
            color: value
                ? accentColor.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.3),
            borderColor: value ? accentColor : Colors.white24,
            child: SizedBox(
              width: 16,
              height: 16,
              child: value
                  ? Icon(Icons.check, size: 14, color: accentColor)
                  : null,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(label!, style: const TextStyle(color: Colors.white)),
          ],
        ],
      ),
    );
  }
}
