import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/daily_challenge.dart';
import 'package:shape_merge/core/models/player_streak.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/services/challenge_service.dart';
import 'package:shape_merge/providers/audio_provider.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/providers/progression_provider.dart';

const _log = AppLogger('DailyChallenge');

final challengeServiceProvider =
    Provider<ChallengeService>((_) => const ChallengeService());

/// Holds today's daily challenge state. Null until first load.
final dailyChallengeProvider =
    StateNotifierProvider<DailyChallengeNotifier, DailyChallengeState?>(
        DailyChallengeNotifier.new);

class DailyChallengeNotifier extends StateNotifier<DailyChallengeState?> {
  DailyChallengeNotifier(this._ref) : super(null);

  final Ref _ref;
  int _renewalGeneration = 0;

  /// Baseline challenge progress values captured at game start.
  /// Used by live sync to compute correct cumulative progress.
  Map<String, int> _baselines = {};

  /// Snapshot the current challenge progress as baseline for a new game.
  void captureBaseline() {
    final current = state;
    if (current == null) {
      _baselines = {};
      return;
    }
    _baselines = {
      for (final c in current.challenges) c.id: c.current,
    };
  }

  /// Called at app launch and on resume — loads or generates today's objectives.
  Future<void> checkRenewal() async {
    final generation = ++_renewalGeneration;
    final service = _ref.read(challengeServiceProvider);
    final storage = await _ref.read(localStorageProvider.future);
    final user = _ref.read(authStateProvider).valueOrNull;
    final player = user != null ? await _ref.read(playerProvider.future) : null;
    if (generation != _renewalGeneration) return; // superseded by newer call
    final playerLevel = player?.level ?? storage.playerLevel;

    DailyChallengeState loaded;
    if (user != null && player != null) {
      final firestore = _ref.read(firestoreServiceProvider);
      loaded = await service.loadOrGenerateSigned(
        uid: user.uid,
        firestore: firestore,
        playerLevel: playerLevel,
      );
    } else {
      loaded = await service.loadOrGenerateGuest(storage, playerLevel: playerLevel);
    }

    if (mounted && generation == _renewalGeneration) state = loaded;
  }

  /// Reset state for account switch (clear stale data immediately).
  void reset() {
    _renewalGeneration++;
    if (mounted) state = null;
  }

  /// Called in real-time during gameplay to update objectives.
  /// Returns list of challenges that were NEWLY completed.
  List<DailyChallenge> syncLiveProgress({
    required int fusionsSoFar,
    required int scoreSoFar,
    required int jokersUsedSoFar,
    required int maxLevelSoFar,
    required int shapesDestroyedSoFar,
    required int wildcardMergesSoFar,
    required int highLevelMergesSoFar,
    required int maxComboSoFar,
  }) {
    final current = state;
    if (current == null) return [];

    final completedBefore = {
      for (final c in current.challenges)
        if (c.completed) c.id,
    };

    final service = _ref.read(challengeServiceProvider);
    final updated = service.applyLiveProgress(
      current,
      baselines: _baselines,
      fusionsSoFar: fusionsSoFar,
      scoreSoFar: scoreSoFar,
      jokersUsedSoFar: jokersUsedSoFar,
      maxLevelSoFar: maxLevelSoFar,
      shapesDestroyedSoFar: shapesDestroyedSoFar,
      wildcardMergesSoFar: wildcardMergesSoFar,
      highLevelMergesSoFar: highLevelMergesSoFar,
      maxComboSoFar: maxComboSoFar,
    );

    if (mounted) state = updated;

    // Persist asynchronously — fire and forget
    unawaited(_persist(updated));

    // Return newly completed challenges
    return [
      for (final c in updated.challenges)
        if (c.completed && !completedBefore.contains(c.id)) c,
    ];
  }

  /// Called at end of each game to update progress.
  Future<void> syncGameResult({
    required int fusionsThisGame,
    required int scoreThisGame,
    required int jokersUsedThisGame,
    required int maxLevelReached,
    required int shapesDestroyedThisGame,
    required int wildcardMergesThisGame,
    required int highLevelMergesThisGame,
    required int maxComboReached,
  }) async {
    final current = state;
    if (current == null) return;

    final service = _ref.read(challengeServiceProvider);
    final updated = service.applyGameResult(
      current,
      fusionsThisGame: fusionsThisGame,
      scoreThisGame: scoreThisGame,
      jokersUsedThisGame: jokersUsedThisGame,
      maxLevelReached: maxLevelReached,
      shapesDestroyedThisGame: shapesDestroyedThisGame,
      wildcardMergesThisGame: wildcardMergesThisGame,
      highLevelMergesThisGame: highLevelMergesThisGame,
      maxComboReached: maxComboReached,
    );

    if (mounted) state = updated;
    await _persist(updated);
  }

