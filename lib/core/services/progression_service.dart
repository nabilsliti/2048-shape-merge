import 'dart:math';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/services/firestore_service.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';

const _log = AppLogger('XP');

/// XP and level management.
/// Formula: xpRequired(level) = floor(100 * level^1.4)
/// Max level: 50
class ProgressionService {
  const ProgressionService();

  static const int maxLevel = 50;

  // ── XP formula ─────────────────────────────────────────────────────────────

  /// XP required to go FROM level to level+1.
  static int xpForLevel(int level) =>
      (100 * pow(level, 1.4)).floor().clamp(100, 999999);

  /// Compute XP gained for a game result.
  static int computeXP({
    required int score,
    required int mergeCount,
    required int maxLevelReached,
    required int currentStreak,
    required int completedObjectives,
  }) {
    var xp = (score / 500).floor()          // score base
        + mergeCount                         // +1 per fusion
        + maxLevelReached * 3                // shape rank bonus
        + completedObjectives * 5;           // objective bonus

    // Streak bonus: +10% if streak >= 7
    if (currentStreak >= 7) xp = (xp * 1.1).floor();

    return max(xp, 1);
  }

  // ── Guest mode ─────────────────────────────────────────────────────────────

  Future<({int level, int currentXP, int leveledUp})> addXPGuest(
    LocalStorageService storage, {
    required int xpToAdd,
  }) async {
    var level = storage.playerLevel;
    var currentXP = storage.currentXP + xpToAdd;
    var totalXP = storage.totalXP + xpToAdd;
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
    var total = totalXP + xpToAdd;
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
