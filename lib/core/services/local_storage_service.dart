import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';

class LocalStorageService {
  static const _bestScoreKey = 'bestScore';
  static const _onboardingDoneKey = 'onboardingDone';
  static const _soundEnabledKey = 'soundEnabled';
  static const _jokerBombKey = 'jokerBomb';
  static const _jokerWildcardKey = 'jokerWildcard';
  static const _jokerReducerKey = 'jokerReducer';
  static const _guestNameKey = 'guestName';
  static const _guestAvatarKey = 'guestAvatar';

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
        bomb: _prefs.getInt(_jokerBombKey) ?? 3,
        wildcard: _prefs.getInt(_jokerWildcardKey) ?? 3,
        reducer: _prefs.getInt(_jokerReducerKey) ?? 3,
      );

  Future<void> saveJokerInventory(JokerInventory inventory) async {
    await _prefs.setInt(_jokerBombKey, inventory.bomb);
    await _prefs.setInt(_jokerWildcardKey, inventory.wildcard);
    await _prefs.setInt(_jokerReducerKey, inventory.reducer);
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
}
