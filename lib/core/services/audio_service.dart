import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final _player = AudioPlayer();
  final _musicPlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _musicEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _musicEnabled = prefs.getBool('musicEnabled') ?? true;
    await playMusic();
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
    if (!_musicEnabled) return;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.4);
      await _musicPlayer.play(AssetSource('sounds/background.mp3'));
    } catch (_) {}
  }

  Future<void> pauseMusic() async {
    try {
      await _musicPlayer.pause();
    } catch (_) {}
  }

  Future<void> resumeMusic() async {
    if (!_musicEnabled) return;
    try {
      await _musicPlayer.resume();
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  Future<void> play(String fileName) async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('sounds/$fileName'));
    } catch (_) {
      // Sound files may be placeholders
    }
  }

  Future<void> playMerge() => play('merge.wav');
  Future<void> playBomb() => play('bomb.wav');
  Future<void> playWildcard() => play('wildcard.wav');
  Future<void> playReducer() => play('reducer.wav');
  Future<void> playGameOver() => play('game_over.wav');
  Future<void> playLevelUp() => play('level_up.wav');
  Future<void> playSpawn() => play('spawn.wav');
  Future<void> playButtonTap() => play('button_tap.wav');

  /// Joue un son progressif selon le niveau de combo.
  Future<void> playCombo(int comboCount) {
    if (comboCount >= 5) return playLevelUp();
    return playMerge();
  }
}
