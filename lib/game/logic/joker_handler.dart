import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
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
      color: Colors.white,
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

  // ── Radar: finds all mergeable pairs, grouped by merge-compatibility ──
  static Map<String, int> findMergeablePairs(List<GameShape> shapes) {
    // Union-Find to group all mutually mergeable shapes
    final parent = <String, String>{};
    for (final s in shapes) {
      parent[s.id] = s.id;
    }
    String find(String x) {
      while (parent[x] != x) {
        parent[x] = parent[parent[x]!]!;
        x = parent[x]!;
      }
      return x;
    }
    void union(String a, String b) {
      parent[find(a)] = find(b);
    }

    for (var i = 0; i < shapes.length; i++) {
      for (var j = i + 1; j < shapes.length; j++) {
        final a = shapes[i];
        final b = shapes[j];
        if (a.type == b.type &&
            a.color == b.color &&
            a.level == b.level &&
            !a.isWildcard &&
            !b.isWildcard) {
          union(a.id, b.id);
        }
      }
    }

    // Collect groups (only roots that have >1 member)
    final groups = <String, List<String>>{};
    for (final s in shapes) {
      final root = find(s.id);
      groups.putIfAbsent(root, () => []).add(s.id);
    }

    // Assign group index only to shapes that have at least one pair
    final result = <String, int>{};
    var groupIdx = 0;
    for (final entry in groups.entries) {
      if (entry.value.length < 2) continue;
      for (final id in entry.value) {
        result[id] = groupIdx;
      }
      groupIdx++;
    }
    return result;
  }

  static JokerInventory useRadar(JokerInventory inventory) {
    if (inventory.countOf(JokerType.radar) <= 0) return inventory;
    return inventory.use(JokerType.radar);
  }

  // ── Evolution: upgrades a shape by one level ──────────────────
  static ({List<GameShape> shapes, JokerInventory inventory, int scoreBonus, GameShape? evolvedShape})
      useEvolution(
    GameShape target,
    List<GameShape> shapes,
    JokerInventory inventory,
  ) {
    if (inventory.countOf(JokerType.evolution) <= 0) {
      return (shapes: shapes, inventory: inventory, scoreBonus: 0, evolvedShape: null);
    }

    final newLevel = target.level + 1;
    final bonus = scoreForMerge(newLevel);
    GameShape? evolved;
    final updated = shapes.map((s) {
      if (s.id == target.id) {
        evolved = s.copyWith(level: newLevel);
        return evolved!;
      }
      return s;
    }).toList();

    return (
      shapes: updated,
      inventory: inventory.use(JokerType.evolution),
      scoreBonus: bonus,
      evolvedShape: evolved,
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
