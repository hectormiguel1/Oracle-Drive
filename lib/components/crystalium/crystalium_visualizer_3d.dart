import 'dart:math' as math;
import 'dart:ui';
import 'package:ff13_mod_resource/components/widgets/crystal_button.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_checkbox.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_container.dart';
import 'package:ff13_mod_resource/components/widgets/style.dart';
import 'package:ff13_mod_resource/models/crystalium/cgt_file.dart';
import 'package:ff13_mod_resource/models/crystalium/mcp_file.dart';
import 'package:ff13_mod_resource/src/utils/crystalium/crystalium_renderer.dart';
import 'package:ff13_mod_resource/src/utils/crystalium/crystalium_walker.dart';
import 'package:ff13_mod_resource/theme/crystal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// View mode for the visualizer.
enum VisualizerMode {
  /// Free orbit camera mode
  orbit,
  /// Walking mode - navigate through the tree
  walk,
}

/// 3D visualizer for FF13 Crystarium CGT data.
class CrystaliumVisualizer3D extends StatefulWidget {
  final CgtFile cgtFile;
  final McpFile? mcpPatterns;
  final CrystariumEntry? selectedEntry;
  final int? selectedNodeIdx;
  final void Function(LogicalKeyboardKey)? onNodeNavigation;
  final void Function(int nodeId)? onNodeSelected;
  final void Function(int nodeId, int stage, int roleId)? onAddOffshoot;
  final void Function(int nodeId, String currentName)? onEditNodeName;
  final VisualizerMode initialMode;

  const CrystaliumVisualizer3D({
    super.key,
    required this.cgtFile,
    this.mcpPatterns,
    this.selectedEntry,
    this.selectedNodeIdx,
    this.onNodeNavigation,
    this.onNodeSelected,
    this.onAddOffshoot,
    this.onEditNodeName,
    this.initialMode = VisualizerMode.orbit,
  });

  @override
  State<CrystaliumVisualizer3D> createState() => _CrystaliumVisualizer3DState();
}

