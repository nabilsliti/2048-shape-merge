import 'package:flutter/material.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';

/// Centralized joker icon + color config.
/// Use [JokerUI.icon] and [JokerUI.color] instead of hardcoding icons everywhere.
class JokerUI {
  JokerUI._();

  // ── Couleurs ──────────────────────────────────────────────────
  static const Color radarColor     = Color(0xFFFFD60A);
  static const Color evolutionColor = Color(0xFF00d4ff);
  static const Color megaBombColor  = Color(0xFFFF6D00);

  static Color color(JokerType type) {
    switch (type) {
      case JokerType.bomb:      return AppTheme.redTop;
      case JokerType.wildcard:  return AppTheme.blueTop;
      case JokerType.reducer:   return AppTheme.greenTop;
      case JokerType.radar:     return radarColor;
      case JokerType.evolution: return evolutionColor;
      case JokerType.megaBomb:  return megaBombColor;
    }
  }

  // ── Icônes ────────────────────────────────────────────────────
  static Widget icon(JokerType type, {double size = 24}) {
    switch (type) {
      case JokerType.bomb:
        return JokerIcon.bomb(size: size);
      case JokerType.wildcard:
        return Icon(Icons.auto_awesome_rounded, color: AppTheme.blueTop, size: size);
      case JokerType.reducer:
        return Icon(Icons.keyboard_double_arrow_down_rounded, color: AppTheme.greenTop, size: size);
      case JokerType.radar:
        return Icon(Icons.track_changes_rounded, color: radarColor, size: size);
      case JokerType.evolution:
        return Icon(Icons.trending_up_rounded, color: evolutionColor, size: size);
      case JokerType.megaBomb:
        return Icon(Icons.local_fire_department_rounded, color: megaBombColor, size: size);
    }
  }

  /// Anneau de couleur pour les orbes (gradient du ring).
  static List<Color> ringColors(JokerType type) {
    switch (type) {
      case JokerType.bomb:      return const [Color(0xFFff6b6b), Color(0xFFcc0000)];
      case JokerType.wildcard:  return const [Color(0xFFce93d8), Color(0xFF7b1fa2)];
      case JokerType.reducer:   return const [Color(0xFF80ffa5), Color(0xFF007c2c)];
      case JokerType.radar:     return const [Color(0xFFfff176), Color(0xFFc49b00)];
      case JokerType.evolution: return const [Color(0xFF40e0ff), Color(0xFF005577)];
      case JokerType.megaBomb:  return const [Color(0xFFFF9E40), Color(0xFFBF360C)];
    }
  }

  /// Intensité du glow (couleur légèrement plus vive que color()).
  static Color glowColor(JokerType type) {
    switch (type) {
      case JokerType.bomb:      return const Color(0xFFff4444);
      case JokerType.wildcard:  return const Color(0xFFaa44ff);
      case JokerType.reducer:   return AppTheme.greenTop;
      case JokerType.radar:     return radarColor;
      case JokerType.evolution: return evolutionColor;
      case JokerType.megaBomb:  return megaBombColor;
    }
  }
}
