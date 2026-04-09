import 'package:flutter/foundation.dart';
import 'package:shape_merge/core/models/player.dart';
import 'package:shape_merge/core/models/player_streak.dart';
import 'package:shape_merge/core/services/firestore_service.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';

/// Dual-mode streak logic.
/// Guest  → reads/writes SharedPreferences via LocalStorageService.
/// Signed → reads/writes Firestore (Player doc) + keeps SharedPreferences in sync.
class StreakService {
  const StreakService();

  // ─────────────────────────────────────────────
  // Guest mode
  // ─────────────────────────────────────────────

  Future<StreakCheckResult> checkAndUpdateGuest(LocalStorageService storage) async {
    final current = PlayerStreak(
      currentStreak: storage.currentStreak,
      longestStreak: storage.longestStreak,
      lastLoginDate: storage.lastLoginDate,
      nextRewardIndex: storage.nextRewardIndex,
    );

    final result = _compute(current, storage.nudgeStreak3Shown);
    await _saveToStorage(result.streak, storage);

    // Mark nudge seen if we're triggering it
    if (result.showGuestNudge) {
      await storage.setNudgeStreak3Shown();
    }

    return result;
  }

  // ─────────────────────────────────────────────
  // Signed-in mode
  // ─────────────────────────────────────────────

  Future<StreakCheckResult> checkAndUpdateSigned({
    required Player player,
    required FirestoreService firestore,
    required LocalStorageService storage,
  }) async {
    final current = PlayerStreak(
      currentStreak: player.currentStreak,
      longestStreak: player.longestStreak,
      lastLoginDate: player.lastLoginDate,
      nextRewardIndex: player.nextRewardIndex,
    );

    final result = _compute(current, false); // nudge not shown for signed-in users
    await _saveToFirestore(player.uid, result.streak, firestore);
    await _saveToStorage(result.streak, storage); // keep local in sync for migration
    return result;
  }

  // ─────────────────────────────────────────────
  // Guest→account migration (called on sign-in)
  // ─────────────────────────────────────────────

  Future<void> migrateGuestToFirestore({
    required Player player,
    required LocalStorageService storage,
    required FirestoreService firestore,
  }) async {
    final localStreak = storage.currentStreak;
    final localLongest = storage.longestStreak;
    final localDate = storage.lastLoginDate;
    final localIndex = storage.nextRewardIndex;

    // Keep the better values: max streak, most recent date
    final merged = PlayerStreak(
      currentStreak: localStreak > player.currentStreak ? localStreak : player.currentStreak,
      longestStreak: localLongest > player.longestStreak ? localLongest : player.longestStreak,
      lastLoginDate: _laterDate(localDate, player.lastLoginDate),
      nextRewardIndex: localStreak >= player.currentStreak ? localIndex : player.nextRewardIndex,
    );

    await _saveToFirestore(player.uid, merged, firestore);
    debugPrint('✅ Streak migrated: local=$localStreak, firestore=${player.currentStreak} → merged=${merged.currentStreak}');
  }

  // ─────────────────────────────────────────────
  // Core computation (pure — no side effects)
  // ─────────────────────────────────────────────

  StreakCheckResult _compute(PlayerStreak current, bool nudgeAlreadyShown) {
    final today = PlayerStreak.todayKey();
    final yesterday = PlayerStreak.yesterdayKey();

    // Already logged in today — no change
    if (current.lastLoginDate == today) {
      return StreakCheckResult(
        streakIncremented: false,
        streakReset: false,
        reward: null,
        streak: current,
      );
    }

    final int newStreak;
    final int newIndex;
    final bool reset;

    if (current.lastLoginDate == yesterday) {
      // Consecutive day — increment
      newStreak = current.currentStreak + 1;
      newIndex = (current.nextRewardIndex + 1) % 7;
      reset = false;
    } else {
      // Missed a day (or first login) — reset to 1
      newStreak = 1;
      newIndex = 1 % 7; // J1 awarded today, next reward is index 1
      reset = current.currentStreak > 0; // true only if there was a streak before
    }

    final newLongest = newStreak > current.longestStreak ? newStreak : current.longestStreak;
    final reward = PlayerStreak.rewardForIndex(current.nextRewardIndex);

    final updatedStreak = PlayerStreak(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastLoginDate: today,
      nextRewardIndex: newIndex,
    );

    final showNudge = !nudgeAlreadyShown && newStreak >= 3;

    return StreakCheckResult(
      streakIncremented: true,
      streakReset: reset,
      reward: reward,
      streak: updatedStreak,
      showGuestNudge: showNudge,
    );
  }

  // ─────────────────────────────────────────────
  // Persistence helpers
  // ─────────────────────────────────────────────

  Future<void> _saveToStorage(PlayerStreak streak, LocalStorageService storage) async {
    await storage.setCurrentStreak(streak.currentStreak);
    await storage.setLongestStreak(streak.longestStreak);
    if (streak.lastLoginDate != null) {
      await storage.setLastLoginDate(streak.lastLoginDate!);
    }
    await storage.setNextRewardIndex(streak.nextRewardIndex);
  }

  Future<void> _saveToFirestore(String uid, PlayerStreak streak, FirestoreService firestore) async {
    try {
      await firestore.updateStreak(uid, streak);
    } catch (e) {
      debugPrint('❌ StreakService: Firestore save failed: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Date helpers
  // ─────────────────────────────────────────────

  /// Returns the later of two "YYYY-MM-DD" strings (null is treated as oldest).
  String? _laterDate(String? a, String? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.compareTo(b) >= 0 ? a : b;
  }
}
