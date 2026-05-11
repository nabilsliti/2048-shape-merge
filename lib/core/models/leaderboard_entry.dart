import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String? docId;
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String? avatarId;
  final int score;
  final int maxLevel;
  final int mergeCount;
  final DateTime timestamp;

  const LeaderboardEntry({
    this.docId,
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.avatarId,
    required this.score,
    required this.maxLevel,
    required this.mergeCount,
    required this.timestamp,
  });

  Map<String, Object?> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'avatarId': avatarId,
      'score': score,
      'maxLevel': maxLevel,
      'mergeCount': mergeCount,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory LeaderboardEntry.fromFirestore(String docId, Map<String, Object?> data) {
    final ts = data['timestamp'];
    // The Cloud Function `submitScore` stores the entry under `docId == uid`
    // but does NOT write an explicit `uid` field on the document. Earlier
    // client-written docs DO carry `uid`. Fall back to `docId` so the
    // self-row detection in the leaderboard screen always works regardless
    // of write path.
    final rawUid = data['uid'] as String?;
    return LeaderboardEntry(
      docId: docId,
      uid: (rawUid == null || rawUid.isEmpty) ? docId : rawUid,
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      avatarId: data['avatarId'] as String?,
      score: data['score'] as int? ?? 0,
      maxLevel: data['maxLevel'] as int? ?? 1,
      mergeCount: data['mergeCount'] as int? ?? 0,
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

