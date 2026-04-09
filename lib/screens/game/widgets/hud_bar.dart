import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

/// Modern flat HUD — 4 elements distributed flexibly inside the card.
class HudBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final capacityRatio = shapeCount / maxShapes;
    final capColor = capacityRatio < 0.6
        ? AppTheme.capGood
        : capacityRatio < 0.85
            ? AppTheme.capWarn
            : AppTheme.capDanger;
    final isNewBest = score > 0 && score >= bestScore;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          // ── Score (hero — gets more space) ────────
          Expanded(
            flex: 3,
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CustomPaint(painter: _StarPainter(glow: isNewBest)),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fmt(score),
                        style: AppTheme.titleStyle(AppTheme.fontH1).copyWith(
                          color: isNewBest ? AppTheme.gold : Colors.white,
                          height: 1.1,
                          shadows: [
                            Shadow(
                              color: AppTheme.gold.withValues(alpha: 0.7),
                              blurRadius: 10,
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
                      const SizedBox(height: 2),
                      Text(
                        isNewBest ? '★ NEW BEST' : 'BEST ${_fmt(bestScore)}',
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
            onPressed: onPause,
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
