import 'dart:math' as math;

import 'package:shape_merge/core/constants/joker_types.dart';

// ─────────────────────────────────────────────────────────────
// Game Tuning — all gameplay constants in one place.
//
// To tweak gameplay: edit values here, no code changes needed.
// ─────────────────────────────────────────────────────────────

/// Board & spawn parameters.
abstract final class BoardTuning {
  static const int maxShapes = 32;
  static const int startShapes = 8;
  static const int spawnPerMove = 1;
  static const double snapRadius = 60.0;
  static const int maxSpawnAttempts = 80;

  /// Rolling window of recent merge attempts for adaptive difficulty.
  static const int recentAttemptsWindow = 20;

  /// Number of shapes to spawn when the board is cleared.
  static const int boardClearSpawnCount = 3;

  /// Max spawn attempts when filling a cleared board.
  static const int boardClearMaxAttempts = 6;

  /// Max spawn attempts to rescue a board with no pairs.
  static const int rescueMaxAttempts = 5;

  /// Probability to spawn a shape that matches an existing one.
  static const double smartSpawnChance = 0.60;

  /// Probability to copy the level of a matched shape.
  static const double levelCopyChance = 0.55;
}

/// Shape sizing per level.
abstract final class ShapeSizing {
  static const double baseSize = 49.0;
  static const double growthPerLevel = 6.0;
  static const double maxSize = 82.0;

  static double forLevel(int level) {
    final size = baseSize + level * growthPerLevel;
    return size > maxSize ? maxSize : size;
  }
}

/// Scoring formulas.
abstract final class Scoring {
  /// Points = 2^newLevel × 10
  static int forMerge(int newLevel) => (1 << newLevel) * 10;
}

/// Chain-combo multiplier tuning.
abstract final class ComboTuning {
  /// Multiplier increment per consecutive combo (×1.5, ×2.0, …).
  static const double perComboIncrement = 0.5;

  /// Maximum combo multiplier cap.
  static const double maxMultiplier = 5.0;
}

/// Joker score bonus values.
abstract final class JokerBonusTuning {
  /// Points per shape removed by a Bomb.
  static const int bombBonusPerShape = 10;

  /// Points for destroying a level-1 shape with Reducer.
  static const int reducerDestroyBonus = 5;

  /// Points per shape removed by a Mega Bomb.
  static const int megaBombBonusPerShape = 15;
}

/// Revive system settings.
abstract final class ReviveTuning {
  /// Number of lowest-level shapes removed on revive.
  static const int shapesToRemove = 10;

  /// Max revives per game.
  static const int maxPerGame = 1;
}

/// Interstitial ad settings.
abstract final class InterstitialTuning {
  /// Show interstitial every N game overs.
  static const int showEveryNGameOvers = 3;
}

/// XP and level progression.
abstract final class Progression {
  static const int maxLevel = 50;

  /// XP required to go FROM [level] to level + 1.
  /// Formula: floor(100 × level^1.4), clamped to [100, 999 999].
  static int xpForLevel(int level) =>
      (100 * math.pow(level, 1.4)).floor().clamp(100, 999999);

  /// Divisor applied to raw score to get base XP.
  static const int scoreDivisor = 500;

  /// XP per merge.
  static const int xpPerMerge = 1;

  /// XP per shape level reached.
  static const int xpPerShapeLevel = 3;

  /// XP per completed objective.
  static const int xpPerObjective = 5;

  /// Streak threshold for XP bonus.
  static const int streakBonusThreshold = 7;

  /// XP multiplier when streak is active.
  static const double streakMultiplier = 1.1;
}

