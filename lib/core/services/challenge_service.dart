import 'dart:convert';
import 'dart:math';

import 'package:shape_merge/core/config/challenge_config.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/daily_challenge.dart';
import 'package:shape_merge/core/models/player_streak.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/services/firestore_service.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';

const _log = AppLogger('Challenge');

/// Generates and manages daily challenges.
/// All logic is client-side — no Cloud Function needed.
/// The client owns its own /players/{uid}/dailyChallenges document.
class ChallengeService {
  const ChallengeService();

  // ── Keys ───────────────────────────────────────────────────────────────────


  // ── Guest mode ─────────────────────────────────────────────────────────────

  Future<DailyChallengeState> loadOrGenerateGuest(
    LocalStorageService storage, {
    required int playerLevel,
  }) async {
    final json = storage.dailyChallengesJson;
    if (json != null) {
      try {
        final state = DailyChallengeState.fromMap(
            Map<String, Object?>.from(jsonDecode(json) as Map));
        if (state.date == PlayerStreak.todayKey()) return state;
      } catch (e) {
        _log.warning('Failed to parse guest challenges', error: e);
      }
    }
    // Generate new ones
    final state = _generate(
      date: PlayerStreak.todayKey(),
      seed: '${storage.guestName}_${PlayerStreak.todayKey()}',
      playerLevel: playerLevel,
    );
    await _saveGuest(state, storage);
    return state;
  }

  Future<void> syncProgressGuest(
    DailyChallengeState state,
    LocalStorageService storage,
  ) => _saveGuest(state, storage);

  // ── Signed-in mode ─────────────────────────────────────────────────────────

  Future<DailyChallengeState> loadOrGenerateSigned({
    required String uid,
    required FirestoreService firestore,
    required int playerLevel,
  }) async {
    final doc = await firestore.getDailyChallenges(uid);
    if (doc != null && doc['date'] == PlayerStreak.todayKey()) {
      try {
        return DailyChallengeState.fromMap(doc);
      } catch (e) {
        _log.warning('Failed to parse signed challenges', error: e);
      }
    }
    final state = _generate(
      date: PlayerStreak.todayKey(),
      seed: '${uid}_${PlayerStreak.todayKey()}',
      playerLevel: playerLevel,
    );
    await firestore.saveDailyChallenges(uid, state);
    return state;
  }

  Future<void> syncProgressSigned(
    DailyChallengeState state, {
    required String uid,
    required FirestoreService firestore,
  }) async {
    await firestore.saveDailyChallenges(uid, state);
  }

  // ── Progress update ────────────────────────────────────────────────────────

  /// Called at end of game. Updates current counters and marks completed.
  DailyChallengeState applyGameResult(
    DailyChallengeState state, {
    required int fusionsThisGame,
    required int scoreThisGame,
    required int jokersUsedThisGame,
    required int maxLevelReached,
  }) {
    final updated = state.challenges.map((c) {
      if (c.rewardCollected) return c;
      int newCurrent = c.current;
      switch (c.type) {
        case ChallengeType.fusions:
          newCurrent = min(c.current + fusionsThisGame, c.target);
        case ChallengeType.score:
          // Best score in a single game (not cumulative)
          if (scoreThisGame > newCurrent) newCurrent = min(scoreThisGame, c.target);
        case ChallengeType.parties:
          newCurrent = min(c.current + 1, c.target);
        case ChallengeType.formeMax:
          if (maxLevelReached > newCurrent) newCurrent = min(maxLevelReached, c.target);
        case ChallengeType.jokersUses:
          newCurrent = min(c.current + jokersUsedThisGame, c.target);
      }
      return c.copyWith(
        current: newCurrent,
        completed: newCurrent >= c.target,
      );
    }).toList();

    return state.copyWith(challenges: updated);
  }

  // ── Generator ─────────────────────────────────────────────────────────────

  DailyChallengeState _generate({
    required String date,
    required String seed,
    required int playerLevel,
  }) {
    final rng = Random(seed.hashCode);

    // Difficulty band based on level
    final ChallengeDifficulty band;
    if (playerLevel < ChallengeBands.easyMaxLevel) {
      band = ChallengeDifficulty.easy;
    } else if (playerLevel < ChallengeBands.mediumMaxLevel) {
      band = ChallengeDifficulty.medium;
    } else {
      band = ChallengeDifficulty.hard;
    }

    final types = List<ChallengeType>.from(ChallengeType.values)..shuffle(rng);
    final selected = types.take(3).toList();

    final challenges = selected.asMap().entries.map((e) {
      final idx = e.key;
      final type = e.value;
      // Mix difficulties: one hard, one medium, one easy (adjusted to band)
      final diff = idx == 0
          ? band
          : idx == 1
              ? ChallengeDifficulty.medium
              : ChallengeDifficulty.easy;
      return _buildChallenge(type, diff, rng);
    }).toList();

    return DailyChallengeState(date: date, challenges: challenges);
  }

  DailyChallenge _buildChallenge(
    ChallengeType type,
    ChallengeDifficulty diff,
    Random rng,
  ) {
    final (target, reward) = _targetAndReward(type, diff, rng);
    return DailyChallenge(
      id: '${type.name}_${diff.name}_${rng.nextInt(9999)}',
      type: type,
      target: target,
      difficulty: diff,
      reward: reward,
    );
  }

  (int, ChallengeReward) _targetAndReward(
      ChallengeType type, ChallengeDifficulty diff, Random rng) {
    // 50% chance joker, 50% chance XP
    final isXP = rng.nextBool();

    final int target = switch (type) {
      ChallengeType.fusions    => ChallengeTargets.target('fusions', diff.name),
      ChallengeType.score      => ChallengeTargets.target('score', diff.name),
      ChallengeType.parties    => ChallengeTargets.target('parties', diff.name),
      ChallengeType.formeMax   => ChallengeTargets.target('formeMax', diff.name),
      ChallengeType.jokersUses => ChallengeTargets.target('jokersUses', diff.name),
    };

    final ChallengeReward reward;
    if (isXP) {
      reward = XpReward(ChallengeRewards.xp[diff.name] ?? 15);
    } else {
      reward = JokerReward(ChallengeRewards.joker[diff.name] ?? JokerType.bomb);
    }

    return (target, reward);
  }

  // ── Persistence helpers ────────────────────────────────────────────────────

  Future<void> _saveGuest(
      DailyChallengeState state, LocalStorageService storage) async {
    await storage.setDailyChallengesJson(jsonEncode(state.toMap()));
  }
}
