import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/models/player_streak.dart';
import 'package:shape_merge/core/services/streak_service.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';

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
    if (_isProcessing) return;
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

  /// Delivers the joker reward to the game inventory. Called from the popup collect button.
  Future<void> claimStreakReward() async {
    if (state == null || state!.rewardClaimed || state!.reward == null) return;
    final (jokerType, amount) = state!.reward!;
    _ref.read(gameStateProvider.notifier).addJokers(jokerType, amount);

    // Persist claimed date
    final storage = await _ref.read(localStorageProvider.future);
    await storage.setRewardClaimedDate(PlayerStreak.todayKey());

    if (mounted) {
      state = state!.copyWith(rewardClaimed: true);
    }
  }

  /// Whether the reward has been claimed today.
  bool get rewardClaimed => state?.rewardClaimed ?? false;

  /// Call on sign-in to migrate guest streak → Firestore.
  Future<void> migrateAndRefresh(User user) async {
    // Acquire the processing lock so a concurrent checkAndUpdate (e.g. from
    // didChangeAppLifecycleState.resumed) cannot run during migration.
    if (_isProcessing) return;
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
