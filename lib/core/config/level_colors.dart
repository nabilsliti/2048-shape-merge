import 'dart:ui';

// ─────────────────────────────────────────────────────────────
// Level Colors — shape fill colors by merge level.
//
// To add a new level color: append to the list.
// Shapes at levels beyond the list wrap to the last color.
// ─────────────────────────────────────────────────────────────

abstract final class LevelColors {
  static const List<Color> palette = [
    Color(0xFFFF0000), // 1 — rouge pur
    Color(0xFF0000FF), // 2 — bleu pur
    Color(0xFFFFFF00), // 3 — jaune pur
    Color(0xFF00FF00), // 4 — vert pur
    Color(0xFF4B0082), // 5 — indigo profond
    Color(0xFFFF8000), // 6 — orange pur
    Color(0xFF00FFFF), // 7 — cyan pur
    Color(0xFFFF1493), // 8 — hot pink
  ];

  /// Returns the fill color for a shape at [level] (1-based).
  static Color forLevel(int level) =>
      palette[(level - 1).clamp(0, palette.length - 1)];
}
