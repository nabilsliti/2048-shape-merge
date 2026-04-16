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

  /// Number of rewards in the weekly cycle.
  static const int rewardCycleLength = 7;

  /// Week number (1-based) computed from streak length.
  int get weekNumber => currentStreak <= 0 ? 1 : ((currentStreak - 1) ~/ rewardCycleLength) + 1;

  /// Base rewards for each day in the cycle (J1–J7).
  /// J1–J6 are classics, J7 is premium (rotates by week).
  static const List<(JokerType, int)> _baseRewards = [
    (JokerType.bomb, 1),       // J1
    (JokerType.reducer, 1),    // J2
    (JokerType.wildcard, 1),   // J3
    (JokerType.bomb, 2),       // J4
    (JokerType.wildcard, 2),   // J5
    (JokerType.reducer, 2),    // J6
    (JokerType.radar, 1),      // J7 — placeholder, replaced by premium rotation
  ];

  /// Premium joker rotation for J7: Radar → Evolution → MegaBomb (cycles).
  static const List<JokerType> _j7PremiumRotation = [
    JokerType.radar,
    JokerType.evolution,
    JokerType.megaBomb,
  ];

  /// Returns (JokerType, amount) for a given [currentStreak] (1-based).
  /// Scaling: week 1 = ×1, week 2 = ×2, week 3+ = ×3 (cap).
  /// J7 premium: always ×1, never scales. Type rotates by week.
  static (JokerType, int) rewardForStreak(int currentStreak) {
    if (currentStreak <= 0) return (JokerType.bomb, 1);
    final dayIndex = (currentStreak - 1) % rewardCycleLength;
    final weekNum = ((currentStreak - 1) ~/ rewardCycleLength) + 1;

    if (dayIndex == 6) {
      // J7: premium rotation, always ×1
      final premiumIndex = (weekNum - 1) % _j7PremiumRotation.length;
      return (_j7PremiumRotation[premiumIndex], 1);
    }

    final (type, baseAmount) = _baseRewards[dayIndex];
    final multiplier = weekNum.clamp(1, 3);
    return (type, baseAmount * multiplier);
  }

  /// Legacy compatibility — returns reward at a given cycle index for week 1.
  static (JokerType, int) rewardForIndex(int index) {
    return rewardForStreak(index + 1);
  }

  /// Milestone bonus rewards — given ON TOP of the daily reward.
  static const Map<int, List<(JokerType, int)>> milestoneRewards = {
    14:  [(JokerType.evolution, 1)],
    30:  [(JokerType.megaBomb, 1), (JokerType.wildcard, 3)],
    100: [(JokerType.megaBomb, 1), (JokerType.evolution, 1), (JokerType.radar, 1)],
  };

  /// Returns bonus milestone rewards for a given streak, or null.
  static List<(JokerType, int)>? milestoneFor(int streak) => milestoneRewards[streak];

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

  /// True if today's reward has been claimed.
  final bool rewardClaimed;

  /// Snapshot of the streak after the update.
  final PlayerStreak streak;

  /// Nudge shown for guest users (shown at streak ≥ 3 once).
  final bool showGuestNudge;

  /// Milestone bonus rewards (on top of daily reward), or null.
  final List<(JokerType, int)>? milestoneReward;

  const StreakCheckResult({
    required this.streakIncremented,
    required this.streakReset,
    required this.reward,
    required this.streak,
    this.rewardClaimed = false,
    this.showGuestNudge = false,
    this.milestoneReward,
  });

  StreakCheckResult copyWith({
    bool? streakIncremented,
    bool? streakReset,
    bool? rewardClaimed,
    bool? showGuestNudge,
  }) {
    return StreakCheckResult(
      streakIncremented: streakIncremented ?? this.streakIncremented,
      streakReset: streakReset ?? this.streakReset,
      reward: reward,
      streak: streak,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
      showGuestNudge: showGuestNudge ?? this.showGuestNudge,
      milestoneReward: milestoneReward,
    );
  }
}
