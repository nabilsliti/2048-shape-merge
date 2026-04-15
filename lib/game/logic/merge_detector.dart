import 'package:flutter/material.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

class MergeDetector {
  static List<Color> get shapeColors => AppTheme.levelColors;

  static bool canMerge(GameShape a, GameShape b) {
    if (a.id == b.id) return false;
    if (a.level != b.level) return false;
    if (a.isWildcard || b.isWildcard) return true;
    return a.type == b.type && a.color == b.color;
  }

  static bool hasPairs(List<GameShape> shapes) {
    // O(n): group non-wildcard shapes by (level, type, color).
    // If any group has 2+, or any wildcard exists with another shape at the
    // same level, there's a pair.
    final groups = <int, Map<Object, int>>{};
    final wildcardCounts = <int, int>{};
    for (final s in shapes) {
      if (s.isWildcard) {
        final c = (wildcardCounts[s.level] ?? 0) + 1;
        wildcardCounts[s.level] = c;
        if (c >= 2) return true;
        continue;
      }
      final levelMap = groups.putIfAbsent(s.level, () => {});
      final key = Object.hash(s.type, s.color);
      final count = (levelMap[key] ?? 0) + 1;
      levelMap[key] = count;
      if (count >= 2) return true;
    }
    // A wildcard merges with any shape of the same level.
    for (final wLevel in wildcardCounts.keys) {
      if (groups.containsKey(wLevel)) return true;
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
      if (dist < BoardTuning.snapRadius * BoardTuning.snapRadius && dist < bestDist) {
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
