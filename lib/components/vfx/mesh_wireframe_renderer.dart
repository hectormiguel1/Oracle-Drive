import 'dart:math' as math;

import 'package:fabula_nova_sdk/bridge_generated/modules/vfx/structs.dart';
import 'package:flutter/material.dart';

/// A widget that renders a VFX mesh as a 3D wireframe with rotation controls.
class MeshWireframeRenderer extends StatefulWidget {
  final VfxMesh mesh;
  final Color wireColor;
  final Color vertexColor;
  final double size;

  const MeshWireframeRenderer({
    super.key,
    required this.mesh,
    this.wireColor = Colors.cyan,
    this.vertexColor = Colors.white,
    this.size = 200,
  });

  @override
  State<MeshWireframeRenderer> createState() => _MeshWireframeRendererState();
}

class _MeshWireframeRendererState extends State<MeshWireframeRenderer> {
  double _rotationX = 0.3; // Initial X rotation (radians)
  double _rotationY = 0.5; // Initial Y rotation (radians)
  Offset? _lastPanPosition;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: GestureDetector(
              onPanStart: (details) {
                _lastPanPosition = details.localPosition;
              },
              onPanUpdate: (details) {
                if (_lastPanPosition != null) {
                  final delta = details.localPosition - _lastPanPosition!;
                  setState(() {
                    _rotationY += delta.dx * 0.01;
                    _rotationX += delta.dy * 0.01;
                  });
                  _lastPanPosition = details.localPosition;
                }
              },
              onPanEnd: (_) {
                _lastPanPosition = null;
              },
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _WireframePainter(
                  mesh: widget.mesh,
                  rotationX: _rotationX,
                  rotationY: _rotationY,
                  wireColor: widget.wireColor,
                  vertexColor: widget.vertexColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.touch_app, size: 14, color: Colors.white38),
            const SizedBox(width: 4),
            Text(
              'Drag to rotate',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                setState(() {
                  _rotationX = 0.3;
                  _rotationY = 0.5;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restart_alt, size: 14, color: Colors.white54),
                    const SizedBox(width: 2),
                    Text(
                      'Reset',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.mesh.vertices.length} vertices, ${widget.mesh.indices.length ~/ 3} triangles',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}

class _WireframePainter extends CustomPainter {
  final VfxMesh mesh;
  final double rotationX;
  final double rotationY;
  final Color wireColor;
  final Color vertexColor;

  _WireframePainter({
    required this.mesh,
    required this.rotationX,
    required this.rotationY,
    required this.wireColor,
    required this.vertexColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width * 0.35; // Scale factor for projection

    // Transform vertices
    final projectedVertices = <Offset>[];
    final zDepths = <double>[];

    for (final vertex in mesh.vertices) {
      final pos = vertex.position;
      var x = pos[0];
      var y = pos[1];
      var z = pos[2];

      // Apply Y rotation (around vertical axis)
      final cosY = math.cos(rotationY);
      final sinY = math.sin(rotationY);
      final newX = x * cosY - z * sinY;
      final newZ = x * sinY + z * cosY;
      x = newX;
      z = newZ;

      // Apply X rotation (around horizontal axis)
      final cosX = math.cos(rotationX);
      final sinX = math.sin(rotationX);
      final newY = y * cosX - z * sinX;
      final newZ2 = y * sinX + z * cosX;
      y = newY;
      z = newZ2;

      // Simple perspective projection
      final perspectiveFactor = 1.0 / (1.0 + z * 0.3);
      final screenX = center.dx + x * scale * perspectiveFactor;
      final screenY = center.dy - y * scale * perspectiveFactor;

      projectedVertices.add(Offset(screenX, screenY));
      zDepths.add(z);
    }

    // Draw coordinate axes (subtle)
    _drawAxes(canvas, center, scale);

    // Draw wireframe edges
    final wirePaint = Paint()
      ..color = wireColor.withOpacity(0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final indices = mesh.indices;
    for (var i = 0; i + 2 < indices.length; i += 3) {
      final i0 = indices[i];
      final i1 = indices[i + 1];
      final i2 = indices[i + 2];

      if (i0 < projectedVertices.length &&
          i1 < projectedVertices.length &&
          i2 < projectedVertices.length) {
        final p0 = projectedVertices[i0];
        final p1 = projectedVertices[i1];
        final p2 = projectedVertices[i2];

        // Calculate average Z for depth-based coloring
        final avgZ = (zDepths[i0] + zDepths[i1] + zDepths[i2]) / 3;
        final depthFactor = (1.0 - avgZ * 0.2).clamp(0.3, 1.0);
        wirePaint.color = wireColor.withOpacity(0.8 * depthFactor);

        // Draw triangle edges
        canvas.drawLine(p0, p1, wirePaint);
        canvas.drawLine(p1, p2, wirePaint);
        canvas.drawLine(p2, p0, wirePaint);
      }
    }

    // Draw vertices as small dots
    final vertexPaint = Paint()
      ..color = vertexColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < projectedVertices.length; i++) {
      final p = projectedVertices[i];
      final depthFactor = (1.0 - zDepths[i] * 0.2).clamp(0.3, 1.0);
      vertexPaint.color = vertexColor.withOpacity(depthFactor);
      canvas.drawCircle(p, 2.5, vertexPaint);
    }
  }

  void _drawAxes(Canvas canvas, Offset center, double scale) {
    final axisLength = scale * 0.3;
    final axisPaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // X axis (red)
    axisPaint.color = Colors.red.withOpacity(0.3);
    var cosY = math.cos(rotationY);
    var sinY = math.sin(rotationY);
    var endX = center.dx + axisLength * cosY;
    var endY = center.dy;
    canvas.drawLine(center, Offset(endX, endY), axisPaint);

    // Y axis (green)
    axisPaint.color = Colors.green.withOpacity(0.3);
    var cosX = math.cos(rotationX);
    endY = center.dy - axisLength * cosX;
    canvas.drawLine(center, Offset(center.dx, endY), axisPaint);

    // Z axis (blue)
    axisPaint.color = Colors.blue.withOpacity(0.3);
    var zX = -sinY * math.cos(rotationX);
    var zY = math.sin(rotationX);
    endX = center.dx + axisLength * zX;
    endY = center.dy + axisLength * zY;
    canvas.drawLine(center, Offset(endX, endY), axisPaint);
  }

  @override
  bool shouldRepaint(_WireframePainter oldDelegate) {
    return rotationX != oldDelegate.rotationX ||
        rotationY != oldDelegate.rotationY ||
        mesh != oldDelegate.mesh;
  }
}
