import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final _player = AudioPlayer();
  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
  }

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
}
