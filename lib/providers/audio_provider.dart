import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/services/audio_service.dart';

final audioProvider =
    StateNotifierProvider<AudioNotifier, bool>((ref) => AudioNotifier());

class AudioNotifier extends StateNotifier<bool> {
  AudioNotifier() : super(AudioService.instance.soundEnabled);

  Future<void> toggle() async {
    await AudioService.instance.toggleSound();
    state = AudioService.instance.soundEnabled;
  }
}
