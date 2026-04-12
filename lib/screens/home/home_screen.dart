import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/screens/hub/widgets/daily_challenge_card.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _bgAnim.dispose();
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
                  ),

                  const SizedBox(height: 12),

                  // ── Daily challenges card ──
                  const DailyChallengeCard(),

                  const SizedBox(height: 12),

                  // ── Play button — full width Button3D green ──
                  Button3D.green(
                    expand: true,
                    onPressed: () {
                      AudioService.instance.playButtonTap();
                      ref.read(gameStateProvider.notifier).startNewGame();
                      context.go('/game');
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

                  // ── Shop & Leaderboard — premium Button3D row ──
                  SizedBox(
                    height: 80,
                    child: Row(
                      children: [
                        Expanded(
                          child: Button3D.orange(
                            expand: true,
                            onPressed: () {
                              AudioService.instance.playButtonTap();
                              context.go('/shop');
                            },
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(
                                'assets/images/removed_bg/shop.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Button3D.orange(
                            expand: true,
                            onPressed: () {
                              AudioService.instance.playButtonTap();
                              context.go('/leaderboard');
                            },
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(
                                'assets/images/removed_bg/podium.png',
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
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Glass Menu Button — frosted translucent card with custom painted icon
// ═══════════════════════════════════════════════════════════════
class _GlassMenuButton extends StatefulWidget {
  final CustomPainter iconPainter;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _GlassMenuButton({required this.iconPainter, required this.label, required this.accentColor, required this.onTap});

  @override
  State<_GlassMenuButton> createState() => _GlassMenuButtonState();
}

class _GlassMenuButtonState extends State<_GlassMenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        margin: EdgeInsets.only(top: _pressed ? 2 : 0),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _pressed ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: widget.accentColor.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: widget.accentColor.withValues(alpha: 0.1), blurRadius: 12),
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: Offset(0, _pressed ? 1 : 3)),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CustomPaint(painter: widget.iconPainter),
            ),
            const SizedBox(height: 6),
            Text(widget.label, style: AppTheme.titleStyle(AppTheme.fontMini)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Best Score Display — floating premium trophy + score (no card)
// ═══════════════════════════════════════════════════════════════
class _BestScoreDisplay extends ConsumerStatefulWidget {
  final String label;
  final int score;

  const _BestScoreDisplay({required this.label, required this.score});

  @override
  ConsumerState<_BestScoreDisplay> createState() => _BestScoreDisplayState();
}

class _BestScoreDisplayState extends ConsumerState<_BestScoreDisplay>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _celebCtrl;
  late final AnimationController _confettiCtrl;
  late final AnimationController _glowCtrl;
  late final List<_HomeConfetti> _confettiPieces;
  bool _pendingCelebration = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _celebCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _confettiPieces = _generateConfetti();

    // Listen to newRecordPending — fires even when branch is inactive.
    // Store flag, trigger animation only when branch becomes visible.
    ref.listenManual(newRecordPendingProvider, (previous, next) {
      if (next) {
        ref.read(newRecordPendingProvider.notifier).state = false;
        _pendingCelebration = true;
        _tryCelebrate();
      }
    });
  }

  /// Start celebration only if tickers are active (branch is visible).
  /// Called from the listener and from didChangeDependencies (which fires
  /// when the IndexedStack re-enables TickerMode for this branch).
  void _tryCelebrate() {
    if (!_pendingCelebration) return;
    // TickerMode is false when this branch is behind another
    // in the StatefulShellRoute.indexedStack.
    if (!TickerMode.valuesOf(context).enabled) return;
    _pendingCelebration = false;
    _celebCtrl.forward(from: 0);
    _confettiCtrl.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When switching back to the Home branch, TickerMode becomes true
    // and didChangeDependencies fires. Trigger pending celebration now.
    _tryCelebrate();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _celebCtrl.dispose();
    _confettiCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  static List<_HomeConfetti> _generateConfetti() {
    final rng = math.Random();
    return List.generate(28, (i) => _HomeConfetti(
      x: rng.nextDouble(),
      speed: 0.4 + rng.nextDouble() * 0.8,
      drift: (rng.nextDouble() - 0.5) * 0.5,
      rotation: rng.nextDouble() * math.pi * 2,
      rotSpeed: (rng.nextDouble() - 0.5) * 8,
      width: 4 + rng.nextDouble() * 5,
      height: 6 + rng.nextDouble() * 8,
      color: [
        const Color(0xFFFF4444),
        const Color(0xFF44AAFF),
        const Color(0xFFFFD700),
        const Color(0xFF44FF88),
        const Color(0xFFFF44FF),
        const Color(0xFFFF8800),
        const Color(0xFF8844FF),
      ][i % 7],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Confetti rain — always in the tree, renders nothing when idle
        AnimatedBuilder(
          animation: _confettiCtrl,
          builder: (context, _) {
            if (!_confettiCtrl.isAnimating) return const SizedBox.shrink();
            return Positioned(
              left: -40,
              top: -30,
              right: -40,
              bottom: -30,
              child: CustomPaint(
                painter: _HomeConfettiPainter(
                  pieces: _confettiPieces,
                  progress: _confettiCtrl.value,
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: Listenable.merge([_pulse, _celebCtrl]),
          builder: (context, _) {
            final p = _pulse.value;

            // Trophy bounce
            final double trophyScale;
            final double glowExtra;
            if (_celebCtrl.isAnimating) {
              if (_celebCtrl.value < 0.12) {
                trophyScale = 1.0 + (_celebCtrl.value / 0.12) * 0.5;
                glowExtra = _celebCtrl.value / 0.12;
              } else if (_celebCtrl.value < 0.25) {
                trophyScale = 1.5 - ((_celebCtrl.value - 0.12) / 0.13) * 0.4;
                glowExtra = 1.0 - ((_celebCtrl.value - 0.12) / 0.13) * 0.5;
              } else if (_celebCtrl.value < 0.4) {
                final t = (_celebCtrl.value - 0.25) / 0.15;
                trophyScale = 1.1 + math.sin(t * math.pi * 2) * 0.06;
                glowExtra = 0.5 * (1 - t);
              } else {
                trophyScale = 1.0;
                glowExtra = 0.0;
              }
            } else {
              trophyScale = 1.0;
              glowExtra = 0.0;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing trophy icon with celebration bounce
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Transform.scale(
                  scale: trophyScale,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gold.withValues(
                            alpha: 0.15 + p * 0.20 + glowExtra * 0.4,
                          ),
                            blurRadius: 24 + p * 16 + glowExtra * 20,
                            spreadRadius: -2 + p * 6 + glowExtra * 8,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/removed_bg/trophy.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                Text(
                  widget.label,
                  style: GoogleFonts.nunito(
                    fontSize: AppTheme.fontMini,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.goldDim.withValues(alpha: 0.7 + p * 0.3),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 2),

                // Score with shimmer sweep during celebration + persistent glow
                Builder(builder: (_) {
                  // Shimmer during celebration burst
                  final shimmerActive = _celebCtrl.isAnimating &&
                      _celebCtrl.value > 0.05 && _celebCtrl.value < 0.55;
                  final shimmerT = shimmerActive
                      ? ((_celebCtrl.value - 0.05) / 0.5).clamp(0.0, 1.0)
                      : 0.0;
                  final glowAlpha = glowExtra > 0 ? 0.7 : 0.0;
                  final glowBlur = glowExtra > 0 ? 16.0 : 0.0;

                  final scoreWidget = _scoreText(p, glowAlpha, glowBlur);

                  if (shimmerActive) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        final shimmerX = bounds.width * (shimmerT * 2 - 0.3);
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: const [
                            Colors.white,
                            Color(0xFFFFF8E0),
                            Colors.white,
                          ],
                          stops: [
                            (shimmerX / bounds.width - 0.15).clamp(0.0, 1.0),
                            (shimmerX / bounds.width).clamp(0.0, 1.0),
                            (shimmerX / bounds.width + 0.15).clamp(0.0, 1.0),
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.modulate,
                      child: scoreWidget,
                    );
                  }
                  return scoreWidget;
                }),

                // Decorative gold line
                Container(
                  width: 80 + p * 20,
                  height: 2,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.gold.withValues(alpha: 0.0),
                        AppTheme.gold.withValues(alpha: 0.5 + p * 0.3),
                        AppTheme.gold.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _scoreText(double p, double glowAlpha, double glowBlur) {
    final hasGlow = glowAlpha > 0;
    return Text(
      '${widget.score}',
      style: GoogleFonts.fredoka(
        fontSize: AppTheme.fontDisplay,
        fontWeight: FontWeight.w900,
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: [AppTheme.gold, AppTheme.goldShimmer, AppTheme.gold],
          ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
        shadows: [
          Shadow(
            color: AppTheme.gold.withValues(alpha: hasGlow ? glowAlpha : 0.3 + p * 0.2),
            blurRadius: hasGlow ? glowBlur : 12 + p * 8,
          ),
          const Shadow(
            color: Colors.black38,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

// ── Home confetti data + painter ──
class _HomeConfetti {
  final double x, speed, drift, rotation, rotSpeed, width, height;
  final Color color;
  const _HomeConfetti({
    required this.x, required this.speed, required this.drift,
    required this.rotation, required this.rotSpeed, required this.width,
    required this.height, required this.color,
  });
}

class _HomeConfettiPainter extends CustomPainter {
  final List<_HomeConfetti> pieces;
  final double progress;
  _HomeConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in pieces) {
      final t = (progress * c.speed).clamp(0.0, 1.0);
      final x = size.width * c.x + c.drift * size.width * t;
      final y = -10 + size.height * 1.3 * t;
      final rot = c.rotation + c.rotSpeed * t;
      final opacity = t < 0.8 ? 1.0 : (1.0 - (t - 0.8) / 0.2);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: c.width, height: c.height),
        Paint()..color = c.color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_HomeConfettiPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
// Floating Title — La Ola wave animation (each letter rises in sequence)
// ═══════════════════════════════════════════════════════════════
class _FloatingTitle extends StatefulWidget {
  const _FloatingTitle();

  @override
  State<_FloatingTitle> createState() => _FloatingTitleState();
}

class _FloatingTitleState extends State<_FloatingTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _line1 = 'SHAPE MERGE';
  static const _line2 = '2048';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line 1: "SHAPE MERGE"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_line1.length, (i) {
                final phase = _ctrl.value * 2 * math.pi - (i * 0.55);
                final dy = math.sin(phase).clamp(0.0, 1.0) * -12;
                final isMerge = i >= 6; // "MERGE" starts at index 6
                final letter = _line1[i];
                if (letter == ' ') return const SizedBox(width: 10);
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Text(
                    letter,
                    style: isMerge
                        ? AppTheme.titleStyle(AppTheme.fontXL)
                            .copyWith(color: AppTheme.orangeTop)
                        : AppTheme.titleStyle(AppTheme.fontXL),
                  ),
                );
              }),
            ),
            // Line 2: "2048"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_line2.length, (i) {
                final phase = _ctrl.value * 2 * math.pi - ((i + _line1.length) * 0.55);
                final dy = math.sin(phase).clamp(0.0, 1.0) * -12;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Text(
                    _line2[i],
                    style: AppTheme.titleStyle(AppTheme.fontXXL)
                        .copyWith(color: AppTheme.orangeTop),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Home Nebula — floating colored clouds for depth
// ═══════════════════════════════════════════════════════════════
class _HomeNebulaPainter extends CustomPainter {
  final double progress;
  _HomeNebulaPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;

    // Purple nebula top-left
    final c1 = Offset(
      size.width * (0.15 + math.sin(t) * 0.08),
      size.height * (0.2 + math.cos(t * 0.7) * 0.05),
    );
    canvas.drawCircle(
      c1,
      size.width * 0.4,
      Paint()
        ..shader = RadialGradient(colors: [
          AppTheme.bgTop.withValues(alpha: 0.45),
          AppTheme.bgTop.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: c1, radius: size.width * 0.4)),
    );

    // Pink nebula right
    final c2 = Offset(
      size.width * (0.8 + math.cos(t) * 0.06),
      size.height * (0.45 + math.sin(t * 0.6) * 0.08),
    );
    canvas.drawCircle(
      c2,
      size.width * 0.35,
      Paint()
        ..shader = RadialGradient(colors: [
          AppTheme.nebulaPink.withValues(alpha: 0.35),
          AppTheme.nebulaPink.withValues(alpha: 0.0),
        ]).createShader(
            Rect.fromCircle(center: c2, radius: size.width * 0.35)),
    );

    // Blue nebula bottom
    final c3 = Offset(
      size.width * 0.4,
      size.height * (0.75 + math.sin(t + 1.5) * 0.06),
    );
    canvas.drawCircle(
      c3,
      size.width * 0.32,
      Paint()
        ..shader = RadialGradient(colors: [
          AppTheme.bgBot.withValues(alpha: 0.3),
          AppTheme.bgBot.withValues(alpha: 0.0),
        ]).createShader(
            Rect.fromCircle(center: c3, radius: size.width * 0.32)),
    );
  }

  @override
  bool shouldRepaint(_HomeNebulaPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════
// Home Particles — floating golden sparkles
// ═══════════════════════════════════════════════════════════════
class _HomeParticlesPainter extends CustomPainter {
  final double progress;
  _HomeParticlesPainter(this.progress);

  static const _seeds = [
    [0.08, 0.15, 2.5, 1.0],
    [0.92, 0.25, 2.0, 1.3],
    [0.22, 0.55, 2.8, 0.8],
    [0.78, 0.70, 2.2, 1.1],
    [0.45, 0.85, 2.5, 0.9],
    [0.65, 0.12, 1.8, 1.4],
    [0.35, 0.40, 2.3, 1.2],
    [0.88, 0.50, 2.0, 0.7],
    [0.15, 0.75, 2.6, 1.0],
    [0.55, 0.30, 2.1, 1.1],
    [0.72, 0.90, 1.9, 0.8],
    [0.40, 0.60, 2.4, 1.3],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _seeds) {
      final x = s[0] * size.width;
      final baseY = s[1] * size.height;
      final radius = s[2];
      final speed = s[3];
      final t = (progress * speed + s[0]) % 1.0;
      final y = baseY - t * 30 + math.sin(t * math.pi * 2) * 8;
      final alpha = (math.sin(t * math.pi) * 0.6).clamp(0.0, 1.0);

      // Glow dot
      canvas.drawCircle(
        Offset(x, y),
        radius * 1.5,
        Paint()
          ..color = AppTheme.goldLight.withValues(alpha: alpha * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = AppTheme.goldLight.withValues(alpha: alpha * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      // Sharp center
      canvas.drawCircle(
        Offset(x, y),
        radius * 0.4,
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_HomeParticlesPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
// Floating Shapes — transparent geometric shapes drifting like bubbles
// ═══════════════════════════════════════════════════════════════
class _FloatingShapesPainter extends CustomPainter {
  final double progress;
  _FloatingShapesPainter(this.progress);

  // [phaseX, phaseY, size, speedX, speedY, rotSpeed, shapeType, ampX, ampY]
  static const _shapes = [
    [0.0, 0.5, 55.0, 1.0, 0.7, 1.0, 0, 0.9, 0.8],
    [0.6, 1.3, 45.0, 0.6, 1.2, 1.0, 1, 0.7, 0.9],
    [1.3, 2.1, 60.0, 1.3, 0.5, 1.0, 2, 0.8, 0.6],
    [1.9, 0.3, 50.0, 0.8, 1.0, 1.0, 3, 0.6, 1.0],
    [2.5, 1.8, 58.0, 1.1, 0.9, 1.0, 4, 1.0, 0.5],
    [3.1, 0.9, 42.0, 0.5, 1.4, 1.0, 0, 0.5, 0.9],
    [3.8, 2.5, 65.0, 1.0, 0.6, 1.0, 3, 0.9, 0.7],
    [4.4, 1.1, 48.0, 0.7, 1.1, 1.0, 1, 0.6, 1.0],
    [5.0, 2.8, 55.0, 1.2, 0.4, 1.0, 2, 1.0, 0.8],
    [5.7, 0.2, 52.0, 0.4, 1.3, 1.0, 4, 0.8, 0.6],
    [0.3, 1.7, 38.0, 1.4, 0.8, 0.7, 2, 0.7, 0.5],
    [0.9, 2.6, 44.0, 0.9, 1.5, 1.3, 0, 0.5, 0.8],
    [1.6, 0.8, 35.0, 0.3, 0.6, 0.5, 4, 0.9, 1.0],
    [2.2, 2.3, 50.0, 1.5, 1.0, 0.9, 1, 0.6, 0.7],
    [2.8, 0.6, 40.0, 0.7, 0.3, 1.1, 3, 1.0, 0.9],
    [3.4, 1.5, 32.0, 1.0, 1.3, 0.8, 0, 0.8, 0.4],
    [4.0, 0.1, 46.0, 0.5, 0.9, 1.4, 2, 0.4, 1.0],
    [4.7, 2.0, 36.0, 1.3, 0.5, 0.6, 4, 0.7, 0.6],
    [5.3, 1.4, 42.0, 0.8, 1.1, 1.2, 1, 0.9, 0.8],
    [5.9, 2.9, 30.0, 0.6, 0.7, 0.4, 3, 0.5, 0.9],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 40.0;
    final halfW = (size.width - margin) / 2;
    final halfH = (size.height - margin) / 2;
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (final s in _shapes) {
      final phaseX = s[0].toDouble();
      final phaseY = s[1].toDouble();
      final shapeSize = s[2].toDouble();
      final speedX = s[3].toDouble();
      final speedY = s[4].toDouble();
      final rotSpeed = s[5].toDouble();
      final shapeType = s[6].toInt();
      final ampX = s[7].toDouble();
      final ampY = s[8].toDouble();

      final t = progress * math.pi * 2;
      final x = cx + math.sin(t * speedX + phaseX) * halfW * ampX;
      final y = cy + math.cos(t * speedY + phaseY) * halfH * ampY;
      final rot = t * rotSpeed;

      final alpha = (0.15 + math.sin(t + phaseX) * 0.1).clamp(0.05, 0.25);
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final fillPaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);

      final r = shapeSize / 2;
      switch (shapeType) {
        case 0: // circle
          canvas.drawCircle(Offset.zero, r, fillPaint);
          canvas.drawCircle(Offset.zero, r, borderPaint);
        case 1: // square
          final rect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: r * 1.8, height: r * 1.8),
            const Radius.circular(6),
          );
          canvas.drawRRect(rect, fillPaint);
          canvas.drawRRect(rect, borderPaint);
        case 2: // triangle
          final path = Path();
          for (var i = 0; i < 3; i++) {
            final a = (i * math.pi * 2 / 3) - math.pi / 2;
            final px = math.cos(a) * r;
            final py = math.sin(a) * r;
            if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
          }
          path.close();
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, borderPaint);
        case 3: // star
          final path = Path();
          for (var i = 0; i < 10; i++) {
            final a = (i * math.pi / 5) - math.pi / 2;
            final sr = i.isEven ? r : r * 0.5;
            final px = math.cos(a) * sr;
            final py = math.sin(a) * sr;
            if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
          }
          path.close();
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, borderPaint);
        case 4: // hexagon
          final path = Path();
          for (var i = 0; i < 6; i++) {
            final a = (i * math.pi / 3) - math.pi / 2;
            final px = math.cos(a) * r;
            final py = math.sin(a) * r;
            if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
          }
          path.close();
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, borderPaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FloatingShapesPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
// Icon shape types for mode buttons
// ═══════════════════════════════════════════════════════════════
enum _IconShape { circle, triangle, square, hexagon }

// ═══════════════════════════════════════════════════════════════
// Mode Island — shape-rush style game mode card with press effect
// ═══════════════════════════════════════════════════════════════
class _ModeIsland extends StatefulWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color topBg;
  final Color botBg;
  final Color iconColor;
  final _IconShape iconShape;
  final VoidCallback onTap;

  const _ModeIsland({
    required this.title,
    required this.desc,
    required this.icon,
    required this.topBg,
    required this.botBg,
    required this.iconColor,
    required this.iconShape,
    required this.onTap,
  });

  @override
  State<_ModeIsland> createState() => _ModeIslandState();
}

class _ModeIslandState extends State<_ModeIsland> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(top: _isPressed ? 4 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: widget.topBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: widget.botBg.withOpacity(0.5),
                offset: Offset(0, _isPressed ? 1 : 3),
                blurRadius: 0),
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: Offset(0, _isPressed ? 2 : 4),
                blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CustomPaint(
                painter: _IconShapePainter(widget.iconShape),
                child: Center(
                  child: Icon(widget.icon,
                      size: 28,
                      color: widget.iconColor,
                      shadows: const [
                        Shadow(
                            color: Colors.black38,
                            offset: Offset(0, 4),
                            blurRadius: 6)
                      ]),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: GoogleFonts.nunito(
                          fontSize: AppTheme.fontH3,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                                color: Colors.black38, offset: Offset(2, 2))
                          ])),
                  Text(widget.desc,
                      style: GoogleFonts.nunito(
                          fontSize: AppTheme.fontTiny,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Painter for geometric icon borders
// ═══════════════════════════════════════════════════════════════
class _IconShapePainter extends CustomPainter {
  final _IconShape shape;
  _IconShapePainter(this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    switch (shape) {
      case _IconShape.circle:
        canvas.drawCircle(Offset(cx, cy), r, fillPaint);
        canvas.drawCircle(Offset(cx, cy), r, borderPaint);

      case _IconShape.triangle:
        final tr = r * 1.25;
        final tyOff = cy + 2;
        final path = Path();
        for (var i = 0; i < 3; i++) {
          final a = (i * math.pi * 2 / 3) - math.pi / 2;
          final px = cx + math.cos(a) * tr;
          final py = tyOff + math.sin(a) * tr;
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);

      case _IconShape.square:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, cy), width: r * 1.8, height: r * 1.8),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, fillPaint);
        canvas.drawRRect(rect, borderPaint);

      case _IconShape.hexagon:
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final a = (i * math.pi / 3) - math.pi / 2;
          final px = cx + math.cos(a) * r;
          final py = cy + math.sin(a) * r;
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(_IconShapePainter old) => old.shape != shape;
}

// ── Animated rocket with subtle hover + tilt ────────────────────
class _AnimatedRocket extends StatefulWidget {
  const _AnimatedRocket({required this.size});
  final double size;

  @override
  State<_AnimatedRocket> createState() => _AnimatedRocketState();
}

class _AnimatedRocketState extends State<_AnimatedRocket>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        // Hover: bottom (+5) to top (-5)
        final dy = 5.0 - t * 10.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: PremiumIcon.rocket(size: widget.size),
    );
  }
}
