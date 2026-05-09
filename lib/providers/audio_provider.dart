import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/button_3d.dart';
import 'package:vibration/vibration.dart';

/// Riverpod handle for [AudioService]. Default returns [AudioService.instance];
/// override in tests via `ProviderScope(overrides: [audioServiceProvider.overrideWithValue(FakeAudioService())])`.
final audioServiceProvider = Provider<AudioService>((_) => AudioService.instance);

final audioProvider =
    StateNotifierProvider<AudioNotifier, bool>((ref) => AudioNotifier(ref));

class AudioNotifier extends StateNotifier<bool> {
  AudioNotifier(this._ref) : super(_ref.read(audioServiceProvider).soundEnabled);

  final Ref _ref;

  Future<void> toggle() async {
    final audio = _ref.read(audioServiceProvider);
    await audio.toggleSound();
    state = audio.soundEnabled;
  }
}

final musicProvider =
    StateNotifierProvider<MusicNotifier, bool>((ref) => MusicNotifier(ref));

class MusicNotifier extends StateNotifier<bool> {
  MusicNotifier(this._ref) : super(_ref.read(audioServiceProvider).musicEnabled);

  final Ref _ref;

  Future<void> toggle() async {
    final audio = _ref.read(audioServiceProvider);
    await audio.toggleMusic();
    state = audio.musicEnabled;
  }
}

final vibrationProvider =
    StateNotifierProvider<VibrationNotifier, bool>((ref) => VibrationNotifier());

class VibrationNotifier extends StateNotifier<bool> {
  static const _key = 'vibrationEnabled';

  VibrationNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
    Button3D.updateVibrationEnabled(state);
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
    Button3D.updateVibrationEnabled(state);
  }

  void vibrate() {
    if (state) Vibration.vibrate(duration: 100);
  }

  void vibrateLight() {
    if (state) Vibration.vibrate(duration: 30);
  }

  void vibrateMedium() {
    if (state) Vibration.vibrate(duration: 60);
  }
}
