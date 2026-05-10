import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  /// Retries a Firestore write up to [maxRetries] times with exponential backoff.
  Future<void> _withRetry(
    Future<void> Function() action, {
    int maxRetries = 2,
    String label = 'write',
  }) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        await action();
        return;
      } catch (e) {
        if (attempt == maxRetries) {
          _log.error('$label failed after ${maxRetries + 1} attempts', error: e);
          rethrow;
        }
        final delay = Duration(milliseconds: 500 * (1 << attempt));
        _log.warning('$label attempt ${attempt + 1} failed, retrying in ${delay.inMilliseconds}ms');
        await Future<void>.delayed(delay);
      }
    }
  }

  CollectionReference<Map<String, Object?>> get _leaderboardRef =>
      _firestore.collection(FirestoreKeys.leaderboard);

  DocumentReference<Map<String, Object?>> _playerRef(String uid) =>
      _firestore.collection(FirestoreKeys.players).doc(uid);

  Future<void> submitScore(LeaderboardEntry entry) async {
    await _withRetry(() async {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('submitScore');
      await callable.call<Map<String, dynamic>>({
        'score': entry.score,
        'mergeCount': entry.mergeCount,
        'maxLevel': entry.maxLevel,
        'displayName': entry.displayName,
        'photoUrl': entry.photoUrl,
        'avatarId': entry.avatarId,
      });
      _log.info('Score submitted via function: ${entry.score} for ${entry.uid}');
    }, label: 'submitScore');
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

  Future<void> savePlayer(Player player) async {
    await _withRetry(() async {
      await _playerRef(player.uid).set(player.toFirestore(), SetOptions(merge: true));
    }, label: 'savePlayer');
  }

  Future<Player?> getPlayer(String uid) async {
    final doc = await _playerRef(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return Player.fromFirestore(uid, doc.data()!);
  }

  // Bug B2 fix: increment gamesPlayed and totalMerges (were never called before)
  Future<void> incrementPlayerStats(String uid, {required int mergesThisGame}) async {
    await _withRetry(() async {
      await _playerRef(uid).set({
        'gamesPlayed': FieldValue.increment(1),
        'totalMerges': FieldValue.increment(mergesThisGame),
      }, SetOptions(merge: true));
    }, label: 'incrementPlayerStats');
  }

  Future<void> updateXP(String uid, {required int level, required int currentXP, required int totalXP}) async {
    await _withRetry(() async {
      await _playerRef(uid).set({
        'level': level,
        'currentXP': currentXP,
        'totalXP': totalXP,
      }, SetOptions(merge: true));
    }, label: 'updateXP');
  }

  Future<void> updateBestScore(String uid, int bestScore) async {
    await _withRetry(() async {
      await _playerRef(uid).set({
        'bestScore': bestScore,
      }, SetOptions(merge: true));
    }, label: 'updateBestScore');
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
    await _withRetry(() async {
      await _playerRef(uid).set({
        'currentStreak': streak.currentStreak,
        'longestStreak': streak.longestStreak,
        'lastLoginDate': streak.lastLoginDate,
        'nextRewardIndex': streak.nextRewardIndex,
      }, SetOptions(merge: true));
    }, label: 'updateStreak');
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
    await _withRetry(() async {
      await _dailyChallengesRef(uid).set(state.toMap().cast<String, Object?>());
    }, label: 'saveDailyChallenges');
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
    await _withRetry(() async {
      await _playerRef(uid).set({
        'jokerInventory': inventory.toMap(),
      }, SetOptions(merge: true));
    }, label: 'updateJokerInventory');
  }

  Future<void> updateRewardClaimedDate(String uid, String date) async {
    await _withRetry(() async {
      await _playerRef(uid).set({
        'rewardClaimedDate': date,
      }, SetOptions(merge: true));
    }, label: 'updateRewardClaimedDate');
  }

  Future<void> updateNoAdsPurchased(String uid, {required bool value}) async {
    await _withRetry(() async {
      await _playerRef(uid).set({
        'noAdsPurchased': value,
      }, SetOptions(merge: true));
    }, label: 'updateNoAdsPurchased');
  }

  Future<void> updateEmojiPackPurchased(String uid, {required bool value}) async {
    await _withRetry(() async {
      await _playerRef(uid).set({
        'emojiPackPurchased': value,
      }, SetOptions(merge: true));
    }, label: 'updateEmojiPackPurchased');
  }

  Future<void> updateProfile(String uid, {String? displayName, String? avatarId}) async {
    final data = <String, Object?>{};
    if (displayName != null) data['displayName'] = displayName;
    if (avatarId != null) data['avatarId'] = avatarId;
    if (data.isNotEmpty) {
      await _withRetry(() async {
        await _playerRef(uid).set(data, SetOptions(merge: true));
      }, label: 'updateProfile');
      // Leaderboard displayName/avatar will be updated on next score submit
      // (via Cloud Function submitScore)
    }
  }
}