/// Rewards given on level-up.
/// Each entry maps a level to a list of (JokerType, amount) rewards.
/// Levels not in the map give no reward.
abstract final class LevelUpRewards {
  static const Map<int, List<(JokerType, int)>> rewards = {
    2:  [(JokerType.bomb, 2)],
    3:  [(JokerType.wildcard, 2)],
    4:  [(JokerType.reducer, 2)],
    5:  [(JokerType.bomb, 3), (JokerType.wildcard, 1)],
    7:  [(JokerType.radar, 1)],
    10: [(JokerType.evolution, 1), (JokerType.bomb, 2)],
    12: [(JokerType.megaBomb, 1)],
    15: [(JokerType.wildcard, 3), (JokerType.radar, 1)],
    18: [(JokerType.evolution, 1), (JokerType.reducer, 3)],
    20: [(JokerType.megaBomb, 1), (JokerType.bomb, 3)],
    25: [(JokerType.evolution, 2), (JokerType.wildcard, 2)],
    30: [(JokerType.megaBomb, 2), (JokerType.radar, 2)],
    35: [(JokerType.evolution, 2), (JokerType.bomb, 5)],
    40: [(JokerType.megaBomb, 2), (JokerType.wildcard, 5)],
    45: [(JokerType.radar, 3), (JokerType.evolution, 2)],
    50: [(JokerType.megaBomb, 3), (JokerType.evolution, 3), (JokerType.radar, 3)],
  };

  /// Returns rewards for reaching [level], or empty list if none.
  static List<(JokerType, int)> forLevel(int level) => rewards[level] ?? const [];
}

/// Initial joker inventory for new players.
abstract final class JokerStartingCounts {
  static const int bomb = 3;
  static const int wildcard = 3;
  static const int reducer = 3;
  static const int radar = 1;
  static const int evolution = 1;
  static const int megaBomb = 1;
}

/// Spawn logic adaptive thresholds.
abstract final class SpawnTuning {
  // Merge-rate bracket thresholds (descending order)
  static const double highMergeRateThreshold = 0.7;
  static const double medHighMergeRateThreshold = 0.5;
  static const double medLowMergeRateThreshold = 0.3;

  // Adaptive smart-chance by merge rate brackets
  static const double chanceWhenHighMergeRate = 0.50;    // mergeRate > 0.7
  static const double chanceWhenMedHighMergeRate = 0.60; // mergeRate > 0.5
  static const double chanceWhenMedLowMergeRate = 0.70;  // mergeRate > 0.3
  static const double chanceWhenLowMergeRate = 0.80;     // otherwise

  /// Board shape count that triggers pressure cap.
  static const int pressureThreshold = 25;

  /// Max smart chance under pressure.
  static const double pressureCap = 0.50;

  /// Total merges below which player is considered beginner.
  static const int beginnerMergeLimit = 20;

  /// Minimum gap between shapes when spawning (pixels).
  static const double minSpawnGap = 12.0;

  /// Padding from board edge when spawning shapes (pixels).
  static const double spawnMarginPadding = 8.0;

  /// Grid resolution for fallback spawn search.
  static const int gridSteps = 16;
}

/// Joker suggestion engine thresholds.
abstract final class SuggestionTuning {
  /// Minimum moves between two suggestions.
  static const int cooldownMoves = 8;

  /// Board fill ratio below which we never suggest.
  static const double minFillToSuggest = 0.5;

  /// Critical fill ratio (almost game over).
  static const double criticalFillRatio = 0.9;

  /// Max pairs allowed to trigger critical suggestion.
  static const int criticalMaxPairs = 2;

  /// High fill ratio (board getting full).
  static const double highFillRatio = 0.75;

  /// Merge rate below which player is considered struggling.
  static const double lowMergeRate = 0.30;

  /// Fill ratio for medium-urgency struggling suggestion.
  static const double strugglingFillRatio = 0.5;

  /// Fill ratio for cluster/lonely suggestions.
  static const double clusterFillRatio = 0.6;

  /// Minimum same-level shapes to recommend MegaBomb.
  static const int megaBombClusterSize = 4;

  /// Minimum shape level to count as "high level" for lonely detection.
  static const int highLevelThreshold = 3;
}
