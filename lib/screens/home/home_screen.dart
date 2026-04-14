import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/config/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/screens/hub/widgets/daily_challenge_card.dart';


part 'widgets/home_widgets.dart';
part 'widgets/home_painters.dart';
part 'widgets/mode_island.dart';
/// Standalone screen (used by router for /home fallback).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: HomeScreenContent());
  }
}

/// Embeddable content widget used inside MainHubScreen tab.
class HomeScreenContent extends ConsumerStatefulWidget {
  const HomeScreenContent({super.key});

  @override
  ConsumerState<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends ConsumerState<HomeScreenContent>
    with TickerProviderStateMixin {
  late final AnimationController _bgAnim;
  late final AnimationController _confettiCtrl;
  late final List<_HomeConfetti> _confettiPieces;
  bool _pendingCelebration = false;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _confettiPieces = _BestScoreDisplayState.generateConfetti();

    ref.listenManual(newRecordPendingProvider, (previous, next) {
      if (next) {
        ref.read(newRecordPendingProvider.notifier).state = false;
        _pendingCelebration = true;
        _tryCelebrate();
      }
    });
  }

  void _tryCelebrate() {
    if (!_pendingCelebration) return;
    if (!TickerMode.valuesOf(context).enabled) return;
    _pendingCelebration = false;
    _confettiCtrl.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryCelebrate();
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameState = ref.watch(gameStateProvider);

    return Stack(
      children: [
        // Nebula background effects
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _bgAnim,
              builder: (context, _) => CustomPaint(
                painter: _HomeNebulaPainter(_bgAnim.value),
              ),
            ),
          ),
        ),
        // Floating particles
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _bgAnim,
              builder: (context, _) => CustomPaint(
                painter: _HomeParticlesPainter(_bgAnim.value),
              ),
            ),
          ),
        ),
        // Floating transparent shapes (bubbles)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _bgAnim,
              builder: (context, _) => CustomPaint(
                painter: _FloatingShapesPainter(_bgAnim.value),
              ),
            ),
          ),
        ),
        // Main content
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // ── Best Score — floating premium display ──
                  _BestScoreDisplay(
                    label: l10n.bestScore.toUpperCase(),
                    score: gameState.bestScore,
                    confettiCtrl: _confettiCtrl,
                  ),

                  const SizedBox(height: 12),

                  // ── Daily challenges card ──
                  const DailyChallengeCard(),

                  const SizedBox(height: 12),

                  // ── Play button — full width Button3D green ──
                  Button3D.green(
                    expand: true,
                    onPressed: () {
                      // Audio joué SEULEMENT dans game_screen
                      context.push(AppRoutes.game);
                    },
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Transform.translate(
                        offset: const Offset(-14, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _AnimatedRocket(size: 44),
                            const SizedBox(width: 14),
                            Text(l10n.play.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontH2)),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // ── Shop & Leaderboard — same style as level badge chip ──
                  SizedBox(
                    height: 80,
                    child: Row(
                      children: [
                        Expanded(
                          child: _LevelBadgeButton(
                            onPressed: () {
                              // Audio joué SEULEMENT dans game_screen
                              context.go(AppRoutes.shop);
                            },
                            child: Image.asset(
                              'assets/images/shop.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LevelBadgeButton(
                            onPressed: () {
                              // Audio joué SEULEMENT dans game_screen
                              context.go(AppRoutes.leaderboard);
                            },
                            child: Image.asset(
                              'assets/images/podium.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 70), // space for ad banner
                ],
              ),
            ),
          ),
        ),
        // Full-screen confetti rain on new record
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (context, _) {
                if (!_confettiCtrl.isAnimating) return const SizedBox.shrink();
                return CustomPaint(
                  painter: _HomeConfettiPainter(
                    pieces: _confettiPieces,
                    progress: _confettiCtrl.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

