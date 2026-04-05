import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';

class GameState {
  final List<GameShape> shapes;
  final int score;
  final int bestScore;
  final int mergeCount;
  final int maxLevelReached;
  final JokerInventory jokerInventory;
  final bool gameActive;
  final bool isPaused;

  const GameState({
    this.shapes = const [],
    this.score = 0,
    this.bestScore = 0,
    this.mergeCount = 0,
    this.maxLevelReached = 1,
    this.jokerInventory = const JokerInventory(),
    this.gameActive = true,
    this.isPaused = false,
  });

  GameState copyWith({
    List<GameShape>? shapes,
    int? score,
    int? bestScore,
    int? mergeCount,
    int? maxLevelReached,
    JokerInventory? jokerInventory,
    bool? gameActive,
    bool? isPaused,
  }) {
    return GameState(
      shapes: shapes ?? this.shapes,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      mergeCount: mergeCount ?? this.mergeCount,
      maxLevelReached: maxLevelReached ?? this.maxLevelReached,
      jokerInventory: jokerInventory ?? this.jokerInventory,
      gameActive: gameActive ?? this.gameActive,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