  /// Called at end of a completed game — only increments `parties` objective.
  /// Other objectives are already synced in real-time via [syncLiveProgress].
  Future<void> syncGameEnd() async {
    final current = state;
    if (current == null) return;

    final updated = current.copyWith(
      challenges: current.challenges.map((c) {
        if (c.rewardCollected || c.type != ChallengeType.parties) return c;
        final newCurrent = (c.current + 1).clamp(0, c.target);
        return c.copyWith(
          current: newCurrent,
          completed: newCurrent >= c.target,
        );
      }).toList(),
    );

    if (mounted) state = updated;
    await _persist(updated);
  }

  /// Collect reward for a completed challenge.
  /// Signed-in: calls Cloud Function (server distributes reward).
  /// Guest: distributes reward client-side.
  Future<void> collectReward(String challengeId) async {
    final current = state;
    if (current == null) return;

    final idx = current.challenges.indexWhere((c) => c.id == challengeId);
    if (idx == -1) return;
    final challenge = current.challenges[idx];
    if (!challenge.canCollect || challenge.rewardCollected) return;

    // Mark collected in state FIRST to prevent double-tap
    final updated = current.copyWith(
      challenges: List.of(current.challenges)
        ..[idx] = challenge.copyWith(rewardCollected: true),
    );
    if (mounted) state = updated;
    _ref.read(audioServiceProvider).playReward();

    final user = _ref.read(authStateProvider).valueOrNull;

    if (user != null) {
      // ── Signed-in: Cloud Function distributes reward ──
      try {
        await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('claimChallengeReward')
            .call({'challengeId': challengeId});

        // Refresh player data to pick up joker/XP changes
        _ref.invalidate(playerProvider);
      } catch (e) {
        _log.error('claimChallengeReward failed', error: e);
        // Revert optimistic UI on failure
        if (mounted) state = current;
        return;
      }
    } else {
      // ── Guest: distribute reward client-side ──
      switch (challenge.reward) {
        case JokerReward(:final joker):
          _ref.read(gameStateProvider.notifier).addJokers(joker, 1);
        case XpReward(:final xp):
          _ref.read(progressionProvider.notifier).addBonusXP(xp);
      }
      await _persist(updated);
    }
  }

  /// Collect reward x2 (after watching ad). Same as [collectReward] but doubles.
  /// Guest: distributes 2x client-side. Signed-in: calls Cloud Function with x2 flag.
  Future<void> collectRewardX2(String challengeId) async {
    final current = state;
    if (current == null) return;

    final idx = current.challenges.indexWhere((c) => c.id == challengeId);
    if (idx == -1) return;
    final challenge = current.challenges[idx];
    if (!challenge.canCollect || challenge.rewardCollected) return;

    // Mark collected in state FIRST to prevent double-tap
    final updated = current.copyWith(
      challenges: List.of(current.challenges)
        ..[idx] = challenge.copyWith(rewardCollected: true),
    );
    if (mounted) state = updated;
    _ref.read(audioServiceProvider).playReward();

    final user = _ref.read(authStateProvider).valueOrNull;

    if (user != null) {
      try {
        await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('claimChallengeReward')
            .call({'challengeId': challengeId, 'doubleReward': true});
        _ref.invalidate(playerProvider);
      } catch (e) {
        _log.error('claimChallengeReward x2 failed', error: e);
        if (mounted) state = current;
        return;
      }
    } else {
      switch (challenge.reward) {
        case JokerReward(:final joker):
          _ref.read(gameStateProvider.notifier).addJokers(joker, 2);
        case XpReward(:final xp):
          _ref.read(progressionProvider.notifier).addBonusXP(xp * 2);
      }
      await _persist(updated);
    }
  }

  /// Collect the bonus for completing all 3 objectives (+3 jokers).
  /// Signed-in: calls Cloud Function. Guest: distributes client-side.
  Future<void> collectBonus() async {
    final current = state;
    if (current == null || !current.canCollectBonus) return;

    _ref.read(audioServiceProvider).playReward();

    final updated = current.copyWith(bonusCollected: true);
    if (mounted) state = updated;

    final user = _ref.read(authStateProvider).valueOrNull;

    if (user != null) {
      // ── Signed-in: Cloud Function distributes bonus ──
      try {
        await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('claimChallengeReward')
            .call({'bonus': true});

        _ref.invalidate(playerProvider);
      } catch (e) {
        _log.error('claimChallengeReward (bonus) failed', error: e);
        if (mounted) state = current;
        return;
      }
    } else {
      // ── Guest: distribute bonus client-side ──
      final notifier = _ref.read(gameStateProvider.notifier);
      for (final j in [JokerType.bomb, JokerType.wildcard, JokerType.reducer]) {
        notifier.addJokers(j, 1);
      }
      await _persist(updated);
    }
  }

  Future<void> _persist(DailyChallengeState state) async {
    final service = _ref.read(challengeServiceProvider);
    final storage = await _ref.read(localStorageProvider.future);
    final user = _ref.read(authStateProvider).valueOrNull;

    if (user != null) {
      final firestore = _ref.read(firestoreServiceProvider);
      await service.syncProgressSigned(
        state,
        uid: user.uid,
        firestore: firestore,
      );
    } else {
      await service.syncProgressGuest(state, storage);
    }
  }

  /// Today's date key for display.
  String get todayKey => PlayerStreak.todayKey();
}
