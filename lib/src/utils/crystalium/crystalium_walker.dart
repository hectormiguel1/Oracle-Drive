import 'dart:math' as math;
import 'package:oracle_drive/models/crystalium/mcp_file.dart';
import 'package:oracle_drive/src/utils/crystalium/crystalium_renderer.dart';

/// State of the Crystarium walker.
enum WalkerState {
  /// Stopped at a node, waiting for input
  idle,

  /// Moving between nodes
  moving,

  /// At a branch point, selecting direction
  selecting,
}

/// Direction info for navigation choices.
class WalkerDirection {
  final int nodeId;
  final Vector3 position;
  final int stage;
  final int roleId;
  final double angle; // Angle from current node for UI display

  WalkerDirection({
    required this.nodeId,
    required this.position,
    required this.stage,
    required this.roleId,
    required this.angle,
  });
}

/// Handles walking/navigation through the Crystarium tree.
class CrystariumWalker {
  final CrystariumRenderer renderer;

  // State
  WalkerState _state = WalkerState.idle;
  int _currentNodeId = 0;
  int _targetNodeId = 0;
  double _transitionProgress = 0.0;

  // Movement settings
  double movementSpeed = 80.0; // Units per second

  // Camera offset from current position
  Vector3 cameraOffset = Vector3(0, 30, 60);

  // Available directions at current node
  List<WalkerDirection> _availableDirections = [];
  int _selectedDirectionIndex = 0;

  // Adjacency map for navigation
  late Map<int, List<int>> _adjacency;

  // Visited nodes (for visual feedback)
  final Set<int> visitedNodes = {0};

  CrystariumWalker(this.renderer) {
    _adjacency = renderer.buildAdjacencyList();
    _updateAvailableDirections();
  }

  // Getters
  WalkerState get state => _state;
  int get currentNodeId => _currentNodeId;
  int get targetNodeId => _targetNodeId;
  double get transitionProgress => _transitionProgress;
  List<WalkerDirection> get availableDirections => _availableDirections;
  int get selectedDirectionIndex => _selectedDirectionIndex;

  /// Get the current world position (interpolated during movement).
  Vector3 get currentPosition {
    if (_state == WalkerState.moving) {
      final fromPos =
          renderer.nodeWorldPositions[_currentNodeId] ?? Vector3(0, 0, 0);
      final toPos =
          renderer.nodeWorldPositions[_targetNodeId] ?? Vector3(0, 0, 0);
      final t = _easeInOutCubic(_transitionProgress);
      return Vector3(
        fromPos.x + (toPos.x - fromPos.x) * t,
        fromPos.y + (toPos.y - fromPos.y) * t,
        fromPos.z + (toPos.z - fromPos.z) * t,
      );
    }
    return renderer.nodeWorldPositions[_currentNodeId] ?? Vector3(0, 0, 0);
  }

  /// Get the camera position based on current position and offset.
  Vector3 get cameraPosition {
    final pos = currentPosition;
    return Vector3(
      pos.x + cameraOffset.x,
      pos.y + cameraOffset.y,
      pos.z + cameraOffset.z,
    );
  }

  /// Get the look target (slightly ahead during movement).
  Vector3 get lookTarget {
    if (_state == WalkerState.moving) {
      // Look ahead towards target
      final targetPos =
          renderer.nodeWorldPositions[_targetNodeId] ?? Vector3(0, 0, 0);
      final currentPos = currentPosition;
      // Blend between current and target
      return Vector3(
        currentPos.x + (targetPos.x - currentPos.x) * 0.5,
        currentPos.y + (targetPos.y - currentPos.y) * 0.5,
        currentPos.z + (targetPos.z - currentPos.z) * 0.5,
      );
    }
    return currentPosition;
  }

  /// Update the walker state (call every frame with delta time).
  void update(double deltaTime) {
    switch (_state) {
      case WalkerState.idle:
        // Already at destination, check if we should auto-enter selection
        if (_availableDirections.length > 1) {
          _state = WalkerState.selecting;
        }
        break;

      case WalkerState.moving:
        _updateMovement(deltaTime);
        break;

      case WalkerState.selecting:
        // Wait for user input
        break;
    }
  }

  void _updateMovement(double deltaTime) {
    final fromPos = renderer.nodeWorldPositions[_currentNodeId];
    final toPos = renderer.nodeWorldPositions[_targetNodeId];

    if (fromPos == null || toPos == null) {
      _arriveAtNode(_targetNodeId);
      return;
    }

    final dx = toPos.x - fromPos.x;
    final dy = toPos.y - fromPos.y;
    final dz = toPos.z - fromPos.z;
    final distance = math.sqrt(dx * dx + dy * dy + dz * dz);

    if (distance < 0.01) {
      _arriveAtNode(_targetNodeId);
      return;
    }

    // Advance progress
    _transitionProgress += (movementSpeed * deltaTime) / distance;

    if (_transitionProgress >= 1.0) {
      _arriveAtNode(_targetNodeId);
    }
  }

