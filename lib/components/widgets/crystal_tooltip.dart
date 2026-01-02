import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';

/// A crystal-themed tooltip with glass-morphism styling.
class CrystalTooltip extends StatelessWidget {
  final Widget child;
  final String message;
  final bool preferBelow;
  final Duration waitDuration;
  final Duration showDuration;

  const CrystalTooltip({
    super.key,
    required this.child,
    required this.message,
    this.preferBelow = true,
    this.waitDuration = const Duration(milliseconds: 500),
    this.showDuration = const Duration(seconds: 2),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>();
    final accentColor = theme?.accent ?? Colors.cyan;

    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      waitDuration: waitDuration,
      showDuration: showDuration,
      decoration: BoxDecoration(
        color: CrystalColors.panelBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );
  }
}

/// A rich tooltip with title and description.
class CrystalRichTooltip extends StatefulWidget {
  final Widget child;
  final String title;
  final String? description;
  final Widget? content;
  final bool preferBelow;

  const CrystalRichTooltip({
    super.key,
    required this.child,
    required this.title,
    this.description,
    this.content,
    this.preferBelow = true,
  });

  @override
  State<CrystalRichTooltip> createState() => _CrystalRichTooltipState();
}

class _CrystalRichTooltipState extends State<CrystalRichTooltip> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isHovering = false;

  void _showTooltip() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideTooltip() {
    final entry = _overlayEntry;
    _overlayEntry = null;
    if (entry != null) {
      entry.remove();
    }
  }

  OverlayEntry _createOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: 240,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, widget.preferBelow ? size.height + 8 : -8),
          targetAnchor:
              widget.preferBelow ? Alignment.bottomLeft : Alignment.topLeft,
          followerAnchor:
              widget.preferBelow ? Alignment.topLeft : Alignment.bottomLeft,
          child: _RichTooltipContent(
            title: widget.title,
            description: widget.description,
            content: widget.content,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _isHovering = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_isHovering) _showTooltip();
          });
        },
        onExit: (_) {
          _isHovering = false;
          _hideTooltip();
        },
        child: widget.child,
      ),
    );
  }
}

class _RichTooltipContent extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? content;

  const _RichTooltipContent({
    required this.title,
    this.description,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>();
    final accentColor = theme?.accent ?? Colors.cyan;

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: CrystalBlur.medium,
            sigmaY: CrystalBlur.medium,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CrystalColors.panelBackground.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    description!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (content != null) ...[
                  const SizedBox(height: 8),
                  content!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
