import 'package:shape_merge/core/constants/joker_types.dart';

/// Lightweight value object for streak state — used by StreakService.
/// The actual persistence lives in Player (Firestore) and LocalStorageService (guest).
class PlayerStreak {
  final int currentStreak;
  final int longestStreak;
  final String? lastLoginDate; // "YYYY-MM-DD" local timezone
  final int nextRewardIndex;   // 0–6 in the weekly cycle

  const PlayerStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastLoginDate,
    required this.nextRewardIndex,
  });

  PlayerStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    String? lastLoginDate,
    int? nextRewardIndex,
  }) {
    return PlayerStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      nextRewardIndex: nextRewardIndex ?? this.nextRewardIndex,
    );
  }

  /// Returns (JokerType, amount) for the reward at [index] in the weekly cycle.
  static (JokerType, int) rewardForIndex(int index) => switch (index % 7) {
    0 => (JokerType.bomb, 1),
    1 => (JokerType.wildcard, 1),
    2 => (JokerType.reducer, 1),
    3 => (JokerType.bomb, 2),
    4 => (JokerType.radar, 1),
    5 => (JokerType.wildcard, 2),
    _ => (JokerType.megaBomb, 1),
  };

  /// Returns today's date as "YYYY-MM-DD" in local timezone.
  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Returns yesterday's date as "YYYY-MM-DD" in local timezone.
  static String yesterdayKey() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  }
}

/// Result produced by StreakService.checkAndUpdate() — drives popup + badge.
class StreakCheckResult {
  /// True if the user earned a new day on their streak today.
  final bool streakIncremented;

  /// True if the streak was broken (came back after more than 1 day gap).
  final bool streakReset;

  /// Joker reward earned today — null if no new reward (already logged today or reset).
  final (JokerType, int)? reward;

  /// Snapshot of the streak after the update.
  final PlayerStreak streak;

  /// Nudge shown for guest users (shown at streak ≥ 3 once).
  final bool showGuestNudge;

  const StreakCheckResult({
    required this.streakIncremented,
    required this.streakReset,
    required this.reward,
    required this.streak,
    this.showGuestNudge = false,
  });
}
