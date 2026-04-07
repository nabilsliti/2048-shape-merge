import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'merge_detector.dart';
import 'spawn_manager.dart';

class JokerHandler {
  static const _uuid = Uuid();

  static ({List<GameShape> shapes, JokerInventory inventory, int scoreBonus})
      useBomb(
    GameShape target,
    List<GameShape> shapes,
    JokerInventory inventory,
  ) {
    if (inventory.countOf(JokerType.bomb) <= 0) {
      return (shapes: shapes, inventory: inventory, scoreBonus: 0);
    }

    final matching = MergeDetector.findMatchingShapes(target, shapes);
    final toRemove = {target.id, ...matching.map((s) => s.id)};
    final remaining = shapes.where((s) => !toRemove.contains(s.id)).toList();
    final bonus = toRemove.length * 10;

    return (
      shapes: remaining,
      inventory: inventory.use(JokerType.bomb),
      scoreBonus: bonus,
    );
  }

  static ({List<GameShape> shapes, JokerInventory inventory})
      spawnWildcard(
    List<GameShape> shapes,
    JokerInventory inventory,
    Size boardSize,
    int level,
  ) {
    if (inventory.countOf(JokerType.wildcard) <= 0) {
      return (shapes: shapes, inventory: inventory);
    }

    final pos = SpawnManager.spawnShape(shapes, boardSize);
    final wildcard = GameShape(
      id: _uuid.v4(),
      x: pos.x,
      y: pos.y,
      type: pos.type,
      color: const Color(0xFFFFFFFF),
      level: level,
      isWildcard: true,
    );

    return (
      shapes: [...shapes, wildcard],
      inventory: inventory.use(JokerType.wildcard),
    );
  }

  static ({List<GameShape> shapes, JokerInventory inventory, int scoreBonus})
      useReducer(
    GameShape target,
    List<GameShape> shapes,
    JokerInventory inventory,
  ) {
    if (inventory.countOf(JokerType.reducer) <= 0) {
      return (shapes: shapes, inventory: inventory, scoreBonus: 0);
    }

    if (target.level <= 1) {
      // Level 1 → disappears
      final remaining = shapes.where((s) => s.id != target.id).toList();
      return (
        shapes: remaining,
        inventory: inventory.use(JokerType.reducer),
        scoreBonus: 5,
      );
    }

    final updated = shapes.map((s) {
      if (s.id == target.id) {
        return s.copyWith(level: s.level - 1);
      }
      return s;
    }).toList();

    return (
      shapes: updated,
      inventory: inventory.use(JokerType.reducer),
      scoreBonus: 0,
    );
  }

  // ── Radar: finds all mergeable pairs ──────────────────────────
  static Set<String> findMergeablePairs(List<GameShape> shapes) {
    final result = <String>{};
    for (var i = 0; i < shapes.length; i++) {
      for (var j = i + 1; j < shapes.length; j++) {
        final a = shapes[i];
        final b = shapes[j];
        if (a.type == b.type &&
            a.color == b.color &&
            a.level == b.level &&
            !a.isWildcard &&
            !b.isWildcard) {
          result.add(a.id);
          result.add(b.id);
        }
      }
    }
    return result;
  }

  static JokerInventory useRadar(JokerInventory inventory) {
    if (inventory.countOf(JokerType.radar) <= 0) return inventory;
    return inventory.use(JokerType.radar);
  }

  // ── Evolution: upgrades a shape by one level ──────────────────
  static ({List<GameShape> shapes, JokerInventory inventory, int scoreBonus})
      useEvolution(
    GameShape target,
    List<GameShape> shapes,
    JokerInventory inventory,
  ) {
    if (inventory.countOf(JokerType.evolution) <= 0) {
      return (shapes: shapes, inventory: inventory, scoreBonus: 0);
    }

    final updated = shapes.map((s) {
      if (s.id == target.id) return s.copyWith(level: s.level + 1);
      return s;
    }).toList();

    return (
      shapes: updated,
      inventory: inventory.use(JokerType.evolution),
      scoreBonus: 0,
    );
  }

  // ── Mega Bomb: removes all shapes of the same level ───────────
  static ({List<GameShape> shapes, JokerInventory inventory, int scoreBonus})
      useMegaBomb(
    GameShape target,
    List<GameShape> shapes,
    JokerInventory inventory,
  ) {
    if (inventory.countOf(JokerType.megaBomb) <= 0) {
      return (shapes: shapes, inventory: inventory, scoreBonus: 0);
    }

    final toRemove =
        shapes.where((s) => s.level == target.level).map((s) => s.id).toSet();
    final remaining = shapes.where((s) => !toRemove.contains(s.id)).toList();
    final bonus = toRemove.length * 15;

    return (
      shapes: remaining,
      inventory: inventory.use(JokerType.megaBomb),
      scoreBonus: bonus,
    );
  }
}
