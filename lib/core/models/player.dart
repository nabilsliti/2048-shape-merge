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

  const Player({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.avatarId,
    this.bestScore = 0,
    this.totalMerges = 0,
    this.gamesPlayed = 0,
    this.jokerInventory = const JokerInventory(),
  });

  Player copyWith({
    String? displayName,
    String? photoUrl,
    String? avatarId,
    int? bestScore,
    int? totalMerges,
    int? gamesPlayed,
    JokerInventory? jokerInventory,
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
    );
  }
}
