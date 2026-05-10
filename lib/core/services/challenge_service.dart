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
    if (json != null && json.isNotEmpty) {
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

  /// Called in real-time during gameplay. Updates all objectives EXCEPT `parties`
  /// (which requires a completed game). Uses baseline values from game start
  /// to compute correct progress.
  DailyChallengeState applyLiveProgress(
    DailyChallengeState state, {
    required Map<String, int> baselines,
    required int fusionsSoFar,
    required int scoreSoFar,
    required int jokersUsedSoFar,
    required int maxLevelSoFar,
    required int shapesDestroyedSoFar,
    required int wildcardMergesSoFar,
    required int highLevelMergesSoFar,
    required int maxComboSoFar,
  }) {
    final updated = state.challenges.map((c) {
      if (c.rewardCollected || c.type == ChallengeType.parties) return c;
      final base = baselines[c.id] ?? c.current;
      int newCurrent = base;
      switch (c.type) {
        case ChallengeType.fusions:
          newCurrent = min(base + fusionsSoFar, c.target);
        case ChallengeType.score:
          if (scoreSoFar > newCurrent) newCurrent = min(scoreSoFar, c.target);
        case ChallengeType.formeMax:
          if (maxLevelSoFar > newCurrent) newCurrent = min(maxLevelSoFar, c.target);
        case ChallengeType.jokersUses:
          newCurrent = min(base + jokersUsedSoFar, c.target);
        case ChallengeType.shapesDestroyed:
          newCurrent = min(base + shapesDestroyedSoFar, c.target);
        case ChallengeType.wildcardMerges:
          newCurrent = min(base + wildcardMergesSoFar, c.target);
        case ChallengeType.highLevelMerges:
          newCurrent = min(base + highLevelMergesSoFar, c.target);
        case ChallengeType.maxCombo:
          if (maxComboSoFar > newCurrent) newCurrent = min(maxComboSoFar, c.target);
        case ChallengeType.parties:
          break; // handled only at game over
      }
      return c.copyWith(
        current: newCurrent,
        completed: newCurrent >= c.target,
      );
    }).toList();

    return state.copyWith(challenges: updated);
  }

  /// Called at end of game. Updates current counters and marks completed.
  DailyChallengeState applyGameResult(
    DailyChallengeState state, {
    required int fusionsThisGame,
    required int scoreThisGame,
    required int jokersUsedThisGame,
    required int maxLevelReached,
    required int shapesDestroyedThisGame,
    required int wildcardMergesThisGame,
    required int highLevelMergesThisGame,
    required int maxComboReached,
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
        case ChallengeType.shapesDestroyed:
          newCurrent = min(c.current + shapesDestroyedThisGame, c.target);
        case ChallengeType.wildcardMerges:
          newCurrent = min(c.current + wildcardMergesThisGame, c.target);
        case ChallengeType.highLevelMerges:
          newCurrent = min(c.current + highLevelMergesThisGame, c.target);
        case ChallengeType.maxCombo:
          // Best combo in a single game (not cumulative)
          if (maxComboReached > newCurrent) newCurrent = min(maxComboReached, c.target);
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
      // Only the hardest challenge (idx 0) gives a joker, others give XP
      return _buildChallenge(type, diff, rng, forceXP: idx != 0);
    }).toList();

    return DailyChallengeState(date: date, challenges: challenges);
  }

  DailyChallenge _buildChallenge(
    ChallengeType type,
    ChallengeDifficulty diff,
    Random rng, {
    bool forceXP = false,
  }) {
    final (target, reward) = _targetAndReward(type, diff, rng, forceXP: forceXP);
    return DailyChallenge(
      id: '${type.name}_${diff.name}_${rng.nextInt(9999)}',
      type: type,
      target: target,
      difficulty: diff,
      reward: reward,
    );
  }

  (int, ChallengeReward) _targetAndReward(
      ChallengeType type, ChallengeDifficulty diff, Random rng, {
      bool forceXP = false,
  }) {
    final int target = switch (type) {
      ChallengeType.fusions         => ChallengeTargets.target('fusions', diff.name),
      ChallengeType.score           => ChallengeTargets.target('score', diff.name),
      ChallengeType.parties         => ChallengeTargets.target('parties', diff.name),
      ChallengeType.formeMax        => ChallengeTargets.target('formeMax', diff.name),
      ChallengeType.jokersUses      => ChallengeTargets.target('jokersUses', diff.name),
      ChallengeType.shapesDestroyed => ChallengeTargets.target('shapesDestroyed', diff.name),
      ChallengeType.wildcardMerges  => ChallengeTargets.target('wildcardMerges', diff.name),
      ChallengeType.highLevelMerges => ChallengeTargets.target('highLevelMerges', diff.name),
      ChallengeType.maxCombo        => ChallengeTargets.target('maxCombo', diff.name),
    };

    final ChallengeReward reward;
    if (forceXP) {
      reward = XpReward(ChallengeRewards.xp[diff.name] ?? 5);
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
