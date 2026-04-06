import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shape_merge/core/models/leaderboard_entry.dart';
import 'package:shape_merge/core/models/player.dart';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, Object?>> get _leaderboardRef =>
      _firestore.collection('leaderboard');

  DocumentReference<Map<String, Object?>> _playerRef(String uid) =>
      _firestore.collection('players').doc(uid);

  Future<void> submitScore(LeaderboardEntry entry) async {
    try {
      final docRef = _leaderboardRef.doc(entry.uid);
      final doc = await docRef.get();

      if (!doc.exists || (doc.data()?['score'] as int? ?? 0) < entry.score) {
        await docRef.set(entry.toFirestore());
        debugPrint('✅ Score submitted: ${entry.score} for ${entry.uid}');
      } else {
        debugPrint('⏭️ Score ${entry.score} not higher than existing');
      }
    } catch (e) {
      debugPrint('❌ Score submission failed: $e');
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

  Future<void> updateProfile(String uid, {String? displayName, String? avatarId}) async {
    final data = <String, Object?>{};
    if (displayName != null) data['displayName'] = displayName;
    if (avatarId != null) data['avatarId'] = avatarId;
    if (data.isNotEmpty) {
      await _playerRef(uid).set(data, SetOptions(merge: true));
      try {
        final doc = await _leaderboardRef.doc(uid).get();
        if (doc.exists) {
          await _leaderboardRef.doc(uid).update(data);
        }
      } catch (_) {}
    }
  }
}
