import 'package:flutter/material.dart';

/// Animated version of CrystalContainer that smoothly transitions colors.
class AnimatedCrystalContainer extends ImplicitlyAnimatedWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final double skew;

  const AnimatedCrystalContainer({
    super.key,
    required this.child,
    this.color = const Color(0xFF020b19),
    this.borderColor = Colors.white24,
    this.skew = 20.0,
    super.duration = const Duration(milliseconds: 200),
    super.curve = Curves.easeOut,
  });

  @override
  ImplicitlyAnimatedWidgetState<AnimatedCrystalContainer> createState() =>
      _AnimatedCrystalContainerState();
}

class _AnimatedCrystalContainerState
    extends AnimatedWidgetBaseState<AnimatedCrystalContainer> {
  ColorTween? _colorTween;
  ColorTween? _borderColorTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _colorTween = visitor(
      _colorTween,
      widget.color,
      (value) => ColorTween(begin: value as Color),
    ) as ColorTween?;
    _borderColorTween = visitor(
      _borderColorTween,
      widget.borderColor,
      (value) => ColorTween(begin: value as Color),
    ) as ColorTween?;
  }

  @override
  Widget build(BuildContext context) {
    final double horizontalPad = widget.skew.abs();
    return CustomPaint(
      painter: _SlantedPainter(
        _colorTween?.evaluate(animation) ?? widget.color,
        _borderColorTween?.evaluate(animation) ?? widget.borderColor,
        widget.skew,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.skew < 0 ? horizontalPad + 20 : 20,
          10,
          widget.skew > 0 ? horizontalPad + 20 : 20,
          10,
        ),
        child: widget.child,
      ),
    );
  }
}

class CrystalContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final double skew;

  const CrystalContainer({
    super.key,
    required this.child,
    this.color = const Color(0xFF020b19),
    this.borderColor = Colors.white24,
    this.skew = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final double horizontalPad = skew.abs();
    return CustomPaint(
      painter: _SlantedPainter(color, borderColor, skew),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          skew < 0 ? horizontalPad + 20 : 20,
          10,
          skew > 0 ? horizontalPad + 20 : 20,
          10,
        ),
        child: child,
      ),
    );
  }
}

class _SlantedPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double skew;

  _SlantedPainter(this.color, this.borderColor, this.skew);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final path = Path();

    if (skew > 0) {
      path.moveTo(skew, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width - skew, size.height);
      path.lineTo(0, size.height);
    } else if (skew < 0) {
      final s = skew.abs();
      path.moveTo(0, 0);
      path.lineTo(size.width - s, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(s, size.height);
    } else {
      // No skew (Standard Rect)
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SlantedPainter oldDelegate) =>
      color != oldDelegate.color ||
      borderColor != oldDelegate.borderColor ||
      skew != oldDelegate.skew;
}
