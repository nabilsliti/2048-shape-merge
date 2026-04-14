part of '../home_screen.dart';

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
  final AnimationController confettiCtrl;

  const _BestScoreDisplay({required this.label, required this.score, required this.confettiCtrl});

  @override
  ConsumerState<_BestScoreDisplay> createState() => _BestScoreDisplayState();
}

class _BestScoreDisplayState extends ConsumerState<_BestScoreDisplay>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _celebCtrl;
  late final AnimationController _glowCtrl;

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
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // When parent's confettiCtrl fires, also trigger trophy celebration
    widget.confettiCtrl.addStatusListener(_onConfettiStatus);
  }

  void _onConfettiStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      _celebCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.confettiCtrl.removeStatusListener(_onConfettiStatus);
    _pulse.dispose();
    _celebCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  static List<_HomeConfetti> generateConfetti() {
    final rng = math.Random();
    return List.generate(60, (i) => _HomeConfetti(
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
                        'assets/images/trophy.png',
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

