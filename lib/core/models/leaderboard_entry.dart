import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String? docId;
  final String uid;
  final String displayName;
  final String? photoUrl;
  final int score;
  final int maxLevel;
  final int mergeCount;
  final DateTime timestamp;
  final String weekKey;

  const LeaderboardEntry({
    this.docId,
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.score,
    required this.maxLevel,
    required this.mergeCount,
    required this.timestamp,
    required this.weekKey,
  });

  Map<String, Object?> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'score': score,
      'maxLevel': maxLevel,
      'mergeCount': mergeCount,
      'timestamp': Timestamp.fromDate(timestamp),
      'weekKey': weekKey,
    };
  }

  factory LeaderboardEntry.fromFirestore(String docId, Map<String, Object?> data) {
    final ts = data['timestamp'];
    return LeaderboardEntry(
      docId: docId,
      uid: data['uid'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      score: data['score'] as int? ?? 0,
      maxLevel: data['maxLevel'] as int? ?? 1,
      mergeCount: data['mergeCount'] as int? ?? 0,
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
      weekKey: data['weekKey'] as String? ?? '',
    );
  }
}
