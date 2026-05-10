import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/services/integrity_guard.dart';

class LocalStorageService {
  static const _bestScoreKey = 'bestScore';
  static const _onboardingDoneKey = 'onboardingDone';
  static const _soundEnabledKey = 'soundEnabled';
  static const _jokerBombKey = 'jokerBomb';
  static const _jokerWildcardKey = 'jokerWildcard';
  static const _jokerReducerKey = 'jokerReducer';
  static const _jokerRadarKey = 'jokerRadar';
  static const _jokerEvolutionKey = 'jokerEvolution';
  static const _jokerMegaBombKey = 'jokerMegaBomb';
  static const _guestNameKey = 'guestName';
  static const _guestAvatarKey = 'guestAvatar';
  static const _noAdsPurchasedKey = 'noAdsPurchased';
  static const _emojiPackPurchasedKey = 'emojiPackPurchased';
  static const _gamesPlayedKey = 'gamesPlayed';
  static const _totalMergesKey = 'totalMerges';

  // ── Schema versioning ─────────────────────────────────────────────────────
  static const _schemaVersionKey = 'schemaVersion';
  static const _currentSchemaVersion = 2;

  // ── Retention keys (guest mode — mirror of Firestore fields for signed-in users) ──
  static const _currentStreakKey           = 'currentStreak';
  static const _longestStreakKey           = 'longestStreak';
  static const _lastLoginDateKey           = 'lastLoginDate';
  static const _nextRewardIndexKey         = 'nextRewardIndex';
  static const _playerLevelKey             = 'playerLevel';
  static const _currentXPKey              = 'currentXP';
  static const _totalXPKey                = 'totalXP';
  // Nudge flags — each shown only once
  static const _rewardClaimedDateKey        = 'rewardClaimedDate';
  static const _nudgeStreak3Key            = 'nudgeStreak3Shown';
  static const _nudgeStreak7Key            = 'nudgeStreak7Shown';
  static const _nudgeLevel5Key             = 'nudgeLevel5Shown';
  static const _nudgeObjectives3DaysKey    = 'nudgeObjectives3DaysShown';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = LocalStorageService(prefs);
    await service._runMigrations();
    return service;
  }

  /// Runs all pending schema migrations in sequence.
  Future<void> _runMigrations() async {
    final version = _prefs.getInt(_schemaVersionKey) ?? 0;
    if (version >= _currentSchemaVersion) return;

    // v0 → v2: joker key migration (legacy migrationV2Done flag)
    if (version < 2 && !migrationV2Done) {
      await setMigrationV2Done();
    }

    await _prefs.setInt(_schemaVersionKey, _currentSchemaVersion);
  }

  int get bestScore => _prefs.getInt(_bestScoreKey) ?? 0;
  Future<void> setBestScore(int score) => _prefs.setInt(_bestScoreKey, score);

  bool get onboardingDone => _prefs.getBool(_onboardingDoneKey) ?? false;
  Future<void> setOnboardingDone(bool done) =>
      _prefs.setBool(_onboardingDoneKey, done);

  // ── Analytics one-shot flags (so first_* events fire only once ever) ──
  static const _firstMergeLoggedKey = 'analyticsFirstMergeLogged';
  static const _firstJokerLoggedKey = 'analyticsFirstJokerLogged';

  bool get firstMergeLogged => _prefs.getBool(_firstMergeLoggedKey) ?? false;
  Future<void> setFirstMergeLogged() =>
      _prefs.setBool(_firstMergeLoggedKey, true);

  bool get firstJokerLogged => _prefs.getBool(_firstJokerLoggedKey) ?? false;
  Future<void> setFirstJokerLogged() =>
      _prefs.setBool(_firstJokerLoggedKey, true);

  // ── Free-joker rewarded-ad gate (cooldown + daily cap) ──
  static const _adJokerLastEpochKey = 'adJokerLastEpochMs';
  static const _adJokerDayKey = 'adJokerDay';
  static const _adJokerCountKey = 'adJokerCount';

  /// UTC date in YYYY-MM-DD form. Used to reset the daily cap at midnight UTC.
  static String _todayUtcKey() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Timestamp of the last free-joker ad (epoch ms), or 0 if never watched.
  int get adJokerLastEpochMs => _prefs.getInt(_adJokerLastEpochKey) ?? 0;

  /// Free-joker ads watched today (auto-resets at midnight UTC).
  int get adJokerCountToday {
    final storedDay = _prefs.getString(_adJokerDayKey);
    if (storedDay != _todayUtcKey()) return 0;
    return _prefs.getInt(_adJokerCountKey) ?? 0;
  }

  /// Remaining cooldown before the next ad-joker can be watched.
  /// Returns [Duration.zero] if cooldown elapsed.
  Duration get adJokerCooldownRemaining {
    final last = adJokerLastEpochMs;
    if (last == 0) return Duration.zero;
    final elapsed = Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch - last);
    final remaining = AdJokerTuning.cooldown - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Number of free-joker ads still available today.
  int get adJokerAdsLeftToday =>
      (AdJokerTuning.dailyCap - adJokerCountToday).clamp(0, AdJokerTuning.dailyCap);

  /// Whether the user can watch a free-joker ad right now (cooldown + cap).
  bool get canWatchAdJoker =>
      adJokerCooldownRemaining == Duration.zero && adJokerAdsLeftToday > 0;

  /// Persist that the user just watched a free-joker ad. Resets the daily
  /// counter if a new UTC day started.
  Future<void> recordAdJokerWatched() async {
    final today = _todayUtcKey();
    final storedDay = _prefs.getString(_adJokerDayKey);
    final newCount = (storedDay == today)
        ? (_prefs.getInt(_adJokerCountKey) ?? 0) + 1
        : 1;
    await _prefs.setString(_adJokerDayKey, today);
    await _prefs.setInt(_adJokerCountKey, newCount);
    await _prefs.setInt(
        _adJokerLastEpochKey, DateTime.now().millisecondsSinceEpoch);
  }

  bool get soundEnabled => _prefs.getBool(_soundEnabledKey) ?? true;
  Future<void> setSoundEnabled(bool enabled) =>
      _prefs.setBool(_soundEnabledKey, enabled);

  // ── Joker inventory (signed against tampering) ─────────────────────────────
  static const _jokerSignedKey = 'jokerSigned';

  JokerInventory get jokerInventory {
    // Try signed format first
    final signed = IntegrityGuard.unwrap(_prefs.getString(_jokerSignedKey));
    if (signed != null) {
      try {
        final m = jsonDecode(signed) as Map<String, Object?>;
        return JokerInventory(
          bomb: m['b'] as int? ?? JokerStartingCounts.bomb,
          wildcard: m['w'] as int? ?? JokerStartingCounts.wildcard,
          reducer: m['r'] as int? ?? JokerStartingCounts.reducer,
          radar: m['a'] as int? ?? 0,
          evolution: m['e'] as int? ?? 0,
          megaBomb: m['m'] as int? ?? 0,
        );
      } catch (_) {
        // Fall through to legacy
      }
    }
    // Legacy unsigned fallback (one-time migration)
    return JokerInventory(
        bomb: _prefs.getInt(_jokerBombKey) ?? JokerStartingCounts.bomb,
        wildcard: _prefs.getInt(_jokerWildcardKey) ?? JokerStartingCounts.wildcard,
        reducer: _prefs.getInt(_jokerReducerKey) ?? JokerStartingCounts.reducer,
        radar: _prefs.getInt(_jokerRadarKey) ?? JokerStartingCounts.radar,
        evolution: _prefs.getInt(_jokerEvolutionKey) ?? JokerStartingCounts.evolution,
        megaBomb: _prefs.getInt(_jokerMegaBombKey) ?? JokerStartingCounts.megaBomb,
      );
  }

  Future<void> saveJokerInventory(JokerInventory inventory) async {
    final data = jsonEncode({
      'b': inventory.bomb,
      'w': inventory.wildcard,
      'r': inventory.reducer,
      'a': inventory.radar,
      'e': inventory.evolution,
      'm': inventory.megaBomb,
    });
    await _prefs.setString(_jokerSignedKey, IntegrityGuard.wrap(data));
    // Keep legacy keys in sync for backwards compatibility during rollout
    await _prefs.setInt(_jokerBombKey, inventory.bomb);
    await _prefs.setInt(_jokerWildcardKey, inventory.wildcard);
    await _prefs.setInt(_jokerReducerKey, inventory.reducer);
    await _prefs.setInt(_jokerRadarKey, inventory.radar);
    await _prefs.setInt(_jokerEvolutionKey, inventory.evolution);
    await _prefs.setInt(_jokerMegaBombKey, inventory.megaBomb);
  }

  String get guestName {
    var name = _prefs.getString(_guestNameKey);
    if (name == null) {
      name = 'Guest_${DateTime.now().millisecondsSinceEpoch % 10000}';
      _prefs.setString(_guestNameKey, name);
    }
    return name;
  }

  Future<void> setGuestName(String name) => _prefs.setString(_guestNameKey, name);

  String? get guestAvatar => _prefs.getString(_guestAvatarKey);
  Future<void> setGuestAvatar(String avatarId) => _prefs.setString(_guestAvatarKey, avatarId);

  bool get noAdsPurchased => _prefs.getBool(_noAdsPurchasedKey) ?? false;
  Future<void> setNoAdsPurchased(bool value) => _prefs.setBool(_noAdsPurchasedKey, value);

  bool get emojiPackPurchased => _prefs.getBool(_emojiPackPurchasedKey) ?? false;
  Future<void> setEmojiPackPurchased(bool value) => _prefs.setBool(_emojiPackPurchasedKey, value);

  // ── Game stats (guest mode) ───────────────────────────────────────────────
  int get gamesPlayed => _prefs.getInt(_gamesPlayedKey) ?? 0;
  Future<void> incrementGamesPlayed() =>
      _prefs.setInt(_gamesPlayedKey, gamesPlayed + 1);
  Future<void> setGamesPlayed(int v) => _prefs.setInt(_gamesPlayedKey, v);

  int get totalMerges => _prefs.getInt(_totalMergesKey) ?? 0;
  Future<void> addMerges(int count) =>
      _prefs.setInt(_totalMergesKey, totalMerges + count);
  Future<void> setTotalMerges(int v) => _prefs.setInt(_totalMergesKey, v);

  // ── Streak (guest mode) ───────────────────────────────────────────────────
  int get currentStreak => _prefs.getInt(_currentStreakKey) ?? 0;
  Future<void> setCurrentStreak(int v) => _prefs.setInt(_currentStreakKey, v);

  int get longestStreak => _prefs.getInt(_longestStreakKey) ?? 0;
  Future<void> setLongestStreak(int v) => _prefs.setInt(_longestStreakKey, v);

  String? get lastLoginDate => _prefs.getString(_lastLoginDateKey);
  Future<void> setLastLoginDate(String date) => _prefs.setString(_lastLoginDateKey, date);
  Future<void> clearLastLoginDate() => _prefs.remove(_lastLoginDateKey);

  int get nextRewardIndex => _prefs.getInt(_nextRewardIndexKey) ?? 0;
  Future<void> setNextRewardIndex(int v) => _prefs.setInt(_nextRewardIndexKey, v);

  String? get rewardClaimedDate => _prefs.getString(_rewardClaimedDateKey);
  Future<void> setRewardClaimedDate(String date) => _prefs.setString(_rewardClaimedDateKey, date);
  Future<void> clearRewardClaimedDate() => _prefs.remove(_rewardClaimedDateKey);

  // ── Level / XP (guest mode) ──────────────────────────────────────────────
  int get playerLevel => _prefs.getInt(_playerLevelKey) ?? 1;
  Future<void> setPlayerLevel(int v) => _prefs.setInt(_playerLevelKey, v);

  int get currentXP => _prefs.getInt(_currentXPKey) ?? 0;
  Future<void> setCurrentXP(int v) => _prefs.setInt(_currentXPKey, v);

  int get totalXP => _prefs.getInt(_totalXPKey) ?? 0;
  Future<void> setTotalXP(int v) => _prefs.setInt(_totalXPKey, v);

  // ── Nudge flags (guest → account conversion, shown only once) ───────────
  bool get nudgeStreak3Shown => _prefs.getBool(_nudgeStreak3Key) ?? false;
  Future<void> setNudgeStreak3Shown() => _prefs.setBool(_nudgeStreak3Key, true);

  bool get nudgeStreak7Shown => _prefs.getBool(_nudgeStreak7Key) ?? false;
  Future<void> setNudgeStreak7Shown() => _prefs.setBool(_nudgeStreak7Key, true);

  bool get nudgeLevel5Shown => _prefs.getBool(_nudgeLevel5Key) ?? false;
  Future<void> setNudgeLevel5Shown() => _prefs.setBool(_nudgeLevel5Key, true);

  bool get nudgeObjectives3DaysShown => _prefs.getBool(_nudgeObjectives3DaysKey) ?? false;
  Future<void> setNudgeObjectives3DaysShown() => _prefs.setBool(_nudgeObjectives3DaysKey, true);

  // ── Migration flag ────────────────────────────────────────────────────────
  static const _migrationV2DoneKey = 'migrationV2Done';
  bool get migrationV2Done => _prefs.getBool(_migrationV2DoneKey) ?? false;
  Future<void> setMigrationV2Done() => _prefs.setBool(_migrationV2DoneKey, true);

  // ── Daily challenges (guest mode) ─────────────────────────────────────────
  static const _dailyChallengesKey = 'dailyChallengesJson';
  String? get dailyChallengesJson => _prefs.getString(_dailyChallengesKey);
  Future<void> setDailyChallengesJson(String json) =>
      _prefs.setString(_dailyChallengesKey, json);

  // ── Crash recovery (in-progress game checkpoint) ───────────────────────────
  static const _gameCheckpointKey = 'gameCheckpoint';

  String? get gameCheckpoint => _prefs.getString(_gameCheckpointKey);

  Future<void> saveGameCheckpoint(String json) =>
      _prefs.setString(_gameCheckpointKey, json);

  Future<void> clearGameCheckpoint() => _prefs.remove(_gameCheckpointKey);

  // ── Pending purchases (guest mode — replayed on sign-in) ─────────────────
  static const _pendingPurchasesKey = 'pendingPurchases';

  /// Returns list of pending purchases [{productId, purchaseToken, platform}].
  List<Map<String, String>> get pendingPurchases {
    final raw = _prefs.getString(_pendingPurchasesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<Object?>;
      return list
          .whereType<Map<String, Object?>>()
          .map((m) => m.map((k, v) => MapEntry(k, v.toString())))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addPendingPurchase({
    required String productId,
    required String purchaseToken,
    required String platform,
  }) async {
    final list = pendingPurchases;
    list.add({
      'productId': productId,
      'purchaseToken': purchaseToken,
      'platform': platform,
    });
    await _prefs.setString(_pendingPurchasesKey, jsonEncode(list));
  }

  Future<void> clearPendingPurchases() =>
      _prefs.remove(_pendingPurchasesKey);

  // ── GDPR ─────────────────────────────────────────────────────────────────
  Future<void> clearAllData() => _prefs.clear();
}
