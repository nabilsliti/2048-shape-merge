import 'dart:math';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/services/firestore_service.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';

const _log = AppLogger('XP');

/// XP and level management — delegates formulas to [Progression] config.
class ProgressionService {
  const ProgressionService();

  static int get maxLevel => Progression.maxLevel;

  static int xpForLevel(int level) => Progression.xpForLevel(level);

  static int computeXP({
    required int score,
    required int mergeCount,
    required int maxLevelReached,
    required int currentStreak,
    required int completedObjectives,
  }) {
    var xp = score ~/ Progression.scoreDivisor
        + mergeCount * Progression.xpPerMerge
        + maxLevelReached * Progression.xpPerShapeLevel
        + completedObjectives * Progression.xpPerObjective;

    if (currentStreak >= Progression.streakBonusThreshold) {
      xp = (xp * Progression.streakMultiplier).toInt();
    }

    return max(xp, 1);
  }

  // ── Guest mode ─────────────────────────────────────────────────────────────

  Future<({int level, int currentXP, int leveledUp})> addXPGuest(
    LocalStorageService storage, {
    required int xpToAdd,
  }) async {
    var level = storage.playerLevel;
    var currentXP = storage.currentXP + xpToAdd;
    final totalXP = storage.totalXP + xpToAdd;
    var levelsGained = 0;

    while (level < maxLevel) {
      final needed = xpForLevel(level);
      if (currentXP < needed) break;
      currentXP -= needed;
      level++;
      levelsGained++;
    }

    await storage.setPlayerLevel(level);
    await storage.setCurrentXP(currentXP);
    await storage.setTotalXP(totalXP);

    _log.info('XP guest: +$xpToAdd → level $level ($currentXP XP)');
    return (level: level, currentXP: currentXP, leveledUp: levelsGained);
  }

  // ── Signed-in mode ─────────────────────────────────────────────────────────

  Future<({int level, int currentXP, int leveledUp})> addXPSigned({
    required String uid,
    required int currentLevel,
    required int currentXP,
    required int totalXP,
    required int xpToAdd,
    required FirestoreService firestore,
  }) async {
    var level = currentLevel;
    var xp = currentXP + xpToAdd;
    final total = totalXP + xpToAdd;
    var levelsGained = 0;

    while (level < maxLevel) {
      final needed = xpForLevel(level);
      if (xp < needed) break;
      xp -= needed;
      level++;
      levelsGained++;
    }

    try {
      await firestore.updateXP(uid, level: level, currentXP: xp, totalXP: total);
    } catch (e) {
      _log.error('Firestore update failed', error: e);
    }

    return (level: level, currentXP: xp, leveledUp: levelsGained);
  }

  // ── Display helpers ────────────────────────────────────────────────────────

  /// Progress fraction (0.0–1.0) within current level.
  static double levelProgress(int currentXP, int level) {
    if (level >= maxLevel) return 1.0;
    return (currentXP / xpForLevel(level)).clamp(0.0, 1.0);
  }

  /// Cumulative XP needed to reach [targetLevel] from level 1.
  /// i.e. sum of xpForLevel(1) + xpForLevel(2) + ... + xpForLevel(targetLevel - 1).
  static int cumulativeXPForLevel(int targetLevel) {
    int total = 0;
    for (int l = 1; l < targetLevel; l++) {
      total += xpForLevel(l);
    }
    return total;
  }
}
