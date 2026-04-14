// ─────────────────────────────────────────────────────────────
// Audio Catalog — all sound file paths and mappings.
//
// To add a new sound: add an entry to sfxFiles, then call
// AudioService.instance.play('yourKey').
// To change which sound a joker uses: edit jokerSounds.
// ─────────────────────────────────────────────────────────────

abstract final class AudioCatalog {
  /// SFX files to preload. Key → asset path.
  static const Map<String, String> sfxFiles = {
    'merge': 'assets/sounds/merge.mp3',
    'level_up': 'assets/sounds/level_up.wav',
    'reward': 'assets/sounds/reward_pub.wav',
    'merge_abort': 'assets/sounds/merge-abort.wav',
    'new_record': 'assets/sounds/new-record.wav',
  };

  /// Background music asset path.
  static const String musicFile = 'assets/sounds/game_music.mp3';

  /// Default music volume (0.0 – 1.0).
  static const double musicVolume = 0.3;

  /// Sound key per game event.
  static const String mergeSound = 'merge';
  static const String levelUpSound = 'level_up';
  static const String mergeAbortSound = 'merge_abort';
  static const String newRecordSound = 'new_record';
  static const String rewardSound = 'reward';
  static const String buttonTapSound = 'merge';
  static const String gameOverSound = 'merge_abort';

  /// Sound key per joker type name.
  /// Key = JokerType.name, value = sfxFiles key.
  static const Map<String, String> jokerSounds = {
    'bomb': 'level_up',
    'wildcard': 'level_up',
    'reducer': 'level_up',
    'radar': 'level_up',
    'evolution': 'level_up',
    'megaBomb': 'level_up',
  };

  /// Combo sound: high combo → level_up, otherwise merge.
  static const int comboThreshold = 3;
}
