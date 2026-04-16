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
import 'package:shape_merge/screens/hub/widgets/animated_xp_badge.dart';
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

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 12,
        right: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left column: Level + Streak ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RetentionUI.levelBadge(level: level, levelShortLabel: l10n.levelShortLabel),
              const SizedBox(height: 50),
              StreakFlameButton(
                streakCount: streakCount,
                dayLabel: l10n.dayLabel,
                hasReward: streakResult != null &&
                    streakResult.reward != null &&
                    !streakResult.rewardClaimed,
                onTap: streakResult != null
                    ? () => StreakPopup.show(context, streakResult)
                    : null,
              ),
            ],
          ),

          const Spacer(),

          // ── Right column: XP + Ad reward ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedXpBadge(currentXP: currentXP, xpNeeded: xpNeeded),
              const SizedBox(height: 50),
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

