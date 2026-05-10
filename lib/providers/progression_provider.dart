import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/services/analytics_service.dart';
import 'package:shape_merge/core/services/progression_service.dart';
import 'package:shape_merge/providers/auth_providers.dart';
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
  final List<(JokerType, int)> rewards;

  const ProgressionResult({
    required this.xpGained,
    required this.newLevel,
    required this.levelsGained,
    required this.currentXP,
    this.rewards = const [],
  });
}

final progressionProvider =
    StateNotifierProvider<ProgressionNotifier, ProgressionResult?>(
        ProgressionNotifier.new);

class ProgressionNotifier extends StateNotifier<ProgressionResult?> {
  ProgressionNotifier(this._ref) : super(null);

  final Ref _ref;

  /// Call at end of each game to process XP gain.
  /// [completedObjectivesDelta] is the number of objectives newly completed
  /// THIS game (not the total for the day).
  Future<int> processGameEnd({
    required int score,
    required int mergeCount,
    required int maxLevelReached,
    int completedObjectivesDelta = 0,
  }) async {
    final storage = await _ref.read(localStorageProvider.future);
    final user = _ref.read(authStateProvider).valueOrNull;
    final player = user != null ? await _ref.read(playerProvider.future) : null;

    final currentStreak = player?.currentStreak ?? storage.currentStreak;

    final xpGained = ProgressionService.computeXP(
      score: score,
      mergeCount: mergeCount,
      maxLevelReached: maxLevelReached,
      currentStreak: currentStreak,
      completedObjectives: completedObjectivesDelta,
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
      _ref.invalidate(playerProvider);
    } else {
      result = await _ref.read(progressionServiceProvider).addXPGuest(
        storage,
        xpToAdd: xpGained,
      );
    }

    // Collect level-up rewards for all levels gained
    final allRewards = <(JokerType, int)>[];
    if (result.leveledUp > 0) {
      final startLevel = result.level - result.leveledUp;
      for (var lvl = startLevel + 1; lvl <= result.level; lvl++) {
        allRewards.addAll(LevelUpRewards.forLevel(lvl));
      }
      // Give joker rewards
      final gameNotifier = _ref.read(gameStateProvider.notifier);
      for (final (type, amount) in allRewards) {
        gameNotifier.addJokers(type, amount);
      }
      unawaited(AnalyticsService.instance.logLevelReached(result.level));
      unawaited(AnalyticsService.instance.setPlayerLevel(result.level));
    }

    if (mounted) {
      state = ProgressionResult(
        xpGained: xpGained,
        newLevel: result.level,
        levelsGained: result.leveledUp,
        currentXP: result.currentXP,
        rewards: allRewards,
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
    } else {
      result = await _ref.read(progressionServiceProvider).addXPGuest(
        storage,
        xpToAdd: xp,
      );
    }

    // Set state BEFORE invalidating playerProvider so the XP chip sees
    // the change via progressionResult (triggers +N XP floating animation).
    // If we invalidate first, playerProvider refetch delivers the new XP
    // before progressionResult is set, so didUpdateWidget sees no delta.
    if (mounted) {
      state = ProgressionResult(
        xpGained: xp,
        newLevel: result.level,
        levelsGained: result.leveledUp,
        currentXP: result.currentXP,
      );
    }

    if (user != null) {
      _ref.invalidate(playerProvider);
    }
  }
}
