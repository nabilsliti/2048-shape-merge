import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/models/player_streak.dart';
import 'package:shape_merge/core/services/streak_service.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/providers/progression_provider.dart';

final streakServiceProvider = Provider<StreakService>((_) => const StreakService());

/// Holds the result of the last streak check — drives popup and badge.
/// Null until the first checkAndUpdate completes.
final streakProvider =
    StateNotifierProvider<StreakNotifier, StreakCheckResult?>(StreakNotifier.new);

class StreakNotifier extends StateNotifier<StreakCheckResult?> {
  StreakNotifier(this._ref) : super(null);

  final Ref _ref;
  bool _isProcessing = false;

  /// Called at app launch (SplashScreen) and on app resume (AppLifecycleState.resumed).
  /// Computes streak but does NOT deliver jokers — call [claimStreakReward] from the popup.
  Future<void> checkAndUpdate() async {
    if (_isProcessing || _isClaiming) return;
    _isProcessing = true;
    try {
    final service = _ref.read(streakServiceProvider);
    final storage = await _ref.read(localStorageProvider.future);
    final user = _ref.read(authStateProvider).valueOrNull;

    StreakCheckResult result;

    if (user != null) {
      final player = await _ref.read(playerProvider.future);
      if (player != null) {
        final firestore = _ref.read(firestoreServiceProvider);
        result = await service.checkAndUpdateSigned(
          player: player,
          firestore: firestore,
          storage: storage,
        );
      } else {
        result = await service.checkAndUpdateGuest(storage);
      }
    } else {
      result = await service.checkAndUpdateGuest(storage);
    }

    if (mounted) state = result;
    } finally {
      _isProcessing = false;
    }
  }

  bool _isClaiming = false;

  /// Delivers the reward to the game inventory. Called from the popup collect button.
  /// [doubled] is true when the user watched a rewarded ad for x2.
  Future<void> claimStreakReward({bool doubled = false}) async {
    if (_isClaiming) return;
    if (state == null || state!.rewardClaimed || state!.reward == null) return;
    _isClaiming = true;
    try {
    // Mark claimed in state FIRST to prevent double-call
    if (mounted) state = state!.copyWith(rewardClaimed: true);
    final reward = state!.reward!;
    final multiplier = doubled ? 2 : 1;

    switch (reward) {
      case StreakJokerReward(:final type, :final amount):
        _ref.read(gameStateProvider.notifier).addJokers(type, amount * multiplier);
      case StreakXpReward(:final xp):
        await _ref.read(progressionProvider.notifier).addBonusXP(xp * multiplier);
    }

    // Also deliver milestone bonus rewards if any
    final milestone = state!.milestoneReward;
    if (milestone != null) {
      for (final m in milestone) {
        _ref.read(gameStateProvider.notifier).addJokers(m.type, m.amount);
      }
    }

    // Persist claimed date — Firestore if signed in, localStorage if guest
    final todayKey = PlayerStreak.todayKey();
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      final firestore = _ref.read(firestoreServiceProvider);
      await firestore.updateRewardClaimedDate(user.uid, todayKey);
      // Invalidate so next checkAndUpdate reads fresh rewardClaimedDate
      _ref.invalidate(playerProvider);
    } else {
      final storage = await _ref.read(localStorageProvider.future);
      await storage.setRewardClaimedDate(todayKey);
    }

    } finally {
      _isClaiming = false;
    }
  }

  /// Whether the reward has been claimed today.
  bool get rewardClaimed => state?.rewardClaimed ?? false;

  /// Call on sign-in to migrate guest streak → Firestore.
  Future<void> migrateAndRefresh(User user) async {
    // Wait for any in-flight checkAndUpdate to complete before migrating.
    // Don't skip migration — it's more important than a routine check.
    while (_isProcessing) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    _isProcessing = true;
    try {
      final service = _ref.read(streakServiceProvider);
      final storage = await _ref.read(localStorageProvider.future);
      final firestore = _ref.read(firestoreServiceProvider);
      final player = await _ref.read(playerProvider.future);

      if (player != null) {
        await service.migrateGuestToFirestore(
          player: player,
          storage: storage,
          firestore: firestore,
        );
      }

      // Invalidate playerProvider so checkAndUpdate reads fresh Firestore data
      _ref.invalidate(playerProvider);
    } finally {
      _isProcessing = false;
    }
    await checkAndUpdate();
  }

  /// Auto-claims the reward if not yet done (safety net for dismiss via ✕).
  void ensureRewardClaimed() {
    if (!rewardClaimed) claimStreakReward();
  }
}
