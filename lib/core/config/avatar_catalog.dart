// ─────────────────────────────────────────────────────────────
// Avatar Catalog — all profile avatars in one place.
//
// To add/remove an avatar: edit this list only.
// ─────────────────────────────────────────────────────────────

class AvatarDef {
  final String id;
  final String emoji;
  const AvatarDef(this.id, this.emoji);
}

abstract final class AvatarCatalog {
  static const List<AvatarDef> all = [
    AvatarDef('robot', '🤖'),
    AvatarDef('alien', '👾'),
    AvatarDef('rocket', '🚀'),
    AvatarDef('fire', '🔥'),
    AvatarDef('star', '⭐'),
    AvatarDef('diamond', '💎'),
    AvatarDef('crown', '👑'),
    AvatarDef('lightning', '⚡'),
    AvatarDef('skull', '💀'),
    AvatarDef('ghost', '👻'),
    AvatarDef('ninja', '🥷'),
    AvatarDef('wizard', '🧙'),
    AvatarDef('dragon', '🐉'),
    AvatarDef('unicorn', '🦄'),
    AvatarDef('phoenix', '🐦‍🔥'),
    AvatarDef('cat', '🐱'),
    AvatarDef('wolf', '🐺'),
    AvatarDef('eagle', '🦅'),
    AvatarDef('trophy', '🏆'),
    AvatarDef('heart', '❤️'),
  ];

  /// Returns emoji for a given avatar ID (or first avatar as default).
  static String emoji(String? avatarId) {
    if (avatarId == null) return all.first.emoji;
    for (final a in all) {
      if (a.id == avatarId) return a.emoji;
    }
    return all.first.emoji;
  }
}
