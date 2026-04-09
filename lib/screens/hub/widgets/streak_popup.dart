import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/models/player_streak.dart';

/// Shows the streak reward popup.
/// Call [StreakPopup.show] from the hub after checking streakProvider.
class StreakPopup extends StatelessWidget {
  const StreakPopup({super.key, required this.result});

  final StreakCheckResult result;

  static Future<void> show(BuildContext context, StreakCheckResult result) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => StreakPopup(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = result.streak;
    final todaySlot = (streak.nextRewardIndex - 1 + 7) % 7;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
        decoration: RetentionUI.glassCard(glow: RetentionUI.streakColor),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(streak),
            const SizedBox(height: 20),
            if (result.streakReset) _buildResetBanner(),
            if (!result.streakReset) ...[
              _buildWeekRow(todaySlot),
              const SizedBox(height: 20),
              if (result.reward != null) _buildRewardRow(result.reward!),
            ],
            if (result.showGuestNudge) ...[
              const SizedBox(height: 16),
              _buildGuestNudge(),
            ],
            const SizedBox(height: 24),
            _buildCloseButton(context),
          ],
        ),
      ).animate().scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1, 1),
            duration: 300.ms,
            curve: Curves.easeOutBack,
          ),
          Positioned(
            top: -12,
            right: -12,
            child: Button3D.red(
              padding: const EdgeInsets.all(8),
              borderRadius: 20,
              onPressed: () => Navigator.of(context).pop(),
              child: const PremiumIcon.close(size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(PlayerStreak streak) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(RetentionUI.streakIcon, color: RetentionUI.streakColor, size: 28),
            const SizedBox(width: 8),
            Text(
              'Jour ${streak.currentStreak}',
              style: GoogleFonts.fredoka(
                fontSize: AppTheme.fontH1,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0),
        const SizedBox(height: 4),
        Text(
          result.streakReset
              ? 'Ton streak s\'est interrompu…'
              : 'Connexion du jour validée !',
          style: GoogleFonts.nunito(
            fontSize: AppTheme.fontXSmall,
            color: Colors.white54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Reset banner ─────────────────────────────────────────────────────────

  Widget _buildResetBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: RetentionUI.dangerColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
        border: Border.all(color: RetentionUI.dangerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: RetentionUI.dangerColor, size: 32),
          const SizedBox(height: 8),
          Text(
            'Streak perdu',
            style: GoogleFonts.fredoka(
                fontSize: AppTheme.fontBody, fontWeight: FontWeight.w700, color: RetentionUI.dangerColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Reviens chaque jour pour accumuler\ndes bonus plus intéressants.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: AppTheme.fontTiny, color: Colors.white60),
          ),
          const SizedBox(height: 12),
          // Still show today's J1 reward
          if (result.reward != null) _buildRewardRow(result.reward!),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  // ── Week row ─────────────────────────────────────────────────────────────

  Widget _buildWeekRow(int todaySlot) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final (jType, amount) = PlayerStreak.rewardForIndex(i);
        final isToday = i == todaySlot;
        final isPast = i < todaySlot;
        return Expanded(
          child: _DaySlot(
            index: i,
            jokerType: jType,
            amount: amount,
            isToday: isToday,
            isPast: isPast,
          ),
        );
      }),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  // ── Reward row ────────────────────────────────────────────────────────────

  Widget _buildRewardRow((JokerType, int) reward) {
    final (jType, amount) = reward;
    final color = JokerUI.color(jType);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(RetentionUI.rewardIcon, color: RetentionUI.streakColor, size: 18),
          const SizedBox(width: 8),
          Text(
            'Récompense : ',
            style: GoogleFonts.nunito(
                fontSize: AppTheme.fontXSmall, color: Colors.white60, fontWeight: FontWeight.w600),
          ),
          JokerUI.icon(jType, size: 20),
          const SizedBox(width: 6),
          Text(
            '+$amount',
            style: GoogleFonts.fredoka(
                fontSize: AppTheme.fontH4, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            _jokerLabel(jType),
            style: GoogleFonts.nunito(
                fontSize: AppTheme.fontXSmall, color: Colors.white70, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms)
        .shimmer(duration: 1200.ms, delay: 400.ms, color: color.withValues(alpha: 0.35));
  }

  // ── Guest nudge ───────────────────────────────────────────────────────────

  Widget _buildGuestNudge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusXTiny),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_sync_outlined, color: Colors.white38, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connecte-toi pour ne jamais perdre ton streak.',
              style: GoogleFonts.nunito(
                  fontSize: AppTheme.fontTiny, color: Colors.white54, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 500.ms);
  }

  // ── Close button ──────────────────────────────────────────────────────────

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: RetentionUI.streakColor.withValues(alpha: 0.15),
          foregroundColor: RetentionUI.streakColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusTiny)),
          side: BorderSide(color: RetentionUI.streakColor.withValues(alpha: 0.3)),
        ),
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Super !',
          style: GoogleFonts.fredoka(
            fontSize: AppTheme.fontRegular,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _jokerLabel(JokerType type) => switch (type) {
    JokerType.bomb      => 'Bombe',
    JokerType.wildcard  => 'Wildcard',
    JokerType.reducer   => 'Réducteur',
    JokerType.radar     => 'Radar',
    JokerType.evolution => 'Évolution',
    JokerType.megaBomb  => 'Méga Bombe',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Day slot widget
// ─────────────────────────────────────────────────────────────────────────────

class _DaySlot extends StatelessWidget {
  const _DaySlot({
    required this.index,
    required this.jokerType,
    required this.amount,
    required this.isToday,
    required this.isPast,
  });

  final int index;
  final JokerType jokerType;
  final int amount;
  final bool isToday;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final color = isToday
        ? RetentionUI.streakColor
        : isPast
            ? RetentionUI.goalColor
            : Colors.white24;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: isToday
            ? RetentionUI.streakColor.withValues(alpha: 0.15)
            : isPast
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusXTiny),
        border: Border.all(
          color: isToday
              ? RetentionUI.streakColor.withValues(alpha: 0.5)
              : isPast
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.05),
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: RetentionUI.streakColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'J${index + 1}',
            style: GoogleFonts.nunito(
              fontSize: AppTheme.fontNano,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          if (isPast)
            Icon(Icons.check_circle_rounded, color: RetentionUI.goalColor, size: 16)
          else if (!isToday)
            Icon(Icons.lock_outline_rounded, color: Colors.white24, size: 14)
          else
            SizedBox(
              width: 20,
              height: 20,
              child: JokerUI.icon(jokerType, size: 18),
            ),
          const SizedBox(height: 2),
          Text(
            isToday || isPast ? '+$amount' : '',
            style: GoogleFonts.nunito(
              fontSize: AppTheme.fontPico,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 80 * index)).fadeIn(duration: 300.ms);
  }
}
