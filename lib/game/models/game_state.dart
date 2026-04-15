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

  /// Cached merge success rate (0.0–1.0) over the last 20 drags.
  final double recentMergeRate;

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
    this.recentMergeRate = 0.5,
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
    bool? radarActive,
    List<bool>? recentAttempts,
    int? jokersUsedThisGame,
    int? comboCount,
    String? lastMergedShapeId,
  }) {
    final attempts = recentAttempts ?? this.recentAttempts;
    final rate = recentAttempts != null ? _computeMergeRate(attempts) : recentMergeRate;
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
      recentAttempts: attempts,
      jokersUsedThisGame: jokersUsedThisGame ?? this.jokersUsedThisGame,
      comboCount: comboCount ?? this.comboCount,
      lastMergedShapeId: lastMergedShapeId ?? this.lastMergedShapeId,
      recentMergeRate: rate,
    );
  }

  static double _computeMergeRate(List<bool> attempts) {
    if (attempts.isEmpty) return 0.5;
    return attempts.where((b) => b).length / attempts.length;
  }

  /// Serializes only the fields needed to resume a game in progress.
  Map<String, Object?> toJson() => {
        'shapes': shapes.map((s) => s.toJson()).toList(),
        'score': score,
        'bestScore': bestScore,
        'mergeCount': mergeCount,
        'maxLevelReached': maxLevelReached,
        'jokerInventory': {
          'bomb': jokerInventory.bomb,
          'wildcard': jokerInventory.wildcard,
          'reducer': jokerInventory.reducer,
          'radar': jokerInventory.radar,
          'evolution': jokerInventory.evolution,
          'megaBomb': jokerInventory.megaBomb,
        },
        'jokersUsedThisGame': jokersUsedThisGame,
        'comboCount': comboCount,
      };

  factory GameState.fromJson(Map<String, Object?> json) {
    final jokerMap = json['jokerInventory'] as Map<String, Object?>? ?? {};
    return GameState(
      shapes: (json['shapes'] as List<Object?>?)
              ?.whereType<Map<String, Object?>>()
              .map(GameShape.fromJson)
              .toList() ??
          [],
      score: json['score'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      mergeCount: json['mergeCount'] as int? ?? 0,
      maxLevelReached: json['maxLevelReached'] as int? ?? 1,
      jokerInventory: JokerInventory(
        bomb: jokerMap['bomb'] as int? ?? 0,
        wildcard: jokerMap['wildcard'] as int? ?? 0,
        reducer: jokerMap['reducer'] as int? ?? 0,
        radar: jokerMap['radar'] as int? ?? 0,
        evolution: jokerMap['evolution'] as int? ?? 0,
        megaBomb: jokerMap['megaBomb'] as int? ?? 0,
      ),
      jokersUsedThisGame: json['jokersUsedThisGame'] as int? ?? 0,
      comboCount: json['comboCount'] as int? ?? 0,
      gameActive: true,
    );
  }
}
