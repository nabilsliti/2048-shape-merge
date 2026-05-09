import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/config/audio_catalog.dart';
import 'package:shape_merge/core/services/app_logger.dart';

const _log = AppLogger('Audio');

/// Public audio API. Concrete implementation is [_SoLoudAudioService] but
/// callers should depend on this abstraction so tests can swap in a fake via
/// [AudioService.setForTesting] (no-arg) or [audioServiceProvider] (Riverpod).
abstract class AudioService {
  static AudioService _instance = _SoLoudAudioService();

  /// Global access for widgets that don't have a `Ref` (e.g. `Button3D`,
  /// score popups). Code that has `Ref` should prefer `audioServiceProvider`.
  static AudioService get instance => _instance;

  /// Override the singleton in tests. Call from `setUp` and reset in
  /// `tearDown` to avoid leaking state across tests.
  @visibleForTesting
  static void setForTesting(AudioService service) {
    _instance = service;
  }

  /// Restores the real SoLoud-backed implementation. Use in test `tearDown`.
  @visibleForTesting
  static void resetForTesting() {
    _instance = _SoLoudAudioService();
  }

  bool get soundEnabled;
  bool get musicEnabled;
  bool get isReady;

  Future<void> init();

  // Settings
  Future<void> toggleSound();
  Future<void> setSoundEnabled(bool enabled);
  Future<void> toggleMusic();
  Future<void> setMusicEnabled(bool enabled);

  // Background music
  void playGameMusic();
  void pauseGameMusic();
  void resumeGameMusic();
  void stopGameMusic();

  // SFX
  void play(String key);
  void playMerge();
  void playLevelUp();
  void playMergeAbort();
  void playNewRecord();
  void playReward();
  void playButtonTap();
  void playGameOver();
  void playJoker(String jokerName);
  void playBomb();
  void playReducer();
  void playWildcard();
  void playEvolution();
  void playCombo(int level);

  void dispose();
}

/// SoLoud-backed implementation. Direct, no workarounds.
///
/// Audio contrôlé uniquement par les boutons dans le jeu.
class _SoLoudAudioService implements AudioService {
  _SoLoudAudioService();

  final _soloud = SoLoud.instance;

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _preloaded = false;

  @override
  bool get soundEnabled => _soundEnabled;
  @override
  bool get musicEnabled => _musicEnabled;
  @override
  bool get isReady => _soloud.isInitialized && _preloaded;

  // ── Pre-loaded audio sources ──────────────────────────────────────────────
  final Map<String, AudioSource> _sources = {};

  /// Only declare files that actually exist in assets/sounds/.
  static const _sfxFiles = AudioCatalog.sfxFiles;

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _musicEnabled = prefs.getBool('musicEnabled') ?? true;

    await _ensureEngine();
    
    // Audio géré uniquement par les boutons de jeu - pas de démarrage automatique
    _log.info('AudioService initialisé - musique gérée manuellement');
  }

  /// Initialises the SoLoud engine + preloads assets.
  /// Safe to call multiple times — skips if already ready.
  Future<bool> _ensureEngine() async {
    if (_soloud.isInitialized && _preloaded) return true;

    // 1. Boot engine
    try {
      if (!_soloud.isInitialized) {
        await _soloud.init();
      }
    } catch (e) {
      _log.warning('SoLoud init failed', error: e);
      return false;
    }

    // 2. Pre-load all SFX + music
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
      // Pre-load music alongside SFX so playGameMusic can be synchronous
      try {
        _musicSource = await _soloud.loadAsset(_musicFile);
      } catch (e) {
        _log.warning('Failed to load game music', error: e);
      }
      _preloaded = true;
      _log.info('Ready: $loaded/${_sfxFiles.length} sounds + music loaded');
    }

    return _soloud.isInitialized;
  }

  // ── Sound effects ─────────────────────────────────────────────────────────

  @override
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', _soundEnabled);
  }

  @override
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', _soundEnabled);
  }

  // ── Background music ───────────────────────────────────────────────────────

  static const _musicFile = AudioCatalog.musicFile;
  AudioSource? _musicSource;
  SoundHandle? _musicHandle;

  /// Lance la musique en boucle à 30% de volume.
  @override
  void playGameMusic() {
    if (!_musicEnabled) return;
    final source = _musicSource;
    if (source == null || !_soloud.isInitialized) return;
    stopGameMusic();
    _musicHandle = _soloud.play(source, volume: AudioCatalog.musicVolume, looping: true);
    _log.info('🎵 Music started');
  }

  @override
  void pauseGameMusic() {
    final handle = _musicHandle;
    if (handle == null || !_soloud.isInitialized) return;
    _soloud.setPause(handle, true);
  }

  @override
  void resumeGameMusic() {
    if (!_musicEnabled) return;
    if (_musicHandle != null && _soloud.isInitialized) {
      _soloud.setPause(_musicHandle!, false);
    } else {
      playGameMusic();
    }
  }

  @override
  void stopGameMusic() {
    final handle = _musicHandle;
    if (handle != null && _soloud.isInitialized) {
      _soloud.stop(handle);
    }
    _musicHandle = null;
  }

  @override
  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', _musicEnabled);
    _log.info('Music: ${_musicEnabled ? "ENABLED" : "DISABLED"}');
    
    if (_musicEnabled) {
      // Musique activée → la lancer directement
      playGameMusic();
    } else {
      // Musique désactivée → l'arrêter
      stopGameMusic();
    }
  }

  @override
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', _musicEnabled);
    _log.info('Music: ${_musicEnabled ? "ENABLED" : "DISABLED"}');
    
    if (enabled) {
      // Musique activée → la lancer directement
      playGameMusic();
    } else {
      // Musique désactivée → l'arrêter
      stopGameMusic();
    }
  }

  // ── Play simple et direct ─────────────────────────────────────────────────

  @override
  void play(String key) {
    if (!_soundEnabled || !_soloud.isInitialized) return;
    
    final source = _sources[key];
    if (source != null) {
      _soloud.play(source);
    }
  }

  // ── Sons existants ────────────────────────────────────────────────────────

  @override
  void playMerge() => play(AudioCatalog.mergeSound);
  @override
  void playLevelUp() => play(AudioCatalog.levelUpSound);
  @override
  void playMergeAbort() => play(AudioCatalog.mergeAbortSound);
  @override
  void playNewRecord() => play(AudioCatalog.newRecordSound);
  @override
  void playReward() => play(AudioCatalog.rewardSound);
  @override
  void playButtonTap() => play(AudioCatalog.buttonTapSound);

  // ── Méthodes pour compatibilité ───────────────────────────────────────────
  @override
  void playGameOver() => play(AudioCatalog.gameOverSound);
  @override
  void playJoker(String jokerName) => play(AudioCatalog.jokerSounds[jokerName] ?? AudioCatalog.mergeSound);
  @override
  void playBomb() => playJoker('bomb');
  @override
  void playReducer() => playJoker('reducer');
  @override
  void playWildcard() => playJoker('wildcard');
  @override
  void playEvolution() => playJoker('evolution');
  @override
  void playCombo(int level) => level > AudioCatalog.comboThreshold ? playLevelUp() : playMerge();

  // ── Cleanup ───────────────────────────────────────────────────────────────

  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopGameMusic();
    if (_musicSource != null && _soloud.isInitialized) {
      _soloud.disposeSource(_musicSource!);
      _musicSource = null;
    }
    for (final source in _sources.values) {
      if (_soloud.isInitialized) _soloud.disposeSource(source);
    }
    _sources.clear();
    _preloaded = false;
    if (_soloud.isInitialized) {
      _soloud.deinit();
    }
  }
}
