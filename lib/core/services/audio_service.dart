import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final _soloud = SoLoud.instance;

  bool _soundEnabled = true;
  bool _musicEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  // ── Pre-loaded audio sources ──────────────────────────────────────────────
  final Map<String, AudioSource> _sources = {};
  SoundHandle? _musicHandle;

  static const _sfxFiles = {
    'merge': 'assets/sounds/merge.mp3',
    'bomb': 'assets/sounds/bomb.wav',
    'wildcard': 'assets/sounds/wildcard.wav',
    'reducer': 'assets/sounds/reducer.wav',
    'game_over': 'assets/sounds/game_over.wav',
    'level_up': 'assets/sounds/level_up.wav',
    'spawn': 'assets/sounds/spawn.wav',
    'button_tap': 'assets/sounds/button_tap.wav',
    'high_score': 'assets/sounds/good_merge.wav',
    'reward': 'assets/sounds/reward_pub.wav',
    'merge_abort': 'assets/sounds/merge-abort.wav',
    'new_record': 'assets/sounds/new-record.wav',
  };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _musicEnabled = prefs.getBool('musicEnabled') ?? true;

    try {
      if (!_soloud.isInitialized) {
        await _soloud.init();
      }
    } catch (e) {
      debugPrint('⚠️ SoLoud init failed: $e');
      return;
    }

    // Pre-load all SFX into memory
    for (final entry in _sfxFiles.entries) {
      try {
        _sources[entry.key] = await _soloud.loadAsset(entry.value);
      } catch (e) {
        debugPrint('⚠️ Failed to load ${entry.key}: $e');
      }
    }

    try {
      await playMusic();
    } catch (e) {
      debugPrint('⚠️ playMusic failed: $e');
    }
  }

  // ── Sound effects ─────────────────────────────────────────────────────────

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', _soundEnabled);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', _soundEnabled);
  }

  // ── Background music ───────────────────────────────────────────────────────

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', _musicEnabled);
    if (_musicEnabled) {
      await playMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', _musicEnabled);
    if (_musicEnabled) {
      await playMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> playMusic() async {
    if (!_musicEnabled || !_soloud.isInitialized) return;
    // No background.mp3 yet — skip silently
  }

  Future<void> pauseMusic() async {
    if (_musicHandle != null && _soloud.isInitialized) {
      _soloud.setPause(_musicHandle!, true);
    }
  }

  Future<void> resumeMusic() async {
    if (!_musicEnabled) return;
    if (_musicHandle != null && _soloud.isInitialized) {
      _soloud.setPause(_musicHandle!, false);
    }
  }

  Future<void> stopMusic() async {
    if (_musicHandle != null && _soloud.isInitialized) {
      await _soloud.stop(_musicHandle!);
      _musicHandle = null;
    }
  }

  void play(String key) {
    if (!_soundEnabled || !_soloud.isInitialized) return;
    final source = _sources[key];
    if (source == null) return;
    _soloud.play(source);
  }

  void playMerge() => play('merge');
  void playBomb() => play('bomb');
  void playWildcard() => play('wildcard');
  void playReducer() => play('reducer');
  void playGameOver() => play('game_over');
  void playLevelUp() => play('level_up');
  void playSpawn() => play('spawn');
  void playMergeAbort() => play('merge_abort');
  void playButtonTap() => play('button_tap');
  void playHighScore() => play('high_score');
  void playNewRecord() => play('new_record');
  void playReward() => play('reward');

  /// Joue un son progressif selon le niveau de combo.
  void playCombo(int comboCount) {
    if (comboCount >= 5) {
      playLevelUp();
    } else {
      playMerge();
    }
  }
}
