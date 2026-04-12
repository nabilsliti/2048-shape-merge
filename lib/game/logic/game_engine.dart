import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/game/models/game_state.dart';
import 'merge_detector.dart';
import 'spawn_manager.dart';

class GameEngine {
  static const _uuid = Uuid();

  static GameState startNewGame(Size boardSize, GameState previous) {
    final shapes = SpawnManager.spawnInitialShapes(boardSize);
    return GameState(
      shapes: shapes,
      bestScore: previous.bestScore,
      jokerInventory: previous.jokerInventory,
    );
  }

  static ({GameState state, GameShape? mergedShape, int pointsEarned, bool wasTap, int comboCount})
      attemptMerge(
    GameState state,
    GameShape dragged,
    Offset dropPosition,
    Size boardSize, {
    bool wasTap = false,
  }) {
    // Tap without real drag → do nothing
    if (wasTap) {
      return (
        state: state,
        mergedShape: null,
        pointsEarned: 0,
        wasTap: true,
        comboCount: state.comboCount,
      );
    }

    final target = MergeDetector.findBestTarget(
      dragged,
      state.shapes,
      dropPosition,
    );

    // Helper: append a drag result to the rolling window of 20 attempts
    List<bool> _updatedAttempts(bool merged) {
      final list = List<bool>.from(state.recentAttempts)..add(merged);
      if (list.length > 20) list.removeAt(0);
      return list;
    }

    if (target == null) {
      // No merge — shape position stays unchanged (snap back handled by UI),
      // spawn only if below max capacity
      final attempts = _updatedAttempts(false);
      final mergeRate = attempts.isEmpty ? 0.5 : attempts.where((b) => b).length / attempts.length;
      final updatedShapes = List<GameShape>.from(state.shapes);
      if (updatedShapes.length < maxShapes) {
        final newShape = SpawnManager.spawnShape(updatedShapes, boardSize, mergeRate: mergeRate, totalMerges: state.mergeCount);
        updatedShapes.add(newShape);
      }

      final newState = state.copyWith(shapes: updatedShapes, recentAttempts: attempts, comboCount: 0);
      return (
        state: _checkGameState(newState, boardSize),
        mergedShape: null,
        pointsEarned: 0,
        wasTap: false,
        comboCount: 0,
      );
    }

    // Merge!
    // Chain combo: only if dragged or target is the result of the previous merge
    final isChain = state.lastMergedShapeId != null &&
        (dragged.id == state.lastMergedShapeId || target.id == state.lastMergedShapeId);
    final newCombo = isChain ? state.comboCount + 1 : 0;
    final newLevel = target.level + 1;
    final midX = target.x;
    final midY = target.y;
    final basePoints = scoreForMerge(newLevel);
    // Combo multiplier: ×1.0 (no chain), ×1.5 (chain 1), ×2.0 (chain 2), ... (capped at ×5)
    final comboMultiplier = newCombo > 0
        ? (1.0 + newCombo * 0.5).clamp(1.0, 5.0)
        : 1.0;
    final points = (basePoints * comboMultiplier).round();

    final merged = GameShape(
      id: _uuid.v4(),
      x: midX,
      y: midY,
      type: dragged.isWildcard ? target.type : dragged.type,
      color: dragged.isWildcard ? target.color : dragged.color,
      level: newLevel,
    );

    final attempts = _updatedAttempts(true);
    final mergeRate = attempts.isEmpty ? 0.5 : attempts.where((b) => b).length / attempts.length;
    final updatedShapes = state.shapes
        .where((s) => s.id != dragged.id && s.id != target.id)
        .toList()
      ..add(merged);

    // Spawn after merge only if below max capacity
    if (updatedShapes.length < maxShapes) {
      final spawnedShape = SpawnManager.spawnShape(updatedShapes, boardSize, mergeRate: mergeRate, totalMerges: state.mergeCount + 1);
      updatedShapes.add(spawnedShape);
    }

    final newScore = state.score + points;
    final newBest =
        newScore > state.bestScore ? newScore : state.bestScore;
    final newMaxLevel = newLevel > state.maxLevelReached
        ? newLevel
        : state.maxLevelReached;

    final newState = state.copyWith(
      shapes: updatedShapes,
      score: newScore,
      bestScore: newBest,
      mergeCount: state.mergeCount + 1,
      maxLevelReached: newMaxLevel,
      recentAttempts: attempts,
      comboCount: newCombo,
      lastMergedShapeId: merged.id,
    );

    return (
      state: _checkGameState(newState, boardSize),
      mergedShape: merged,
      pointsEarned: points,
      wasTap: false,
      comboCount: newCombo,
    );
  }

  static GameState moveDraggedShape(
    GameState state,
    String shapeId,
    double newX,
    double newY,
  ) {
    final updatedShapes = state.shapes.map((s) {
      if (s.id == shapeId) {
        s.x = newX;
        s.y = newY;
      }
      return s;
    }).toList();
    return state.copyWith(shapes: updatedShapes);
  }

  /// Re-check game state after external mutations (joker usage).
  /// Spawns shapes if board is empty or has no pairs.
  static GameState checkAfterJoker(GameState state, Size boardSize) {
    return _checkGameState(state, boardSize);
  }

  static GameState _checkGameState(GameState state, Size boardSize) {
    if (state.shapes.isEmpty) {
      // Board cleared — spawn fresh shapes so the game continues
      final shapes = <GameShape>[];
      var attempts = 0;
      while (shapes.length < 3 && attempts < 6) {
        shapes.add(SpawnManager.spawnShape(shapes, boardSize, mergeRate: state.recentMergeRate, totalMerges: state.mergeCount));
        attempts++;
      }
      return state.copyWith(shapes: shapes);
    }

    if (state.shapes.length >= maxShapes) {
      if (!MergeDetector.hasPairs(state.shapes)) {
        // Game over
        return state.copyWith(gameActive: false);
      }
      // Full but has pairs — continue (warning shown in UI)
    }

    if (!MergeDetector.hasPairs(state.shapes) &&
        state.shapes.length < maxShapes) {
      // No pairs but space — spawn until pair exists
      final shapes = List<GameShape>.from(state.shapes);
      var attempts = 0;
      while (
          !MergeDetector.hasPairs(shapes) && shapes.length < maxShapes && attempts < 5) {
        shapes.add(SpawnManager.spawnShape(shapes, boardSize, mergeRate: state.recentMergeRate, totalMerges: state.mergeCount));
        attempts++;
      }
      return state.copyWith(shapes: shapes);
    }

    return state;
  }

  static bool isGameOver(GameState state) {
    return !state.gameActive;
  }

  static bool isVictory(GameState state) {
    return !state.gameActive && state.shapes.isEmpty;
  }

  static bool isBoardFull(GameState state) {
    return state.shapes.length >= maxShapes;
  }
}
