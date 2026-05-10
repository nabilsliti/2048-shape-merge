import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/models/player_streak.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/ads_provider.dart';
import 'package:shape_merge/providers/streak_provider.dart';
import 'package:vibration/vibration.dart';

/// Premium Daily Bonus overlay — luxurious neon design matching AppTheme.
class StreakPopup extends ConsumerStatefulWidget {
  const StreakPopup({super.key, required this.result});

  final StreakCheckResult result;

  /// Prevents duplicate popups from opening simultaneously.
  static bool _isShowing = false;

  static Future<void> show(BuildContext context, StreakCheckResult result) {
    if (_isShowing) return Future<void>.value();
    _isShowing = true;
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => StreakPopup(result: result),
    ).whenComplete(() => _isShowing = false);
  }

  @override
  ConsumerState<StreakPopup> createState() => _StreakPopupState();
}

class _StreakPopupState extends ConsumerState<StreakPopup>
    with TickerProviderStateMixin {
  /// True once the local collect animation has finished. Combined with the
  /// live `streakProvider.rewardClaimed` to decide whether the popup should
  /// show the Collect button, the reward animation, or the countdown. We
  /// must NOT cache `widget.result.rewardClaimed` once at construction —
  /// that snapshot can become stale (e.g. user closes the popup mid-claim,
  /// reopens it, and the provider state has since flipped to claimed). See
  /// regression: "clicked Collect, closed, reopened, Collect appeared
  /// again".
  bool _localAnimDone = false;
  bool _showCollectAnim = false;
  bool _isX2 = false;

  late final AnimationController _bounceCtrl;
  late final AnimationController _plusOneCtrl;
  late final AnimationController _sparkleCtrl;

  Timer? _countdownTimer;
  Duration _timeToNextReward = Duration.zero;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _plusOneCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _sparkleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _startCountdown();
  }

  void _startCountdown() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateCountdown();
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    setState(() => _timeToNextReward = tomorrow.difference(now));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bounceCtrl.dispose();
    _plusOneCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  void _onCollect() {
    // Source of truth = live provider state (already-claimed guard) plus the
    // local animation guard (don't re-trigger while we're mid-celebration).
    final liveClaimed = ref.read(streakProvider)?.rewardClaimed ?? false;
    if (liveClaimed || _showCollectAnim || _localAnimDone) return;
    ref.read(streakProvider.notifier).claimStreakReward();
    _playCollectAnimation();
  }

  void _playCollectAnimation() {
    if (_showCollectAnim) return;
    setState(() => _showCollectAnim = true);
    if (Button3D.vibrationEnabled) Vibration.vibrate(duration: 100);
    AudioService.instance.playReward();
    _bounceCtrl.forward(from: 0);
    _plusOneCtrl.forward(from: 0);
    _sparkleCtrl.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _localAnimDone = true);
    });
  }

  void _onCollectX2() async {
    final liveClaimed = ref.read(streakProvider)?.rewardClaimed ?? false;
    if (liveClaimed || _showCollectAnim || _localAnimDone) return;
    final adsService = ref.read(adsServiceProvider);
    final rewarded = await adsService.showRewardedAd(onRewarded: () {});
    if (!rewarded) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adNotReady,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: AppTheme.redTop,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      adsService.loadRewardedAd();
      return;
    }
    if (!mounted) return;
    // Claim with x2 multiplier — claimStreakReward handles the doubling
    ref.read(streakProvider.notifier).claimStreakReward(doubled: true);
    adsService.loadRewardedAd();
    _isX2 = true;
    _playCollectAnimation();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ────────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final streak = result.streak;
    final todaySlot = (streak.nextRewardIndex - 1 +
            PlayerStreak.rewardCycleLength) %
        PlayerStreak.rewardCycleLength;
    final l10n = AppLocalizations.of(context)!;

    // `collected` is reactive: as soon as the streak provider flips to
    // claimed (server CF success, guest local write, or already-claimed
    // detected on retry), the popup hides the Collect button and shows the
    // countdown — even if the popup was opened with a stale `widget.result`.
    final liveClaimed = ref.watch(streakProvider)?.rewardClaimed ?? false;
    final collected = liveClaimed || _localAnimDone;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Main panel ──
          Container(
            decoration: BoxDecoration(
              color: AppTheme.panelBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(color: AppTheme.panelBorder, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.panelBorder.withValues(alpha: 0.35),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                    color: AppTheme.shadowDeep, offset: Offset(0, 8)),
                const BoxShadow(
                    color: Colors.black54,
                    offset: Offset(0, 14),
                    blurRadius: 28),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL - 2.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTitleBar(l10n),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.dailyBonusSubtitle,
                          style: GoogleFonts.nunito(
                            fontSize: AppTheme.fontSmall,
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildMilestoneBar(streak.currentStreak, collected, l10n),
                        const SizedBox(height: 10),
                        if (result.streakReset) ...[
                          _buildResetBanner(l10n),
                          const SizedBox(height: 8),
                        ],
                        _buildDayGrid(todaySlot, streak.currentStreak, collected, l10n),
                        const SizedBox(height: 8),
                        _buildDay7Card(todaySlot, streak.currentStreak, l10n),
                        const SizedBox(height: 10),
                        if (result.showGuestNudge) ...[
                          _buildGuestNudge(l10n),
                          const SizedBox(height: 10),
                        ],
                        if (!collected &&
                            !_showCollectAnim &&
                            result.reward != null)
                          _buildCollectButton(l10n, result.reward!)
                        else if (_showCollectAnim && !collected && result.reward != null)
                          _buildCollectAnimation(result.reward!)
                        else
                          _buildCountdown(l10n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1, 1),
                duration: 350.ms,
                curve: Curves.easeOutBack,
              ),

          // ── Close button ──
          Positioned(
            top: -12,
            right: -12,
            child: Button3D.red(
              padding: const EdgeInsets.all(8),
              borderRadius: 20,
              onPressed: () => Navigator.of(context).pop(),
              child: PremiumIcon.close(size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // TITLE BAR — gradient with shimmer
  // ────────────────────────────────────────────────────────────────
  Widget _buildTitleBar(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.panelBorder, AppTheme.blueTop],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container()
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                  duration: 2000.ms,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
          ),
          Text(
            l10n.dailyBonusTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: AppTheme.fontH1,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.3, end: 0);
  }

  // ────────────────────────────────────────────────────────────────
  // MILESTONE BAR
  // ────────────────────────────────────────────────────────────────
  Widget _buildMilestoneBar(int currentStreak, bool collected, AppLocalizations l10n) {
    const milestones = [7, 14, 21, 28];
    const giftImages = [
      'assets/images/gift_1.webp',
      'assets/images/gift_2.webp',
      'assets/images/gift_3.webp',
      'assets/images/gift_4.webp',
    ];
    // Cycle every 28 days (4 weeks)
    const cycleLength = 28;
    final effectiveDay = currentStreak == 0
        ? 0
        : ((currentStreak - 1) % cycleLength) + 1;
    // Progress: before collect stops just before today, after collect includes today
    final progressDay = collected ? effectiveDay : (effectiveDay - 1).clamp(0, cycleLength);
    final progress = (progressDay / cycleLength).clamp(0.0, 1.0);

    bool isMilestoneReached(int milestone) {
      if (effectiveDay > milestone) return true;
      if (effectiveDay == milestone && collected) return true;
      return false;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const barLeft = 50.0;
        const barRight = 15.0;
        final barWidth = constraints.maxWidth - barLeft - barRight;

        return SizedBox(
          height: 65,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Day counter badge
              Positioned(
                left: 0,
                top: 18,
                child: Container(
                  width: 44,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppTheme.streakBadgeTop, AppTheme.streakBadgeBot],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.streakBadgeBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.panelBorder.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.dayLabel,
                        style: GoogleFonts.fredoka(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.muted,
                        ),
                      ),
                      Text(
                        '$currentStreak',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Progress bar track
              Positioned(
                left: barLeft,
                right: barRight,
                top: 38,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.goalColor, AppTheme.panelBorder],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goalColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Milestone gift icons
              for (var i = 0; i < milestones.length; i++)
                Positioned(
                  left: barLeft +
                      ((i + 1) / milestones.length) * barWidth -
                      20,
                  top: 0,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: isMilestoneReached(milestones[i])
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.goalColor
                                              .withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Image.asset(
                                giftImages[i],
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (isMilestoneReached(milestones[i]))
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.panelBg,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.goalColor
                                            .withValues(alpha: 0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.check_circle_rounded,
                                      color: AppTheme.goalColor, size: 16),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isMilestoneReached(milestones[i])
                              ? AppTheme.goalColor
                              : AppTheme.gold,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: (isMilestoneReached(milestones[i])
                                      ? AppTheme.goalColor
                                      : AppTheme.gold)
                                  .withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '${milestones[i]}',
                          style: GoogleFonts.fredoka(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.panelBg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  // ────────────────────────────────────────────────────────────────
  // RESET BANNER
  // ────────────────────────────────────────────────────────────────
  Widget _buildResetBanner(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: RetentionUI.dangerColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: RetentionUI.dangerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: RetentionUI.dangerColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.streakLost,
                  style: GoogleFonts.fredoka(
                    fontSize: AppTheme.fontSmall,
                    fontWeight: FontWeight.w700,
                    color: RetentionUI.dangerColor,
                  ),
                ),
                Text(
                  l10n.streakLostDesc,
                  style: GoogleFonts.nunito(
                    fontSize: AppTheme.fontTiny,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  // ────────────────────────────────────────────────────────────────
  // DAY GRID 3x2
  // ────────────────────────────────────────────────────────────────
  Widget _buildDayGrid(
      int todaySlot, int currentStreak, bool collected, AppLocalizations l10n) {
    final weekStart =
        currentStreak - (currentStreak - 1) % PlayerStreak.rewardCycleLength;
    return Column(
      children: [
        for (var row = 0; row < 2; row++)
          Padding(
            padding: EdgeInsets.only(bottom: row == 0 ? 8 : 0),
            child: Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _buildDayCard(
                      index: row * 3 + col,
                      todaySlot: todaySlot,
                      weekStart: weekStart,
                      collected: collected,
                      l10n: l10n,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }

  Widget _buildDayCard({
    required int index,
    required int todaySlot,
    required int weekStart,
    required bool collected,
    required AppLocalizations l10n,
  }) {
    final dayStreak = weekStart + index;
    final reward = PlayerStreak.rewardForStreak(dayStreak);
    final isToday = index == todaySlot;
    final isPast = index < todaySlot;
    final isCollectedToday = isToday && collected;

    final Widget rewardIcon;
    final String rewardLabel;
    switch (reward) {
      case StreakJokerReward(:final type, :final amount):
        rewardIcon = JokerUI.icon(type, size: 44);
        rewardLabel = l10n.rewardPlusN(amount);
      case StreakXpReward(:final xp):
        rewardIcon = const Icon(RetentionUI.xpIcon, color: RetentionUI.xpColor, size: 44);
        rewardLabel = l10n.xpGained(xp);
    }

    final isFuture = !isToday && !isPast;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        gradient: isToday
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isCollectedToday
                    ? [
                        AppTheme.goalColor.withValues(alpha: 0.3),
                        AppTheme.goalColor.withValues(alpha: 0.15),
                      ]
                    : [
                        AppTheme.goalColor.withValues(alpha: 0.2),
                        AppTheme.goalColor.withValues(alpha: 0.06),
                      ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? AppTheme.goalColor
              : isPast
                  ? AppTheme.goalColor.withValues(alpha: 0.2)
                  : AppTheme.panelBorder.withValues(alpha: 0.15),
          width: isToday ? 2 : 1,
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppTheme.goalColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isToday ? l10n.todayLabel : l10n.streakDay(index + 1),
            style: GoogleFonts.fredoka(
              fontSize: isToday ? 11 : 10,
              fontWeight: FontWeight.w700,
              color: isToday
                  ? AppTheme.goalColor
                  : isPast
                      ? AppTheme.muted.withValues(alpha: 0.5)
                      : AppTheme.muted.withValues(alpha: 0.4),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 50,
            height: 50,
            child: isFuture
                ? const Center(
                    child: Icon(Icons.lock_rounded, color: Colors.white24, size: 28),
                  )
                : Stack(
                    children: [
                      Center(
                        child: (isPast || isCollectedToday)
                            ? ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                    Colors.white24, BlendMode.modulate),
                                child: rewardIcon,
                              )
                            : rewardIcon,
                      ),
                      if (isPast || isCollectedToday)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.panelBg,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goalColor.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.check_circle_rounded,
                                color: AppTheme.goalColor, size: 16),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 2),
          Text(
            isFuture ? '???' : rewardLabel,
            style: GoogleFonts.fredoka(
              fontSize: AppTheme.fontSmall,
              fontWeight: FontWeight.w700,
              color: isPast ? Colors.white38 : Colors.white,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 250.ms);
  }

  // ────────────────────────────────────────────────────────────────
  // DAY 7 CARD — gift showcase
  // ────────────────────────────────────────────────────────────────
  Widget _buildDay7Card(
      int todaySlot, int currentStreak, AppLocalizations l10n) {
    final isToday = todaySlot == 6;
    final isPast = todaySlot > 6;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: isToday
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.goalColor.withValues(alpha: 0.2),
                  AppTheme.goalColor.withValues(alpha: 0.06),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.gold.withValues(alpha: 0.08),
                  AppTheme.panelBorder.withValues(alpha: 0.04),
                ],
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? AppTheme.goalColor
              : AppTheme.gold.withValues(alpha: 0.3),
          width: isToday ? 2 : 1.5,
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppTheme.goalColor.withValues(alpha: 0.25),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? l10n.todayLabel : l10n.streakDay(7),
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontBody,
                  fontWeight: FontWeight.w700,
                  color: isToday ? AppTheme.goalColor : AppTheme.gold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.bonusStars,
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontPico,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gold.withValues(alpha: 0.6),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 88,
            height: 88,
            child: OverflowBox(
              maxWidth: 110,
              maxHeight: 110,
              child: Image.asset(
                'assets/images/gift_5.webp',
                width: 110,
                height: 110,
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (isPast) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.panelBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goalColor.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.goalColor, size: 22),
            ),
          ],
        ],
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 300.ms);
  }

  // ────────────────────────────────────────────────────────────────
  // GUEST NUDGE
  // ────────────────────────────────────────────────────────────────
  Widget _buildGuestNudge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_sync_outlined,
              color: Colors.white38, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.streakSaveNudge,
              style: GoogleFonts.nunito(
                fontSize: AppTheme.fontTiny,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 500.ms);
  }

  // ────────────────────────────────────────────────────────────────
  // COLLECT BUTTON
  // ────────────────────────────────────────────────────────────────
  Widget _buildCollectButton(
      AppLocalizations l10n, StreakReward reward) {
    final canDouble = reward.canDoubleWithAd;

    if (!canDouble) {
      // Premium reward — single collect button only, no x2
      return SizedBox(
        height: 56,
        width: double.infinity,
        child: Button3D.green(
          onPressed: _onCollect,
          borderRadius: 14,
          expand: true,
          child: Text(
            l10n.collectReward,
            style: GoogleFonts.fredoka(
              fontSize: AppTheme.fontBody,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        // x2 button (ad) — first position
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 56,
            child: Button3D.green(
              onPressed: _onCollectX2,
              borderRadius: 14,
              expand: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/pub.webp', width: 40, height: 40),
                  const SizedBox(width: 6),
                  Text(
                    '${l10n.collectReward}${l10n.rewardX2}',
                    style: GoogleFonts.fredoka(
                      fontSize: AppTheme.fontBody,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
                begin: 1.0,
                end: 1.04,
                duration: 800.ms,
                curve: Curves.easeInOut),
        const SizedBox(width: 20),
        // Normal collect button
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 56,
            child: Button3D.gold(
              onPressed: _onCollect,
              borderRadius: 14,
              expand: true,
              child: Text(
                l10n.collectReward,
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontBody,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // COUNTDOWN
  // ────────────────────────────────────────────────────────────────
  Widget _buildCountdown(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.nextRewardIn,
          style: GoogleFonts.nunito(
            fontSize: AppTheme.fontSmall,
            color: AppTheme.muted.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDuration(_timeToNextReward),
          style: GoogleFonts.fredoka(
            fontSize: AppTheme.fontH3,
            fontWeight: FontWeight.w700,
            color: AppTheme.panelBorder,
            shadows: [
              Shadow(
                color: AppTheme.panelBorder.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // COLLECT ANIMATION
  // ────────────────────────────────────────────────────────────────
  Widget _buildCollectAnimation(StreakReward reward) {
    final Color color;
    final Widget icon;
    final String label;

    final l10n = AppLocalizations.of(context)!;

    switch (reward) {
      case StreakJokerReward(:final type, :final amount):
        color = JokerUI.color(type);
        icon = JokerUI.icon(type, size: 28);
        final displayAmount = _isX2 ? amount * 2 : amount;
        label = l10n.rewardPlusN(displayAmount);
      case StreakXpReward(:final xp):
        color = RetentionUI.xpColor;
        icon = const Icon(RetentionUI.xpIcon, color: RetentionUI.xpColor, size: 28);
        final displayXp = _isX2 ? xp * 2 : xp;
        label = l10n.xpGained(displayXp);
    }

    return SizedBox(
      height: 56,
      child: AnimatedBuilder(
        animation:
            Listenable.merge([_bounceCtrl, _plusOneCtrl, _sparkleCtrl]),
        builder: (context, _) {
          final double bounceScale;
          if (_bounceCtrl.value < 0.3) {
            bounceScale = 1.0 + (_bounceCtrl.value / 0.3) * 0.5;
          } else if (_bounceCtrl.value < 0.6) {
            bounceScale = 1.5 - ((_bounceCtrl.value - 0.3) / 0.3) * 0.6;
          } else {
            bounceScale = 0.9 + ((_bounceCtrl.value - 0.6) / 0.4) * 0.1;
          }

          final plusT = Curves.easeOutCubic.transform(_plusOneCtrl.value);
          final plusOpacity =
              (1.0 - _plusOneCtrl.value * 0.8).clamp(0.0, 1.0);
          final plusOffset = -40.0 * plusT;

          final glowIntensity = _bounceCtrl.value < 0.5
              ? _bounceCtrl.value * 2
              : 2 - _bounceCtrl.value * 2;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (_sparkleCtrl.isAnimating)
                for (var i = 0; i < 8; i++)
                  Positioned(
                    top: 28 +
                        math.sin((i / 8) * 2 * math.pi) *
                            30 *
                            _sparkleCtrl.value,
                    left: (MediaQuery.sizeOf(context).width - 48) / 2 +
                        math.cos((i / 8) * 2 * math.pi) *
                            35 *
                            _sparkleCtrl.value,
                    child: Opacity(
                      opacity:
                          (1.0 - _sparkleCtrl.value).clamp(0.0, 1.0),
                      child: Container(
                        width: 5 * (1 - _sparkleCtrl.value * 0.5),
                        height: 5 * (1 - _sparkleCtrl.value * 0.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [
                            BoxShadow(
                                color: color.withValues(alpha: 0.6),
                                blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
              Transform.scale(
                scale: _bounceCtrl.isAnimating ? bounceScale : 1.0,
                child: Container(
                  decoration: glowIntensity > 0
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(
                                  alpha: glowIntensity * 0.7),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        )
                      : null,
                  child: icon,
                ),
              ),
              if (_plusOneCtrl.isAnimating)
                Positioned(
                  top: plusOffset,
                  child: Opacity(
                    opacity: plusOpacity,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.fredoka(
                            fontSize: AppTheme.fontH3,
                            fontWeight: FontWeight.w900,
                            color: color,
                            shadows: [
                              Shadow(
                                  color: color.withValues(alpha: 0.8),
                                  blurRadius: 8),
                            ],
                          ),
                        ),
                        if (_isX2) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.goldPale, AppTheme.gold],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(color: AppTheme.gold.withValues(alpha: 0.6), blurRadius: 6),
                              ],
                            ),
                            child: Text(
                              'x2',
                              style: GoogleFonts.fredoka(
                                fontSize: AppTheme.fontBody,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
