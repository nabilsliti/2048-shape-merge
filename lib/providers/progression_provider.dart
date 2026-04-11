import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/services/progression_service.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';

final progressionServiceProvider =
    Provider<ProgressionService>((_) => const ProgressionService());

/// Holds XP gained and levels gained from the last game.
/// Null between games. Drives the LevelUpOverlay.
class ProgressionResult {
  final int xpGained;
  final int newLevel;
  final int levelsGained;
  final int currentXP;

  const ProgressionResult({
    required this.xpGained,
    required this.newLevel,
    required this.levelsGained,
    required this.currentXP,
  });
}

final progressionProvider =
    StateNotifierProvider<ProgressionNotifier, ProgressionResult?>(
        ProgressionNotifier.new);

class ProgressionNotifier extends StateNotifier<ProgressionResult?> {
  ProgressionNotifier(this._ref) : super(null);

  final Ref _ref;

  /// Call at end of each game to process XP gain.
  /// Returns XP gained (useful for GameOverOverlay display).
  Future<int> processGameEnd({
    required int score,
    required int mergeCount,
    required int maxLevelReached,
  }) async {
    final storage = await _ref.read(localStorageProvider.future);
    final user = _ref.read(authStateProvider).valueOrNull;
    final player = user != null ? await _ref.read(playerProvider.future) : null;
    final challengeState = _ref.read(dailyChallengeProvider);

    final currentStreak = player?.currentStreak ?? storage.currentStreak;
    final completedObjectives = challengeState?.completedCount ?? 0;

    final xpGained = ProgressionService.computeXP(
      score: score,
      mergeCount: mergeCount,
      maxLevelReached: maxLevelReached,
      currentStreak: currentStreak,
      completedObjectives: completedObjectives,
    );

    final ({int level, int currentXP, int leveledUp}) result;

    if (user != null && player != null) {
      final firestore = _ref.read(firestoreServiceProvider);
      result = await _ref.read(progressionServiceProvider).addXPSigned(
        uid: user.uid,
        currentLevel: player.level,
        currentXP: player.currentXP,
        totalXP: player.totalXP,
        xpToAdd: xpGained,
        firestore: firestore,
      );
    } else {
      result = await _ref.read(progressionServiceProvider).addXPGuest(
        storage,
        xpToAdd: xpGained,
      );
    }

    if (mounted) {
      state = ProgressionResult(
        xpGained: xpGained,
        newLevel: result.level,
        levelsGained: result.leveledUp,
        currentXP: result.currentXP,
      );
    }

    return xpGained;
  }

  void clearResult() {
    if (mounted) state = null;
  }

  /// Grant bonus XP directly (e.g. from collecting a daily challenge reward).
  Future<void> addBonusXP(int xp) async {
    final storage = await _ref.read(localStorageProvider.future);
    final user = _ref.read(authStateProvider).valueOrNull;
    final player = user != null ? await _ref.read(playerProvider.future) : null;

    final ({int level, int currentXP, int leveledUp}) result;

    if (user != null && player != null) {
      final firestore = _ref.read(firestoreServiceProvider);
      result = await _ref.read(progressionServiceProvider).addXPSigned(
        uid: user.uid,
        currentLevel: player.level,
        currentXP: player.currentXP,
        totalXP: player.totalXP,
        xpToAdd: xp,
        firestore: firestore,
      );
      _ref.invalidate(playerProvider);
    } else {
      result = await _ref.read(progressionServiceProvider).addXPGuest(
        storage,
        xpToAdd: xp,
      );
    }

    if (mounted) {
      state = ProgressionResult(
        xpGained: xp,
        newLevel: result.level,
        levelsGained: result.leveledUp,
        currentXP: result.currentXP,
      );
    }
  }
}
