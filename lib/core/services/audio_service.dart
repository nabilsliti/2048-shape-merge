import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/services/app_logger.dart';

const _log = AppLogger('Audio');

/// Centralised audio service using flutter_soloud.
///
/// All SFX are pre-loaded at startup. Missing asset files are skipped
/// gracefully. A lazy-retry mechanism ensures that if SoLoud fails to
/// initialise on the first attempt (common on some Android devices),
/// subsequent [play] calls will re-attempt init once.
class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final _soloud = SoLoud.instance;

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _initAttempted = false;
  bool _preloaded = false;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get isReady => _soloud.isInitialized && _preloaded;

  // ── Pre-loaded audio sources ──────────────────────────────────────────────
  final Map<String, AudioSource> _sources = {};

  /// Only declare files that actually exist in assets/sounds/.
  static const _sfxFiles = {
    'merge': 'assets/sounds/merge.mp3',
    'level_up': 'assets/sounds/level_up.wav',
    'reward': 'assets/sounds/reward_pub.wav',
    'merge_abort': 'assets/sounds/merge-abort.wav',
    'new_record': 'assets/sounds/new-record.wav',
  };

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _musicEnabled = prefs.getBool('musicEnabled') ?? true;

    await _ensureEngine();
  }

  /// Initialises the SoLoud engine + preloads assets.
  /// Safe to call multiple times — skips if already ready.
  Future<bool> _ensureEngine() async {
    if (_soloud.isInitialized && _preloaded) return true;

    _initAttempted = true;

    // 1. Boot engine
    try {
      if (!_soloud.isInitialized) {
        await _soloud.init();
      }
    } catch (e) {
      _log.warning('SoLoud init failed', error: e);
      return false;
    }

    // 2. Pre-load all SFX
    if (!_preloaded) {
      var loaded = 0;
      for (final entry in _sfxFiles.entries) {
        try {
          _sources[entry.key] = await _soloud.loadAsset(entry.value);
          loaded++;
        } catch (e) {
          _log.warning('Failed to load ${entry.key}', error: e);
        }
      }
      _preloaded = true;
      _log.info('Ready: $loaded/${_sfxFiles.length} sounds loaded');
    }

    return _soloud.isInitialized;
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
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', _musicEnabled);
  }

  // ── Core play ─────────────────────────────────────────────────────────────

  void play(String key) {
    if (!_soundEnabled) return;

    final source = _sources[key];
    if (source != null && _soloud.isInitialized) {
      _soloud.play(source);
      return;
    }

    // Lazy retry: engine may not have been ready at startup
    if (!_soloud.isInitialized && _initAttempted) {
      _retryAndPlay(key);
    }
  }

  Future<void> _retryAndPlay(String key) async {
    final ok = await _ensureEngine();
    if (!ok || !_soundEnabled) return;
    final source = _sources[key];
    if (source != null) {
      _soloud.play(source);
    }
  }

  // ── Convenience methods ───────────────────────────────────────────────────

  void playMerge() => play('merge');
  void playLevelUp() => play('level_up');
  void playMergeAbort() => play('merge_abort');
  void playNewRecord() => play('new_record');
  void playReward() => play('reward');

  // Fallbacks: sons manquants mappés sur des sons existants.
  // Quand les vrais fichiers seront ajoutés, il suffira de les déclarer
  // dans _sfxFiles et créer une clé dédiée.
  void playBomb() => play('level_up');
  void playWildcard() => play('merge');
  void playReducer() => play('merge');
  void playGameOver() => play('merge_abort');
  void playButtonTap() => play('merge');
  void playHighScore() => play('new_record');

  /// Son progressif selon le niveau de combo.
  void playCombo(int comboCount) {
    if (comboCount >= 5) {
      playLevelUp();
    } else {
      playMerge();
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  void dispose() {
    for (final source in _sources.values) {
      _soloud.disposeSource(source);
    }
    _sources.clear();
    _preloaded = false;
    if (_soloud.isInitialized) {
      _soloud.deinit();
    }
  }
}
