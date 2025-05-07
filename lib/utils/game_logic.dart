import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:verse/utils/constants.dart';
import 'dart:math';

enum SnakeDirection { none, up, down, left, right }

class GameLogic {
  List<vector.Vector3> snakePositions = [];
  SnakeDirection currentDirection = SnakeDirection.right;
  SnakeDirection nextDirection = SnakeDirection.right;
  vector.Vector3 foodPosition = vector.Vector3.zero();
  double segmentSize = GameConstants.snakeSegmentSize;
  double foodSize = GameConstants.foodSize;
  double lastMoveTime = 0;
  bool isGameOver = false;
  final int initialLength;
  final double snakeSpeed = GameConstants.snakeSpeed;
  Function(vector.Vector3) spawnFoodCallback;
  bool Function(vector.Vector3) checkCollisionCallback;
  Function(List<vector.Vector3>) moveSnakeNodesCallback;

  GameLogic({
    required this.initialLength,
    required this.segmentSize,
    required this.foodSize,
    required this.spawnFoodCallback,
    required this.checkCollisionCallback,
    required this.moveSnakeNodesCallback,
  });

  void initialize({
    required int initialLength,
    required double segmentSize,
    required double foodSize,
    required Function(vector.Vector3) spawnFood,
    required bool Function(vector.Vector3) checkCollision,
    required Function(List<vector.Vector3>) moveSnakeNodes,
  }) {
    snakePositions.clear();
    currentDirection = SnakeDirection.right;
    nextDirection = SnakeDirection.right;
    isGameOver = false;
    this.segmentSize = segmentSize;
    this.foodSize = foodSize;
    spawnFoodCallback = spawnFood;
    checkCollisionCallback = checkCollision;
    moveSnakeNodesCallback = moveSnakeNodes;

    // Initial snake positioning (starting from origin, moving right)
    for (int i = 0; i < initialLength; i++) {
      snakePositions.add(
        vector.Vector3(-i * segmentSize, 0, -0.5),
      ); // Slightly offset in Z for better AR visibility
    }
    _spawnInitialFood();
    moveSnakeNodesCallback(snakePositions);
  }

  void _spawnInitialFood() {
    final random = Random();
    const spawnRadius = 0.5; // Adjust the spawn radius as needed
    final x = (random.nextDouble() * 2 - 1) * spawnRadius;
    final y = (random.nextDouble() * 2 - 1) * spawnRadius;
    foodPosition.setValues(
      x,
      y,
      -0.5,
    ); // Keep food on the same Z-plane as the snake
    spawnFoodCallback(foodPosition);
  }

  bool update(double deltaTime, SnakeDirection swipeDirection) {
    if (isGameOver) return false;

    // Handle swipe direction
    if (swipeDirection != SnakeDirection.none) {
      nextDirection = swipeDirection;
    }

    final timeSinceLastMove =
        DateTime.now().millisecondsSinceEpoch / 1000 - lastMoveTime;
    if (timeSinceLastMove >= snakeSpeed) {
      lastMoveTime = DateTime.now().millisecondsSinceEpoch / 1000;
      _moveSnake();
      return _checkFoodCollision();
    }
    return false;
  }

  void _moveSnake() {
    // Update direction if a valid change is requested
    if (nextDirection != currentDirection) {
      if ((currentDirection == SnakeDirection.up &&
              nextDirection != SnakeDirection.down) ||
          (currentDirection == SnakeDirection.down &&
              nextDirection != SnakeDirection.up) ||
          (currentDirection == SnakeDirection.left &&
              nextDirection != SnakeDirection.right) ||
          (currentDirection == SnakeDirection.right &&
              nextDirection != SnakeDirection.left)) {
        currentDirection = nextDirection;
      }
    }

    // Calculate new head position
    final headPosition = snakePositions.first.clone();
    switch (currentDirection) {
      case SnakeDirection.up:
        headPosition.y += segmentSize;
        break;
      case SnakeDirection.down:
        headPosition.y -= segmentSize;
        break;
      case SnakeDirection.left:
        headPosition.x -= segmentSize;
        break;
      case SnakeDirection.right:
        headPosition.x += segmentSize;
        break;
      case SnakeDirection.none:
        return;
    }

    // Move the snake body
    for (int i = snakePositions.length - 1; i > 0; i--) {
      snakePositions[i].setFrom(snakePositions[i - 1]);
    }
    snakePositions[0].setFrom(headPosition);

    // Check for self-collision
    if (checkCollisionCallback(headPosition)) {
      isGameOver = true;
    }

    // Notify AR view to update node positions
    moveSnakeNodesCallback(snakePositions);
  }

  bool _checkFoodCollision() {
    if ((snakePositions.first - foodPosition).length <
        (segmentSize / 2 + foodSize / 2)) {
      _growSnake();
      _spawnNewFood();
      return true;
    }
    return false;
  }

  void _growSnake() {
    final lastSegment = snakePositions.last;
    snakePositions.add(lastSegment.clone()); // Add a new segment at the end
    moveSnakeNodesCallback(
      snakePositions,
    ); // Update AR view with the new segment
  }

  void _spawnNewFood() {
    final random = Random();
    const spawnRadius = 0.6;
    vector.Vector3 newFoodPosition;
    bool collision;
    int attempts = 0;
    const maxAttempts = 10;

    do {
      final x = (random.nextDouble() * 2 - 1) * spawnRadius;
      final y = (random.nextDouble() * 2 - 1) * spawnRadius;
      newFoodPosition = vector.Vector3(x, y, -0.5);
      collision = false;
      for (final segment in snakePositions) {
        if ((newFoodPosition - segment).length < segmentSize) {
          collision = true;
          break;
        }
      }
      attempts++;
      if (attempts > maxAttempts) {
        // Fallback in case we can't find a non-colliding position
        newFoodPosition.setFrom(vector.Vector3(0.5, 0.5, -0.5));
        collision = false;
        break;
      }
    } while (collision);

    foodPosition.setFrom(newFoodPosition);
    spawnFoodCallback(foodPosition);
  }
}
