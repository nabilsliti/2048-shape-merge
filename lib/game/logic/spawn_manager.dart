import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/constants/shape_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'merge_detector.dart';

class SpawnManager {
  static const _uuid = Uuid();
  static final _random = Random();

  static GameShape spawnShape(
    List<GameShape> existing,
    Size boardSize,
  ) {
    ShapeType type;
    Color color;
    int level;

    if (existing.isNotEmpty && _random.nextDouble() < smartSpawnChance) {
      final template = existing[_random.nextInt(existing.length)];
      type = template.type;
      color = template.color;
      level = (_random.nextDouble() < levelCopyChance) ? template.level : 1;
    } else {
      type = ShapeType.values[_random.nextInt(ShapeType.values.length)];
      color = MergeDetector.shapeColors[
          _random.nextInt(MergeDetector.shapeColors.length)];
      level = 1;
    }

    final pos = _findFreePosition(existing, boardSize, shapeSize(level));
    return GameShape(
      id: _uuid.v4(),
      x: pos.dx,
      y: pos.dy,
      type: type,
      color: color,
      level: level,
    );
  }

  static List<GameShape> spawnInitialShapes(Size boardSize) {
    final shapes = <GameShape>[];
    // Spawn pairs to guarantee merges
    for (var i = 0; i < startShapes ~/ 2; i++) {
      final type = ShapeType.values[_random.nextInt(ShapeType.values.length)];
      final color = MergeDetector.shapeColors[
          _random.nextInt(MergeDetector.shapeColors.length)];
      const level = 1;

      for (var j = 0; j < 2; j++) {
        final pos = _findFreePosition(shapes, boardSize, shapeSize(level));
        shapes.add(GameShape(
          id: _uuid.v4(),
          x: pos.dx,
          y: pos.dy,
          type: type,
          color: color,
          level: level,
        ));
      }
    }
    return shapes;
  }

  static Offset _findFreePosition(
    List<GameShape> existing,
    Size boardSize,
    double size,
  ) {
    final margin = size / 2 + 4;
    for (var attempt = 0; attempt < maxSpawnAttempts; attempt++) {
      final x = margin + _random.nextDouble() * (boardSize.width - 2 * margin);
      final y =
          margin + _random.nextDouble() * (boardSize.height - 2 * margin);

      var hasOverlap = false;
      for (final shape in existing) {
        final otherSize = shapeSize(shape.level);
        final minDist = (size + otherSize) / 2 + 4;
        final dx = x - shape.x;
        final dy = y - shape.y;
        if (dx * dx + dy * dy < minDist * minDist) {
          hasOverlap = true;
          break;
        }
      }
      if (!hasOverlap) return Offset(x, y);
    }
    // Fallback: random position
    return Offset(
      margin + _random.nextDouble() * (boardSize.width - 2 * margin),
      margin + _random.nextDouble() * (boardSize.height - 2 * margin),
    );
  }
}
