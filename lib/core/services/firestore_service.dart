import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shape_merge/core/config/firestore_keys.dart';
import 'package:shape_merge/core/models/daily_challenge.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/models/leaderboard_entry.dart';
import 'package:shape_merge/core/models/player.dart';
import 'package:shape_merge/core/models/player_streak.dart';
import 'package:shape_merge/core/services/app_logger.dart';

const _log = AppLogger('Firestore');

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, Object?>> get _leaderboardRef =>
      _firestore.collection(FirestoreKeys.leaderboard);

  DocumentReference<Map<String, Object?>> _playerRef(String uid) =>
      _firestore.collection(FirestoreKeys.players).doc(uid);

  Future<void> submitScore(LeaderboardEntry entry) async {
    try {
      final docRef = _leaderboardRef.doc(entry.uid);
      await _firestore.runTransaction((tx) async {
        final doc = await tx.get(docRef);
        final existing = (doc.data()?['score'] as num?)?.toInt() ?? 0;
        if (!doc.exists || existing < entry.score) {
          tx.set(docRef, entry.toFirestore());
          _log.info('Score submitted: ${entry.score} for ${entry.uid}');
        } else {
          _log.debug('Score ${entry.score} not higher than existing $existing');
        }
      });
    } catch (e) {
      _log.error('Score submission failed', error: e);
      rethrow;
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

  // Bug B2 fix: increment gamesPlayed and totalMerges (were never called before)
  Future<void> incrementPlayerStats(String uid, {required int mergesThisGame}) async {
    try {
      await _playerRef(uid).set({
        'gamesPlayed': FieldValue.increment(1),
        'totalMerges': FieldValue.increment(mergesThisGame),
      }, SetOptions(merge: true));
    } catch (e) {
      _log.error('incrementPlayerStats failed', error: e);
    }
  }

  Future<void> updateXP(String uid, {required int level, required int currentXP, required int totalXP}) async {
    await _playerRef(uid).set({
      'level': level,
      'currentXP': currentXP,
      'totalXP': totalXP,
    }, SetOptions(merge: true));
  }

  Future<void> updateBestScore(String uid, int bestScore) async {
    try {
      await _playerRef(uid).set({
        'bestScore': bestScore,
      }, SetOptions(merge: true));
    } catch (e) {
      _log.error('updateBestScore failed', error: e);
    }
  }

  Future<int> getLeaderboardScore(String uid) async {
    try {
      final doc = await _leaderboardRef.doc(uid).get();
      if (doc.exists) {
        return (doc.data()?['score'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      _log.warning('getLeaderboardScore failed', error: e);
    }
    return 0;
  }

  Future<void> updateStreak(String uid, PlayerStreak streak) async {
    await _playerRef(uid).set({
      'currentStreak': streak.currentStreak,
      'longestStreak': streak.longestStreak,
      'lastLoginDate': streak.lastLoginDate,
      'nextRewardIndex': streak.nextRewardIndex,
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, Object?>> _dailyChallengesRef(String uid) =>
      _playerRef(uid).collection(FirestoreKeys.playerData).doc(FirestoreKeys.dailyChallenges);

  Future<Map<String, Object?>?> getDailyChallenges(String uid) async {
    try {
      final doc = await _dailyChallengesRef(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      _log.error('getDailyChallenges failed', error: e);
      return null;
    }
  }

  Future<void> saveDailyChallenges(String uid, DailyChallengeState state) async {
    try {
      await _dailyChallengesRef(uid).set(state.toMap().cast<String, Object?>());
    } catch (e) {
      _log.error('saveDailyChallenges failed', error: e);
    }
  }

  /// Deletes all server-side data for [uid] atomically.
  Future<void> deleteAccount(String uid) async {
    try {
      final batch = _firestore.batch();
      batch.delete(_dailyChallengesRef(uid));
      batch.delete(_playerRef(uid));
      batch.delete(_leaderboardRef.doc(uid));
      await batch.commit();
    } catch (e) {
      _log.error('deleteAccount failed for $uid', error: e);
      rethrow;
    }
  }

  Future<void> updateJokerInventory(String uid, JokerInventory inventory) async {
    await _playerRef(uid).set({
      'jokerInventory': inventory.toMap(),
    }, SetOptions(merge: true));
  }

  Future<void> updateRewardClaimedDate(String uid, String date) async {
    await _playerRef(uid).set({
      'rewardClaimedDate': date,
    }, SetOptions(merge: true));
  }

  Future<void> updateNoAdsPurchased(String uid, {required bool value}) async {
    await _playerRef(uid).set({
      'noAdsPurchased': value,
    }, SetOptions(merge: true));
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
      } catch (e) {
        _log.warning('Leaderboard profile sync failed', error: e);
      }
    }
  }
}
