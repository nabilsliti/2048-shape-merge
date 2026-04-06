import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/game_state_provider.dart';

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 90, bottom: 24),
                    child: _FloatingTitle(),
                  ),

                  // ── Best Score — floating premium display ──
                  _BestScoreDisplay(
                    label: l10n.bestScore.toUpperCase(),
                    score: gameState.bestScore,
                  ),

                  const SizedBox(height: 32),

                  // ── Play button — full width Button3D green ──
                  Button3D.green(
                    expand: true,
                    onPressed: () => context.go('/game'),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Transform.translate(
                        offset: const Offset(-14, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const PremiumIcon.rocket(size: 44),
                            const SizedBox(width: 14),
                            Text(l10n.play.toUpperCase(), style: AppTheme.titleStyle(24)),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── Shop & Leaderboard — premium Button3D row ──
                  Row(
                    children: [
                      Expanded(
                        child: Button3D.purple(
                          expand: true,
                          onPressed: () => context.go('/shop'),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: CustomPaint(painter: _JokerBagPainter()),
                                ),
                                const SizedBox(height: 6),
                                Text(l10n.shop.toUpperCase(), style: AppTheme.titleStyle(12)),
                              ],
                            ),
                          ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Button3D.orange(
                          expand: true,
                          onPressed: () => context.go('/leaderboard'),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: CustomPaint(painter: _TrophyPainter()),
                                ),
                                const SizedBox(height: 6),
                                Text(l10n.leaderboard.toUpperCase(), style: AppTheme.titleStyle(12)),
                              ],
                            ),
                          ),
                      ),
                    ],
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
          borderRadius: BorderRadius.circular(18),
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
            Text(widget.label, style: AppTheme.titleStyle(11)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Best Score Display — floating premium trophy + score (no card)
// ═══════════════════════════════════════════════════════════════
class _BestScoreDisplay extends StatefulWidget {
  final String label;
  final int score;

  const _BestScoreDisplay({required this.label, required this.score});

  @override
  State<_BestScoreDisplay> createState() => _BestScoreDisplayState();
}

class _BestScoreDisplayState extends State<_BestScoreDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final p = _pulse.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing trophy icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15 + p * 0.20),
                    blurRadius: 24 + p * 16,
                    spreadRadius: -2 + p * 6,
                  ),
                ],
              ),
              child: CustomPaint(painter: _TrophyPainter()),
            ),
            const SizedBox(height: 8),

            // Label
            Text(
              widget.label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFBBA86E).withValues(alpha: 0.7 + p * 0.3),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 2),

            // Score — big gold gradient numbers
            Text(
              '${widget.score}',
              style: GoogleFonts.fredoka(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFF8DC), Color(0xFFFFD700)],
                  ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                shadows: [
                  Shadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3 + p * 0.2),
                    blurRadius: 12 + p * 8,
                  ),
                  const Shadow(
                    color: Colors.black38,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),

            // Decorative gold line
            Container(
              width: 80 + p * 20,
              height: 2,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.0),
                    const Color(0xFFFFD700).withValues(alpha: 0.5 + p * 0.3),
                    const Color(0xFFFFD700).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Joker Bag Painter — premium hand-drawn shopping bag icon
