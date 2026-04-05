import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/constants/shape_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/game/logic/game_engine.dart';
import 'package:shape_merge/game/models/game_state.dart';

void main() {
  const boardSize = Size(400, 600);

  group('GameEngine', () {
    test('startNewGame creates initial shapes', () {
      final state = GameEngine.startNewGame(
        boardSize,
        const GameState(),
      );
      expect(state.shapes.length, startShapes);
      expect(state.score, 0);
      expect(state.gameActive, true);
    });

    test('startNewGame preserves bestScore and jokers', () {
      const previous = GameState(
        bestScore: 500,
        jokerInventory: JokerInventory(bomb: 5, wildcard: 2, reducer: 1),
      );
      final state = GameEngine.startNewGame(boardSize, previous);
      expect(state.bestScore, 500);
      expect(state.jokerInventory.bomb, 5);
      expect(state.jokerInventory.wildcard, 2);
    });

    test('attemptMerge with matching shapes merges them', () {
      final shape1 = GameShape(
        id: '1', x: 100, y: 100,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
      );
      final shape2 = GameShape(
        id: '2', x: 150, y: 100,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
      );
      final state = GameState(shapes: [shape1, shape2]);

      final result = GameEngine.attemptMerge(
        state,
        shape1,
        Offset(shape2.x, shape2.y),
        boardSize,
      );

      expect(result.mergedShape, isNotNull);
      expect(result.mergedShape!.level, 2);
      expect(result.pointsEarned, scoreForMerge(2));
    });

    test('attemptMerge with non-matching shapes returns null merge', () {
      final shape1 = GameShape(
        id: '1', x: 100, y: 100,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
      );
      final shape2 = GameShape(
        id: '2', x: 300, y: 300,
        type: ShapeType.square, color: const Color(0xFF69F0AE), level: 1,
      );
      final state = GameState(shapes: [shape1, shape2]);

      final result = GameEngine.attemptMerge(
        state, shape1, const Offset(300, 300), boardSize,
      );

      // No merge because different type/color
      expect(result.mergedShape, isNull);
    });

    test('isVictory when no shapes remain', () {
      const state = GameState(shapes: [], gameActive: false);
      expect(GameEngine.isVictory(state), true);
    });

    test('isBoardFull at max shapes', () {
      final shapes = List.generate(maxShapes, (i) => GameShape(
        id: '$i', x: 0, y: 0,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
      ));
      final state = GameState(shapes: shapes);
      expect(GameEngine.isBoardFull(state), true);
    });
  });
}
