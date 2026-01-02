import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:flutter/material.dart';

/// Represents a single action item in a CrystalActionBar.
class CrystalAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const CrystalAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isPrimary = false,
  });
}

/// A toolbar-style component that groups related icon buttons.
///
/// Uses the crystal aesthetic with a shared background container
/// and individual hover states for each action.
class CrystalActionBar extends StatelessWidget {
  final String? label;
  final List<CrystalAction> actions;
  final double iconSize;
  final double spacing;

  const CrystalActionBar({
    super.key,
    this.label,
    required this.actions,
    this.iconSize = 18,
    this.spacing = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: CrystalStyles.label.copyWith(
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          decoration: BoxDecoration(
            color: CrystalColors.panelBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                _ActionButton(
                  action: actions[i],
                  iconSize: iconSize,
                ),
                if (i < actions.length - 1) SizedBox(width: spacing),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final CrystalAction action;
  final double iconSize;

  const _ActionButton({
    required this.action,
    required this.iconSize,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).extension<CrystalTheme>()!.accent;
    final isDisabled = widget.action.onPressed == null;
    final isPrimary = widget.action.isPrimary;

    final bool isHighlighted = (isPrimary || _isHovered) && !isDisabled;

    final Color bgColor = isHighlighted
        ? Colors.white
        : Colors.transparent;
    final Color iconColor = isDisabled
        ? Colors.white24
        : isHighlighted
            ? Colors.black
            : Colors.white70;
    final Color borderColor = isHighlighted
        ? accentColor
        : Colors.transparent;

    return Tooltip(
      message: widget.action.tooltip,
      child: MouseRegion(
        cursor: isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.action.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Icon(
              widget.action.icon,
              size: widget.iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// A vertical variant of CrystalActionBar for sidebar-style layouts.
class CrystalActionBarVertical extends StatelessWidget {
  final String? label;
  final List<CrystalAction> actions;
  final double iconSize;
  final double spacing;

  const CrystalActionBarVertical({
    super.key,
    this.label,
    required this.actions,
    this.iconSize = 18,
    this.spacing = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: CrystalStyles.label.copyWith(
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          decoration: BoxDecoration(
            color: CrystalColors.panelBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                _ActionButton(
                  action: actions[i],
                  iconSize: iconSize,
                ),
                if (i < actions.length - 1) SizedBox(height: spacing),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
