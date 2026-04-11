import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';

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
    return LocalStorageService(prefs);
  }

  int get bestScore => _prefs.getInt(_bestScoreKey) ?? 0;
  Future<void> setBestScore(int score) => _prefs.setInt(_bestScoreKey, score);

  bool get onboardingDone => _prefs.getBool(_onboardingDoneKey) ?? false;
  Future<void> setOnboardingDone(bool done) =>
      _prefs.setBool(_onboardingDoneKey, done);

  bool get soundEnabled => _prefs.getBool(_soundEnabledKey) ?? true;
  Future<void> setSoundEnabled(bool enabled) =>
      _prefs.setBool(_soundEnabledKey, enabled);

  JokerInventory get jokerInventory => JokerInventory(
        bomb: _prefs.getInt(_jokerBombKey) ?? initialJokerCount,
        wildcard: _prefs.getInt(_jokerWildcardKey) ?? initialJokerCount,
        reducer: _prefs.getInt(_jokerReducerKey) ?? initialJokerCount,
        radar: _prefs.getInt(_jokerRadarKey) ?? initialRadarCount,
        evolution: _prefs.getInt(_jokerEvolutionKey) ?? initialEvolutionCount,
        megaBomb: _prefs.getInt(_jokerMegaBombKey) ?? initialMegaBombCount,
      );

  Future<void> saveJokerInventory(JokerInventory inventory) async {
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

  // ── Streak (guest mode) ───────────────────────────────────────────────────
  int get currentStreak => _prefs.getInt(_currentStreakKey) ?? 0;
  Future<void> setCurrentStreak(int v) => _prefs.setInt(_currentStreakKey, v);

  int get longestStreak => _prefs.getInt(_longestStreakKey) ?? 0;
  Future<void> setLongestStreak(int v) => _prefs.setInt(_longestStreakKey, v);

  String? get lastLoginDate => _prefs.getString(_lastLoginDateKey);
  Future<void> setLastLoginDate(String date) => _prefs.setString(_lastLoginDateKey, date);

  int get nextRewardIndex => _prefs.getInt(_nextRewardIndexKey) ?? 0;
  Future<void> setNextRewardIndex(int v) => _prefs.setInt(_nextRewardIndexKey, v);

  String? get rewardClaimedDate => _prefs.getString(_rewardClaimedDateKey);
  Future<void> setRewardClaimedDate(String date) => _prefs.setString(_rewardClaimedDateKey, date);

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

  // ── Daily challenges (guest mode) ─────────────────────────────────────────
  static const _dailyChallengesKey = 'dailyChallengesJson';
  String? get dailyChallengesJson => _prefs.getString(_dailyChallengesKey);
  Future<void> setDailyChallengesJson(String json) =>
      _prefs.setString(_dailyChallengesKey, json);

  // ── GDPR ─────────────────────────────────────────────────────────────────
  Future<void> clearAllData() => _prefs.clear();
}
