import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/button_3d.dart';
import 'package:vibration/vibration.dart';

final audioProvider =
    StateNotifierProvider<AudioNotifier, bool>((ref) => AudioNotifier());

class AudioNotifier extends StateNotifier<bool> {
  AudioNotifier() : super(AudioService.instance.soundEnabled);

  Future<void> toggle() async {
    await AudioService.instance.toggleSound();
    state = AudioService.instance.soundEnabled;
  }
}

final musicProvider =
    StateNotifierProvider<MusicNotifier, bool>((ref) => MusicNotifier());

class MusicNotifier extends StateNotifier<bool> {
  MusicNotifier() : super(AudioService.instance.musicEnabled);

  Future<void> toggle() async {
    await AudioService.instance.toggleMusic();
    state = AudioService.instance.musicEnabled;
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
