import 'package:flutter/material.dart';

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
