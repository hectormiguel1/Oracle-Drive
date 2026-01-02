import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';

/// A crystal-themed loading spinner with accent color glow.
class CrystalLoadingSpinner extends StatefulWidget {
  /// Size of the spinner.
  final double size;

  /// Stroke width of the spinner arc.
  final double strokeWidth;

  /// Optional custom color override.
  final Color? color;

  /// Whether to show the glow effect.
  final bool showGlow;

  /// Optional label to display below the spinner.
  final String? label;

  const CrystalLoadingSpinner({
    super.key,
    this.size = 40,
    this.strokeWidth = 3,
    this.color,
    this.showGlow = true,
    this.label,
  });

  /// Creates a small inline spinner.
  const CrystalLoadingSpinner.small({
    super.key,
    this.color,
    this.label,
  })  : size = 20,
        strokeWidth = 2,
        showGlow = false;

  /// Creates a large centered spinner with optional label.
  const CrystalLoadingSpinner.large({
    super.key,
    this.color,
    this.label,
  })  : size = 60,
        strokeWidth = 4,
        showGlow = true;

  @override
  State<CrystalLoadingSpinner> createState() => _CrystalLoadingSpinnerState();
}

class _CrystalLoadingSpinnerState extends State<CrystalLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>();
    final spinnerColor = widget.color ?? theme?.accent ?? Colors.cyan;

    Widget spinner = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _CrystalSpinnerPainter(
            progress: _controller.value,
            color: spinnerColor,
            strokeWidth: widget.strokeWidth,
            showGlow: widget.showGlow,
          ),
        );
      },
    );

    if (widget.label != null) {
      spinner = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          spinner,
          const SizedBox(height: 12),
          Text(
            widget.label!,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      );
    }

    return spinner;
  }
}

class _CrystalSpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool showGlow;

  _CrystalSpinnerPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background ring
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Draw spinning arc
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Create gradient along the arc
    final sweepAngle = math.pi * 0.75; // 135 degrees
    final startAngle = 2 * math.pi * progress - math.pi / 2;

    arcPaint.shader = SweepGradient(
      center: Alignment.center,
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        color.withValues(alpha: 0),
        color,
        Colors.white,
      ],
      stops: const [0.0, 0.7, 1.0],
      transform: GradientRotation(startAngle),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Add glow effect
    if (showGlow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
    }

    // Draw the main arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Draw crystal points (small diamonds at cardinal points)
    _drawCrystalPoints(canvas, center, radius, progress);
  }

  void _drawCrystalPoints(
      Canvas canvas, Offset center, double radius, double progress) {
    final pointPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Draw 4 crystal points that pulse
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) + (progress * math.pi * 2);
      final pulseScale = 0.5 + 0.5 * math.sin(progress * math.pi * 4 + i);
      final pointSize = 2 * pulseScale;

      final x = center.dx + (radius + 6) * math.cos(angle);
      final y = center.dy + (radius + 6) * math.sin(angle);

      // Draw diamond shape
      final path = Path()
        ..moveTo(x, y - pointSize)
        ..lineTo(x + pointSize, y)
        ..lineTo(x, y + pointSize)
        ..lineTo(x - pointSize, y)
        ..close();

      canvas.drawPath(path, pointPaint);
    }
  }

  @override
  bool shouldRepaint(_CrystalSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// A centered loading overlay with crystal spinner.
class CrystalLoadingOverlay extends StatelessWidget {
  final String? message;
  final bool visible;
  final Widget child;

  const CrystalLoadingOverlay({
    super.key,
    this.message,
    required this.visible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: CrystalLoadingSpinner.large(label: message),
              ),
            ),
          ),
      ],
    );
  }
}
