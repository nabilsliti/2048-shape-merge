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

    // 70% smart until 25 shapes, then drops to 50%
    final smartChance = existing.length >= 25 ? 0.50 : smartSpawnChance;

    if (existing.isNotEmpty && _random.nextDouble() < smartChance) {
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
    final types = List<ShapeType>.of(ShapeType.values)..shuffle(_random);
    final colors = List<Color>.of(MergeDetector.shapeColors)..shuffle(_random);

    // Spawn pairs — round-robin through types and colors for variety
    for (var i = 0; i < startShapes ~/ 2; i++) {
      final type = types[i % types.length];
      final color = colors[i % colors.length];
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
    final margin = size / 2 + 8;
    final minGap = 8.0;

    // Phase 1: try random positions with comfortable gap
    for (var attempt = 0; attempt < maxSpawnAttempts; attempt++) {
      final x = margin + _random.nextDouble() * (boardSize.width - 2 * margin);
      final y = margin + _random.nextDouble() * (boardSize.height - 2 * margin);

      var hasOverlap = false;
      for (final shape in existing) {
        final otherSize = shapeSize(shape.level);
        final minDist = (size + otherSize) / 2 + 12;
        final dx = x - shape.x;
        final dy = y - shape.y;
        if (dx * dx + dy * dy < minDist * minDist) {
          hasOverlap = true;
          break;
        }
      }
      if (!hasOverlap) return Offset(x, y);
    }

    // Phase 2: grid scan to find the least overlapping spot
    const gridSteps = 16;
    final stepX = (boardSize.width - 2 * margin) / gridSteps;
    final stepY = (boardSize.height - 2 * margin) / gridSteps;
    Offset bestPos = Offset(boardSize.width / 2, boardSize.height / 2);
    double bestMinDist = double.negativeInfinity;

    for (var gx = 0; gx <= gridSteps; gx++) {
      for (var gy = 0; gy <= gridSteps; gy++) {
        final x = margin + gx * stepX;
        final y = margin + gy * stepY;
        double closestDist = double.infinity;

        for (final shape in existing) {
          final otherSize = shapeSize(shape.level);
          final dx = x - shape.x;
          final dy = y - shape.y;
          final dist = (dx * dx + dy * dy) - ((size + otherSize) / 2 + minGap) * ((size + otherSize) / 2 + minGap);
          if (dist < closestDist) closestDist = dist;
        }

        if (closestDist > bestMinDist) {
          bestMinDist = closestDist;
          bestPos = Offset(x, y);
        }
      }
    }

    return bestPos;
  }
}
