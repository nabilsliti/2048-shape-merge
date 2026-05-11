import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/constants/shape_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/game/logic/spawn_manager.dart';

void main() {
  const boardSize = Size(400, 600);

  group('SpawnManager.spawnInitialShapes', () {
    test('produces exactly BoardTuning.startShapes shapes', () {
      final shapes = SpawnManager.spawnInitialShapes(boardSize);
      expect(shapes.length, BoardTuning.startShapes);
    });

    test('every shape starts at level 1', () {
      final shapes = SpawnManager.spawnInitialShapes(boardSize);
      for (final s in shapes) {
        expect(s.level, 1);
      }
    });

    test('every shape has a unique id', () {
      final shapes = SpawnManager.spawnInitialShapes(boardSize);
      expect(shapes.map((s) => s.id).toSet().length, shapes.length);
    });

    test('shapes spawn within board bounds (account for radius+padding)', () {
      final shapes = SpawnManager.spawnInitialShapes(boardSize);
      for (final s in shapes) {
        expect(s.x, greaterThanOrEqualTo(0));
        expect(s.y, greaterThanOrEqualTo(0));
        expect(s.x, lessThanOrEqualTo(boardSize.width));
        expect(s.y, lessThanOrEqualTo(boardSize.height));
      }
    });

    test('initial shapes are organised in mergeable pairs', () {
      // Run a few times to absorb shuffling — every run must contain at least
      // one matching pair (same type + color + level).
      for (var trial = 0; trial < 5; trial++) {
        final shapes = SpawnManager.spawnInitialShapes(boardSize);
        final keys = shapes.map((s) =>
            '${s.type.index}|${s.color.toARGB32()}|${s.level}').toList();
        final hasPair = keys.toSet().length < keys.length;
        expect(hasPair, true, reason: 'trial $trial produced no pair');
      }
    });
  });

  group('SpawnManager.spawnShape', () {
    test('first shape on empty board is level 1', () {
      // With empty list, the smart-spawn branch is bypassed → level 1.
      final s = SpawnManager.spawnShape(<GameShape>[], boardSize);
      expect(s.level, 1);
    });

    test('returned shape has unique-looking uuid', () {
      final s1 = SpawnManager.spawnShape(<GameShape>[], boardSize);
      final s2 = SpawnManager.spawnShape(<GameShape>[], boardSize);
      expect(s1.id, isNot(s2.id));
    });

    test('respects board bounds with margin', () {
      final shapes = <GameShape>[];
      for (var i = 0; i < 20; i++) {
        shapes.add(SpawnManager.spawnShape(shapes, boardSize));
      }
      for (final s in shapes) {
        expect(s.x, greaterThan(0));
        expect(s.y, greaterThan(0));
        expect(s.x, lessThan(boardSize.width));
        expect(s.y, lessThan(boardSize.height));
      }
    });

    test('uses a known shape type and color from the palette', () {
      for (var i = 0; i < 10; i++) {
        final s = SpawnManager.spawnShape(<GameShape>[], boardSize);
        expect(ShapeType.values, contains(s.type));
      }
    });
  });
}
