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

  /// Called at app launch (SplashScreen) and on app resume (AppLifecycleState.resumed).
  /// Delivers the joker reward via gameStateProvider if a new streak day was earned.
  Future<void> checkAndUpdate() async {
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
        // Player doc not yet created — fall back to guest logic until it's ready
        result = await service.checkAndUpdateGuest(storage);
      }
    } else {
      result = await service.checkAndUpdateGuest(storage);
    }

    // Deliver joker reward if a new streak day was earned
    if (result.streakIncremented && result.reward != null) {
      final (jokerType, amount) = result.reward!;
      _ref.read(gameStateProvider.notifier).addJokers(jokerType, amount);
    }

    if (mounted) state = result;
  }

  /// Call on sign-in to migrate guest streak → Firestore.
  /// Then run checkAndUpdate to refresh state.
  Future<void> migrateAndRefresh(User user) async {
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

    await checkAndUpdate();
  }

  /// Clears the result — used after the popup is dismissed.
  void clearResult() {
    if (mounted) state = null;
  }
}
