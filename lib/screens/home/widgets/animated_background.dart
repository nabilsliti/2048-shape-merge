import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

/// Deep space background with stars, nebula and perspective grid.
/// Reused across splash, home, game and overlays.
class SpaceBackground extends StatelessWidget {
  const SpaceBackground({this.darken = 0.0, this.lite = false, super.key});

  final double darken;
  final bool lite;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Deep space gradient
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.2,
              colors: [
                AppTheme.spaceDeep1,
                AppTheme.spaceDeep2,
                AppTheme.spaceDeep3,
                AppTheme.spaceDarkest,
              ],
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
          ),
        ),
        // Stars + nebula + perspective grid
        IgnorePointer(
          child: CustomPaint(painter: _SpaceBackgroundPainter(lite: lite)),
        ),
        // Soft vignette
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.9,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
        ),
        if (darken > 0)
          Container(color: Colors.black.withValues(alpha: darken)),
      ],
    );
  }
}

// Keep the old name as an alias so existing imports don't break
typedef AnimatedBackground = SpaceBackground;

class _SpaceBackgroundPainter extends CustomPainter {
  final bool lite;
  _SpaceBackgroundPainter({this.lite = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);

    if (lite) {
      // Fewer, smaller stars for compact cards
      _drawStarLayer(canvas, size, rng, count: 20, maxRadius: 0.5, opacity: 0.2);
      _drawStarLayer(canvas, size, rng, count: 8, maxRadius: 0.8, opacity: 0.35);
    } else {
      // ── Stars (3 layers: far, medium, close) ──
      _drawStarLayer(canvas, size, rng, count: 80, maxRadius: 0.8, opacity: 0.3);
      _drawStarLayer(canvas, size, rng, count: 40, maxRadius: 1.2, opacity: 0.5);
      _drawStarLayer(canvas, size, rng, count: 15, maxRadius: 2.0, opacity: 0.8);
    }

    // ── Nebula glow spots ──
    final nebulaPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    nebulaPaint.color = AppTheme.bgTop.withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.15), 100, nebulaPaint);
    nebulaPaint.color = AppTheme.bgBot.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.75), 120, nebulaPaint);
    nebulaPaint.color = AppTheme.orbPink.withValues(alpha: 0.03);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.45), 90, nebulaPaint);

    // ── Perspective grid ──
    _drawPerspectiveGrid(canvas, size);
  }

  void _drawStarLayer(Canvas canvas, Size size, Random rng,
      {required int count, required double maxRadius, required double opacity}) {
    for (var i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.3 + rng.nextDouble() * maxRadius;
      final brightness = 0.5 + rng.nextDouble() * 0.5;

      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * brightness * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 3);
      canvas.drawCircle(Offset(x, y), r * 2, glowPaint);

      final starPaint = Paint()..color = Colors.white.withValues(alpha: opacity * brightness);
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
  }

  void _drawPerspectiveGrid(Canvas canvas, Size size) {
    final vanishX = size.width / 2;
    final vanishY = size.height * 0.3;
    final bottomY = size.height;
    final gridPaint = Paint()
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const lineCount = 14;
    for (var i = 0; i <= lineCount; i++) {
      final t = i / lineCount;
      final bottomX = t * size.width;
      final distFromCenter = (t - 0.5).abs();
      final alpha = (0.12 - distFromCenter * 0.15).clamp(0.02, 0.12);
      gridPaint.color = AppTheme.panelBorder.withValues(alpha: alpha);
      canvas.drawLine(Offset(vanishX, vanishY), Offset(bottomX, bottomY), gridPaint);
    }

    const horizLines = 10;
    for (var i = 1; i <= horizLines; i++) {
      final t = i / horizLines;
      final progress = t * t;
      final y = vanishY + (bottomY - vanishY) * progress;
      final spreadX = (size.width / 2) * progress;
      final alpha = (0.04 + progress * 0.1).clamp(0.02, 0.14);
      gridPaint.color = AppTheme.panelBorder.withValues(alpha: alpha);
      canvas.drawLine(Offset(vanishX - spreadX, y), Offset(vanishX + spreadX, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
