import 'package:shape_merge/core/constants/joker_types.dart';

/// Types d'objectifs quotidiens disponibles.
enum ChallengeType { fusions, score, formeMax, parties, jokersUses }

/// Difficulté d'un objectif — influence la récompense.
enum ChallengeDifficulty { easy, medium, hard }

/// Récompense d'un objectif : soit un joker, soit des XP.
sealed class ChallengeReward {
  const ChallengeReward();

  Map<String, Object?> toMap();

  static ChallengeReward fromMap(Map<String, Object?> m) {
    if (m['kind'] == 'xp') {
      return XpReward(m['xp'] as int);
    }
    return JokerReward(JokerType.values.byName(m['joker'] as String));
  }
}

class JokerReward extends ChallengeReward {
  final JokerType joker;
  const JokerReward(this.joker);

  @override
  Map<String, Object?> toMap() => {'kind': 'joker', 'joker': joker.name};
}

class XpReward extends ChallengeReward {
  final int xp;
  const XpReward(this.xp);

  @override
  Map<String, Object?> toMap() => {'kind': 'xp', 'xp': xp};
}

/// Un objectif quotidien unique.
class DailyChallenge {
  final String id;
  final ChallengeType type;
  final int target;
  final int current;
  final bool completed;
  final bool rewardCollected;
  final ChallengeDifficulty difficulty;
  final ChallengeReward reward;

  const DailyChallenge({
    required this.id,
    required this.type,
    required this.target,
    this.current = 0,
    this.completed = false,
    this.rewardCollected = false,
    required this.difficulty,
    required this.reward,
  });

  double get progress => target == 0 ? 0 : (current / target).clamp(0.0, 1.0);

  bool get canCollect => completed && !rewardCollected;

  DailyChallenge copyWith({
    int? current,
    bool? completed,
    bool? rewardCollected,
  }) {
    return DailyChallenge(
      id: id,
      type: type,
      target: target,
      current: current ?? this.current,
      completed: completed ?? this.completed,
      rewardCollected: rewardCollected ?? this.rewardCollected,
      difficulty: difficulty,
      reward: reward,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'type': type.name,
    'target': target,
    'current': current,
    'completed': completed,
    'rewardCollected': rewardCollected,
    'difficulty': difficulty.name,
    'reward': reward.toMap(),
  };

  static DailyChallenge fromMap(Map<String, Object?> m) {
    // Legacy support: old format had 'reward' as a string (JokerType name)
    final rawReward = m['reward'];
    final ChallengeReward reward;
    if (rawReward is String) {
      reward = JokerReward(JokerType.values.byName(rawReward));
    } else {
      reward = ChallengeReward.fromMap(rawReward as Map<String, Object?>);
    }
    return DailyChallenge(
      id: m['id'] as String,
      type: ChallengeType.values.byName(m['type'] as String),
      target: m['target'] as int,
      current: m['current'] as int? ?? 0,
      completed: m['completed'] as bool? ?? false,
      rewardCollected: m['rewardCollected'] as bool? ?? false,
      difficulty: ChallengeDifficulty.values.byName(m['difficulty'] as String),
      reward: reward,
    );
  }
}

/// État global des objectifs quotidiens pour un jour.
class DailyChallengeState {
  final String date; // "YYYY-MM-DD"
  final List<DailyChallenge> challenges;
  final bool bonusCollected;

  const DailyChallengeState({
    required this.date,
    required this.challenges,
    this.bonusCollected = false,
  });

  bool get allCompleted =>
      challenges.isNotEmpty && challenges.every((c) => c.completed);

  bool get canCollectBonus => allCompleted && !bonusCollected;

  /// Number of completed objectives.
  int get completedCount => challenges.where((c) => c.completed).length;

  DailyChallengeState copyWith({
    List<DailyChallenge>? challenges,
    bool? bonusCollected,
  }) {
    return DailyChallengeState(
      date: date,
      challenges: challenges ?? this.challenges,
      bonusCollected: bonusCollected ?? this.bonusCollected,
    );
  }

  Map<String, Object?> toMap() => {
    'date': date,
    'challenges': challenges.map((c) => c.toMap()).toList(),
    'bonusCollected': bonusCollected,
  };

  static DailyChallengeState fromMap(Map<String, Object?> m) =>
      DailyChallengeState(
        date: m['date'] as String,
        challenges: (m['challenges'] as List<dynamic>)
            .map((e) => DailyChallenge.fromMap(Map<String, Object?>.from(e as Map)))
            .toList(),
        bonusCollected: m['bonusCollected'] as bool? ?? false,
      );
}
