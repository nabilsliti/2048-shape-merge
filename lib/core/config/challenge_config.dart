import 'package:shape_merge/core/constants/joker_types.dart';

// ─────────────────────────────────────────────────────────────
// Challenge Config — daily challenge targets, rewards, bands.
//
// To adjust difficulty: edit targets or band thresholds below.
// To add a challenge type: add entry in ChallengeType enum
// then add targets here.
// ─────────────────────────────────────────────────────────────

/// Difficulty band thresholds based on player level.
abstract final class ChallengeBands {
  /// Below this level → easy challenges.
  static const int easyMaxLevel = 5;

  /// Below this level → medium challenges. Above → hard.
  static const int mediumMaxLevel = 20;
}

/// Challenge targets by type and difficulty.
/// Key structure: ChallengeType → { easy, medium, hard }
abstract final class ChallengeTargets {
  static const Map<String, Map<String, int>> targets = {
    'fusions': {'easy': 10, 'medium': 25, 'hard': 50},
    'score': {'easy': 500, 'medium': 2000, 'hard': 6000},
    'parties': {'easy': 1, 'medium': 2, 'hard': 3},
    'formeMax': {'easy': 5, 'medium': 8, 'hard': 12},
    'jokersUses': {'easy': 2, 'medium': 5, 'hard': 8},
  };

  /// Lookup target for a type name and difficulty name.
  static int target(String typeName, String diffName) =>
      targets[typeName]?[diffName] ?? 1;
}

/// XP rewards by difficulty.
abstract final class ChallengeRewards {
  static const Map<String, int> xp = {
    'easy': 15,
    'medium': 30,
    'hard': 50,
  };

  /// Joker reward type by difficulty.
  static const Map<String, JokerType> joker = {
    'easy': JokerType.bomb,
    'medium': JokerType.wildcard,
    'hard': JokerType.reducer,
  };
}
