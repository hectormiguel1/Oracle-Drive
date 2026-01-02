import 'package:oracle_drive/components/widgets/crystal_container.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:flutter/material.dart';

/// A compact crystal-styled button with icon and short label.
/// Smaller than CrystalButton, suitable for toolbars and dense UIs.
class CrystalCompactButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final String? tooltip;

  const CrystalCompactButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.tooltip,
  });

  @override
  State<CrystalCompactButton> createState() => _CrystalCompactButtonState();
}

class _CrystalCompactButtonState extends State<CrystalCompactButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).extension<CrystalTheme>()!.accent;
    final isDisabled = widget.onPressed == null;

    final bool isHighlighted = (widget.isPrimary || _isHovered) && !isDisabled;
    final Color targetBgColor = isHighlighted
        ? Colors.white
        : CrystalColors.panelBackground.withValues(alpha: 0.7);
    final Color targetContentColor = isDisabled
        ? Colors.white38
        : isHighlighted
            ? Colors.black
            : Colors.white;
    final Color targetBorderColor = isDisabled
        ? Colors.white12
        : (widget.isPrimary || _isHovered)
            ? accentColor
            : Colors.white24;

    Widget button = MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isHovered && !isDisabled ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            child: CrystalContainer(
              skew: 12,
              color: targetBgColor,
              borderColor: targetBorderColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: targetContentColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: targetContentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
