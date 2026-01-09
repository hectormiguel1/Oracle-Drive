import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/workflow/workflow_models.dart';

/// Common node dimension constants to avoid hardcoding values.
/// Bug #22 fix: Extract constants for consistent use across the codebase.
class NodeDimensions {
  static const double width = 220.0;
  static const double headerHeight = 36.0;

  // Port layout constants for accurate connection positioning
  static const double portsContainerPaddingY = 8.0;
  static const double portRowPaddingY = 4.0;
  static const double portRowPaddingX = 8.0;
  static const double portCircleDiameter = 12.0;
  static const double portCircleRadius = portCircleDiameter / 2;

  /// Each port row height: top padding + circle + bottom padding
  static const double portSpacing = portRowPaddingY + portCircleDiameter + portRowPaddingY; // 20px

  /// Get the X offset for input port circles (from node left edge).
  static double get inputPortX => portRowPaddingX + portCircleRadius;

  /// Get the X offset for output port circles (from node left edge).
  static double get outputPortX => width - portRowPaddingX - portCircleRadius;

  /// Get the Y offset for the first port center (from node top).
  static double get firstPortY =>
      headerHeight + portsContainerPaddingY + portRowPaddingY + portCircleRadius;
}

/// Paints bezier curves between connected nodes.
class ConnectionPainter extends CustomPainter {
  final List<WorkflowConnection> connections;
  final List<WorkflowNode> nodes;
  final String? highlightedConnectionId;

  /// Actual rendered port positions from the widgets.
  /// Key format: "nodeId:portId:isInput" (e.g., "node123:output:false")
  final Map<String, Offset> portPositions;

  /// Pre-built node map for O(1) lookups instead of O(n) list searches.
  late final Map<String, WorkflowNode> _nodeMap;

  ConnectionPainter({
    required this.connections,
    required this.nodes,
    this.highlightedConnectionId,
    this.portPositions = const {},
  }) {
    // Build node map once at construction for O(1) lookups
    _nodeMap = {for (final node in nodes) node.id: node};
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final connection in connections) {
      _paintConnection(canvas, connection);
    }
  }

  void _paintConnection(Canvas canvas, WorkflowConnection connection) {
    // O(1) lookups using node map
    final sourceNode = _nodeMap[connection.sourceNodeId];
    final targetNode = _nodeMap[connection.targetNodeId];

    if (sourceNode == null || targetNode == null) return;

    final startPoint = _getOutputPortPosition(sourceNode, connection.sourcePort);
    final endPoint = _getInputPortPosition(targetNode, connection.targetPort);

    // Determine connection color based on port type
    final portDef = sourceNode.type.outputPorts.firstWhere(
      (p) => p.id == connection.sourcePort,
      orElse: () => const PortDefinition('output', 'Output'),
    );
    final connectionColor = portDef.color ?? Colors.cyan;

    final isHighlighted = connection.id == highlightedConnectionId;

    // Paint glow for highlighted connections
    if (isHighlighted) {
      final glowPaint = Paint()
        ..color = connectionColor.withValues(alpha: 0.3)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      _drawBezier(canvas, startPoint, endPoint, glowPaint);
    }

    // Main connection line
    final paint = Paint()
      ..color = connectionColor.withValues(alpha: isHighlighted ? 0.9 : 0.6)
      ..strokeWidth = isHighlighted ? 3 : 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawBezier(canvas, startPoint, endPoint, paint);

    // Draw arrow at the end
    _drawArrow(canvas, startPoint, endPoint, connectionColor.withValues(alpha: 0.8));
  }

  void _drawBezier(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();

    // Tiny horizontal exit/entry - just enough to clear the node edge (~14px from port to edge)
    const exitOffset = 14.0;
    const entryOffset = 14.0;

    // Exit and entry points (just outside the node bounds)
    final exitPoint = Offset(start.dx + exitOffset, start.dy);
    final entryPoint = Offset(end.dx - entryOffset, end.dy);

    path.moveTo(start.dx, start.dy);

    // Tiny horizontal exit from port to node edge
    path.lineTo(exitPoint.dx, exitPoint.dy);

    // Calculate control points for smooth bezier curve
    // The curve should flow naturally between exit and entry points
    final curveDx = entryPoint.dx - exitPoint.dx;
    final curveDy = entryPoint.dy - exitPoint.dy;

    if (curveDx > 40) {
      // Normal case: target is to the right
      // Use horizontal tangent control points for smooth S-curve
      final controlStrength = (curveDx * 0.4).clamp(30.0, 150.0);

      path.cubicTo(
        exitPoint.dx + controlStrength, exitPoint.dy,   // Control 1: horizontal from exit
        entryPoint.dx - controlStrength, entryPoint.dy, // Control 2: horizontal to entry
        entryPoint.dx, entryPoint.dy,
      );
    } else {
      // Target is close or to the left - need to loop around
      // Calculate how far to swing out based on vertical distance
      final loopOut = (curveDy.abs() * 0.3 + 50).clamp(60.0, 200.0);

      path.cubicTo(
        exitPoint.dx + loopOut, exitPoint.dy,                    // Swing right from exit
        entryPoint.dx - loopOut, entryPoint.dy,                  // Swing right to entry
        entryPoint.dx, entryPoint.dy,
      );
    }

    // Tiny horizontal entry from node edge to port
    path.lineTo(end.dx, end.dy);

    canvas.drawPath(path, paint);
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const arrowSize = 8.0;
    const arrowAngle = 0.5; // ~30 degrees

    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - arrowSize,
      end.dy - arrowSize * arrowAngle,
    );
    arrowPath.lineTo(
      end.dx - arrowSize * 0.6,
      end.dy,
    );
    arrowPath.lineTo(
      end.dx - arrowSize,
      end.dy + arrowSize * arrowAngle,
    );
    arrowPath.close();

    canvas.drawPath(arrowPath, paint);
  }

  Offset _getOutputPortPosition(WorkflowNode node, String portId) {
    // Try to get actual rendered position first
    final key = '${node.id}:$portId:false';
    final actualPosition = portPositions[key];
    if (actualPosition != null) {
      return actualPosition;
    }

    // Fallback to calculated position
    final portIndex = node.outputPortIds.indexOf(portId);
    final portY = NodeDimensions.firstPortY + portIndex * NodeDimensions.portSpacing;

    return Offset(
      node.position.dx + NodeDimensions.outputPortX,
      node.position.dy + portY,
    );
  }

  Offset _getInputPortPosition(WorkflowNode node, String portId) {
    // Try to get actual rendered position first
    final key = '${node.id}:$portId:true';
    final actualPosition = portPositions[key];
    if (actualPosition != null) {
      return actualPosition;
    }

    // Fallback to calculated position
    final portIndex = node.inputPortIds.indexOf(portId);
    final portY = NodeDimensions.firstPortY + portIndex * NodeDimensions.portSpacing;

    return Offset(
      node.position.dx + NodeDimensions.inputPortX,
      node.position.dy + portY,
    );
  }

  // Bug #19 fix: Use deep equality for list comparison instead of reference comparison
  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return !listEquals(connections, oldDelegate.connections) ||
        !listEquals(nodes, oldDelegate.nodes) ||
        highlightedConnectionId != oldDelegate.highlightedConnectionId ||
        !_mapEquals(portPositions, oldDelegate.portPositions);
  }

  bool _mapEquals(Map<String, Offset> a, Map<String, Offset> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
