import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';

class LocalStorageService {
  static const _bestScoreKey = 'bestScore';
  static const _onboardingDoneKey = 'onboardingDone';
  static const _soundEnabledKey = 'soundEnabled';
  static const _jokerBombKey = 'jokerBomb';
  static const _jokerWildcardKey = 'jokerWildcard';
  static const _jokerReducerKey = 'jokerReducer';

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
}
