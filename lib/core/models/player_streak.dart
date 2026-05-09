import 'package:shape_merge/core/constants/joker_types.dart';

// ─────────────────────────────────────────────────────────────
// Streak Reward — sealed type for daily streak rewards.
// ─────────────────────────────────────────────────────────────

sealed class StreakReward {
  const StreakReward();

  /// Whether this reward can be doubled via rewarded ad.
  bool get canDoubleWithAd;
}

class StreakJokerReward extends StreakReward {
  final JokerType type;
  final int amount;
  const StreakJokerReward(this.type, this.amount);

  @override
  bool get canDoubleWithAd => !type.isPremium;
}

class StreakXpReward extends StreakReward {
  final int xp;
  const StreakXpReward(this.xp);

  @override
  bool get canDoubleWithAd => true;
}

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
  /// Alternates XP and joker. J7 is premium (no x2 allowed).
  static const List<StreakReward> _baseRewards = [
    StreakXpReward(15),                       // J1
    StreakJokerReward(JokerType.bomb, 1),     // J2
    StreakXpReward(20),                       // J3
    StreakJokerReward(JokerType.wildcard, 1), // J4
    StreakXpReward(25),                       // J5
    StreakJokerReward(JokerType.reducer, 1),  // J6
    StreakJokerReward(JokerType.radar, 1),    // J7 — placeholder, replaced by premium rotation
  ];

  /// Premium joker rotation for J7: Radar → Evolution → MegaBomb (cycles).
  static const List<JokerType> _j7PremiumRotation = [
    JokerType.radar,
    JokerType.evolution,
    JokerType.megaBomb,
  ];

  /// Returns the streak reward for a given [currentStreak] (1-based).
  /// J7 premium: always ×1, type rotates by week. No weekly scaling.
  static StreakReward rewardForStreak(int currentStreak) {
    if (currentStreak <= 0) return const StreakXpReward(15);
    final dayIndex = (currentStreak - 1) % rewardCycleLength;
    final weekNum = ((currentStreak - 1) ~/ rewardCycleLength) + 1;

    if (dayIndex == 6) {
      // J7: premium rotation, always ×1
      final premiumIndex = (weekNum - 1) % _j7PremiumRotation.length;
      return StreakJokerReward(_j7PremiumRotation[premiumIndex], 1);
    }

    return _baseRewards[dayIndex];
  }

  /// Legacy compatibility — returns reward at a given cycle index for week 1.
  static StreakReward rewardForIndex(int index) {
    return rewardForStreak(index + 1);
  }

  /// Milestone bonus rewards — given ON TOP of the daily reward.
  static const Map<int, List<StreakJokerReward>> milestoneRewards = {
    14:  [StreakJokerReward(JokerType.evolution, 1)],
    30:  [StreakJokerReward(JokerType.megaBomb, 1), StreakJokerReward(JokerType.wildcard, 1)],
    100: [StreakJokerReward(JokerType.megaBomb, 1), StreakJokerReward(JokerType.evolution, 1), StreakJokerReward(JokerType.radar, 1)],
  };

  /// Returns bonus milestone rewards for a given streak, or null.
  static List<StreakJokerReward>? milestoneFor(int streak) => milestoneRewards[streak];

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

  /// Reward earned today — null if no new reward (already logged today or reset).
  final StreakReward? reward;

  /// True if today's reward has been claimed.
  final bool rewardClaimed;

  /// Snapshot of the streak after the update.
  final PlayerStreak streak;

  /// Nudge shown for guest users (shown at streak ≥ 3 once).
  final bool showGuestNudge;

  /// Milestone bonus rewards (on top of daily reward), or null.
  final List<StreakJokerReward>? milestoneReward;

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

/// Server-authoritative response from the `claimDailyStreakReward` CF.
/// All fields are computed server-side using `Timestamp.now()`.
class StreakClaimResult {
  final int currentStreak;
  final int longestStreak;
  final int nextRewardIndex;
  final StreakReward reward;
  final List<StreakJokerReward>? milestone;

  const StreakClaimResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.nextRewardIndex,
    required this.reward,
    this.milestone,
  });

  factory StreakClaimResult.fromMap(Map<String, Object?> data) {
    final rewardMap = Map<String, Object?>.from(data['reward'] as Map);
    final reward = _rewardFromMap(rewardMap);

    final rawMilestone = data['milestone'];
    List<StreakJokerReward>? milestone;
    if (rawMilestone is List) {
      milestone = rawMilestone
          .whereType<Map<Object?, Object?>>()
          .map((m) => Map<String, Object?>.from(m))
          .map((m) => StreakJokerReward(
                JokerType.values.byName(m['type'] as String),
                (m['amount'] as num).toInt(),
              ))
          .toList();
    }

    return StreakClaimResult(
      currentStreak: (data['currentStreak'] as num).toInt(),
      longestStreak: (data['longestStreak'] as num).toInt(),
      nextRewardIndex: (data['nextRewardIndex'] as num).toInt(),
      reward: reward,
      milestone: milestone,
    );
  }

  static StreakReward _rewardFromMap(Map<String, Object?> m) {
    final kind = m['kind'] as String;
    if (kind == 'xp') {
      return StreakXpReward((m['xp'] as num).toInt());
    }
    return StreakJokerReward(
      JokerType.values.byName(m['type'] as String),
      (m['amount'] as num).toInt(),
    );
  }
}
