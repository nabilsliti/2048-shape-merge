import 'package:flutter/material.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';

/// Centralized joker icon + color config.
/// All colors come from AppTheme — no Color literals here.
class JokerUI {
  JokerUI._();

  // ── Color aliases (delegate to AppTheme) ──────────────────────
  static const Color radarColor     = AppTheme.radarColor;
  static const Color evolutionColor = AppTheme.evolutionColor;
  static const Color megaBombColor  = AppTheme.megaBombColor;

  static Color color(JokerType type) {
    switch (type) {
      case JokerType.bomb:      return AppTheme.redTop;
      case JokerType.wildcard:  return AppTheme.blueTop;
      case JokerType.reducer:   return AppTheme.greenTop;
      case JokerType.radar:     return AppTheme.radarColor;
      case JokerType.evolution: return AppTheme.evolutionColor;
      case JokerType.megaBomb:  return AppTheme.megaBombColor;
    }
  }

  // ── Icons ─────────────────────────────────────────────────────
  static Widget icon(JokerType type, {double size = 24}) {
    switch (type) {
      case JokerType.bomb:
        return JokerIcon.bomb(size: size);
      case JokerType.wildcard:
        return Icon(Icons.auto_awesome_rounded, color: AppTheme.blueTop, size: size);
      case JokerType.reducer:
        return Icon(Icons.keyboard_double_arrow_down_rounded, color: AppTheme.greenTop, size: size);
      case JokerType.radar:
        return Icon(Icons.track_changes_rounded, color: AppTheme.radarColor, size: size);
      case JokerType.evolution:
        return Icon(Icons.trending_up_rounded, color: AppTheme.evolutionColor, size: size);
      case JokerType.megaBomb:
        return Icon(Icons.local_fire_department_rounded, color: AppTheme.megaBombColor, size: size);
    }
  }

  /// Ring gradient colors for orb ring effect.
  static List<Color> ringColors(JokerType type) {
    switch (type) {
      case JokerType.bomb:      return [AppTheme.reducerArrow1, AppTheme.deathBadgeBot];
      case JokerType.wildcard:  return [AppTheme.purpleBorder, AppTheme.purpleBot];
      case JokerType.reducer:   return [AppTheme.greenBorder, AppTheme.greenBot];
      case JokerType.radar:     return [AppTheme.yellowBorder, AppTheme.yellowBot];
      case JokerType.evolution: return [AppTheme.xpBadgeBorder, AppTheme.xpBadgeTop];
      case JokerType.megaBomb:  return [AppTheme.orangeBorder, AppTheme.orangeBot];
    }
  }

  static String label(JokerType type) => switch (type) {
    JokerType.bomb      => 'Bombe',
    JokerType.wildcard  => 'Wildcard',
    JokerType.reducer   => 'Réducteur',
    JokerType.radar     => 'Radar',
    JokerType.evolution => 'Évolution',
    JokerType.megaBomb  => 'MégaBombe',
  };

  static Color glowColor(JokerType type) {
    switch (type) {
      case JokerType.bomb:      return AppTheme.bombGlow;
      case JokerType.wildcard:  return AppTheme.wildcardGlowPurple;
      case JokerType.reducer:   return AppTheme.greenTop;
      case JokerType.radar:     return AppTheme.radarColor;
      case JokerType.evolution: return AppTheme.evolutionColor;
      case JokerType.megaBomb:  return AppTheme.megaBombColor;
    }
  }
}
