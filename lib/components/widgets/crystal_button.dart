import 'package:oracle_drive/components/widgets/crystal_container.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:flutter/material.dart';

class CrystalButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final IconData? icon;

  const CrystalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.icon,
  });

  @override
  State<CrystalButton> createState() => _CrystalButtonState();
}

class _CrystalButtonState extends State<CrystalButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).extension<CrystalTheme>()!.accent;

    // Target Values
    final bool isWhiteBg = widget.isPrimary || _isHovered;
    final Color targetBgColor = isWhiteBg
        ? Colors.white
        : CrystalColors.panelBackground.withValues(alpha: 0.7);
    final Color targetContentColor = isWhiteBg ? Colors.black : Colors.white;
    final Color targetBorderColor = widget.isPrimary || _isHovered
        ? accentColor
        : Colors.white24;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onPressed,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(begin: targetBgColor, end: targetBgColor),
            duration: const Duration(milliseconds: 200),
            builder: (context, bgColor, _) {
              return TweenAnimationBuilder<Color?>(
                tween: ColorTween(
                  begin: targetContentColor,
                  end: targetContentColor,
                ),
                duration: const Duration(milliseconds: 200),
                builder: (context, contentColor, _) {
                  return CrystalContainer(
                    skew: 20,
                    color: bgColor ?? targetBgColor,
                    borderColor: targetBorderColor,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: contentColor, size: 16),
                          const SizedBox(width: 4),
                        ] else if (widget.isPrimary) ...[
                          Icon(Icons.play_arrow, color: contentColor, size: 16),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: contentColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
