import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shape_merge/game/logic/game_engine.dart';
import 'package:shape_merge/game/logic/joker_handler.dart';
import 'package:shape_merge/game/models/game_state.dart';
import 'package:shape_merge/core/models/game_shape.dart';

final localStorageProvider = FutureProvider<LocalStorageService>((ref) async {
  return LocalStorageService.create();
});

final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});

enum JokerMode { none, bomb, wildcard, reducer }

final jokerModeProvider = StateProvider<JokerMode>((_) => JokerMode.none);

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(const GameState());

  Size? _boardSize;

  void setBoardSize(Size size) => _boardSize = size;

  void startNewGame() {
    if (_boardSize == null) return;
    state = GameEngine.startNewGame(_boardSize!, state);
  }

  void loadSavedState({required int bestScore, required JokerInventory jokers}) {
    state = state.copyWith(bestScore: bestScore, jokerInventory: jokers);
  }

  ({GameShape? mergedShape, int pointsEarned, bool wasTap}) attemptMerge(
    GameShape dragged,
    Offset dropPosition, {
    bool wasTap = false,
  }) {
    if (_boardSize == null) {
      return (mergedShape: null, pointsEarned: 0, wasTap: wasTap);
    }
    final result = GameEngine.attemptMerge(
      state,
      dragged,
      dropPosition,
      _boardSize!,
      wasTap: wasTap,
    );
    state = result.state;
    return (mergedShape: result.mergedShape, pointsEarned: result.pointsEarned, wasTap: result.wasTap);
  }

  void updateShapePosition(String shapeId, double x, double y) {
    state = GameEngine.moveDraggedShape(state, shapeId, x, y);
  }

  void useBomb(GameShape target) {
    final result = JokerHandler.useBomb(
      target,
      state.shapes,
      state.jokerInventory,
    );
    state = state.copyWith(
      shapes: result.shapes,
      jokerInventory: result.inventory,
      score: state.score + result.scoreBonus,
    );
  }

  void spawnWildcard(int level) {
    if (_boardSize == null) return;
    final result = JokerHandler.spawnWildcard(
      state.shapes,
      state.jokerInventory,
      _boardSize!,
      level,
    );
    state = state.copyWith(
      shapes: result.shapes,
      jokerInventory: result.inventory,
    );
  }

  void useReducer(GameShape target) {
    final result = JokerHandler.useReducer(
      target,
      state.shapes,
      state.jokerInventory,
    );
    state = state.copyWith(
      shapes: result.shapes,
      jokerInventory: result.inventory,
      score: state.score + result.scoreBonus,
    );
  }

  void addJokers(JokerType type, [int amount = 1]) {
    state = state.copyWith(
      jokerInventory: state.jokerInventory.add(type, amount),
    );
  }

  void updateJokerInventory(JokerInventory inventory) {
    state = state.copyWith(jokerInventory: inventory);
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }
}
