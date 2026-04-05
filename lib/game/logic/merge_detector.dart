import 'package:flutter/material.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/models/game_shape.dart';

class MergeDetector {
  static const List<Color> shapeColors = [
    Color(0xFF4FC3F7),
    Color(0xFF69F0AE),
    Color(0xFFCE93D8),
    Color(0xFFFFD54F),
  ];

  static bool canMerge(GameShape a, GameShape b) {
    if (a.id == b.id) return false;
    if (a.level != b.level) return false;
    if (a.level >= maxLevel) return false;
    if (a.isWildcard || b.isWildcard) return true;
    return a.type == b.type && a.color == b.color;
  }

  static bool hasPairs(List<GameShape> shapes) {
    for (var i = 0; i < shapes.length; i++) {
      for (var j = i + 1; j < shapes.length; j++) {
        if (canMerge(shapes[i], shapes[j])) return true;
      }
    }
    return false;
  }

  static int countPairs(List<GameShape> shapes) {
    var count = 0;
    final used = <int>{};
    for (var i = 0; i < shapes.length; i++) {
      if (used.contains(i)) continue;
      for (var j = i + 1; j < shapes.length; j++) {
        if (used.contains(j)) continue;
        if (canMerge(shapes[i], shapes[j])) {
          count++;
          used.addAll([i, j]);
          break;
        }
      }
    }
    return count;
  }

  static GameShape? findBestTarget(
    GameShape dragged,
    List<GameShape> shapes,
    Offset dragPosition,
  ) {
    GameShape? best;
    var bestDist = double.infinity;
    for (final shape in shapes) {
      if (shape.id == dragged.id) continue;
      if (!canMerge(dragged, shape)) continue;
      final dx = dragPosition.dx - shape.x;
      final dy = dragPosition.dy - shape.y;
      final dist = (dx * dx + dy * dy);
      if (dist < snapRadius * snapRadius && dist < bestDist) {
        bestDist = dist;
        best = shape;
      }
    }
    return best;
  }

  static List<GameShape> findMatchingShapes(
    GameShape target,
    List<GameShape> shapes,
  ) {
    return shapes
        .where((s) =>
            s.id != target.id &&
            s.type == target.type &&
            s.color == target.color)
        .toList();
  }
}
