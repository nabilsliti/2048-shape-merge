import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

/// Centralized design system for all retention UI components.
/// All colors come from AppTheme — no Color literals here.
class RetentionUI {
  RetentionUI._();

  // ── Color aliases (delegate to AppTheme) ──────────────────────
  static const Color streakColor = AppTheme.streakColor;
  static const Color levelColor  = AppTheme.purpleTop;
  static const Color goalColor   = AppTheme.goalColor;
  static const Color dangerColor = AppTheme.dangerColor;
  static const Color cardBg      = AppTheme.cardBg;

  // ── Icons ─────────────────────────────────────────────────────
  static const IconData streakIcon  = Icons.local_fire_department_rounded;
  static const IconData levelIcon   = Icons.military_tech_rounded;
  static const IconData goalIcon    = Icons.flag_rounded;
  static const IconData fusionIcon  = Icons.merge_type_rounded;
  static const IconData scoreIcon   = Icons.emoji_events_rounded;
  static const IconData gamesIcon   = Icons.sports_esports_rounded;
  static const IconData xpIcon      = Icons.auto_awesome_rounded;
  static const IconData rewardIcon  = Icons.card_giftcard_rounded;
  static const IconData levelUpIcon = Icons.arrow_upward_rounded;
  static const IconData checkIcon   = Icons.check_circle_rounded;

  // ── pillBadge ─────────────────────────────────────────────────

  static Widget pillBadge({
    required IconData icon,
    required Color color,
    required String value,
    String? sub,
    VoidCallback? onTap,
  }) {
    final shadow = Color.fromARGB(
      255,
      (color.r * 0.45).round(),
      (color.g * 0.45).round(),
      (color.b * 0.45).round(),
    );

    final badge = IntrinsicHeight(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 4, left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: shadow,
                borderRadius: BorderRadius.circular(AppTheme.radiusXTiny),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radiusXTiny),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 14,
                    shadows: const [Shadow(color: Colors.black38, blurRadius: 4)]),
                const SizedBox(width: 5),
                if (sub != null) ...[
                  Text(sub,
                      style: GoogleFonts.fredoka(
                          fontSize: AppTheme.fontMini, color: Colors.white70, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 2),
                ],
                Text(value,
                    style: GoogleFonts.fredoka(
                        fontSize: AppTheme.fontRegular, color: Colors.white, fontWeight: FontWeight.w700,
                        shadows: [const Shadow(color: Colors.black45, blurRadius: 3)])),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return badge;
    return GestureDetector(onTap: onTap, child: badge);
  }

  // ── xpBadge ───────────────────────────────────────────────────

  static Widget xpBadge({required int currentXP, required int xpNeeded, String xpLabel = 'XP', bool expand = false, VoidCallback? onTap}) {
    const color = AppTheme.xpBadgeBot;
    final w = Container(
      constraints: const BoxConstraints(minWidth: 80, minHeight: 46),
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.xpBadgeTop, AppTheme.xpBadgeBot],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.xpBadgeBorder, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 14, offset: const Offset(0, 4)),
          const BoxShadow(color: Colors.black54, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('⚡', style: TextStyle(fontSize: AppTheme.fontRegular, height: 1)),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(xpLabel,
                  style: AppTheme.titleStyle(AppTheme.fontPico).copyWith(
                      color: AppTheme.goldLabel, letterSpacing: 1, height: 1)),
              Text(
                '$currentXP/$xpNeeded',
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontRegular,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return w;
    return GestureDetector(onTap: onTap, child: w);
  }

  // ── streakBadge ───────────────────────────────────────────────

  static Widget streakBadge({required int count, String dayLabel = 'DAY', bool expand = false, VoidCallback? onTap}) {
    final w = Container(
      constraints: const BoxConstraints(minWidth: 80, minHeight: 46),
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.streakBadgeTop, AppTheme.streakBadgeBot],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.streakBadgeBorder, width: 1.5),
        boxShadow: [
          BoxShadow(color: AppTheme.streakBadgeBot.withValues(alpha: 0.75), blurRadius: 14, offset: const Offset(0, 4)),
          const BoxShadow(color: Colors.black54, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [AppTheme.gold, AppTheme.goldIce, AppTheme.goldDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(r),
            child: const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dayLabel,
                  style: AppTheme.titleStyle(AppTheme.fontPico).copyWith(
                      color: AppTheme.goldLabel, letterSpacing: 1, height: 1)),
              Text(
                '$count',
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontH4,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  shadows: const [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return w;
    return GestureDetector(onTap: onTap, child: w);
  }

  // ── levelBadge ────────────────────────────────────────────────

  static Widget levelBadge({required int level, String levelShortLabel = 'NIV', bool expand = false, VoidCallback? onTap}) {
    final w = Container(
      constraints: const BoxConstraints(minWidth: 80, minHeight: 46),
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.levelBadgeTop, AppTheme.levelBadgeBot],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.levelBadgeBorder, width: 1.5),
        boxShadow: [
          BoxShadow(color: AppTheme.levelBadgeTop.withValues(alpha: 0.65), blurRadius: 14, offset: const Offset(0, 4)),
          const BoxShadow(color: Colors.black54, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('⭐', style: TextStyle(fontSize: AppTheme.fontRegular, height: 1)),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(levelShortLabel,
                  style: AppTheme.titleStyle(AppTheme.fontPico).copyWith(
                      color: AppTheme.goldLabel, letterSpacing: 1, height: 1)),
              Text(
                '$level',
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontH4,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return w;
    return GestureDetector(onTap: onTap, child: w);
  }

  // ── glassCard ─────────────────────────────────────────────────

  static BoxDecoration glassCard({required Color glow}) {
    return BoxDecoration(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      boxShadow: [
        BoxShadow(color: glow.withValues(alpha: 0.12), blurRadius: 16, spreadRadius: 1),
      ],
    );
  }

  // ── progressBar ───────────────────────────────────────────────

  static Widget progressBar({
    required double value,
    required Color color,
    double height = 5,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  // ── cardHeader ────────────────────────────────────────────────

  static Widget cardHeader({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.fredoka(
            fontSize: AppTheme.fontSmall,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        if (subtitle != null) ...[
          const Spacer(),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: AppTheme.fontMini,
              color: Colors.white38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  // ── shimmer ───────────────────────────────────────────────────

  static Widget shimmer({required Widget child, required Color color}) {
    return child
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1500.ms, color: color.withValues(alpha: 0.4));
  }

  // ── xpBarColor ────────────────────────────────────────────────

  static Color xpBarColor(int level) {
    if (level <= 10) return AppTheme.purpleTop;
    if (level <= 25) return AppTheme.xpBarViolet;
    return AppTheme.streakColor;
  }
}
