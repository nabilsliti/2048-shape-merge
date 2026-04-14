import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

export 'premium_icons.dart';

/// Premium hand-painted Bomb joker icon
class BombPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.48;
    final cy = h * 0.58;
    final r = w * 0.34;

    // Shadow
    canvas.drawCircle(Offset(cx, cy + 3), r, Paint()..color = Colors.black.withValues(alpha: 0.25));

    // Body — dark gradient sphere
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        colors: [AppTheme.bombBodyLight, AppTheme.bombBodyMid, AppTheme.bombBodyDark, AppTheme.bombBodyShade],
        stops: [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // Metallic ring
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = AppTheme.bombBodyLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Shine highlight
    canvas.drawCircle(
      Offset(cx - r * 0.25, cy - r * 0.25),
      r * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Fuse top — small cylinder
    final fuseBase = Offset(cx + w * 0.08, cy - r + 1);
    final fuseTop = Offset(cx + w * 0.15, h * 0.12);
    canvas.drawLine(fuseBase, fuseTop, Paint()
      ..color = AppTheme.fuseOuter
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round);
    canvas.drawLine(fuseBase, fuseTop, Paint()
      ..color = AppTheme.fuseInner
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round);

    // Fuse tip ring
    canvas.drawCircle(fuseTop, 3.5, Paint()
      ..shader = const RadialGradient(
        colors: [AppTheme.fuseTipLight, AppTheme.fuseTipDark],
      ).createShader(Rect.fromCircle(center: fuseTop, radius: 3.5)));

    // Spark glow
    canvas.drawCircle(Offset(fuseTop.dx + 1, fuseTop.dy - 3), 5, Paint()
      ..color = AppTheme.sparkOrange.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(Offset(fuseTop.dx + 1, fuseTop.dy - 3), 3, Paint()
      ..color = AppTheme.sparkYellow.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawCircle(Offset(fuseTop.dx + 1, fuseTop.dy - 2), 1.5, Paint()..color = Colors.white);

    // Spark lines
    const sparkColor = AppTheme.sparkFlame;
    for (var i = 0; i < 5; i++) {
      final a = (i * math.pi * 2 / 5) - math.pi * 0.6;
      final len = 4.0 + (i % 2) * 3;
      canvas.drawLine(
        Offset(fuseTop.dx + 1 + math.cos(a) * 3, fuseTop.dy - 3 + math.sin(a) * 3),
        Offset(fuseTop.dx + 1 + math.cos(a) * len, fuseTop.dy - 3 + math.sin(a) * len),
        Paint()..color = sparkColor.withValues(alpha: 0.6)..strokeWidth = 0.8..strokeCap = StrokeCap.round,
      );
    }

    // Skull mark — danger dot
    canvas.drawCircle(
      Offset(cx - 1, cy + 2),
      r * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Premium hand-painted Wildcard joker icon (magic star)
class WildcardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.50;
    final cy = h * 0.52;
    final r = w * 0.38;

    // Outer glow
    canvas.drawCircle(Offset(cx, cy), r + 4, Paint()
      ..color = AppTheme.wildcardGlow.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Magic circle background
    canvas.drawCircle(Offset(cx, cy + 2), r, Paint()..color = Colors.black.withValues(alpha: 0.2));
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [AppTheme.wildcardBody1, AppTheme.wildcardBody2, AppTheme.wildcardBody3],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = AppTheme.wildcardRing.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);

    // Star
    final starR = r * 0.60;
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final a = (i * math.pi / 5) - math.pi / 2;
      final sr = i.isEven ? starR : starR * 0.42;
      final px = cx + math.cos(a) * sr;
      final py = cy + math.sin(a) * sr;
      if (i == 0) {
        star.moveTo(px, py);
      } else {
        star.lineTo(px, py);
      }
    }
    star.close();

    // Star shadow
    canvas.drawPath(star.shift(const Offset(0, 1.5)), Paint()..color = Colors.black.withValues(alpha: 0.3));

    // Star gradient
    canvas.drawPath(star, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.goldPale, AppTheme.gold, AppTheme.victoryBadgeBot],
      ).createShader(Rect.fromLTWH(cx - starR, cy - starR, starR * 2, starR * 2)));
    canvas.drawPath(star, Paint()
      ..color = AppTheme.fuseOuter
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);

    // Center dot
    canvas.drawCircle(Offset(cx, cy), 2, Paint()..color = Colors.white.withValues(alpha: 0.8));

    // Sparkle dots around
    const sparkles = [
      [0.22, 0.18], [0.78, 0.22], [0.82, 0.75], [0.20, 0.80],
    ];
    for (final s in sparkles) {
      final sx = w * s[0];
      final sy = h * s[1];
      canvas.drawCircle(Offset(sx, sy), 1.5, Paint()..color = AppTheme.gold.withValues(alpha: 0.6));
      canvas.drawCircle(Offset(sx, sy), 0.8, Paint()..color = Colors.white.withValues(alpha: 0.8));
    }

    // Shine streak
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - r * 0.55, cy - r * 0.65, r * 0.25, r * 0.15), const Radius.circular(4)),
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Premium Reducer joker icon — circle with red down arrow + "-1"
class ReducerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;
    final r = w * 0.46;

    // Outer glow
    canvas.drawCircle(Offset(cx, cy), r + 3, Paint()
      ..color = AppTheme.reducerGlow.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Circle background — dark gradient
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        colors: [AppTheme.reducerBody1, AppTheme.reducerBody2, AppTheme.reducerBody3],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // Circle border
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = AppTheme.reducerGlow.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // ── Red down arrow (left side) ──
    final arrowCx = w * 0.32;
    final arrowTop = h * 0.22;
    final arrowBot = h * 0.78;
    final arrowW = w * 0.11; // half-width of shaft
    final headW = w * 0.20;  // half-width of arrowhead
    final headH = h * 0.22;  // height of arrowhead

    final arrowPath = Path()
      // Shaft
      ..moveTo(arrowCx - arrowW, arrowTop)
      ..lineTo(arrowCx + arrowW, arrowTop)
      ..lineTo(arrowCx + arrowW, arrowBot - headH)
      // Right wing
      ..lineTo(arrowCx + headW, arrowBot - headH)
      // Tip
      ..lineTo(arrowCx, arrowBot)
      // Left wing
      ..lineTo(arrowCx - headW, arrowBot - headH)
      ..lineTo(arrowCx - arrowW, arrowBot - headH)
      ..close();

    // Arrow shadow
    canvas.save();
    canvas.translate(1, 2);
    canvas.drawPath(arrowPath, Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.restore();

    // Arrow fill — red gradient
    canvas.drawPath(arrowPath, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.reducerArrow1, AppTheme.reducerArrow2],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Arrow highlight (left edge shine)
    final shineRect = Rect.fromLTWH(arrowCx - arrowW, arrowTop, arrowW * 0.7, arrowBot - headH - arrowTop);
    canvas.drawRect(shineRect, Paint()
      ..color = Colors.white.withValues(alpha: 0.12));

    // ── "-1" text (right side) ──
    final textPainter = TextPainter(
      text: TextSpan(
        text: '-1',
        style: TextStyle(
          color: Colors.white,
          fontSize: w * 0.32,
          fontWeight: FontWeight.w900,
          fontFamily: AppTheme.fontFamilyTitle,
          shadows: const [
            Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(
      w * 0.52 - textPainter.width * 0.1,
      cy - textPainter.height / 2,
    ));

    // Circle shine (top-left)
    canvas.drawCircle(
      Offset(cx - r * 0.3, cy - r * 0.35),
      r * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Convenience widget — wraps a joker painter in a sized box
class JokerIcon extends StatelessWidget {
  final CustomPainter painter;
  final double size;

  const JokerIcon.bomb({super.key, this.size = 32}) : painter = const _BombPainterConst();
  const JokerIcon.wildcard({super.key, this.size = 32}) : painter = const _WildcardPainterConst();
  const JokerIcon.reducer({super.key, this.size = 32}) : painter = const _ReducerPainterConst();

  const JokerIcon({super.key, required this.painter, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: painter),
    );
  }
}

// Const wrappers — implement paint by delegating
class _BombPainterConst extends CustomPainter {
  const _BombPainterConst();
  static final _delegate = BombPainter();

  @override
  void paint(Canvas canvas, Size size) => _delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WildcardPainterConst extends CustomPainter {
  const _WildcardPainterConst();
  static final _delegate = WildcardPainter();

  @override
  void paint(Canvas canvas, Size size) => _delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReducerPainterConst extends CustomPainter {
  const _ReducerPainterConst();
  static final _delegate = ReducerPainter();

  @override
  void paint(Canvas canvas, Size size) => _delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
