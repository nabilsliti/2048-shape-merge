import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';

/// Modern flat HUD — 4 elements distributed flexibly inside the card.
class HudBar extends StatefulWidget {
  final int score;
  final int bestScore;
  final int shapeCount;
  final int mergeCount;
  final VoidCallback? onPause;

  const HudBar({
    super.key,
    required this.score,
    required this.bestScore,
    required this.shapeCount,
    required this.mergeCount,
    this.onPause,
  });

  @override
  State<HudBar> createState() => _HudBarState();
}

class _HudBarState extends State<HudBar> with TickerProviderStateMixin {
  late final AnimationController _celebCtrl;
  late final AnimationController _confettiCtrl;
  late final AnimationController _glowCtrl;
  late final List<_Confetti> _confettiPieces;
  bool _celebrationPlayed = false;
  /// The bestScore captured at the start of each game.
  /// This is the threshold the player must beat.
  int _recordAtGameStart = 0;

  @override
  void initState() {
    super.initState();
    _celebCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _confettiPieces = _generateConfetti();
    // Capture initial best score when HUD is first created
    _recordAtGameStart = widget.bestScore;
  }

  @override
  void didUpdateWidget(covariant HudBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When a new game starts (score drops to 0), snapshot the bestScore as
    // the threshold for this game and reset the celebration flag.
    if (widget.score == 0 && oldWidget.score > 0) {
      _celebrationPlayed = false;
      _recordAtGameStart = widget.bestScore;
      _glowCtrl.reset();
    }
    // Play celebration exactly once per game when STRICTLY beating the record
    final isNewBest = widget.score > 0 && widget.score > _recordAtGameStart;
    if (isNewBest && !_celebrationPlayed) {
      _celebrationPlayed = true;
      _celebCtrl.forward(from: 0);
      _confettiCtrl.forward(from: 0);
      _glowCtrl.repeat(reverse: true);
      AudioService.instance.playNewRecord();
    }
  }

