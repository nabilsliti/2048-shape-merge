import 'joker_inventory.dart';

class Player {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String? avatarId;
  final int bestScore;
  final int totalMerges;
  final int gamesPlayed;
  final JokerInventory jokerInventory;
  // Retention fields (stored in Player document, merge-safe with existing data)
  final int currentStreak;
  final int longestStreak;
  final String? lastLoginDate;   // "YYYY-MM-DD" timezone locale
  final int nextRewardIndex;     // index 0-6 dans le cycle de récompenses streak
  final int level;
  final int currentXP;
  final int totalXP;
  final List<String> unlockedRewards;

  const Player({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.avatarId,
    this.bestScore = 0,
    this.totalMerges = 0,
    this.gamesPlayed = 0,
    this.jokerInventory = const JokerInventory(),
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastLoginDate,
    this.nextRewardIndex = 0,
    this.level = 1,
    this.currentXP = 0,
    this.totalXP = 0,
    this.unlockedRewards = const [],
  });

  Player copyWith({
    String? displayName,
    String? photoUrl,
    String? avatarId,
    int? bestScore,
    int? totalMerges,
    int? gamesPlayed,
    JokerInventory? jokerInventory,
    int? currentStreak,
    int? longestStreak,
    String? lastLoginDate,
    int? nextRewardIndex,
    int? level,
    int? currentXP,
    int? totalXP,
    List<String>? unlockedRewards,
  }) {
    return Player(
      uid: uid,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarId: avatarId ?? this.avatarId,
      bestScore: bestScore ?? this.bestScore,
      totalMerges: totalMerges ?? this.totalMerges,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      jokerInventory: jokerInventory ?? this.jokerInventory,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      nextRewardIndex: nextRewardIndex ?? this.nextRewardIndex,
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      totalXP: totalXP ?? this.totalXP,
      unlockedRewards: unlockedRewards ?? this.unlockedRewards,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'avatarId': avatarId,
      'bestScore': bestScore,
      'totalMerges': totalMerges,
      'gamesPlayed': gamesPlayed,
      'jokerInventory': jokerInventory.toMap(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastLoginDate': lastLoginDate,
      'nextRewardIndex': nextRewardIndex,
      'level': level,
      'currentXP': currentXP,
      'totalXP': totalXP,
      'unlockedRewards': unlockedRewards,
    };
  }

  factory Player.fromFirestore(String uid, Map<String, Object?> data) {
    final jokerMap = data['jokerInventory'] as Map<String, Object?>?;
    return Player(
      uid: uid,
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      avatarId: data['avatarId'] as String?,
      bestScore: data['bestScore'] as int? ?? 0,
      totalMerges: data['totalMerges'] as int? ?? 0,
      gamesPlayed: data['gamesPlayed'] as int? ?? 0,
      jokerInventory: jokerMap != null
          ? JokerInventory.fromMap(jokerMap)
          : const JokerInventory(),
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      lastLoginDate: data['lastLoginDate'] as String?,
      nextRewardIndex: data['nextRewardIndex'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      currentXP: data['currentXP'] as int? ?? 0,
      totalXP: data['totalXP'] as int? ?? 0,
      unlockedRewards: (data['unlockedRewards'] as List<Object?>?)?.cast<String>() ?? [],
    );
  }
}
