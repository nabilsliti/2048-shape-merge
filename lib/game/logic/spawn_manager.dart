import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/constants/shape_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'merge_detector.dart';

class SpawnManager {
  static const _uuid = Uuid();
  static final _random = Random();

  static GameShape spawnShape(
    List<GameShape> existing,
    Size boardSize, {
    double mergeRate = 0.5,
    int totalMerges = 999,
  }) {
    ShapeType type;
    Color color;
    int level;

    // Adaptive smart chance: high merge rate → harder (less smart); low → easier (more smart)
    // Board pressure: ≥pressureThreshold shapes always reduces smart chance
    final double adaptiveChance = mergeRate > 0.7
        ? SpawnTuning.chanceWhenHighMergeRate
        : mergeRate > 0.5
            ? SpawnTuning.chanceWhenMedHighMergeRate
            : mergeRate > 0.3
                ? SpawnTuning.chanceWhenMedLowMergeRate
                : SpawnTuning.chanceWhenLowMergeRate;
    final smartChance = existing.length >= SpawnTuning.pressureThreshold
        ? adaptiveChance.clamp(0.0, SpawnTuning.pressureCap)
        : adaptiveChance;

    if (existing.isNotEmpty && _random.nextDouble() < smartChance) {
      // For beginners (< 20 total merges), prefer spawning a shape that already
      // has a matching partner on the board (same type+color) so they can merge.
      final bool isBeginner = totalMerges < SpawnTuning.beginnerMergeLimit;
      GameShape template;

      if (isBeginner) {
        // Find shapes that have at least one matching partner on the board
        final mergeable = existing.where((s) =>
          existing.any((other) =>
            other.id != s.id &&
            other.type == s.type &&
            other.color == s.color &&
            other.level == s.level
          )
        ).toList();
        template = mergeable.isNotEmpty
            ? mergeable[_random.nextInt(mergeable.length)]
            : existing[_random.nextInt(existing.length)];
      } else {
        // Prefer "orphan" shapes — those with exactly 1 partner (same type+color+level).
        // Creating a 2nd match gives the player a new pair without stacking triples.
        final orphans = existing.where((s) {
          final partners = existing.where((o) =>
            o.id != s.id &&
            o.type == s.type &&
            o.color == s.color &&
            o.level == s.level
          ).length;
          return partners == 1;
        }).toList();
        // Fallback: shapes with 0 partners (creates a new pair)
        final solos = orphans.isEmpty
            ? existing.where((s) {
                final partners = existing.where((o) =>
                  o.id != s.id &&
                  o.type == s.type &&
                  o.color == s.color &&
                  o.level == s.level
                ).length;
                return partners == 0;
              }).toList()
            : <GameShape>[];
        final candidates = orphans.isNotEmpty
            ? orphans
            : solos.isNotEmpty
                ? solos
                : existing;
        template = candidates[_random.nextInt(candidates.length)];
      }

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
    final halfSize = size / 2;
    final margin = halfSize + 8; // S'assurer qu'aucune forme ne déborde
    const minGap = 8.0;

    // Phase 1: try random positions with comfortable gap
    for (var attempt = 0; attempt < maxSpawnAttempts; attempt++) {
      final x = margin + _random.nextDouble() * (boardSize.width - 2 * margin);
      final y = margin + _random.nextDouble() * (boardSize.height - 2 * margin);

      var hasOverlap = false;
      for (final shape in existing) {
        final otherSize = shapeSize(shape.level);
        final minDist = (size + otherSize) / 2 + SpawnTuning.minSpawnGap;
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
    const gridSteps = SpawnTuning.gridSteps;
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
