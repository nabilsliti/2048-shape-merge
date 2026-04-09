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
  final bool radarActive;
  /// Last 20 drag outcomes — true=merged, false=missed.
  /// Used by SpawnManager for adaptive difficulty.
  final List<bool> recentAttempts;
  /// Number of jokers used this session (for daily challenges).
  final int jokersUsedThisGame;
  /// Current chain combo (merging the result of a previous merge).
  final int comboCount;
  /// ID of the shape created by the last merge (for chain detection).
  final String? lastMergedShapeId;

  const GameState({
    this.shapes = const [],
    this.score = 0,
    this.bestScore = 0,
    this.mergeCount = 0,
    this.maxLevelReached = 1,
    this.jokerInventory = const JokerInventory(),
    this.gameActive = true,
    this.isPaused = false,
    this.radarActive = false,
    this.recentAttempts = const [],
    this.jokersUsedThisGame = 0,
    this.comboCount = 0,
    this.lastMergedShapeId,
  });

  /// 0.0–1.0 merge success rate over the last 20 drags.
  double get recentMergeRate {
    if (recentAttempts.isEmpty) return 0.5;
    return recentAttempts.where((b) => b).length / recentAttempts.length;
  }

  GameState copyWith({
    List<GameShape>? shapes,
    int? score,
    int? bestScore,
    int? mergeCount,
    int? maxLevelReached,
    JokerInventory? jokerInventory,
    bool? gameActive,
    bool? isPaused,
    bool? radarActive,
    List<bool>? recentAttempts,
    int? jokersUsedThisGame,
    int? comboCount,
    String? lastMergedShapeId,
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
      radarActive: radarActive ?? this.radarActive,
      recentAttempts: recentAttempts ?? this.recentAttempts,
      jokersUsedThisGame: jokersUsedThisGame ?? this.jokersUsedThisGame,
      comboCount: comboCount ?? this.comboCount,
      lastMergedShapeId: lastMergedShapeId ?? this.lastMergedShapeId,
    );
  }
}
