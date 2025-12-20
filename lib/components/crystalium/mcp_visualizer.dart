import 'dart:math' as math;
import 'package:oracle_drive/models/crystalium/mcp_file.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:flutter/material.dart';

class McpVisualizer extends StatefulWidget {
  final McpPattern pattern;

  const McpVisualizer({super.key, required this.pattern});

  @override
  State<McpVisualizer> createState() => _McpVisualizerState();
}

class _McpVisualizerState extends State<McpVisualizer> {
  double _rotationX = 0;
  double _rotationY = 0;
  double _focalLength = 300;
  bool _showRing = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _rotationY += details.delta.dx * 0.01;
                    _rotationX -= details.delta.dy * 0.01;
                  });
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: McpPainter(
                    pattern: widget.pattern,
                    rotationX: _rotationX,
                    rotationY: _rotationY,
                    focalLength: _focalLength,
                    showRing: _showRing,
                    accentColor:
                        Theme.of(context).extension<CrystalTheme>()?.accent ??
                        Colors.cyan,
                  ),
                ),
              );
            },
          ),
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    final theme = Theme.of(context).extension<CrystalTheme>()!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Text("Focal Length"),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: _focalLength,
                  min: 50,
                  max: 1000,
                  onChanged: (val) => setState(() => _focalLength = val),
                ),
              ),
              const SizedBox(width: 24),
              Text("Show Ring"),
              Switch(
                value: _showRing,
                onChanged: (val) => setState(() => _showRing = val),
                activeColor: theme.accent,
              ),
            ],
          ),
          Text(
            "Rotate by dragging on the 3D view",
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class McpPainter extends CustomPainter {
  final McpPattern pattern;
  final double rotationX;
  final double rotationY;
  final double focalLength;
  final bool showRing;
  final Color accentColor;

  McpPainter({
    required this.pattern,
    required this.rotationX,
    required this.rotationY,
    required this.focalLength,
    required this.showRing,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final points = pattern.validNodes;
    final allProjected = <_ProjectedPoint>[];

    double minProjectedX = double.infinity,
        maxProjectedX = double.negativeInfinity;
    double minProjectedY = double.infinity,
        maxProjectedY = double.negativeInfinity;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      // Apply Y-axis rotation
      double xAfterY = p.x * math.cos(rotationY) + p.z * math.sin(rotationY);
      double yAfterY = p.y;
      double zAfterY = -p.x * math.sin(rotationY) + p.z * math.cos(rotationY);

      // Then apply X-axis rotation
      double rotatedX = xAfterY;
      double rotatedYVal =
          yAfterY * math.cos(rotationX) - zAfterY * math.sin(rotationX);
      double rotatedZ =
          yAfterY * math.sin(rotationX) + zAfterY * math.cos(rotationX);

      // Perspective Projection
      if (focalLength + rotatedZ <= 0) {
        allProjected.add(
          _ProjectedPoint(x: 0, y: 0, z: rotatedZ, isVisible: false),
        );
        continue;
      }

      double perspectiveFactor = focalLength / (focalLength + rotatedZ);
      double projectedX = rotatedX * perspectiveFactor;
      double projectedY = rotatedYVal * perspectiveFactor;

      minProjectedX = math.min(minProjectedX, projectedX);
      maxProjectedX = math.max(maxProjectedX, projectedX);
      minProjectedY = math.min(minProjectedY, projectedY);
      maxProjectedY = math.max(maxProjectedY, projectedY);

      allProjected.add(
        _ProjectedPoint(
          x: projectedX,
          y: projectedY,
          z: rotatedZ,
          isVisible: true,
        ),
      );
    }

    if (allProjected.where((p) => p.isVisible).isEmpty) return;

    double rangeX = maxProjectedX - minProjectedX;
    double rangeY = maxProjectedY - minProjectedY;
    if (rangeX == 0) rangeX = 1;
    if (rangeY == 0) rangeY = 1;

    final padding = 30.0;
    double scaleX = (size.width - 2.0 * padding) / rangeX;
    double scaleY = (size.height - 2.0 * padding) / rangeY;
    double autoScaleFactor = math.min(scaleX, scaleY);

    Offset toScreen(double px, double py) {
      return Offset(
        centerX +
            (px - (minProjectedX + maxProjectedX) / 2.0) * autoScaleFactor,
        centerY -
            (py - (minProjectedY + maxProjectedY) / 2.0) * autoScaleFactor,
      );
    }

    // Draw the thick glowing ring first

    if (showRing) {
      final ringPaintGlow = Paint()
        ..color = accentColor.withAlpha(40)
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final ringPaintMain = Paint()
        ..color = accentColor.withAlpha(100)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (var i = 0; i < allProjected.length; i++) {
        final p1 = allProjected[i];

        final p2 = allProjected[(i + 1) % allProjected.length];

        if (p1.isVisible && p2.isVisible) {
          final node1 = points[i];

          final node2 = points[(i + 1) % allProjected.length];

          if ((node1.x == 0 && node1.z == 0) || (node2.x == 0 && node2.z == 0))
            continue;

          final avgZ = (p1.z + p2.z) / 2.0;

          double depthFactor = focalLength / (focalLength + avgZ);

          depthFactor = depthFactor.clamp(0.0, 1.5);

          ringPaintGlow.strokeWidth = 8.0 * depthFactor;

          ringPaintMain.strokeWidth = 3.0 * depthFactor;

          final s1 = toScreen(p1.x, p1.y);

          final s2 = toScreen(p2.x, p2.y);

          canvas.drawLine(s1, s2, ringPaintGlow);

          canvas.drawLine(s1, s2, ringPaintMain);
        }
      }
    }

    // Sort visible points for node rendering

    final visibleProjectedWithIdx = <_ProjectedWithIndex>[];

    for (int i = 0; i < allProjected.length; i++) {
      if (allProjected[i].isVisible) {
        visibleProjectedWithIdx.add(_ProjectedWithIndex(allProjected[i], i));
      }
    }

    visibleProjectedWithIdx.sort((a, b) => b.point.z.compareTo(a.point.z));

    for (final item in visibleProjectedWithIdx) {
      final p = item.point;

      final originalNode = points[item.index];

      if (originalNode.x == 0 && originalNode.z == 0 && originalNode.y == 0)
        continue;

      final screenPos = toScreen(p.x, p.y);

      double depthFactor = focalLength / (focalLength + p.z);

      depthFactor = depthFactor.clamp(0.0, 1.5);

      // Draw "Base Ring" underneath the dot

      final baseRadius = 12.0 * depthFactor;

      final basePaint = Paint()
        ..color = accentColor.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * depthFactor;

      final baseGlow = Paint()
        ..color = accentColor.withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 * depthFactor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      // To make the base ring look "flat" in 3D, we'd ideally project it point by point,

      // but a simple ellipse often suffices for this perspective.

      canvas.drawOval(
        Rect.fromCenter(
          center: screenPos,
          width: baseRadius * 2,
          height: baseRadius * 0.8,
        ),

        baseGlow,
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: screenPos,
          width: baseRadius * 2,
          height: baseRadius * 0.8,
        ),

        basePaint,
      );

      // Draw the central dot (Crystal)

      final pointSize = math.max(4.0, 10.0 * depthFactor);

      final alpha = (255 * depthFactor).toInt().clamp(100, 255);

      final paint = Paint()
        ..color = Colors.white.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      final corePaint = Paint()
        ..color = accentColor.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      // Inner core

      canvas.drawCircle(screenPos, pointSize / 2, corePaint);

      // Brighter center

      canvas.drawCircle(screenPos, pointSize / 4, paint);

      // Glow effect

      final glowPaint = Paint()
        ..color = accentColor.withAlpha(alpha ~/ 2)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(screenPos, pointSize, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant McpPainter oldDelegate) {
    return oldDelegate.pattern != pattern ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.focalLength != focalLength ||
        oldDelegate.showRing != showRing;
  }
}

class _ProjectedWithIndex {
  final _ProjectedPoint point;

  final int index;

  _ProjectedWithIndex(this.point, this.index);
}

class _ProjectedPoint {
  final double x;
  final double y;
  final double z;
  final bool isVisible;

  _ProjectedPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.isVisible,
  });
}