// ═══════════════════════════════════════════════════════════════
class _JokerBagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow
    final shadowPath = Path()
      ..moveTo(w * 0.15, h * 0.35)
      ..lineTo(w * 0.20, h * 0.92)
      ..quadraticBezierTo(w * 0.22, h, w * 0.32, h)
      ..lineTo(w * 0.68, h)
      ..quadraticBezierTo(w * 0.78, h, w * 0.80, h * 0.92)
      ..lineTo(w * 0.85, h * 0.35)
      ..close();
    canvas.drawPath(shadowPath.shift(const Offset(0, 2)), Paint()..color = Colors.black.withValues(alpha: 0.25));

    // Bag body — purple gradient
    final bag = Path()
      ..moveTo(w * 0.15, h * 0.35)
      ..lineTo(w * 0.20, h * 0.90)
      ..quadraticBezierTo(w * 0.22, h * 0.98, w * 0.32, h * 0.98)
      ..lineTo(w * 0.68, h * 0.98)
      ..quadraticBezierTo(w * 0.78, h * 0.98, w * 0.80, h * 0.90)
      ..lineTo(w * 0.85, h * 0.35)
      ..close();

    canvas.drawPath(bag, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFc56cff), Color(0xFFa541ff), Color(0xFF7b1fa2)],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Bag border
    canvas.drawPath(bag, Paint()..color = const Color(0xFF6a0dad)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Bag flap — top rectangle
    final flap = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.30, w * 0.76, h * 0.12),
      const Radius.circular(4),
    );
    canvas.drawRRect(flap, Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFd98fff), Color(0xFFb560e8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));
    canvas.drawRRect(flap, Paint()..color = const Color(0xFF6a0dad)..style = PaintingStyle.stroke..strokeWidth = 1.2);

    // Handle — arch
    final handle = Path()
      ..moveTo(w * 0.35, h * 0.32)
      ..quadraticBezierTo(w * 0.35, h * 0.08, w * 0.50, h * 0.08)
      ..quadraticBezierTo(w * 0.65, h * 0.08, w * 0.65, h * 0.32);
    canvas.drawPath(handle, Paint()
      ..color = const Color(0xFFe0b0ff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round);
    canvas.drawPath(handle, Paint()
      ..color = const Color(0xFF6a0dad)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round);

    // Star on bag
    _drawStar(canvas, Offset(w * 0.50, h * 0.68), w * 0.14, const Color(0xFFFFD700), const Color(0xFFFF8C00));

    // Shine highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, h * 0.45, w * 0.12, h * 0.20), const Radius.circular(6)),
      Paint()..color = Colors.white.withValues(alpha: 0.20),
    );
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color c1, Color c2) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = (i * math.pi / 5) - math.pi / 2;
      final sr = i.isEven ? r : r * 0.45;
      final px = center.dx + math.cos(a) * sr;
      final py = center.dy + math.sin(a) * sr;
      if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
    }
    path.close();
    canvas.drawPath(path, Paint()
      ..shader = RadialGradient(colors: [c1, c2]).createShader(
        Rect.fromCircle(center: center, radius: r)));
    canvas.drawPath(path, Paint()..color = const Color(0xFF8B6914)..style = PaintingStyle.stroke..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// Trophy Painter — premium hand-drawn trophy icon
// ═══════════════════════════════════════════════════════════════
class _TrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, h * 0.88, w * 0.50, h * 0.08), const Radius.circular(3)),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );

    // Base plate
    final basePlate = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.25, h * 0.84, w * 0.50, h * 0.10),
      const Radius.circular(3),
    );
    canvas.drawRRect(basePlate, Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE082), Color(0xFFDAA520), Color(0xFFB8860B)],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));
    canvas.drawRRect(basePlate, Paint()..color = const Color(0xFF8B6914)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Stem
    final stem = Path()
      ..moveTo(w * 0.42, h * 0.62)
      ..lineTo(w * 0.42, h * 0.84)
      ..lineTo(w * 0.58, h * 0.84)
      ..lineTo(w * 0.58, h * 0.62)
      ..close();
    canvas.drawPath(stem, Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));
    canvas.drawPath(stem, Paint()..color = const Color(0xFF8B6914)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Cup body
    final cup = Path()
      ..moveTo(w * 0.20, h * 0.10)
      ..lineTo(w * 0.25, h * 0.55)
      ..quadraticBezierTo(w * 0.28, h * 0.65, w * 0.42, h * 0.65)
      ..lineTo(w * 0.58, h * 0.65)
      ..quadraticBezierTo(w * 0.72, h * 0.65, w * 0.75, h * 0.55)
      ..lineTo(w * 0.80, h * 0.10)
      ..close();

    // Cup shadow
    canvas.drawPath(cup.shift(const Offset(0, 2)), Paint()..color = Colors.black.withValues(alpha: 0.2));

    // Cup gradient
    canvas.drawPath(cup, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Color(0xFFFFE082), Color(0xFFFFD700), Color(0xFFDAA520), Color(0xFFB8860B)],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));
    canvas.drawPath(cup, Paint()..color = const Color(0xFF8B6914)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Left handle
    final lHandle = Path()
      ..moveTo(w * 0.20, h * 0.18)
      ..quadraticBezierTo(w * 0.04, h * 0.20, w * 0.06, h * 0.35)
      ..quadraticBezierTo(w * 0.08, h * 0.48, w * 0.22, h * 0.45);
    canvas.drawPath(lHandle, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 3.5..strokeCap = StrokeCap.round);
    canvas.drawPath(lHandle, Paint()..color = const Color(0xFF8B6914)..style = PaintingStyle.stroke..strokeWidth = 1.2..strokeCap = StrokeCap.round);

    // Right handle
    final rHandle = Path()
      ..moveTo(w * 0.80, h * 0.18)
      ..quadraticBezierTo(w * 0.96, h * 0.20, w * 0.94, h * 0.35)
      ..quadraticBezierTo(w * 0.92, h * 0.48, w * 0.78, h * 0.45);
    canvas.drawPath(rHandle, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 3.5..strokeCap = StrokeCap.round);
    canvas.drawPath(rHandle, Paint()..color = const Color(0xFF8B6914)..style = PaintingStyle.stroke..strokeWidth = 1.2..strokeCap = StrokeCap.round);

    // Star on cup
    _drawStar(canvas, Offset(w * 0.50, h * 0.35), w * 0.12);

    // Shine highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.16, w * 0.10, h * 0.22), const Radius.circular(5)),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );

    // Rim highlight
    canvas.drawLine(
      Offset(w * 0.24, h * 0.12),
      Offset(w * 0.76, h * 0.12),
      Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.6)..strokeWidth = 1.5..strokeCap = StrokeCap.round,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = (i * math.pi / 5) - math.pi / 2;
      final sr = i.isEven ? r : r * 0.45;
      final px = center.dx + math.cos(a) * sr;
      final py = center.dy + math.sin(a) * sr;
      if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.7));
    canvas.drawPath(path, Paint()..color = const Color(0xFF8B6914).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 0.7);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
                        ? AppTheme.titleStyle(38)
                            .copyWith(color: AppTheme.orangeTop)
                        : AppTheme.titleStyle(38),
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
                    style: AppTheme.titleStyle(48)
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
          const Color(0xFF6a11cb).withValues(alpha: 0.45),
          const Color(0xFF6a11cb).withValues(alpha: 0.0),
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
          const Color(0xFFE040FB).withValues(alpha: 0.35),
          const Color(0xFFE040FB).withValues(alpha: 0.0),
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
          const Color(0xFF2575fc).withValues(alpha: 0.3),
          const Color(0xFF2575fc).withValues(alpha: 0.0),
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
          ..color = const Color(0xFFFFD740).withValues(alpha: alpha * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = const Color(0xFFFFD740).withValues(alpha: alpha * 0.7)
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

  static const _shapes = [
    [0.0, 0.5, 55.0, 1, 1, 1, 0],
    [0.6, 1.3, 45.0, 1, 1, 1, 1],
    [1.3, 2.1, 60.0, 1, 1, 1, 2],
    [1.9, 0.3, 50.0, 1, 1, 1, 3],
    [2.5, 1.8, 58.0, 1, 1, 1, 4],
    [3.1, 0.9, 42.0, 1, 1, 1, 0],
    [3.8, 2.5, 65.0, 1, 1, 1, 3],
    [4.4, 1.1, 48.0, 1, 1, 1, 1],
    [5.0, 2.8, 55.0, 1, 1, 1, 2],
    [5.7, 0.2, 52.0, 1, 1, 1, 4],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 40.0;
    final halfW = (size.width - margin) / 2;
    final halfH = (size.height - margin) / 2;
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (final s in _shapes) {
      final phaseX = s[0];
      final phaseY = s[1];
      final shapeSize = s[2].toDouble();
      final rotSpeed = s[5];
      final shapeType = s[6].toInt();

      final t = progress * math.pi * 2;
      final x = cx + math.sin(t + phaseX) * halfW;
      final y = cy + math.cos(t + phaseY) * halfH;
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
          borderRadius: BorderRadius.circular(16),
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
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                                color: Colors.black38, offset: Offset(2, 2))
                          ])),
                  Text(widget.desc,
                      style: GoogleFonts.nunito(
                          fontSize: 12,
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
