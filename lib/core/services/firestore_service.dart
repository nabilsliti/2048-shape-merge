import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shape_merge/core/models/leaderboard_entry.dart';
import 'package:shape_merge/core/models/player.dart';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, Object?>> get _leaderboardRef =>
      _firestore.collection('leaderboard');

  DocumentReference<Map<String, Object?>> _playerRef(String uid) =>
      _firestore.collection('players').doc(uid);

  Future<void> submitScore(LeaderboardEntry entry) async {
    final query = await _leaderboardRef
        .where('uid', isEqualTo: entry.uid)
        .orderBy('score', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty || query.docs.first.data()['score'] as int < entry.score) {
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(entry.toFirestore());
      } else {
        await _leaderboardRef.add(entry.toFirestore());
      }
    }
  }

  Stream<List<LeaderboardEntry>> leaderboardStream({int limit = 50}) {
    return _leaderboardRef
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => LeaderboardEntry.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Stream<List<LeaderboardEntry>> weeklyLeaderboardStream(String weekKey,
      {int limit = 50}) {
    return _leaderboardRef
        .where('weekKey', isEqualTo: weekKey)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => LeaderboardEntry.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<void> savePlayer(Player player) async {
    await _playerRef(player.uid).set(player.toFirestore(), SetOptions(merge: true));
  }

  Future<Player?> getPlayer(String uid) async {
    final doc = await _playerRef(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return Player.fromFirestore(uid, doc.data()!);
  }
}
