import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';

/// A crystal-themed popup menu item.
class CrystalMenuItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final bool enabled;
  final bool isDanger;

  const CrystalMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.isDanger = false,
  });
}

/// A crystal-themed popup menu button with glass-morphism styling.
class CrystalPopupMenuButton<T> extends StatefulWidget {
  /// The items to display in the menu.
  final List<CrystalMenuItem<T>> items;

  /// Called when an item is selected.
  final ValueChanged<T>? onSelected;

  /// The button to display. If null, shows a default icon button.
  final Widget? child;

  /// Default icon if no child is provided.
  final IconData icon;

  /// Tooltip for the button.
  final String? tooltip;

  /// Whether the menu is enabled.
  final bool enabled;

  /// Menu offset from the button.
  final Offset offset;

  const CrystalPopupMenuButton({
    super.key,
    required this.items,
    this.onSelected,
    this.child,
    this.icon = Icons.more_vert,
    this.tooltip,
    this.enabled = true,
    this.offset = const Offset(0, 8),
  });

  @override
  State<CrystalPopupMenuButton<T>> createState() =>
      _CrystalPopupMenuButtonState<T>();
}

class _CrystalPopupMenuButtonState<T> extends State<CrystalPopupMenuButton<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _showMenu() {
    if (!widget.enabled || widget.items.isEmpty) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _hideMenu() {
    _removeOverlay();
    setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    final entry = _overlayEntry;
    _overlayEntry = null;
    if (entry != null) {
      entry.remove();
    }
  }

  void _selectItem(CrystalMenuItem<T> item) {
    _hideMenu();
    if (item.enabled) {
      widget.onSelected?.call(item.value);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final buttonSize = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop to close menu on tap outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hideMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Menu positioned near button
          Positioned(
            width: 200,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, buttonSize.height + widget.offset.dy),
              child: _CrystalMenuDropdown<T>(
                items: widget.items,
                onSelected: _selectItem,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>();
    final accentColor = theme?.accent ?? Colors.cyan;

    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.child != null
          ? GestureDetector(
              onTap: widget.enabled ? _showMenu : null,
              child: widget.child,
            )
          : IconButton(
              onPressed: widget.enabled ? _showMenu : null,
              icon: Icon(widget.icon),
              tooltip: widget.tooltip,
              color: _isOpen ? accentColor : Colors.white70,
              style: IconButton.styleFrom(
                backgroundColor: _isOpen
                    ? accentColor.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
            ),
    );
  }
}

class _CrystalMenuDropdown<T> extends StatelessWidget {
  final List<CrystalMenuItem<T>> items;
  final ValueChanged<CrystalMenuItem<T>> onSelected;

  const _CrystalMenuDropdown({
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: CrystalBlur.medium, sigmaY: CrystalBlur.medium),
          child: Container(
            decoration: BoxDecoration(
              color: CrystalColors.panelBackground.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items.map((item) {
                return _CrystalMenuItemWidget<T>(
                  item: item,
                  onTap: () => onSelected(item),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrystalMenuItemWidget<T> extends StatefulWidget {
  final CrystalMenuItem<T> item;
  final VoidCallback onTap;

  const _CrystalMenuItemWidget({
    required this.item,
    required this.onTap,
  });

  @override
  State<_CrystalMenuItemWidget<T>> createState() =>
      _CrystalMenuItemWidgetState<T>();
}

class _CrystalMenuItemWidgetState<T> extends State<_CrystalMenuItemWidget<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>();
    final accentColor = theme?.accent ?? Colors.cyan;

    Color textColor;
    Color? bgColor;

    if (!widget.item.enabled) {
      textColor = Colors.white30;
      bgColor = null;
    } else if (widget.item.isDanger) {
      textColor = _isHovered ? Colors.red.shade300 : Colors.red.shade400;
      bgColor = _isHovered ? Colors.red.withValues(alpha: 0.1) : null;
    } else {
      textColor = _isHovered ? Colors.white : Colors.white70;
      bgColor = _isHovered ? accentColor.withValues(alpha: 0.15) : null;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.item.enabled ? widget.onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              left: BorderSide(
                color: _isHovered && widget.item.enabled
                    ? (widget.item.isDanger ? Colors.red : accentColor)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(
                  widget.item.icon,
                  size: 18,
                  color: textColor,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight:
                        _isHovered ? FontWeight.w500 : FontWeight.normal,
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

/// A divider for use within crystal menus.
class CrystalMenuDivider extends StatelessWidget {
  const CrystalMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
