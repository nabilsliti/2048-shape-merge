import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/shape_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/game/logic/joker_handler.dart';

void main() {
  group('JokerHandler', () {
    final target = GameShape(
      id: 'target', x: 100, y: 100,
      type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 2,
    );
    final sameTypeColorLevel = GameShape(
      id: 'same', x: 200, y: 200,
      type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 2,
    );
    final sameTypeColorDiffLevel = GameShape(
      id: 'samediff', x: 250, y: 250,
      type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 3,
    );
    final different = GameShape(
      id: 'diff', x: 300, y: 300,
      type: ShapeType.square, color: const Color(0xFF69F0AE), level: 1,
    );
    final inventory = const JokerInventory(bomb: 2, wildcard: 2, reducer: 2);

    group('bomb', () {
      test('removes shapes of same type+color+level', () {
        final shapes = [target, sameTypeColorLevel, different];
        final result = JokerHandler.useBomb(target, shapes, inventory);

        expect(result.shapes.length, 1);
        expect(result.shapes.first.id, 'diff');
        expect(result.inventory.bomb, 1);
        expect(result.scoreBonus, greaterThan(0));
      });

      test('removes same type+color regardless of level', () {
        final shapes = [target, sameTypeColorDiffLevel, different];
        final result = JokerHandler.useBomb(target, shapes, inventory);

        // Bomb removes all shapes with matching type+color, ignoring level
        // (matches the user-facing description "quel que soit leur niveau").
        expect(result.shapes.length, 1);
        expect(result.shapes.first.id, 'diff');
      });

      test('does nothing with 0 bombs', () {
        final shapes = [target, sameTypeColorLevel];
        const empty = JokerInventory(bomb: 0, wildcard: 0, reducer: 0);
        final result = JokerHandler.useBomb(target, shapes, empty);

        expect(result.shapes.length, 2);
        expect(result.inventory.bomb, 0);
      });
    });

    group('reducer', () {
      test('decreases level by 1', () {
        final shapes = [target, different];
        final result = JokerHandler.useReducer(target, shapes, inventory);

        final reduced = result.shapes.firstWhere((s) => s.id == 'target');
        expect(reduced.level, 1);
        expect(result.inventory.reducer, 1);
      });

      test('removes shape at level 1', () {
        final level1 = GameShape(
          id: 'l1', x: 0, y: 0,
          type: ShapeType.star, color: const Color(0xFFCE93D8), level: 1,
        );
        final shapes = [level1, different];
        final result = JokerHandler.useReducer(level1, shapes, inventory);

        expect(result.shapes.length, 1);
        expect(result.shapes.first.id, 'diff');
      });

      test('does nothing with 0 reducers', () {
        const empty = JokerInventory(bomb: 0, wildcard: 0, reducer: 0);
        final shapes = [target];
        final result = JokerHandler.useReducer(target, shapes, empty);
        expect(result.shapes.first.level, 2);
        expect(result.scoreBonus, 0);
      });
    });

    group('bomb (extra cases)', () {
      test('never destroys wildcards even if type/color match', () {
        final wildcard = GameShape(
          id: 'wild', x: 0, y: 0,
          type: target.type, color: target.color, level: target.level,
          isWildcard: true,
        );
        final shapes = [target, wildcard, sameTypeColorLevel];
        final result = JokerHandler.useBomb(target, shapes, inventory);
        expect(result.shapes.any((s) => s.id == 'wild'), true,
            reason: 'wildcard must survive bomb');
      });

      test('a wildcard target removes only itself (no type/color match)', () {
        final wildcardTarget = GameShape(
          id: 'wt', x: 0, y: 0,
          type: ShapeType.star, color: const Color(0xFFFFFFFF),
          level: 1, isWildcard: true,
        );
        final shapes = [wildcardTarget, target, sameTypeColorLevel];
        final result = JokerHandler.useBomb(wildcardTarget, shapes, inventory);
        // Only the wildcard target itself is removed (the target.id branch)
        expect(result.shapes.any((s) => s.id == 'wt'), false);
        expect(result.shapes.length, 2);
      });
    });

    group('wildcard spawn', () {
      test('adds an isWildcard shape and decrements counter', () {
        const inv = JokerInventory(bomb: 0, wildcard: 2, reducer: 0);
        final result = JokerHandler.spawnWildcard(
          [], inv, const Size(400, 600), 1,
        );
        expect(result.shapes.length, 1);
        expect(result.shapes.first.isWildcard, true);
        expect(result.shapes.first.level, 1);
        expect(result.inventory.wildcard, 1);
      });

      test('does nothing without wildcards in inventory', () {
        const inv = JokerInventory(bomb: 0, wildcard: 0, reducer: 0);
        final result = JokerHandler.spawnWildcard(
          [target], inv, const Size(400, 600), 1,
        );
        expect(result.shapes.length, 1);
        expect(result.inventory.wildcard, 0);
      });
    });

    group('evolution', () {
      test('increments target level and returns evolved shape', () {
        const inv = JokerInventory(evolution: 2);
        final shapes = [target, different];
        final result = JokerHandler.useEvolution(target, shapes, inv);
        expect(result.evolvedShape, isNotNull);
        expect(result.evolvedShape!.level, target.level + 1);
        expect(result.scoreBonus, greaterThan(0));
        expect(result.inventory.evolution, 1);
        // The shape with id=target.id has been bumped
        final updated = result.shapes.firstWhere((s) => s.id == 'target');
        expect(updated.level, target.level + 1);
      });

      test('does nothing without evolution charges', () {
        const inv = JokerInventory(evolution: 0);
        final shapes = [target];
        final result = JokerHandler.useEvolution(target, shapes, inv);
        expect(result.evolvedShape, isNull);
        expect(result.scoreBonus, 0);
        expect(result.shapes.first.level, target.level);
      });
    });

    group('megaBomb', () {
      test('removes every shape that shares the level with the target', () {
        final lvl2a = GameShape(
          id: 'l2a', x: 0, y: 0,
          type: ShapeType.square, color: const Color(0xFFFFFFFF), level: 2,
        );
        final lvl2b = GameShape(
          id: 'l2b', x: 1, y: 1,
          type: ShapeType.star, color: const Color(0xFF000000), level: 2,
        );
        final lvl1 = GameShape(
          id: 'l1', x: 0, y: 0,
          type: ShapeType.circle, color: const Color(0xFF000000), level: 1,
        );
        const inv = JokerInventory(megaBomb: 1);
        // target = lvl2a (level 2). Should remove l2a + l2b + target (level 2)
        final result = JokerHandler.useMegaBomb(lvl2a, [target, lvl2a, lvl2b, lvl1], inv);
        // target itself is level 2 → also removed; l1 stays
        expect(result.shapes.map((s) => s.id).toSet(), {'l1'});
        expect(result.scoreBonus, 3 * JokerBonusTuning.megaBombBonusPerShape);
        expect(result.inventory.megaBomb, 0);
      });

      test('does nothing without mega bombs', () {
        const inv = JokerInventory(megaBomb: 0);
        final result = JokerHandler.useMegaBomb(target, [target, sameTypeColorLevel], inv);
        expect(result.shapes.length, 2);
        expect(result.scoreBonus, 0);
      });
    });

    group('radar (findMergeablePairs)', () {
      test('groups same type+color+level into one cluster', () {
        final groups = JokerHandler.findMergeablePairs([
          target, sameTypeColorLevel, different,
        ]);
        // target & sameTypeColorLevel are mergeable → same group; different alone.
        expect(groups.length, 2);
        expect(groups['target'], groups['same']);
        expect(groups.containsKey('diff'), false);
      });

      test('no group with all distinct shapes', () {
        final groups = JokerHandler.findMergeablePairs([target, different]);
        expect(groups, isEmpty);
      });

      test('wildcards never participate in pair groups', () {
        final wildcard = GameShape(
          id: 'wild', x: 0, y: 0,
          type: target.type, color: target.color, level: target.level,
          isWildcard: true,
        );
        final groups = JokerHandler.findMergeablePairs([target, wildcard]);
        expect(groups, isEmpty);
      });

      test('useRadar decrements only when a charge is available', () {
        const noCharge = JokerInventory(radar: 0);
        expect(JokerHandler.useRadar(noCharge).radar, 0);
        const oneCharge = JokerInventory(radar: 1);
        expect(JokerHandler.useRadar(oneCharge).radar, 0);
      });
    });
  });
}
