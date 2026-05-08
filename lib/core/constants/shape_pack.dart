import 'package:shape_merge/core/constants/shape_types.dart';

/// Available shape packs (visual skins for the game pieces).
enum ShapePack {
  classic,
  emoji;

  /// Localized display name (delegates to l10n at call site).
  String get key => name;
}

/// Maps each [ShapeType] to an SVG asset path for a given [ShapePack].
///
/// Returns `null` for [ShapePack.classic] (uses procedural Canvas drawing).
abstract final class ShapePackAssets {
  static const _emojiAssets = {
    ShapeType.circle: 'assets/shapes/emoji/heart.svg',
    ShapeType.square: 'assets/shapes/emoji/bolt.svg',
    ShapeType.triangle: 'assets/shapes/emoji/moon.svg',
    ShapeType.diamond: 'assets/shapes/emoji/flame.svg',
    ShapeType.star: 'assets/shapes/emoji/clover.svg',
    ShapeType.hexagon: 'assets/shapes/emoji/cloud.svg',
  };

  /// Returns the SVG asset path for the given [pack] and [type],
  /// or `null` if the pack uses procedural rendering.
  static String? svgAsset(ShapePack pack, ShapeType type) {
    return switch (pack) {
      ShapePack.classic => null,
      ShapePack.emoji => _emojiAssets[type],
    };
  }
}
