import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/nav_provider.dart';
import 'package:shape_merge/screens/home/widgets/best_score_nudge.dart';
import 'package:shape_merge/screens/home/widgets/daily_challenge_footer.dart';
import 'package:shape_merge/screens/home/widgets/home_play_button.dart';
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _bgAnim;
  late final AnimationController _confettiCtrl;
  late final List<_HomeConfetti> _confettiPieces;
  bool _pendingCelebration = false;
  bool _bgAnimPausedByLifecycle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause the 60s background loop when the app is backgrounded to save battery.
    final shouldPause =
        state == AppLifecycleState.paused || state == AppLifecycleState.inactive;
    if (shouldPause && _bgAnim.isAnimating) {
      _bgAnim.stop();
      _bgAnimPausedByLifecycle = true;
    } else if (!shouldPause && _bgAnimPausedByLifecycle) {
      _bgAnim.repeat();
      _bgAnimPausedByLifecycle = false;
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _bgAnim.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameState = ref.watch(gameStateProvider);

    // Pause the 60s nebula loop when this tab is not visible (other branch
    // selected in the bottom nav). Saves CPU/battery while the user is on
    // Shop / Leaderboard / Profile / Settings.
    const homeBranchIndex = 2;
    ref.listen<int>(currentBranchIndexProvider, (_, next) {
      if (_bgAnimPausedByLifecycle) return; // lifecycle takes precedence
      if (next == homeBranchIndex && !_bgAnim.isAnimating) {
        _bgAnim.repeat();
      } else if (next != homeBranchIndex && _bgAnim.isAnimating) {
        _bgAnim.stop();
      }
    });

    return Stack(
      children: [
        // Nebula background effects
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _bgAnim,
                builder: (context, _) => CustomPaint(
                  painter: _HomeNebulaPainter(_bgAnim.value),
                ),
              ),
            ),
          ),
        ),
        // Floating particles
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _bgAnim,
                builder: (context, _) => CustomPaint(
                  painter: _HomeParticlesPainter(_bgAnim.value),
                ),
              ),
            ),
          ),
        ),
        // Floating transparent shapes (bubbles)
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _bgAnim,
                builder: (context, _) => CustomPaint(
                  painter: _FloatingShapesPainter(_bgAnim.value),
                ),
              ),
            ),
          ),
        ),
        // Main content
        Positioned.fill(
          child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: MediaQuery.of(context).viewPadding.top,
              ),
              child: Column(
                children: [

                  // ── Best Score — floating premium display ──
                  _BestScoreDisplay(
                    label: l10n.bestScore.toUpperCase(),
                    score: gameState.bestScore,
                    confettiCtrl: _confettiCtrl,
                  ),

                  const SizedBox(height: 8),

                  // ── Motivational nudge (Top World / beat player / first record) ──
                  const BestScoreNudge(),

                  const SizedBox(height: 10),

                  // ── Daily challenges card + global progress footer ──
                  const DailyChallengeCard(),
                  const DailyChallengeFooter(),

                  const SizedBox(height: 10),

                  // ── Play button (contextual subtitle + glow when objectives close) ──
                  const HomePlayButton(
                    rocket: _AnimatedRocket(size: 44),
                  ),

                  const SizedBox(height: 24), // space for bottom nav + ad
                ],
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

