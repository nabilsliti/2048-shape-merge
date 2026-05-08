import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/services/progression_service.dart';
import 'package:shape_merge/core/widgets/joker_choice_dialog.dart';
import 'package:shape_merge/providers/ads_provider.dart';
import 'package:shape_merge/providers/progression_provider.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/iap_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/providers/streak_provider.dart';
import 'package:shape_merge/screens/home/home_screen.dart';

import 'package:shape_merge/screens/hub/widgets/ad_reward_gem_button.dart';
import 'package:shape_merge/screens/hub/widgets/level_up_overlay.dart';
import 'package:shape_merge/screens/hub/widgets/streak_flame_button.dart';
import 'package:shape_merge/screens/hub/widgets/streak_popup.dart';

class MainHubScreen extends ConsumerStatefulWidget {
  const MainHubScreen({super.key});

  @override
  ConsumerState<MainHubScreen> createState() => _MainHubScreenState();
}

class _MainHubScreenState extends ConsumerState<MainHubScreen> {

  @override
  Widget build(BuildContext context) {
    // Initialize IAP early to catch pending purchases
    ref.watch(iapReadyProvider);

    // Preload rewarded ad (same pattern as shop)
    ref.read(adsServiceProvider).loadRewardedAd();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Stack(
        children: [
          // Global Background
          Positioned.fill(child: _buildGradientBackground()),

          // Home Screen Content
          const Positioned.fill(
            child: HomeScreenContent(),
          ),

          // Top HUD
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopHud(),
          ),

          // Level-up overlay — centered, auto-dismisses after 2.5s
          const Positioned.fill(child: LevelUpOverlay()),
        ],
      ),
    );
  }

  static Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.bgTop, AppTheme.bgBot],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.orbPink.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.orbCyan.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHud extends ConsumerWidget {

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final player = ref.watch(playerProvider).valueOrNull;
    final streakResult = ref.watch(streakProvider);

    final localStorage = ref.watch(localStorageProvider).valueOrNull;
    final streakCount = user != null
        ? (player?.currentStreak ?? localStorage?.currentStreak ?? 0)
        : (localStorage?.currentStreak ?? 0);

    // Level: prefer live progressionProvider result (updated immediately after game)
    final progressionResult = ref.watch(progressionProvider);
    final level = progressionResult?.newLevel
        ?? (user != null
            ? (player?.level ?? localStorage?.playerLevel ?? 1)
            : (localStorage?.playerLevel ?? 1));
    final currentXP = progressionResult?.currentXP
        ?? (user != null
            ? (player?.currentXP ?? localStorage?.currentXP ?? 0)
            : (localStorage?.currentXP ?? 0));
    final xpNeeded = ProgressionService.xpForLevel(level);

    final l10n = AppLocalizations.of(context)!;
    final topPad = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(top: topPad + 4, left: 24, right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Level & XP badges ──
          Row(
            children: [
              _HudChip(
                icon: const Icon(RetentionUI.levelIcon, size: 14, color: RetentionUI.levelColor),
                label: l10n.levelShortLabel,
                value: '$level',
              ),
              const Spacer(),
              _AnimatedXpChip(
                currentXP: currentXP,
                xpNeeded: xpNeeded,
              ),
            ],
          ),

          const SizedBox(height: 36),

          // ── Second row: Streak calendar — Spacer — Ad reward ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreakFlameButton(
                streakCount: streakCount,
                dayLabel: l10n.dayLabel,
                hasReward: streakResult != null &&
                    streakResult.reward != null &&
                    !streakResult.rewardClaimed,
                rewardClaimed: streakResult != null &&
                    streakResult.rewardClaimed,
                onTap: streakResult != null
                    ? () => StreakPopup.show(context, streakResult)
                    : null,
              ),
              const Spacer(),
              AdRewardGemButton(
                onTap: () => _watchAdFromHub(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _watchAdFromHub(BuildContext context, WidgetRef ref) async {
    final adsService = ref.read(adsServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    final rewarded = await adsService.showRewardedAd(onRewarded: () {});

    if (!rewarded) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adNotReady, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: AppTheme.redTop,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      adsService.loadRewardedAd();
      return;
    }

    if (context.mounted) {
      final chosen = await JokerChoiceDialog.show(context);
      if (chosen != null) {
        ref.read(gameStateProvider.notifier).addJokers(chosen);
      }
      adsService.loadRewardedAd();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// HUD chip — sits inside the 3D panel bar
// ═══════════════════════════════════════════════════════════════
class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 5),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.fredoka(
                  fontSize: 8,
                  color: AppTheme.goldLabel,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  height: 1,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 3),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Animated XP chip — same visual as _HudChip + bounce, rolling
// counter, and floating "+N XP" label on XP gain.
// ═══════════════════════════════════════════════════════════════
class _AnimatedXpChip extends StatefulWidget {
  const _AnimatedXpChip({required this.currentXP, required this.xpNeeded});

  final int currentXP;
  final int xpNeeded;

  @override
  State<_AnimatedXpChip> createState() => _AnimatedXpChipState();
}

class _AnimatedXpChipState extends State<_AnimatedXpChip>
    with TickerProviderStateMixin {
  late final AnimationController _bounce;
  late final AnimationController _counterRoll;
  late final AnimationController _plusFloat;
  late final Listenable _allAnimations;

  int _displayXP = 0;
  int _prevXP = 0;
  int _gainedXP = 0;
  bool _isRolling = false;

  @override
  void initState() {
    super.initState();
    _displayXP = widget.currentXP;
    _prevXP = widget.currentXP;

    _bounce = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _counterRoll = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _isRolling = false;
          _displayXP = widget.currentXP;
        }
      });
    _plusFloat = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _allAnimations = Listenable.merge([_bounce, _counterRoll, _plusFloat]);
  }

  @override
  void didUpdateWidget(covariant _AnimatedXpChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentXP == oldWidget.currentXP) return;

    _bounce.forward(from: 0);

    if (widget.currentXP > oldWidget.currentXP) {
      _prevXP = oldWidget.currentXP;
      _gainedXP = widget.currentXP - oldWidget.currentXP;
      _isRolling = true;
      _counterRoll.forward(from: 0);
      _plusFloat.forward(from: 0);
    } else {
      _isRolling = false;
      _displayXP = widget.currentXP;
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    _counterRoll.dispose();
    _plusFloat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _allAnimations,
      builder: (context, _) {
        // Bounce: elastic scale 1 → 1.3 → 0.92 → 1
        final double bounceScale;
        if (_bounce.value < 0.3) {
          bounceScale = 1.0 + (_bounce.value / 0.3) * 0.30;
        } else if (_bounce.value < 0.6) {
          bounceScale = 1.30 - ((_bounce.value - 0.3) / 0.3) * 0.38;
        } else {
          bounceScale = 0.92 + ((_bounce.value - 0.6) / 0.4) * 0.08;
        }

        // Rolling counter
        final counterShown = _isRolling
            ? (_prevXP +
                    (widget.currentXP - _prevXP) *
                        Curves.easeInOut.transform(_counterRoll.value))
                .round()
                .clamp(0, widget.xpNeeded)
            : _displayXP;

        // Floating +N XP
        final plusT = Curves.easeOutCubic.transform(_plusFloat.value);
        final plusOpacity = (1.0 - _plusFloat.value * 1.2).clamp(0.0, 1.0);
        final plusDy = 40.0 * plusT;
        final plusScale = _plusFloat.value < 0.15
            ? _plusFloat.value / 0.15 * 1.3
            : 1.3 - (_plusFloat.value - 0.15) * 0.35;

        return SizedBox(
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // ── The chip ──
              Transform.scale(
                scale: _bounce.isAnimating ? bounceScale : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(RetentionUI.xpIcon, size: 14, color: RetentionUI.xpColor),
                      const SizedBox(width: 5),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.xpLabel,
                            style: GoogleFonts.fredoka(
                              fontSize: 8,
                              color: AppTheme.goldLabel,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              height: 1,
                            ),
                          ),
                          Text(
                            '$counterShown/${widget.xpNeeded}',
                            style: GoogleFonts.fredoka(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 3),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Floating "+N XP" ──
              if (_plusFloat.isAnimating && _gainedXP > 0)
                Positioned(
                  bottom: 26 + plusDy,
                  child: Transform.scale(
                    scale: plusScale.clamp(0.5, 1.5),
                    child: Opacity(
                      opacity: plusOpacity,
                      child: Text(
                        AppLocalizations.of(context)!.xpGained(_gainedXP),
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.gold,
                          shadows: [
                            Shadow(
                                color: AppTheme.gold.withValues(alpha: 0.8),
                                blurRadius: 10),
                            const Shadow(color: Colors.black87, blurRadius: 6),
                          ],
                        ),
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
}
