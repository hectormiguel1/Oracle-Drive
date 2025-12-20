import 'package:ff13_mod_resource/components/widgets/crystal_container.dart';
import 'package:ff13_mod_resource/components/widgets/style.dart';
import 'package:ff13_mod_resource/theme/crystal_theme.dart';
import 'package:flutter/material.dart';

class CrystalIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isSelected;

  const CrystalIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.isSelected = false,
  });

  @override
  State<CrystalIconButton> createState() => _CrystalIconButtonState();
}

class _CrystalIconButtonState extends State<CrystalIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).extension<CrystalTheme>()!.accent;

    final bool isWhiteBg = widget.isSelected || _isHovered;
    final Color targetBgColor = isWhiteBg
        ? Colors.white
        : CrystalColors.panelBackground.withValues(alpha: 0.7);
    final Color targetContentColor = isWhiteBg ? Colors.black : Colors.white;
    final Color targetBorderColor =
        widget.isSelected || _isHovered ? accentColor : Colors.white24;

    Widget button = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isHovered ? 1.1 : 1.0,
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
                    skew: 10, // Slightly less skew for icon buttons
                    color: bgColor ?? targetBgColor,
                    borderColor: targetBorderColor,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        widget.icon,
                        color: contentColor,
                        size: 20,
                      ),
                    ),
                  );
                },
              );
            },
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
