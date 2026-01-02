import 'package:flutter/material.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';

/// A crystal-themed toggle switch.
class CrystalSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool enabled;

  const CrystalSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>();
    final accentColor = theme?.accent ?? Colors.cyan;

    Widget switchWidget = GestureDetector(
      onTap: enabled ? () => onChanged?.call(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value
              ? accentColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: value
                ? accentColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? accentColor : Colors.white54,
              boxShadow: [
                BoxShadow(
                  color: (value ? accentColor : Colors.black)
                      .withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label!,
            style: TextStyle(
              color: enabled ? Colors.white70 : Colors.white30,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          switchWidget,
        ],
      );
    }

    return switchWidget;
  }
}

/// A crystal-themed slider.
class CrystalSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String? label;
  final bool showValue;
  final String Function(double)? valueFormatter;

  const CrystalSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChanged,
    this.label,
    this.showValue = true,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>();
    final accentColor = theme?.accent ?? Colors.cyan;

    String formattedValue = valueFormatter?.call(value) ??
        (divisions != null ? value.toInt().toString() : value.toStringAsFixed(2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showValue)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (showValue)
                  Text(
                    formattedValue,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: accentColor,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            thumbColor: accentColor,
            overlayColor: accentColor.withValues(alpha: 0.2),
            thumbShape: _CrystalSliderThumbShape(accentColor: accentColor),
            trackShape: _CrystalSliderTrackShape(),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            tickMarkShape: SliderTickMarkShape.noTickMark,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _CrystalSliderThumbShape extends SliderComponentShape {
  final Color accentColor;

  const _CrystalSliderThumbShape({required this.accentColor});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(16, 16);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Outer glow
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, 8, glowPaint);

    // Main thumb
    final thumbPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, thumbPaint);

    // Inner highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.translate(-1, -1), 2, highlightPaint);
  }
}

class _CrystalSliderTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4;
    final trackLeft = offset.dx + 8;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width - 16;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final canvas = context.canvas;
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );

    // Inactive track
    final inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.white12
      ..style = PaintingStyle.fill;

    final inactiveRRect = RRect.fromRectAndRadius(
      trackRect,
      const Radius.circular(2),
    );
    canvas.drawRRect(inactiveRRect, inactivePaint);

    // Active track with gradient
    final activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );

    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          sliderTheme.activeTrackColor!.withValues(alpha: 0.6),
          sliderTheme.activeTrackColor!,
        ],
      ).createShader(activeRect)
      ..style = PaintingStyle.fill;

    final activeRRect = RRect.fromRectAndRadius(
      activeRect,
      const Radius.circular(2),
    );
    canvas.drawRRect(activeRRect, activePaint);
  }
}