  @override
  void dispose() {
    _celebCtrl.dispose();
    _confettiCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  static List<_Confetti> _generateConfetti() {
    final rng = Random();
    return List.generate(24, (i) => _Confetti(
      x: rng.nextDouble(),
      speed: 0.5 + rng.nextDouble() * 0.8,
      drift: (rng.nextDouble() - 0.5) * 0.4,
      rotation: rng.nextDouble() * pi * 2,
      rotSpeed: (rng.nextDouble() - 0.5) * 8,
      width: 3 + rng.nextDouble() * 4,
      height: 5 + rng.nextDouble() * 6,
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
    final score = widget.score;
    final bestScore = widget.bestScore;
    final shapeCount = widget.shapeCount;
    final mergeCount = widget.mergeCount;
    final capacityRatio = shapeCount / maxShapes;
    final capColor = capacityRatio < 0.6
        ? AppTheme.capGood
        : capacityRatio < 0.85
            ? AppTheme.capWarn
            : AppTheme.capDanger;
    final isNewBest = score > 0 && score > _recordAtGameStart;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          // ── Score (hero — gets more space) ────────
          Expanded(
            flex: 3,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Confetti rain — overflows above/below the score area
                AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (context, _) {
                    if (!_confettiCtrl.isAnimating) return const SizedBox.shrink();
                    return Positioned(
                      left: -10,
                      top: -20,
                      right: -10,
                      bottom: -20,
                      child: CustomPaint(
                        painter: _ConfettiPainter(
                          pieces: _confettiPieces,
                          progress: _confettiCtrl.value,
                        ),
                      ),
                    );
                  },
                ),
                Row(
                    children: [
                      // Star with premium bounce + golden glow pulse
                      AnimatedBuilder(
                        animation: _celebCtrl,
                        builder: (context, child) {
                          final double s;
                          final double glowExtra;
                          if (_celebCtrl.isAnimating) {
                            if (_celebCtrl.value < 0.12) {
                              s = 1.0 + (_celebCtrl.value / 0.12) * 0.6;
                              glowExtra = _celebCtrl.value / 0.12;
                            } else if (_celebCtrl.value < 0.25) {
                              s = 1.6 - ((_celebCtrl.value - 0.12) / 0.13) * 0.5;
                              glowExtra = 1.0 - ((_celebCtrl.value - 0.12) / 0.13) * 0.6;
                            } else if (_celebCtrl.value < 0.4) {
                              final t = (_celebCtrl.value - 0.25) / 0.15;
                              s = 1.1 + sin(t * pi * 2) * 0.08;
                              glowExtra = 0.4 * (1 - t);
                            } else {
                              s = 1.0;
                              glowExtra = 0.0;
                            }
                          } else {
                            s = 1.0;
                            glowExtra = 0.0;
                          }
                          return Transform.scale(
                            scale: s,
                            child: Container(
                              decoration: glowExtra > 0
                                  ? BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.gold.withValues(alpha: glowExtra * 0.8),
                                          blurRadius: 18,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    )
                                  : null,
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CustomPaint(painter: _StarPainter(glow: isNewBest)),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Score text with premium pulse + shimmer + glow
                            AnimatedBuilder(
                              animation: Listenable.merge([_celebCtrl, _glowCtrl]),
                              builder: (context, _) {
                                final double s;
                                if (_celebCtrl.isAnimating && _celebCtrl.value < 0.4) {
                                  final t = _celebCtrl.value / 0.4;
                                  s = 1.0 + sin(t * pi) * 0.18;
                                } else {
                                  s = 1.0;
                                }
                                // Shimmer sweep — spread across more of the animation
                                final shimmerActive = _celebCtrl.isAnimating &&
                                    _celebCtrl.value > 0.05 && _celebCtrl.value < 0.55;
                                final shimmerT = shimmerActive
                                    ? ((_celebCtrl.value - 0.05) / 0.5).clamp(0.0, 1.0)
                                    : 0.0;
                                // Persistent golden glow pulse when holding record
                                final glowAlpha = isNewBest && _glowCtrl.isAnimating
                                    ? 0.4 + _glowCtrl.value * 0.6
                                    : (isNewBest ? 0.7 : 0.0);
                                final glowBlur = isNewBest
                                    ? 12.0 + (_glowCtrl.isAnimating ? _glowCtrl.value * 10 : 0.0)
                                    : 0.0;

                                return Transform.scale(
                                  scale: s,
                                  alignment: Alignment.centerLeft,
                                  child: ShaderMask(
                                    shaderCallback: (bounds) {
                                      if (!shimmerActive) {
                                        return const LinearGradient(
                                          colors: [Colors.white, Colors.white],
                                        ).createShader(bounds);
                                      }
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
                                    child: Text(
                                      _fmt(score),
                                      style: AppTheme.titleStyle(AppTheme.fontH1).copyWith(
                                        color: isNewBest ? AppTheme.gold : Colors.white,
                                        height: 1.1,
                                        shadows: [
                                          Shadow(
                                            color: AppTheme.gold.withValues(alpha: isNewBest ? glowAlpha : 0.7),
                                            blurRadius: isNewBest ? glowBlur : 10,
                                          ),
                                          const Shadow(
                                            color: Colors.black54,
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isNewBest ? AppLocalizations.of(context)!.hudNewBest : AppLocalizations.of(context)!.hudBest(_fmt(bestScore)),
                              style: AppTheme.titleStyle(AppTheme.fontPico).copyWith(
                                color: isNewBest
                                    ? AppTheme.goldLight
                                    : AppTheme.goldLabel,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ),

          _divider(),

          // ── Capacity ──────────────────────────────
          Expanded(
            flex: 2,
            child: _StatColumn(
              icon: SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(
                  painter: _RingPainter(ratio: capacityRatio, color: capColor),
                ),
              ),
              value: '$shapeCount',
              label: '/$maxShapes',
              color: capColor,
              valueColor: shapeCount >= 25 ? AppTheme.capDanger : null,
            ),
          ),

          _divider(),

          // ── Merges ────────────────────────────────
          Expanded(
            flex: 2,
            child: _StatColumn(
              icon: SizedBox(
                width: 18,
                height: 18,
                child: CustomPaint(painter: _BoltPainter()),
              ),
              value: '$mergeCount',
              color: AppTheme.statMerge,
            ),
          ),

          _divider(),

          // ── Pause button ──────────────────────────
          Button3D.red(
            padding: const EdgeInsets.all(8),
            borderRadius: 10,
            onPressed: () {
              AudioService.instance.playButtonTap();
              widget.onPause?.call();
            },
            child: const Icon(Icons.pause, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  static Widget _divider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.white.withValues(alpha: 0.08),
      );

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─── Stat column: icon on top, value below ──────────────────
class _StatColumn extends StatelessWidget {
  final Widget icon;
  final String value;
  final String? label;
  final Color color;
  final Color? valueColor;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.color,
    this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: value,
              style: AppTheme.titleStyle(AppTheme.fontBody).copyWith(
                color: valueColor ?? Colors.white,
                height: 1.1,
                shadows: [
                  Shadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
                ],
              ),
            ),
            if (label != null)
              TextSpan(
                text: label,
                style: AppTheme.titleStyle(AppTheme.fontMini).copyWith(
                  color: AppTheme.goldLabel,
                ),
              ),
          ]),
        ),
      ],
    );
  }
}

// ─── Star painter — golden 5-point star ─────────────────────
class _StarPainter extends CustomPainter {
  final bool glow;
  _StarPainter({this.glow = false});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.46;
    final innerR = outerR * 0.42;

    final path = _starPath(cx, cy, outerR, innerR, 5);

    if (glow) {
      canvas.drawPath(path, Paint()
        ..color = AppTheme.gold.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    canvas.drawPath(path, Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx, cy - outerR),
        Offset(cx, cy + outerR),
        [AppTheme.goldLight, AppTheme.goldAntique],
      ));

    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = AppTheme.goldPale.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.glow != glow;
}

// ─── Ring painter — capacity arc gauge ──────────────────────
class _RingPainter extends CustomPainter {
  final double ratio;
  final Color color;
  _RingPainter({required this.ratio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;
    final sw = size.width * 0.14;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Track
    canvas.drawArc(rect, -pi / 2, 2 * pi, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.06));

    // Arc
    canvas.drawArc(rect, -pi / 2, 2 * pi * ratio.clamp(0.0, 1.0), false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..color = color);

    // 3x3 grid dots in center
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    final dotR = r * 0.12;
    final gap = r * 0.35;
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        canvas.drawCircle(
          Offset(cx + dx * gap, cy + dy * gap),
          dotR,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.ratio != ratio || old.color != color;
}

// ─── Bolt painter — merge lightning icon ────────────────────
class _BoltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bolt = Path()
      ..moveTo(w * 0.55, 0)
      ..lineTo(w * 0.20, h * 0.50)
      ..lineTo(w * 0.45, h * 0.48)
      ..lineTo(w * 0.35, h)
      ..lineTo(w * 0.80, h * 0.42)
      ..lineTo(w * 0.52, h * 0.44)
      ..close();

    canvas.drawPath(bolt, Paint()
      ..color = AppTheme.statMerge.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    canvas.drawPath(bolt, Paint()
      ..shader = ui.Gradient.linear(
        Offset(w * 0.5, 0),
        Offset(w * 0.5, h),
        [AppTheme.purpleBorder, AppTheme.statMerge2],
      ));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Helper ─────────────────────────────────────────────────
Path _starPath(double cx, double cy, double outer, double inner, int points) {
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final angle = (i * pi / points) - pi / 2;
    final r = i.isEven ? outer : inner;
    final px = cx + cos(angle) * r;
    final py = cy + sin(angle) * r;
    if (i == 0) {
      path.moveTo(px, py);
    } else {
      path.lineTo(px, py);
    }
  }
  path.close();
  return path;
}

// ─── Confetti data model ────────────────────────────────────
class _Confetti {
  final double x;
  final double speed;
  final double drift;
  final double rotation;
  final double rotSpeed;
  final double width;
  final double height;
  final Color color;

  const _Confetti({
    required this.x,
    required this.speed,
    required this.drift,
    required this.rotation,
    required this.rotSpeed,
    required this.width,
    required this.height,
    required this.color,
  });
}

// ─── Confetti painter — multicolor falling ribbons ──────────
class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> pieces;
  final double progress;

  _ConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in pieces) {
      // Stagger start: each piece starts at a slightly different time
      final delay = c.x * 0.2;
      final localP = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (localP <= 0) continue;

      final opacity = localP < 0.8 ? 1.0 : (1 - (localP - 0.8) / 0.2);
      final px = c.x * size.width + sin(localP * pi * 2) * c.drift * size.width;
      final py = -5 + localP * (size.height + 10) * c.speed;
      final rot = c.rotation + localP * c.rotSpeed;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);

      // Draw a small ribbon/rectangle
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: c.width,
        height: c.height * (0.5 + 0.5 * cos(localP * pi * 3).abs()),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = c.color.withValues(alpha: opacity.clamp(0.0, 1.0))
          ..style = PaintingStyle.fill,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}
