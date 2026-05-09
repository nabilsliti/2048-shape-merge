import 'package:cloud_functions/cloud_functions.dart';
import 'package:shape_merge/core/models/player.dart';
import 'package:shape_merge/core/models/player_streak.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/services/firestore_service.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';

const _log = AppLogger('Streak');

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

    final result = _compute(current, nudgeAlreadyShown: storage.nudgeStreak3Shown, rewardClaimedDate: storage.rewardClaimedDate);
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

    // Read-only prediction for UI — NEVER writes to Firestore client-side.
    // The actual streak update happens server-side in `claimDailyStreakReward`
    // when the user collects the reward (anti-cheat: clock manipulation).
    final claimedToday = _isClaimedToday(player);
    return _compute(
      current,
      nudgeAlreadyShown: false,
      rewardClaimedDate: claimedToday ? PlayerStreak.todayKey() : null,
    );
  }

  /// Returns true if the player's `lastClaimAt` (server timestamp) falls on
  /// the same UTC day as now. Falls back to the legacy `rewardClaimedDate`
  /// String if no server timestamp is set yet.
  bool _isClaimedToday(Player player) {
    final last = player.lastClaimAt;
    if (last != null) {
      final nowUtc = DateTime.now().toUtc();
      final lastUtc = last.toUtc();
      return nowUtc.year == lastUtc.year &&
          nowUtc.month == lastUtc.month &&
          nowUtc.day == lastUtc.day;
    }
    return player.rewardClaimedDate == PlayerStreak.todayKey();
  }

  /// Calls the `claimDailyStreakReward` Cloud Function.
  /// Returns the server-authoritative result, or null on already-claimed.
  /// Throws on network/auth errors so the caller can show a retry UI.
  Future<StreakClaimResult?> claimSigned() async {
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('claimDailyStreakReward');
    try {
      final res = await callable.call<Map<Object?, Object?>>();
      final data = Map<String, Object?>.from(res.data);
      return StreakClaimResult.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        _log.info('Streak already claimed today (server)');
        return null;
      }
      rethrow;
    }
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

    final today = PlayerStreak.todayKey();
    final yesterday = PlayerStreak.yesterdayKey();

    // Compute the correct streak for today based on Firestore's date context:
    // - If Firestore already updated today → keep as-is
    // - If Firestore last login was yesterday → consecutive day, increment
    // - Otherwise → streak is broken, reset to 1
    int mergedStreak;
    int mergedIndex;

    if (player.lastLoginDate == today) {
      // Firestore already handled today (e.g. another device)
      mergedStreak = player.currentStreak;
      mergedIndex = player.nextRewardIndex;
    } else if (player.lastLoginDate == yesterday) {
      // Consecutive day — increment from Firestore
      mergedStreak = player.currentStreak + 1;
      mergedIndex = (player.nextRewardIndex + 1) % PlayerStreak.rewardCycleLength;
    } else {
      // Streak broken or first ever — reset
      mergedStreak = 1;
      mergedIndex = 1;
    }

    // If guest had a higher streak from today, prefer it
    if (localDate == today && localStreak > mergedStreak) {
      mergedStreak = localStreak;
      mergedIndex = localIndex;
    }

    // Ensure longestStreak invariant: always >= currentStreak
    final mergedLongest = [localLongest, player.longestStreak, mergedStreak]
        .reduce((a, b) => a > b ? a : b);

    final merged = PlayerStreak(
      currentStreak: mergedStreak,
      longestStreak: mergedLongest,
      lastLoginDate: today,
      nextRewardIndex: mergedIndex,
    );

    await _saveToFirestore(player.uid, merged, firestore);
    _log.info('Migrated: local=$localStreak, firestore=${player.currentStreak} → merged=${merged.currentStreak}');
  }

  // ─────────────────────────────────────────────
  // Core computation (pure — no side effects)
  // ─────────────────────────────────────────────

  StreakCheckResult _compute(PlayerStreak current, {required bool nudgeAlreadyShown, required String? rewardClaimedDate}) {
    final today = PlayerStreak.todayKey();
    final yesterday = PlayerStreak.yesterdayKey();
    final claimedToday = rewardClaimedDate == today;

    // Already logged in today — no streak change, but reward may still be pending
    if (current.lastLoginDate == today) {
      final pendingReward = claimedToday
          ? null
          : PlayerStreak.rewardForStreak(current.currentStreak);
      final milestone = claimedToday ? null : PlayerStreak.milestoneFor(current.currentStreak);

      return StreakCheckResult(
        streakIncremented: false,
        streakReset: false,
        reward: pendingReward,
        rewardClaimed: claimedToday,
        streak: current,
        milestoneReward: milestone,
      );
    }

    final int newStreak;
    final int newIndex;
    final bool reset;

    if (current.lastLoginDate == yesterday) {
      // Consecutive day — increment
      newStreak = current.currentStreak + 1;
      newIndex = (current.nextRewardIndex + 1) % PlayerStreak.rewardCycleLength;
      reset = false;
    } else {
      // Missed a day (or first login) — reset to 1
      newStreak = 1;
      newIndex = 1; // J1 awarded today, next reward is index 1
      reset = current.currentStreak > 0; // true only if there was a streak before
    }

    final newLongest = newStreak > current.longestStreak ? newStreak : current.longestStreak;
    final reward = PlayerStreak.rewardForStreak(newStreak);
    final milestone = PlayerStreak.milestoneFor(newStreak);

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
      milestoneReward: milestone,
    );
  }

  // ─────────────────────────────────────────────
  // Signed→Guest sync (called on sign-out)
  // ─────────────────────────────────────────────

  Future<void> syncToLocalOnSignOut({
    required Player player,
    required LocalStorageService storage,
  }) async {
    final streak = PlayerStreak(
      currentStreak: player.currentStreak,
      longestStreak: player.longestStreak,
      lastLoginDate: player.lastLoginDate,
      nextRewardIndex: player.nextRewardIndex,
    );
    await _saveToStorage(streak, storage);
    if (player.rewardClaimedDate != null) {
      await storage.setRewardClaimedDate(player.rewardClaimedDate!);
    }
    _log.info('Synced streak to local on sign-out: ${streak.currentStreak}');
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
      _log.error('Firestore save failed', error: e);
    }
  }
}
