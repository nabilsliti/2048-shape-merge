// ─────────────────────────────────────────────────────────────
// Avatar Catalog — all profile avatars in one place.
//
// To add/remove an avatar: edit this list only.
// ─────────────────────────────────────────────────────────────

class AvatarDef {
  final String id;
  final String emoji;
  /// Minimum player level required to unlock this avatar (0 = free).
  final int unlockLevel;
  const AvatarDef(this.id, this.emoji, {this.unlockLevel = 0});

  bool isUnlocked(int playerLevel) => playerLevel >= unlockLevel;
}

abstract final class AvatarCatalog {
  /// Avatars ordered by unlock progression.
  static const List<AvatarDef> all = [
    // Free starters
    AvatarDef('robot', '🤖'),
    AvatarDef('star', '⭐'),
    // Early game — common & friendly
    AvatarDef('cat', '🐱', unlockLevel: 3),
    AvatarDef('fire', '🔥', unlockLevel: 5),
    AvatarDef('ghost', '👻', unlockLevel: 7),
    // Mid-early — adventurous
    AvatarDef('alien', '👾', unlockLevel: 10),
    AvatarDef('rocket', '🚀', unlockLevel: 12),
    AvatarDef('lightning', '⚡', unlockLevel: 15),
    AvatarDef('heart', '❤️', unlockLevel: 17),
    // Mid game — fierce
    AvatarDef('skull', '💀', unlockLevel: 20),
    AvatarDef('wolf', '🐺', unlockLevel: 22),
    AvatarDef('ninja', '🥷', unlockLevel: 25),
    AvatarDef('eagle', '🦅', unlockLevel: 28),
    // Late game — legendary
    AvatarDef('wizard', '🧙', unlockLevel: 30),
    AvatarDef('dragon', '🐉', unlockLevel: 33),
    AvatarDef('unicorn', '🦄', unlockLevel: 35),
    AvatarDef('phoenix', '🐦‍🔥', unlockLevel: 38),
    // End game — prestige
    AvatarDef('diamond', '💎', unlockLevel: 40),
    AvatarDef('crown', '👑', unlockLevel: 45),
    AvatarDef('trophy', '🏆', unlockLevel: 50),
  ];

  static final _emojiMap = {for (final a in all) a.id: a.emoji};

  /// Returns emoji for a given avatar ID (or first avatar as default).
  static String emoji(String? avatarId) =>
      _emojiMap[avatarId] ?? all.first.emoji;
}
