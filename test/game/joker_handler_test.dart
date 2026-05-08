import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/shape_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
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

      test('does not remove same type+color at different level', () {
        final shapes = [target, sameTypeColorDiffLevel, different];
        final result = JokerHandler.useBomb(target, shapes, inventory);

        expect(result.shapes.length, 2);
        expect(result.shapes.any((s) => s.id == 'samediff'), true);
        expect(result.shapes.any((s) => s.id == 'diff'), true);
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
    });
  });
}
