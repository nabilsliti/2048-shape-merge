import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/daily_challenge.dart';
import 'package:shape_merge/core/models/player_streak.dart';
import 'package:shape_merge/core/services/challenge_service.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/providers/progression_provider.dart';

final challengeServiceProvider =
    Provider<ChallengeService>((_) => const ChallengeService());

/// Holds today's daily challenge state. Null until first load.
final dailyChallengeProvider =
    StateNotifierProvider<DailyChallengeNotifier, DailyChallengeState?>(
        DailyChallengeNotifier.new);

class DailyChallengeNotifier extends StateNotifier<DailyChallengeState?> {
  DailyChallengeNotifier(this._ref) : super(null);

  final Ref _ref;

  /// Called at app launch and on resume — loads or generates today's objectives.
  Future<void> checkRenewal() async {
    final service = _ref.read(challengeServiceProvider);
    final storage = await _ref.read(localStorageProvider.future);
    final user = _ref.read(authStateProvider).valueOrNull;
    final player = user != null ? await _ref.read(playerProvider.future) : null;
    final playerLevel = player?.level ?? storage.playerLevel;

    DailyChallengeState loaded;
    if (user != null && player != null) {
      final firestore = _ref.read(firestoreServiceProvider);
      loaded = await service.loadOrGenerateSigned(
        uid: user.uid,
        firestore: firestore,
        storage: storage,
        playerLevel: playerLevel,
      );
    } else {
      loaded = await service.loadOrGenerateGuest(storage, playerLevel: playerLevel);
    }

    if (mounted) state = loaded;
  }

  /// Called at end of each game to update progress.
  Future<void> syncGameResult({
    required int fusionsThisGame,
    required int scoreThisGame,
    required int jokersUsedThisGame,
    required int maxLevelReached,
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
    );

    if (mounted) state = updated;
    await _persist(updated);
  }

  /// Collect reward for a completed challenge.
  Future<void> collectReward(String challengeId) async {
    final current = state;
    if (current == null) return;

    final idx = current.challenges.indexWhere((c) => c.id == challengeId);
    if (idx == -1) return;
    final challenge = current.challenges[idx];
    if (!challenge.canCollect) return;

    // Deliver reward (joker or XP)
    switch (challenge.reward) {
      case JokerReward(:final joker):
        _ref.read(gameStateProvider.notifier).addJokers(joker, 1);
      case XpReward(:final xp):
        _ref.read(progressionProvider.notifier).addBonusXP(xp);
    }

    final updated = current.copyWith(
      challenges: List.of(current.challenges)
        ..[idx] = challenge.copyWith(rewardCollected: true),
    );
    if (mounted) state = updated;
    await _persist(updated);
  }

  /// Collect the bonus for completing all 3 objectives (+3 random jokers).
  Future<void> collectBonus() async {
    final current = state;
    if (current == null || !current.canCollectBonus) return;

    final notifier = _ref.read(gameStateProvider.notifier);
    final bonusRewards = [JokerType.bomb, JokerType.wildcard, JokerType.reducer];
    for (final j in bonusRewards) {
      notifier.addJokers(j, 1);
    }

    final updated = current.copyWith(bonusCollected: true);
    if (mounted) state = updated;
    await _persist(updated);
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
        storage: storage,
      );
    } else {
      await service.syncProgressGuest(state, storage);
    }
  }

  /// Today's date key for display.
  String get todayKey => PlayerStreak.todayKey();
}
