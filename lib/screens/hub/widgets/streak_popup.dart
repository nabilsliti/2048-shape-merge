import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/models/player_streak.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/streak_provider.dart';

/// Shows the streak reward popup.
/// Call [StreakPopup.show] from the hub after checking streakProvider.
class StreakPopup extends ConsumerStatefulWidget {
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
  ConsumerState<StreakPopup> createState() => _StreakPopupState();
}

class _StreakPopupState extends ConsumerState<StreakPopup>
    with TickerProviderStateMixin {
  bool _collected = false;
  bool _animDone = false;
  late final AnimationController _bounceCtrl;
  late final AnimationController _plusOneCtrl;
  late final AnimationController _sparkleCtrl;

  @override
  void initState() {
    super.initState();
    _collected = widget.result.rewardClaimed;
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _plusOneCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _sparkleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _plusOneCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  void _onCollect() {
    if (_collected) return;
    setState(() => _collected = true);
    HapticFeedback.heavyImpact();
    ref.read(streakProvider.notifier).claimStreakReward();
    _bounceCtrl.forward(from: 0);
    _plusOneCtrl.forward(from: 0);
    _sparkleCtrl.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 400), () {
      AudioService.instance.playReward();
    });
    // After animation, switch to "already collected" state
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _animDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final streak = result.streak;
    final todaySlot = (streak.nextRewardIndex - 1 + 7) % 7;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
        decoration: BoxDecoration(
          color: AppTheme.panelBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: AppTheme.panelBorder, width: 3),
          boxShadow: const [
            BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 8)),
            BoxShadow(color: Colors.black54, offset: Offset(0, 12), blurRadius: 20),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(streak, l10n),
            const SizedBox(height: 20),
            if (result.streakReset) ...[_buildResetBanner(l10n)],
            if (!result.streakReset) ...[
              _buildWeekRow(todaySlot),
              const SizedBox(height: 20),
              if (result.reward != null) _buildRewardRow(result.reward!, l10n),
            ],
            if (result.showGuestNudge) ...[
              const SizedBox(height: 16),
              _buildGuestNudge(l10n),
            ],
            if (!result.streakReset) ...[const SizedBox(height: 24), _buildCollectButton(l10n, result.reward)],
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

  Widget _buildHeader(PlayerStreak streak, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(RetentionUI.streakIcon, color: RetentionUI.streakColor, size: 28),
            const SizedBox(width: 8),
            Text(
              l10n.streakDay(streak.currentStreak),
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
          widget.result.streakReset
              ? l10n.streakBrokenDesc
              : l10n.streakConnectedToday,
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

  Widget _buildResetBanner(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: RetentionUI.dangerColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
        border: Border.all(color: RetentionUI.dangerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: RetentionUI.dangerColor, size: 36),
          const SizedBox(height: 10),
          Text(
            l10n.streakLost,
            style: GoogleFonts.fredoka(
                fontSize: AppTheme.fontH4, fontWeight: FontWeight.w700, color: RetentionUI.dangerColor),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.streakLostDesc,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: AppTheme.fontTiny, color: Colors.white60),
          ),
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

  Widget _buildRewardRow((JokerType, int) reward, AppLocalizations l10n) {
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
            l10n.rewardLabel,
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
            _jokerLabel(jType, l10n),
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

  Widget _buildGuestNudge(AppLocalizations l10n) {
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
              l10n.streakSaveNudge,
              style: GoogleFonts.nunito(
                  fontSize: AppTheme.fontTiny, color: Colors.white54, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 500.ms);
  }

  // ── Collect button ─────────────────────────────────────────────────────────

  Widget _buildCollectButton(AppLocalizations l10n, (JokerType, int)? reward) {
    // No reward to collect, or animation finished
    if (reward == null || _animDone) {
      return Button3D.gray(
        expand: true,
        onPressed: null,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, color: Colors.white54, size: 18),
              const SizedBox(width: 6),
              Text(
                l10n.streakCollect,
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontBody,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Animation playing after just collecting
    if (_collected) {
      return _buildRewardAnimation(reward!);
    }

    final (jType, amount) = reward!;

    // Active collect button
    final content = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.collectReward,
            style: GoogleFonts.fredoka(
              fontSize: AppTheme.fontBody,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          JokerUI.icon(jType, size: 18),
          const SizedBox(width: 4),
          Text(
            '+$amount',
            style: GoogleFonts.fredoka(
              fontSize: AppTheme.fontBody,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    return Button3D.green(
      expand: true,
      onPressed: _onCollect,
      child: content,
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.05, duration: 800.ms, curve: Curves.easeInOut);
  }

  Widget _buildRewardAnimation((JokerType, int) reward) {
    final (jType, amount) = reward;
    final rewardColor = JokerUI.color(jType);
    final rewardIcon = JokerUI.icon(jType, size: 28);
    final rewardLabel = '+$amount';

    return AnimatedBuilder(
      animation: Listenable.merge([_bounceCtrl, _plusOneCtrl, _sparkleCtrl]),
      builder: (context, _) {
        // Bounce: 1→1.5→0.9→1
        final double bounceScale;
        if (_bounceCtrl.value < 0.3) {
          bounceScale = 1.0 + (_bounceCtrl.value / 0.3) * 0.5;
        } else if (_bounceCtrl.value < 0.6) {
          bounceScale = 1.5 - ((_bounceCtrl.value - 0.3) / 0.3) * 0.6;
        } else {
          bounceScale = 0.9 + ((_bounceCtrl.value - 0.6) / 0.4) * 0.1;
        }

        // +N float up
        final plusT = Curves.easeOutCubic.transform(_plusOneCtrl.value);
        final plusOpacity = (1.0 - _plusOneCtrl.value * 0.8).clamp(0.0, 1.0);
        final plusOffset = -40.0 * plusT;

        // Glow intensity
        final glowIntensity = _bounceCtrl.value < 0.5
            ? _bounceCtrl.value * 2
            : 2 - _bounceCtrl.value * 2;

        return SizedBox(
          height: 50,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Sparkles
              if (_sparkleCtrl.isAnimating)
                for (var i = 0; i < 8; i++)
                  Positioned(
                    top: 25 + math.sin((i / 8) * 2 * math.pi) * 30 * _sparkleCtrl.value,
                    left: MediaQuery.of(context).size.width * 0.3 +
                        math.cos((i / 8) * 2 * math.pi) * 35 * _sparkleCtrl.value,
                    child: Opacity(
                      opacity: (1.0 - _sparkleCtrl.value).clamp(0.0, 1.0),
                      child: Container(
                        width: 5 * (1 - _sparkleCtrl.value * 0.5),
                        height: 5 * (1 - _sparkleCtrl.value * 0.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rewardColor,
                          boxShadow: [BoxShadow(color: rewardColor.withValues(alpha: 0.6), blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
              // Icon bouncing
              Transform.scale(
                scale: _bounceCtrl.isAnimating ? bounceScale : 1.0,
                child: Container(
                  decoration: glowIntensity > 0
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: rewardColor.withValues(alpha: glowIntensity * 0.7), blurRadius: 16, spreadRadius: 2),
                          ],
                        )
                      : null,
                  child: rewardIcon,
                ),
              ),
              // Floating "+N"
              if (_plusOneCtrl.isAnimating)
                Positioned(
                  top: plusOffset,
                  child: Opacity(
                    opacity: plusOpacity,
                    child: Text(
                      rewardLabel,
                      style: GoogleFonts.fredoka(
                        fontSize: AppTheme.fontH3,
                        fontWeight: FontWeight.w900,
                        color: rewardColor,
                        shadows: [
                          Shadow(color: rewardColor.withValues(alpha: 0.8), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _jokerLabel(JokerType type, AppLocalizations l10n) => switch (type) {
    JokerType.bomb      => l10n.jokerBomb,
    JokerType.wildcard  => l10n.jokerWildcard,
    JokerType.reducer   => l10n.jokerReducer,
    JokerType.radar     => l10n.jokerRadar,
    JokerType.evolution => l10n.jokerEvolution,
    JokerType.megaBomb  => l10n.jokerMegaBomb,
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