class _CrystaliumVisualizer3DState extends State<CrystaliumVisualizer3D>
    with SingleTickerProviderStateMixin {
  // View mode
  late VisualizerMode _mode;

  // Orbit camera state
  double _rotationX = 0.3;
  double _rotationY = 0.0;
  double _zoom = 1.0;
  double _previousZoom = 1.0;
  int _currentStage = 10;

  // Walk mode camera state
  double _walkZoom = 18.0; // Very zoomed in for walking
  double _walkRotationX = 0.5;
  double _walkRotationY = 0.0;
  double _targetWalkRotationX = 0.5;
  double _targetWalkRotationY = 0.0;

  // Smooth camera following
  Vector3 _cameraTarget = Vector3(0, 0, 0);
  Vector3 _currentCameraPos = Vector3(0, 0, 0);

  // Role filtering
  Set<int> _enabledRoles = {0, 1, 2, 3, 4, 5}; // All roles enabled by default

  // Display options
  bool _showNodeNames = false;

  // Walking state
  late CrystariumRenderer _renderer;
  CrystariumWalker? _walker;
  late AnimationController _animController;

  // Click detection for direction arrows
  List<_ClickableDirection> _clickableDirections = [];
  Size _lastSize = Size.zero;

  // Focus node for keyboard input
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _renderer = CrystariumRenderer(
      cgtFile: widget.cgtFile,
      mcpPatterns: widget.mcpPatterns,
    );
    _walker = CrystariumWalker(_renderer);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_onAnimationTick);

    if (_mode == VisualizerMode.walk) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(CrystaliumVisualizer3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cgtFile != widget.cgtFile ||
        oldWidget.mcpPatterns != widget.mcpPatterns) {
      // Preserve walker state before rebuilding
      final previousNodeId = _walker?.currentNodeId ?? 0;
      final previousVisitedNodes = _walker?.visitedNodes.toSet() ?? <int>{};
      final wasInWalkMode = _mode == VisualizerMode.walk;

      _renderer = CrystariumRenderer(
        cgtFile: widget.cgtFile,
        mcpPatterns: widget.mcpPatterns,
      );
      _walker = CrystariumWalker(_renderer);

      // Restore walker position if we were in walk mode and the node still exists
      if (wasInWalkMode && _renderer.nodeWorldPositions.containsKey(previousNodeId)) {
        _walker!.jumpToNode(previousNodeId);
        // Restore visited nodes that still exist
        for (final nodeId in previousVisitedNodes) {
          if (_renderer.nodeWorldPositions.containsKey(nodeId)) {
            _walker!.visitedNodes.add(nodeId);
          }
        }
        // Keep camera at same position
        _currentCameraPos = _walker!.currentPosition;
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    if (_mode == VisualizerMode.walk && _walker != null) {
      _walker!.update(0.016); // ~60fps

      // Smooth camera follow
      final targetPos = _walker!.currentPosition;
      _cameraTarget = targetPos;

      // Lerp camera position for smooth following
      const smoothing = 0.1;
      _currentCameraPos = Vector3(
        _currentCameraPos.x + (targetPos.x - _currentCameraPos.x) * smoothing,
        _currentCameraPos.y + (targetPos.y - _currentCameraPos.y) * smoothing,
        _currentCameraPos.z + (targetPos.z - _currentCameraPos.z) * smoothing,
      );

      // Auto-rotate camera to face the stage plane
      // Calculate target rotation based on movement direction
      if (_walker!.state == WalkerState.moving) {
        final from = _renderer.nodeWorldPositions[_walker!.currentNodeId];
        final to = _renderer.nodeWorldPositions[_walker!.targetNodeId];
        if (from != null && to != null) {
          final dx = to.x - from.x;
          final dz = to.z - from.z;
          if (dx.abs() > 0.01 || dz.abs() > 0.01) {
            _targetWalkRotationY = math.atan2(dx, dz);
          }
        }
      }

      // Smoothly interpolate camera rotation
      const rotSmoothing = 0.05;
      _walkRotationY += (_targetWalkRotationY - _walkRotationY) * rotSmoothing;
      _walkRotationX += (_targetWalkRotationX - _walkRotationX) * rotSmoothing;

      setState(() {});
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (_mode == VisualizerMode.walk && _walker != null) {
      // Walking mode controls
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        if (_walker!.state == WalkerState.selecting ||
            _walker!.state == WalkerState.idle) {
          setState(() => _walker!.confirmSelection());
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        setState(() => _walker!.moveToParent());
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.keyA) {
        setState(() => _walker!.selectPreviousDirection());
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.keyD) {
        setState(() => _walker!.selectNextDirection());
      } else if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        setState(() => _walker!.confirmSelection());
      } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
        setState(() {
          _walker!.reset();
          _currentCameraPos = Vector3(0, 0, 0);
        });
      }
    } else if (widget.onNodeNavigation != null) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        widget.onNodeNavigation!(event.logicalKey);
      }
    }
  }

  void _onModeChanged(VisualizerMode newMode) {
    setState(() {
      _mode = newMode;
      if (_mode == VisualizerMode.walk) {
        _animController.repeat();
        // Initialize camera to current walker position
        if (_walker != null) {
          _currentCameraPos = _walker!.currentPosition;
          _cameraTarget = _currentCameraPos;
        }
      } else {
        _animController.stop();
      }
    });
  }

  void _toggleRole(int roleId) {
    setState(() {
      if (_enabledRoles.contains(roleId)) {
        // Don't allow disabling all roles
        if (_enabledRoles.length > 1) {
          _enabledRoles.remove(roleId);
        }
      } else {
        _enabledRoles.add(roleId);
      }
    });
  }

  void _enableOnlyRole(int roleId) {
    setState(() {
      _enabledRoles = {roleId};
    });
  }

  void _enableAllRoles() {
    setState(() {
      _enabledRoles = {0, 1, 2, 3, 4, 5};
    });
  }

  void _handleDirectionClick(Offset tapPosition) {
    if (_walker == null || _clickableDirections.isEmpty) return;

    // Find if tap is within any clickable direction
    for (final clickable in _clickableDirections) {
      final distance = (tapPosition - clickable.screenPosition).distance;
      if (distance <= clickable.radius) {
        // Found a match - move to this direction
        setState(() {
          _walker!.moveToNode(clickable.nodeId);
        });
        return;
      }
    }
  }

  void _updateClickableDirections(List<_ClickableDirection> directions) {
    _clickableDirections = directions;
  }

  List<Widget> _buildDirectionButtons(BoxConstraints constraints, CrystalTheme theme) {
    if (_walker == null) return [];

    // Filter directions by enabled roles only
    final directions = _walker!.availableDirections
        .where((d) => _enabledRoles.contains(d.roleId))
        .toList();

    if (directions.isEmpty) return [];

    final centerX = constraints.maxWidth / 2;
    final centerY = constraints.maxHeight / 2;

    const buttonRadius = 140.0; // Distance from center
    const buttonSize = 80.0;

    final widgets = <Widget>[];

    // Determine labels based on count
    final isFork = directions.length > 1;

    for (var i = 0; i < directions.length; i++) {
      final dir = directions[i];
      final actualIdx = _walker!.availableDirections.indexOf(dir);
      final isSelected = actualIdx == _walker!.selectedDirectionIndex;

      // Calculate button position based on angle
      final angle = dir.angle - _walkRotationY - math.pi / 2;
      final x = centerX + math.cos(angle) * buttonRadius - buttonSize / 2;
      final y = centerY + math.sin(angle) * buttonRadius - buttonSize / 2;

      final color = _getRoleColor(dir.roleId);

      // Determine label
      String label;
      IconData icon;
      if (isFork) {
        if (directions.length == 2) {
          label = i == 0 ? 'Left' : 'Right';
          icon = i == 0 ? Icons.turn_left : Icons.turn_right;
        } else {
          label = 'Fork ${i + 1}';
          icon = Icons.call_split;
        }
      } else {
        label = 'Next';
        icon = Icons.arrow_upward;
      }

      widgets.add(
        Positioned(
          left: x,
          top: y,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _walker!.moveToNode(dir.nodeId);
              });
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? color.withValues(alpha: 0.7)
                    : color.withValues(alpha: 0.4),
                border: Border.all(
                  color: isSelected ? Colors.white : color,
                  width: isSelected ? 4 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: isSelected ? 25 : 15,
                    spreadRadius: isSelected ? 8 : 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Add back/previous button if not at root
    if (_walker!.currentNodeId != 0) {
      final cgtNode = _renderer.cgtFile.getNode(_walker!.currentNodeId);
      if (cgtNode != null && cgtNode.parentIndex >= 0) {
        // Check if parent is in enabled roles
        final parentInfo = _renderer.nodeInfo[cgtNode.parentIndex];
        final parentRoleEnabled = parentInfo == null || _enabledRoles.contains(parentInfo.roleId);

        if (parentRoleEnabled) {
          widgets.add(
            Positioned(
              left: centerX - 50,
              bottom: 30,
              child: GestureDetector(
                onTap: () {
                  setState(() => _walker!.moveToParent());
                },
                child: Container(
                  width: 100,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: Colors.white.withValues(alpha: 0.25),
                    border: Border.all(color: Colors.white70, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_downward, color: Colors.white, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        'Prev',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>()!;

    return Column(
      children: [
        _buildControls(theme),
        _buildRoleFilters(theme),
        Expanded(
          child: KeyboardListener(
            focusNode: _focusNode,
            onKeyEvent: _handleKeyEvent,
            autofocus: true,
            child: GestureDetector(
              onScaleStart: (details) {
                if (_mode == VisualizerMode.orbit) {
                  _previousZoom = _zoom;
                } else {
                  _previousZoom = _walkZoom;
                }
              },
              onScaleUpdate: (details) {
                setState(() {
                  if (_mode == VisualizerMode.orbit) {
                    _rotationY += details.focalPointDelta.dx * 0.01;
                    _rotationX -= details.focalPointDelta.dy * 0.01;
                    _rotationX = _rotationX.clamp(-math.pi / 2, math.pi / 2);
                    _zoom = (_previousZoom * details.scale).clamp(0.1, 5.0);
                  } else {
                    // Walk mode - allow rotation and zoom adjustment
                    _walkRotationY += details.focalPointDelta.dx * 0.01;
                    _walkRotationX -= details.focalPointDelta.dy * 0.01;
                    _walkRotationX = _walkRotationX.clamp(-math.pi / 2, math.pi / 2);
                    _walkZoom = (_previousZoom * details.scale).clamp(4.0, 25.0);
                  }
                });
              },
              onTapUp: (details) {
                if (_mode == VisualizerMode.walk) {
                  _handleDirectionClick(details.localPosition);
                }
              },
              onDoubleTap: () {
                if (_mode == VisualizerMode.walk && _walker != null && widget.onEditNodeName != null) {
                  final currentNodeId = _walker!.currentNodeId;
                  final cgtNode = widget.cgtFile.getNode(currentNodeId);
                  final currentName = cgtNode?.name.replaceAll(RegExp(r'\x00'), '') ?? '';
                  widget.onEditNodeName!(currentNodeId, currentName);
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
                  return Stack(
                    children: [
                      CustomPaint(
                        size: _lastSize,
                        painter: CrystariumPainter(
                          renderer: _renderer,
                          rotationX: _mode == VisualizerMode.orbit ? _rotationX : _walkRotationX,
                          rotationY: _mode == VisualizerMode.orbit ? _rotationY : _walkRotationY,
                          zoom: _mode == VisualizerMode.orbit ? _zoom : _walkZoom,
                          currentStage: _currentStage,
                          selectedEntry: widget.selectedEntry,
                          selectedNodeIdx: _mode == VisualizerMode.walk
                              ? _walker?.currentNodeId
                              : widget.selectedNodeIdx,
                          accentColor: theme.accent,
                          walker: _mode == VisualizerMode.walk ? _walker : null,
                          visitedNodes: _walker?.visitedNodes ?? {},
                          enabledRoles: _enabledRoles,
                          cameraOffset: _mode == VisualizerMode.walk ? _currentCameraPos : null,
                          isWalkMode: _mode == VisualizerMode.walk,
                          showNodeNames: _showNodeNames,
                        ),
                      ),
                      // Clickable direction arrows in walk mode
                      if (_mode == VisualizerMode.walk && _walker != null)
                        ..._buildDirectionButtons(constraints, theme),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        if (_mode == VisualizerMode.walk) _buildWalkingInfo(theme),
        _buildLegend(theme),
      ],
    );
  }

  Widget _buildControls(CrystalTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Mode toggle using crystal containers
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeButton(VisualizerMode.orbit, 'Orbit', Icons.threed_rotation, theme),
              const SizedBox(width: 4),
              _buildModeButton(VisualizerMode.walk, 'Walk', Icons.directions_walk, theme),
            ],
          ),
          const SizedBox(width: 16),
          // Stage control
          Text(
            'STAGE',
            style: TextStyle(
              color: theme.accent.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: theme.accent,
                inactiveTrackColor: Colors.white12,
                thumbColor: theme.accent,
                overlayColor: theme.accent.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _currentStage.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) {
                  setState(() => _currentStage = value.round());
                },
              ),
            ),
          ),
          CrystalContainer(
            skew: 0,
            color: theme.accent.withValues(alpha: 0.15),
            borderColor: theme.accent.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                '$_currentStage',
                style: TextStyle(
                  color: theme.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Zoom control
          Text(
            'ZOOM',
            style: TextStyle(
              color: theme.accent.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: theme.accent,
                inactiveTrackColor: Colors.white12,
                thumbColor: theme.accent,
                overlayColor: theme.accent.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _mode == VisualizerMode.orbit ? _zoom : _walkZoom,
                min: _mode == VisualizerMode.orbit ? 0.1 : 4.0,
                max: _mode == VisualizerMode.orbit ? 5.0 : 25.0,
                onChanged: (value) {
                  setState(() {
                    if (_mode == VisualizerMode.orbit) {
                      _zoom = value;
                    } else {
                      _walkZoom = value;
                    }
                  });
                },
              ),
            ),
          ),
          if (_mode == VisualizerMode.walk) ...[
            const SizedBox(width: 8),
            CrystalButton(
              label: 'Reset',
              icon: Icons.refresh,
              onPressed: () => setState(() {
                _walker?.reset();
                _currentCameraPos = Vector3(0, 0, 0);
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeButton(VisualizerMode mode, String label, IconData icon, CrystalTheme theme) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => _onModeChanged(mode),
      child: CrystalContainer(
        skew: 12,
        color: isSelected ? theme.accent.withValues(alpha: 0.2) : CrystalColors.panelBackground,
        borderColor: isSelected ? theme.accent : Colors.white24,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? theme.accent : Colors.white54),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.accent : Colors.white54,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleFilters(CrystalTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Text('Roles:', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 8),
          ...CrystariumRole.values.map((role) {
            final isEnabled = _enabledRoles.contains(role.id);
            final color = _getRoleColor(role.id);
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => _toggleRole(role.id),
                onDoubleTap: () => _enableOnlyRole(role.id),
                child: Tooltip(
                  message: '${role.fullName}\nClick: Toggle\nDouble-click: Solo',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isEnabled ? color.withValues(alpha: 0.3) : Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isEnabled ? color : Colors.white24,
                        width: isEnabled ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isEnabled ? color : Colors.white24,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          role.abbreviation,
                          style: TextStyle(
                            color: isEnabled ? Colors.white : Colors.white38,
                            fontSize: 11,
                            fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _enableAllRoles,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text('All', style: TextStyle(color: theme.accent, fontSize: 11)),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 24, color: Colors.white24),
          const SizedBox(width: 16),
          CrystalCheckbox(
            value: _showNodeNames,
            onChanged: (value) => setState(() => _showNodeNames = value),
            label: 'Node Names',
          ),
        ],
      ),
    );
  }

  Widget _buildWalkingInfo(CrystalTheme theme) {
    if (_walker == null) return const SizedBox.shrink();

    final currentNodeId = _walker!.currentNodeId;
    final nodeInfo = _renderer.nodeInfo[currentNodeId];
    final cgtNode = widget.cgtFile.getNode(currentNodeId);
    final directions = _walker!.availableDirections
        .where((d) => _enabledRoles.contains(d.roleId))
        .toList();

    // Find the entry containing this node
    CrystariumEntry? currentEntry;
    for (final entry in widget.cgtFile.entries) {
      if (entry.nodeIds.contains(currentNodeId)) {
        currentEntry = entry;
        break;
      }
    }

    final nodeName = cgtNode?.name.replaceAll(RegExp(r'\x00'), '') ?? 'Unknown';
    final patternName = currentEntry?.patternName.replaceAll(RegExp(r'\x00'), '') ?? 'N/A';
    final stage = nodeInfo?.stage ?? currentEntry?.stage ?? 1;
    final roleId = nodeInfo?.roleId ?? currentEntry?.roleId ?? 0;
    final role = CrystariumRole.fromId(roleId);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CrystalColors.panelBackground.withValues(alpha: 0.7),
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              // Node info section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Section label
                    Text(
                      'CURRENT NODE',
                      style: TextStyle(
                        color: theme.accent.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Node details row
                    Row(
                      children: [
                        // Node ID badge
                        CrystalContainer(
                          skew: 0,
                          color: theme.accent.withValues(alpha: 0.2),
                          borderColor: theme.accent,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: Text(
                              '#$currentNodeId',
                              style: TextStyle(
                                color: theme.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Node name
                        Expanded(
                          child: Text(
                            nodeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Stage, Pattern, Role info
                    Row(
                      children: [
                        _buildInfoChip('STAGE', '$stage', theme),
                        const SizedBox(width: 12),
                        _buildInfoChip('PATTERN', patternName, theme),
                        const SizedBox(width: 12),
                        _buildRoleChip(role, theme),
                      ],
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 50,
                color: Colors.white12,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              // Actions section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ACTIONS',
                    style: TextStyle(
                      color: theme.accent.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (widget.onAddOffshoot != null)
                    CrystalButton(
                      label: 'Add Offshoot',
                      icon: Icons.add_circle_outline,
                      onPressed: () {
                        widget.onAddOffshoot?.call(currentNodeId, stage, roleId);
                      },
                    ),
                ],
              ),
              const SizedBox(width: 8),
              // Directions section (compact)
              if (directions.isNotEmpty)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PATHS (${directions.length})',
                      style: TextStyle(
                        color: theme.accent.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: directions.take(4).map((dir) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _getRoleColor(dir.roleId).withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: _getRoleColor(dir.roleId)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, CrystalTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.accent.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChip(CrystariumRole role, CrystalTheme theme) {
    final color = _getRoleColor(role.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ROLE',
          style: TextStyle(
            color: theme.accent.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${role.abbreviation} (${role.fullName})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend(CrystalTheme theme) {
    final roles = CrystariumRole.values;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: roles.map((role) {
          final color = _getRoleColor(role.id);
          final isEnabled = _enabledRoles.contains(role.id);
          return Opacity(
            opacity: isEnabled ? 1.0 : 0.3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  role.abbreviation,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getRoleColor(int roleId) {
    switch (roleId) {
      case 0: return const Color(0xFFFF4444); // COM - Red
      case 1: return const Color(0xFF44FF44); // RAV - Green
      case 2: return const Color(0xFF4444FF); // SEN - Blue
      case 3: return const Color(0xFFFF44FF); // SAB - Magenta
      case 4: return const Color(0xFFFFFF44); // SYN - Yellow
      case 5: return const Color(0xFF44FFFF); // MED - Cyan
      default: return Colors.white;
    }
  }
}

/// Custom painter for rendering the Crystarium in 3D.
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
      camOffset = Vector3(-cameraOffset!.x, -cameraOffset!.y, -cameraOffset!.z);
    }

    // Filter and project connections by depth
    final projectedConnections = <_ProjectedConnection>[];
    for (final conn in connections) {
      // Check if both ends are in enabled roles
      final fromInfo = renderer.nodeInfo[conn.fromNodeId];
      final toInfo = renderer.nodeInfo[conn.toNodeId];
      final fromRole = fromInfo?.roleId ?? 0;
      final toRole = toInfo?.roleId ?? 0;

      // Show connection if either end is in enabled roles (or it's the root)
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
        final isFiltered = !enabledRoles.contains(fromRole) && !enabledRoles.contains(toRole);
        projectedConnections.add(_ProjectedConnection(
          from: from,
          to: to,
          depth: (from.z + to.z) / 2,
          roleId: conn.roleId,
          isVisited: isVisited,
          isFiltered: isFiltered,
        ));
      }
    }
    projectedConnections.sort((a, b) => b.depth.compareTo(a.depth));

    // Draw connections
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

      // Show node if it's in enabled roles or is the root
      final showNode = enabledRoles.contains(roleId) || nodeId == 0;
      if (!showNode) continue;

      final pos = _applyOffset(entry.value, camOffset);
      final projected = _project(pos, scale);
      if (projected.isVisible) {
        // Get node name from CGT file
        String? nodeName;
        if (showNodeNames) {
          final cgtNode = renderer.cgtFile.getNode(nodeId);
          nodeName = cgtNode?.name;
        }

        projectedNodes.add(_ProjectedNode(
          nodeId: nodeId,
          screen: projected,
          roleId: roleId,
          stage: info?.stage ?? 1,
          isVisited: visitedNodes.contains(nodeId),
          nodeName: nodeName,
        ));
      }
    }
    projectedNodes.sort((a, b) => b.screen.z.compareTo(a.screen.z));

    // Draw available direction indicators in walk mode
    if (walker != null && walker!.availableDirections.isNotEmpty) {
      final selectedIdx = walker!.selectedDirectionIndex;
      for (var i = 0; i < walker!.availableDirections.length; i++) {
        final dir = walker!.availableDirections[i];

        // Only show directions for enabled roles
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
          );
        }
      }
    }

    // Draw nodes
    for (final node in projectedNodes) {
      final isCurrentWalkerNode = walker != null && node.nodeId == walker!.currentNodeId;
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

    // Draw crosshair in walk mode
    if (isWalkMode) {
      _drawCrosshair(canvas, Offset(centerX, centerY));
    }
  }

  void _drawCrosshair(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    const size = 15.0;
    const gap = 5.0;

    // Horizontal lines
    canvas.drawLine(
      Offset(center.dx - size, center.dy),
      Offset(center.dx - gap, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + size, center.dy),
      paint,
    );

    // Vertical lines
    canvas.drawLine(
      Offset(center.dx, center.dy - size),
      Offset(center.dx, center.dy - gap),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + size),
      paint,
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

    final focalLength = 500.0;
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

  void _drawConnection(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color,
    double depth, {
    bool isVisited = false,
    bool isFiltered = false,
  }) {
    final opacity = (1.0 - (depth / 500).clamp(0.0, 0.7)).clamp(0.3, 1.0);
    final visitedMultiplier = isVisited ? 1.0 : 0.5;
    final filteredMultiplier = isFiltered ? 0.2 : 1.0;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.3 * visitedMultiplier * filteredMultiplier)
      ..strokeWidth = isVisited ? 8.0 : 4.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(from, to, glowPaint);

    final linePaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.7 * visitedMultiplier * filteredMultiplier)
      ..strokeWidth = isVisited ? 3.0 : 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, linePaint);
  }

  void _drawDirectionIndicator(
    Canvas canvas,
    Offset position,
    Color color,
    bool isSelected,
  ) {
    final size = isSelected ? 24.0 : 16.0;

    // Outer glow
    if (isSelected) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(position, size + 5, glowPaint);
    }

    // Ring
    final ringPaint = Paint()
      ..color = isSelected ? Colors.white : color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 2.0;
    canvas.drawCircle(position, size, ringPaint);

    if (isSelected) {
      // Arrow indicator pointing up
      final arrowPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(position.dx, position.dy - size - 12)
        ..lineTo(position.dx - 8, position.dy - size - 4)
        ..lineTo(position.dx + 8, position.dy - size - 4)
        ..close();
      canvas.drawPath(path, arrowPaint);

      // "GO" text or similar indicator
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'GO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
      );
    }
  }

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
    final depthFactor = (500 / (500 + depth)).clamp(0.5, 1.5);
    final baseSize = 6.0 * depthFactor;
    final opacity = (1.0 - (depth / 500).clamp(0.0, 0.7)).clamp(0.4, 1.0);
    final visitedMultiplier = isVisited ? 1.0 : 0.4;

    if (isCurrentWalker) {
      // Current walker position - large pulsing indicator
      final walkerGlow = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(position, baseSize + 20, walkerGlow);

      final walkerRing = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawCircle(position, baseSize + 12, walkerRing);

      final innerRing = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(position, baseSize + 6, innerRing);
    } else if (isSelected) {
      final selectPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(position, baseSize + 6, selectPaint);

      final selectGlow = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(position, baseSize + 10, selectGlow);
    }

    if (isHighlighted && !isSelected && !isCurrentWalker) {
      final highlightPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(position, baseSize + 4, highlightPaint);
    }

    // Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.4 * visitedMultiplier)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(position, baseSize * 2, glowPaint);

    // Main node
    final nodePaint = Paint()
      ..color = color.withValues(alpha: opacity * visitedMultiplier)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, baseSize, nodePaint);

    // Inner highlight
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.7 * visitedMultiplier)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, baseSize * 0.4, innerPaint);

    // Draw node name if provided
    if (nodeName != null && nodeName.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: nodeName,
          style: TextStyle(
            color: Colors.white.withValues(alpha: opacity * visitedMultiplier * 0.9),
            fontSize: 9.0 * depthFactor,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          position.dx - textPainter.width / 2,
          position.dy + baseSize + 4,
        ),
      );
    }
  }

  Color _getRoleColor(int roleId) {
    switch (roleId) {
      case 0: return const Color(0xFFFF4444);
      case 1: return const Color(0xFF44FF44);
      case 2: return const Color(0xFF4444FF);
      case 3: return const Color(0xFFFF44FF);
      case 4: return const Color(0xFFFFFF44);
      case 5: return const Color(0xFF44FFFF);
      default: return Colors.white;
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

class _ClickableDirection {
  final int nodeId;
  final Offset screenPosition;
  final double radius;

  _ClickableDirection({
    required this.nodeId,
    required this.screenPosition,
    required this.radius,
  });
}
