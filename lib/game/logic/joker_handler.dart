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
      level: shapes.isNotEmpty ? shapes.first.level : 1,
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
}