  void _arriveAtNode(int nodeId) {
    _currentNodeId = nodeId;
    _targetNodeId = nodeId;
    _transitionProgress = 0.0;
    visitedNodes.add(nodeId);
    _updateAvailableDirections();

    if (_availableDirections.isEmpty) {
      _state = WalkerState.idle;
    } else if (_availableDirections.length == 1) {
      // Auto-select if only one direction (but don't auto-move)
      _state = WalkerState.idle;
      _selectedDirectionIndex = 0;
    } else {
      _state = WalkerState.selecting;
      _selectedDirectionIndex = 0;
    }
  }

  void _updateAvailableDirections() {
    _availableDirections = [];
    final neighbors = _adjacency[_currentNodeId] ?? [];
    final currentPos =
        renderer.nodeWorldPositions[_currentNodeId] ?? Vector3(0, 0, 0);

    for (final neighborId in neighbors) {
      final neighborPos = renderer.nodeWorldPositions[neighborId];
      if (neighborPos == null) continue;

      final info = renderer.nodeInfo[neighborId];

      // Calculate angle for UI display
      final dx = neighborPos.x - currentPos.x;
      final dz = neighborPos.z - currentPos.z;
      final angle = math.atan2(dz, dx);

      _availableDirections.add(
        WalkerDirection(
          nodeId: neighborId,
          position: neighborPos,
          stage: info?.stage ?? 1,
          roleId: info?.roleId ?? 0,
          angle: angle,
        ),
      );
    }

    // Sort by angle for consistent ordering
    _availableDirections.sort((a, b) => a.angle.compareTo(b.angle));
  }

  /// Move to the next node in the given direction index.
  bool moveToDirection(int directionIndex) {
    if (directionIndex < 0 || directionIndex >= _availableDirections.length) {
      return false;
    }

    final direction = _availableDirections[directionIndex];
    return moveToNode(direction.nodeId);
  }

  /// Move to a specific node (must be adjacent).
  bool moveToNode(int nodeId) {
    final neighbors = _adjacency[_currentNodeId] ?? [];
    if (!neighbors.contains(nodeId)) {
      return false;
    }

    _targetNodeId = nodeId;
    _transitionProgress = 0.0;
    _state = WalkerState.moving;
    return true;
  }

  /// Select the next direction (cycle through available).
  void selectNextDirection() {
    if (_availableDirections.isEmpty) return;
    _selectedDirectionIndex =
        (_selectedDirectionIndex + 1) % _availableDirections.length;
  }

  /// Select the previous direction (cycle through available).
  void selectPreviousDirection() {
    if (_availableDirections.isEmpty) return;
    _selectedDirectionIndex =
        (_selectedDirectionIndex - 1 + _availableDirections.length) %
        _availableDirections.length;
  }

  /// Confirm the current selection and start moving.
  bool confirmSelection() {
    if (_state != WalkerState.selecting && _state != WalkerState.idle) {
      return false;
    }
    if (_availableDirections.isEmpty) {
      return false;
    }
    return moveToDirection(_selectedDirectionIndex);
  }

  /// Move back to parent node.
  bool moveToParent() {
    final node = renderer.cgtFile.getNode(_currentNodeId);
    if (node == null || node.parentIndex < 0) {
      return false;
    }
    return moveToNode(node.parentIndex);
  }

  /// Reset to starting position (root).
  void reset() {
    _currentNodeId = 0;
    _targetNodeId = 0;
    _transitionProgress = 0.0;
    _state = WalkerState.idle;
    _selectedDirectionIndex = 0;
    visitedNodes.clear();
    visitedNodes.add(0);
    _updateAvailableDirections();

    if (_availableDirections.length > 1) {
      _state = WalkerState.selecting;
    }
  }

  /// Jump directly to a node (for editing purposes).
  void jumpToNode(int nodeId) {
    if (!renderer.nodeWorldPositions.containsKey(nodeId)) return;

    _currentNodeId = nodeId;
    _targetNodeId = nodeId;
    _transitionProgress = 0.0;
    _state = WalkerState.idle;
    visitedNodes.add(nodeId);
    _updateAvailableDirections();

    if (_availableDirections.length > 1) {
      _state = WalkerState.selecting;
    }
  }

  /// Check if a node has been visited.
  bool isVisited(int nodeId) => visitedNodes.contains(nodeId);

  /// Smooth easing function.
  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
  }
}
