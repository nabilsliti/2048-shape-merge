import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/constants/shape_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/game/models/game_state.dart';

void main() {
  group('GameState serialization', () {
    test('toJson/fromJson round-trip preserves all fields', () {
      final shapes = [
        GameShape(
          id: 's1', x: 10.5, y: 20.3,
          type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 3,
        ),
        GameShape(
          id: 's2', x: 100, y: 200,
          type: ShapeType.star, color: const Color(0xFFFF0000), level: 1,
          isWildcard: true,
        ),
      ];
      final original = GameState(
        shapes: shapes,
        score: 1234,
        bestScore: 5678,
        mergeCount: 42,
        maxLevelReached: 5,
        jokerInventory: const JokerInventory(
          bomb: 3, wildcard: 2, reducer: 1, radar: 0, evolution: 1, megaBomb: 0,
        ),
        jokersUsedThisGame: 7,
        comboCount: 2,
      );

      final json = jsonEncode(original.toJson());
      final restored = GameState.fromJson(
        jsonDecode(json) as Map<String, Object?>,
      );

      expect(restored.score, original.score);
      expect(restored.bestScore, original.bestScore);
      expect(restored.mergeCount, original.mergeCount);
      expect(restored.maxLevelReached, original.maxLevelReached);
      expect(restored.jokersUsedThisGame, original.jokersUsedThisGame);
      expect(restored.comboCount, original.comboCount);
      expect(restored.gameActive, true);
      expect(restored.shapes.length, 2);
      expect(restored.jokerInventory.bomb, 3);
      expect(restored.jokerInventory.wildcard, 2);
      expect(restored.jokerInventory.evolution, 1);
    });

    test('fromJson with empty/null shapes returns empty list', () {
      final state = GameState.fromJson({'score': 100});
      expect(state.shapes, isEmpty);
      expect(state.score, 100);
    });

    test('fromJson with malformed data uses defaults', () {
      final state = GameState.fromJson({});
      expect(state.score, 0);
      expect(state.bestScore, 0);
      expect(state.gameActive, true);
    });
  });

  group('GameShape serialization', () {
    test('toJson/fromJson round-trip', () {
      final shape = GameShape(
        id: 'abc', x: 42.5, y: 99.9,
        type: ShapeType.diamond, color: const Color(0xAABBCCDD),
        level: 7, isWildcard: true,
      );
      final json = shape.toJson();
      final restored = GameShape.fromJson(json);

      expect(restored.id, 'abc');
      expect(restored.x, 42.5);
      expect(restored.y, 99.9);
      expect(restored.type, ShapeType.diamond);
      expect(restored.color, const Color(0xAABBCCDD));
      expect(restored.level, 7);
      expect(restored.isWildcard, true);
    });

    test('fromJson defaults isWildcard to false when missing', () {
      final shape = GameShape.fromJson({
        'id': 'x', 'x': 0.0, 'y': 0.0,
        'type': 0, 'color': const Color(0xFF000000).toARGB32(), 'level': 1,
      });
      expect(shape.isWildcard, false);
    });
  });
}
