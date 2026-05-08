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
    'level_up': 'assets/sounds/level_complete.mp3',
    'reward': 'assets/sounds/reward_pub.wav',
    'merge_abort': 'assets/sounds/merge-abort.mp3',
    'new_record': 'assets/sounds/new-record.wav',
    'click': 'assets/sounds/click.mp3',
    'game_over': 'assets/sounds/game_over.wav',
    'joker_bomb': 'assets/sounds/joker_bomb.wav',
    'joker_wildcard': 'assets/sounds/joker_wildcard.mp3',
    'joker_reducer': 'assets/sounds/joker_reducer.mp3',
    'joker_radar': 'assets/sounds/joker_radar.mp3',
    'joker_evolution': 'assets/sounds/joker_evolution.mp3',
    'joker_mega_bomb': 'assets/sounds/joker_mega_bomb.mp3',
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
  static const String buttonTapSound = 'click';
  static const String gameOverSound = 'game_over';

  /// Sound key per joker type name.
  /// Key = JokerType.name, value = sfxFiles key.
  static const Map<String, String> jokerSounds = {
    'bomb': 'joker_bomb',
    'wildcard': 'joker_wildcard',
    'reducer': 'joker_reducer',
    'radar': 'joker_radar',
    'evolution': 'joker_evolution',
    'megaBomb': 'joker_mega_bomb',
  };

  /// Combo sound: high combo → level_up, otherwise merge.
  static const int comboThreshold = 3;
}
