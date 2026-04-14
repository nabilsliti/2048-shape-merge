import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/config/audio_catalog.dart';
import 'package:shape_merge/core/services/app_logger.dart';

const _log = AppLogger('Audio');

/// Service audio simple et direct.
/// 
/// Audio contrôlé uniquement par les boutons dans le jeu.
/// Aucun démarrage automatique, aucun workaround.
class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final _soloud = SoLoud.instance;

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _preloaded = false;
  
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get isReady => _soloud.isInitialized && _preloaded;

  // ── Pre-loaded audio sources ──────────────────────────────────────────────
  final Map<String, AudioSource> _sources = {};

  /// Only declare files that actually exist in assets/sounds/.
  static const _sfxFiles = AudioCatalog.sfxFiles;

  // ── Init ──────────────────────────────────────────────────────────────────

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

  static const _musicFile = AudioCatalog.musicFile;
  AudioSource? _musicSource;
  SoundHandle? _musicHandle;

  /// Lance la musique en boucle à 30% de volume.
  void playGameMusic() {
    if (!_musicEnabled) return;
    final source = _musicSource;
    if (source == null || !_soloud.isInitialized) return;
    stopGameMusic();
    _musicHandle = _soloud.play(source, volume: AudioCatalog.musicVolume, looping: true);
    _log.info('🎵 Music started');
  }

  void pauseGameMusic() {
    final handle = _musicHandle;
    if (handle == null || !_soloud.isInitialized) return;
    _soloud.setPause(handle, true);
  }

  void resumeGameMusic() {
    if (!_musicEnabled) return;
    if (_musicHandle != null && _soloud.isInitialized) {
      _soloud.setPause(_musicHandle!, false);
    } else {
      playGameMusic();
    }
  }

  void stopGameMusic() {
    final handle = _musicHandle;
    if (handle != null && _soloud.isInitialized) {
      _soloud.stop(handle);
    }
    _musicHandle = null;
  }

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

  void play(String key) {
    if (!_soundEnabled || !_soloud.isInitialized) return;
    
    final source = _sources[key];
    if (source != null) {
      _soloud.play(source);
    }
  }

  // ── Sons existants ────────────────────────────────────────────────────────

  void playMerge() => play(AudioCatalog.mergeSound);
  void playLevelUp() => play(AudioCatalog.levelUpSound);
  void playMergeAbort() => play(AudioCatalog.mergeAbortSound);
  void playNewRecord() => play(AudioCatalog.newRecordSound);
  void playReward() => play(AudioCatalog.rewardSound);
  void playButtonTap() => play(AudioCatalog.buttonTapSound);

  // ── Méthodes pour compatibilité ───────────────────────────────────────────
  void playGameOver() => play(AudioCatalog.gameOverSound);
  void playJoker(String jokerName) => play(AudioCatalog.jokerSounds[jokerName] ?? AudioCatalog.mergeSound);
  void playBomb() => playJoker('bomb');
  void playReducer() => playJoker('reducer');
  void playWildcard() => playJoker('wildcard');
  void playCombo(int level) => level > AudioCatalog.comboThreshold ? playLevelUp() : playMerge();

  // ── Cleanup ───────────────────────────────────────────────────────────────

  void dispose() {
    stopGameMusic();
    if (_musicSource != null && _soloud.isInitialized) {
      _soloud.disposeSource(_musicSource!);
      _musicSource = null;
    }
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
