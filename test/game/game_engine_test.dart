import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
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
      expect(state.shapes.length, BoardTuning.startShapes);
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
      expect(result.pointsEarned, Scoring.forMerge(2));
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
      final shapes = List.generate(BoardTuning.maxShapes, (i) => GameShape(
        id: '$i', x: 0, y: 0,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
      ));
      final state = GameState(shapes: shapes);
      expect(GameEngine.isBoardFull(state), true);
    });

    test('attemptMerge with wasTap returns state unchanged', () {
      final shape = GameShape(
        id: 's', x: 0, y: 0,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
      );
      final state = GameState(shapes: [shape]);
      final r = GameEngine.attemptMerge(
        state, shape, const Offset(0, 0), boardSize, wasTap: true,
      );
      expect(r.mergedShape, isNull);
      expect(r.pointsEarned, 0);
      expect(r.wasTap, true);
      expect(r.state, same(state));
    });

    test('wildcard merge increments wildcardMergesThisGame', () {
      final wild = GameShape(
        id: 'w', x: 0, y: 0,
        type: ShapeType.star, color: const Color(0xFFFFFFFF), level: 1,
        isWildcard: true,
      );
      final partner = GameShape(
        id: 'p', x: 50, y: 0,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
      );
      final state = GameState(shapes: [wild, partner]);
      final r = GameEngine.attemptMerge(
        state, wild, Offset(partner.x, partner.y), boardSize,
      );
      expect(r.mergedShape, isNotNull);
      // Counter incremented in returned state
      expect(r.state.wildcardMergesThisGame, 1);
    });

    test('high-level merge (newLevel >= 6) increments highLevelMergesThisGame', () {
      // Two level-5 shapes → merge produces level 6
      final a = GameShape(
        id: 'a', x: 0, y: 0,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 5,
      );
      final b = GameShape(
        id: 'b', x: 50, y: 0,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 5,
      );
      final state = GameState(shapes: [a, b]);
      final r = GameEngine.attemptMerge(
        state, a, Offset(b.x, b.y), boardSize,
      );
      expect(r.mergedShape!.level, 6);
      expect(r.state.highLevelMergesThisGame, 1);
    });

    test('combo: merging the result of a previous merge bumps comboCount', () {
      // First merge
      final a = GameShape(
        id: 'a', x: 0, y: 0,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
      );
      final b = GameShape(
        id: 'b', x: 50, y: 0,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
      );
      // Pre-place a partner at level 2 next to where the merge will land.
      // Merge result will be at b.position with level 2 → it can pair with c.
      final c = GameShape(
        id: 'c', x: 60, y: 0,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 2,
      );
      final state0 = GameState(shapes: [a, b, c]);
      final first = GameEngine.attemptMerge(
        state0, a, Offset(b.x, b.y), boardSize,
      );
      expect(first.mergedShape, isNotNull);
      expect(first.comboCount, 0, reason: 'first merge has no chain');

      // Now drag the freshly merged shape onto c.
      final merged = first.state.shapes.firstWhere((s) => s.id == first.mergedShape!.id);
      final partner = first.state.shapes.firstWhere((s) => s.id == 'c');
      final second = GameEngine.attemptMerge(
        first.state, merged, Offset(partner.x, partner.y), boardSize,
      );
      expect(second.mergedShape, isNotNull);
      expect(second.comboCount, 1);
      expect(second.state.maxComboReached, greaterThanOrEqualTo(1));
    });

    test('moveDraggedShape updates only the targeted shape', () {
      final a = GameShape(
        id: 'a', x: 0, y: 0,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
      );
      final b = GameShape(
        id: 'b', x: 100, y: 100,
        type: ShapeType.square, color: const Color(0xFF69F0AE), level: 1,
      );
      final state = GameState(shapes: [a, b]);
      final next = GameEngine.moveDraggedShape(state, 'a', 50, 60);
      final movedA = next.shapes.firstWhere((s) => s.id == 'a');
      final unchangedB = next.shapes.firstWhere((s) => s.id == 'b');
      expect(movedA.x, 50);
      expect(movedA.y, 60);
      expect(unchangedB.x, 100);
      expect(unchangedB.y, 100);
    });

    test('isGameOver mirrors !gameActive', () {
      const a = GameState(gameActive: true);
      const b = GameState(gameActive: false);
      expect(GameEngine.isGameOver(a), false);
      expect(GameEngine.isGameOver(b), true);
    });

    test('checkAfterJoker on empty board respawns shapes and counts a clear', () {
      const empty = GameState(shapes: [], boardClearsThisGame: 0);
      final r = GameEngine.checkAfterJoker(empty, boardSize);
      expect(r.shapes, isNotEmpty);
      expect(r.boardClearsThisGame, 1);
    });
  });
}
