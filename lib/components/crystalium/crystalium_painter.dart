import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:oracle_drive/models/crystalium/cgt_file.dart';
import 'package:oracle_drive/models/crystalium/mcp_file.dart';
import 'package:oracle_drive/src/utils/crystalium/crystalium_renderer.dart';
import 'package:oracle_drive/src/utils/crystalium/crystalium_walker.dart';

/// Custom painter for rendering the Crystarium.
/// Optimized for performance - no blur effects.
class CrystariumPainter extends CustomPainter {
  final CrystariumRenderer renderer;
  final double rotationX;
  final double rotationY;
  final double zoom;
  final int currentStage;
  final CrystariumEntry? selectedEntry;
  final int? selectedNodeIdx;
  final Color accentColor;
  final CrystariumWalker? walker;
  final Set<int> visitedNodes;
  final Set<int> enabledRoles;
  final Vector3? cameraOffset;
  final bool isWalkMode;
  final bool showNodeNames;

  // FF13 Color Palette
  static const Color _primaryPink = Color(0xFFFF69B4);
  static const Color _primaryCyan = Color(0xFF00FFFF);
  static const Color _primaryMagenta = Color(0xFFFF00FF);
  static const Color _energyWhite = Color(0xFFE0E0FF);

  CrystariumPainter({
    required this.renderer,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    required this.currentStage,
    this.selectedEntry,
    this.selectedNodeIdx,
    required this.accentColor,
    this.walker,
    this.visitedNodes = const {},
    this.enabledRoles = const {0, 1, 2, 3, 4, 5},
    this.cameraOffset,
    this.isWalkMode = false,
    this.showNodeNames = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Get filtered data
    final connections = renderer.getConnectionsForStage(currentStage);
    final nodePositions = renderer.getNodesForStage(currentStage);

    // Calculate scale based on bounding box and zoom
    final bounds = renderer.getBoundingBox();
    final sceneSize = math.max(
      bounds.max.x - bounds.min.x,
      math.max(bounds.max.y - bounds.min.y, bounds.max.z - bounds.min.z),
    );
    final baseScale = math.min(size.width, size.height) / (sceneSize + 50);
    final scale = baseScale * zoom;

    // Camera offset for walking mode (smooth following)
    Vector3 camOffset = Vector3(0, 0, 0);
    if (cameraOffset != null) {
      camOffset =
          Vector3(-cameraOffset!.x, -cameraOffset!.y, -cameraOffset!.z);
    }

    // Filter and project connections by depth
    final projectedConnections = <_ProjectedConnection>[];
    for (final conn in connections) {
      final fromInfo = renderer.nodeInfo[conn.fromNodeId];
      final toInfo = renderer.nodeInfo[conn.toNodeId];
      final fromRole = fromInfo?.roleId ?? 0;
      final toRole = toInfo?.roleId ?? 0;

      final showConnection = enabledRoles.contains(fromRole) ||
          enabledRoles.contains(toRole) ||
          conn.fromNodeId == 0 ||
          conn.toNodeId == 0;

      if (!showConnection) continue;

      final fromPos = _applyOffset(conn.fromPosition, camOffset);
      final toPos = _applyOffset(conn.toPosition, camOffset);
      final from = _project(fromPos, scale);
      final to = _project(toPos, scale);
      if (from.isVisible && to.isVisible) {
        final isVisited = visitedNodes.contains(conn.fromNodeId) &&
            visitedNodes.contains(conn.toNodeId);
        final isFiltered =
            !enabledRoles.contains(fromRole) && !enabledRoles.contains(toRole);
        projectedConnections.add(
          _ProjectedConnection(
            from: from,
            to: to,
            depth: (from.z + to.z) / 2,
            roleId: conn.roleId,
            isVisited: isVisited,
            isFiltered: isFiltered,
          ),
        );
      }
    }
    projectedConnections.sort((a, b) => b.depth.compareTo(a.depth));

    // Draw connections (simple lines - fast)
    for (final conn in projectedConnections) {
      _drawConnection(
        canvas,
        Offset(centerX + conn.from.x, centerY - conn.from.y),
        Offset(centerX + conn.to.x, centerY - conn.to.y),
        _getRoleColor(conn.roleId),
        conn.depth,
        isVisited: conn.isVisited,
        isFiltered: conn.isFiltered,
      );
    }

    // Filter and project nodes by depth
    final projectedNodes = <_ProjectedNode>[];
    for (final entry in nodePositions.entries) {
      final nodeId = entry.key;
      final info = renderer.nodeInfo[nodeId];
      final roleId = info?.roleId ?? 0;

      final showNode = enabledRoles.contains(roleId) || nodeId == 0;
      if (!showNode) continue;

      final pos = _applyOffset(entry.value, camOffset);
      final projected = _project(pos, scale);
      if (projected.isVisible) {
        String? nodeName;
        if (showNodeNames) {
          final cgtNode = renderer.cgtFile.getNode(nodeId);
          nodeName = cgtNode?.name;
        }

        projectedNodes.add(
          _ProjectedNode(
            nodeId: nodeId,
            screen: projected,
            roleId: roleId,
            stage: info?.stage ?? 1,
            isVisited: visitedNodes.contains(nodeId),
            nodeName: nodeName,
          ),
        );
      }
    }
    projectedNodes.sort((a, b) => b.screen.z.compareTo(a.screen.z));

    // Draw direction indicators in walk mode
    if (walker != null && walker!.availableDirections.isNotEmpty) {
      final selectedIdx = walker!.selectedDirectionIndex;
      for (var i = 0; i < walker!.availableDirections.length; i++) {
        final dir = walker!.availableDirections[i];
        if (!enabledRoles.contains(dir.roleId)) continue;

        final pos = _applyOffset(dir.position, camOffset);
        final projected = _project(pos, scale);
        if (projected.isVisible) {
          final isSelected = i == selectedIdx;
          _drawDirectionIndicator(
            canvas,
            Offset(centerX + projected.x, centerY - projected.y),
            _getRoleColor(dir.roleId),
            isSelected,
            projected.z,
          );
        }
      }
    }

    // Draw nodes
    for (final node in projectedNodes) {
      final isCurrentWalkerNode =
          walker != null && node.nodeId == walker!.currentNodeId;
      final isSelected = node.nodeId == selectedNodeIdx || isCurrentWalkerNode;
      final isInSelectedEntry =
          selectedEntry?.nodeIds.contains(node.nodeId) ?? false;

      _drawNode(
        canvas,
        Offset(centerX + node.screen.x, centerY - node.screen.y),
        node.screen.z,
        _getRoleColor(node.roleId),
        isSelected: isSelected,
        isHighlighted: isInSelectedEntry,
        isVisited: node.isVisited,
        isCurrentWalker: isCurrentWalkerNode,
        nodeName: node.nodeName,
      );
    }
  }

  /// Draw connection line (simple, fast)
  void _drawConnection(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color,
    double depth, {
    bool isVisited = false,
    bool isFiltered = false,
  }) {
    final opacity = (1.0 - (depth / 600).clamp(0.0, 0.6)).clamp(0.2, 1.0);
    final visitedMultiplier = isVisited ? 1.0 : 0.4;
    final filteredMultiplier = isFiltered ? 0.2 : 1.0;
    final finalOpacity = opacity * visitedMultiplier * filteredMultiplier;

    // Outer glow (wider, semi-transparent)
    final outerPaint = Paint()
      ..color = color.withValues(alpha: finalOpacity * 0.3)
      ..strokeWidth = isVisited ? 6.0 : 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, outerPaint);

    // Core line (bright)
    final corePaint = Paint()
      ..color = color.withValues(alpha: finalOpacity * 0.9)
      ..strokeWidth = isVisited ? 2.0 : 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, corePaint);
  }

  /// Draw direction indicator
  void _drawDirectionIndicator(
    Canvas canvas,
    Offset position,
    Color color,
    bool isSelected,
    double depth,
  ) {
    final depthFactor = (500 / (500 + depth)).clamp(0.5, 1.3);
    final size = (isSelected ? 24.0 : 16.0) * depthFactor;

    if (isSelected) {
      // Selection ring
      final selectRing = Paint()
        ..color = _energyWhite
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(position, size, selectRing);

      // Inner fill
      final fillPaint = Paint()
        ..color = _primaryCyan.withValues(alpha: 0.5);
      canvas.drawCircle(position, size - 2, fillPaint);

      // Arrow pointing up
      final arrowPaint = Paint()
        ..color = _energyWhite
        ..style = PaintingStyle.fill;

      final arrowPath = Path()
        ..moveTo(position.dx, position.dy - size - 12)
        ..lineTo(position.dx - 8, position.dy - size - 4)
        ..lineTo(position.dx + 8, position.dy - size - 4)
        ..close();
      canvas.drawPath(arrowPath, arrowPaint);
    } else {
      // Simple ring for unselected
      final ringPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(position, size, ringPaint);
    }
  }

  /// Draw node (simple circles - fast)
  void _drawNode(
    Canvas canvas,
    Offset position,
    double depth,
    Color color, {
    bool isSelected = false,
    bool isHighlighted = false,
    bool isVisited = false,
    bool isCurrentWalker = false,
    String? nodeName,
  }) {
    final depthFactor = (500 / (500 + depth)).clamp(0.4, 1.4);
    final baseSize = 8.0 * depthFactor;
    final opacity = (1.0 - (depth / 600).clamp(0.0, 0.6)).clamp(0.3, 1.0);
    final visitedMultiplier = isVisited ? 1.0 : 0.35;

    if (isCurrentWalker) {
      // Walker position - larger with rings
      // Outer ring
      final outerRing = Paint()
        ..color = _primaryCyan.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(position, baseSize + 16, outerRing);

      // Middle ring
      final midRing = Paint()
        ..color = _energyWhite.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(position, baseSize + 10, midRing);

      // Inner ring
      final innerRing = Paint()
        ..color = _primaryMagenta.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(position, baseSize + 4, innerRing);

      // Core
      final corePaint = Paint()..color = _energyWhite;
      canvas.drawCircle(position, baseSize, corePaint);
    } else if (isSelected) {
      // Selected node highlight
      final selectRing = Paint()
        ..color = _energyWhite
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(position, baseSize + 6, selectRing);
    }

    if (isHighlighted && !isSelected && !isCurrentWalker) {
      final highlightPaint = Paint()
        ..color = _primaryPink.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(position, baseSize + 4, highlightPaint);
    }

    // Outer glow (simple circle, no blur)
    final outerPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.2 * visitedMultiplier);
    canvas.drawCircle(position, baseSize * 2, outerPaint);

    // Main node body
    final nodePaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.9 * visitedMultiplier);
    canvas.drawCircle(position, baseSize, nodePaint);

    // White core highlight
    final corePaint = Paint()
      ..color = _energyWhite.withValues(alpha: opacity * 0.7 * visitedMultiplier);
    canvas.drawCircle(position, baseSize * 0.4, corePaint);

    // Draw node label
    if (nodeName != null && nodeName.isNotEmpty) {
      _drawNodeLabel(canvas, position, nodeName, baseSize, opacity, visitedMultiplier);
    }
  }

  void _drawNodeLabel(
    Canvas canvas,
    Offset position,
    String nodeName,
    double baseSize,
    double opacity,
    double visitedMultiplier,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: nodeName,
        style: TextStyle(
          color: _energyWhite.withValues(alpha: opacity * visitedMultiplier * 0.9),
          fontSize: 10.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy + baseSize + 6),
    );
  }

  Vector3 _applyOffset(Vector3 pos, Vector3 offset) {
    return Vector3(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z);
  }

  _Projected3D _project(Vector3 pos, double scale) {
    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);
    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX);

    final xAfterY = pos.x * cosY + pos.z * sinY;
    final yAfterY = pos.y;
    final zAfterY = -pos.x * sinY + pos.z * cosY;

    final xFinal = xAfterY;
    final yFinal = yAfterY * cosX - zAfterY * sinX;
    final zFinal = yAfterY * sinX + zAfterY * cosX;

    const focalLength = 500.0;
    if (focalLength + zFinal <= 0) {
      return _Projected3D(x: 0, y: 0, z: zFinal, isVisible: false);
    }

    final perspectiveFactor = focalLength / (focalLength + zFinal);
    return _Projected3D(
      x: xFinal * scale * perspectiveFactor,
      y: yFinal * scale * perspectiveFactor,
      z: zFinal,
      isVisible: true,
    );
  }

  /// FF13 Role Colors
  Color _getRoleColor(int roleId) {
    switch (roleId) {
      case 1: // Commando
        return const Color(0xFFFF6090);
      case 5: // Medic
        return const Color(0xFF40FF90);
      case 2: // Ravager
        return const Color(0xFF6090FF);
      case 3: // Saboteur
        return const Color(0xFFFF60FF);
      case 0: // Sentinel
        return const Color(0xFFFFB060);
      case 4: // Synergist
        return const Color(0xFF60FFFF);
      default:
        return _energyWhite;
    }
  }

  @override
  bool shouldRepaint(covariant CrystariumPainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.zoom != zoom ||
        oldDelegate.currentStage != currentStage ||
        oldDelegate.selectedEntry != selectedEntry ||
        oldDelegate.selectedNodeIdx != selectedNodeIdx ||
        oldDelegate.walker?.currentNodeId != walker?.currentNodeId ||
        oldDelegate.walker?.transitionProgress != walker?.transitionProgress ||
        oldDelegate.walker?.selectedDirectionIndex != walker?.selectedDirectionIndex ||
        oldDelegate.enabledRoles != enabledRoles ||
        oldDelegate.cameraOffset != cameraOffset ||
        oldDelegate.showNodeNames != showNodeNames;
  }
}

// Helper classes

class _Projected3D {
  final double x;
  final double y;
  final double z;
  final bool isVisible;

  _Projected3D({
    required this.x,
    required this.y,
    required this.z,
    required this.isVisible,
  });
}

class _ProjectedConnection {
  final _Projected3D from;
  final _Projected3D to;
  final double depth;
  final int roleId;
  final bool isVisited;
  final bool isFiltered;

  _ProjectedConnection({
    required this.from,
    required this.to,
    required this.depth,
    required this.roleId,
    this.isVisited = false,
    this.isFiltered = false,
  });
}

class _ProjectedNode {
  final int nodeId;
  final _Projected3D screen;
  final int roleId;
  final int stage;
  final bool isVisited;
  final String? nodeName;

  _ProjectedNode({
    required this.nodeId,
    required this.screen,
    required this.roleId,
    required this.stage,
    this.isVisited = false,
    this.nodeName,
  });
}
