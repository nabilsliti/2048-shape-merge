import 'dart:math' as math;
import 'package:flutter/material.dart';

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
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: const [Color(0xFF555555), Color(0xFF333333), Color(0xFF1a1a1a), Color(0xFF0d0d0d)],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // Metallic ring
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = const Color(0xFF555555)
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
      ..color = const Color(0xFF8B6914)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round);
    canvas.drawLine(fuseBase, fuseTop, Paint()
      ..color = const Color(0xFFDAA520)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round);

    // Fuse tip ring
    canvas.drawCircle(fuseTop, 3.5, Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFE082), Color(0xFFDAA520)],
      ).createShader(Rect.fromCircle(center: fuseTop, radius: 3.5)));

    // Spark glow
    canvas.drawCircle(Offset(fuseTop.dx + 1, fuseTop.dy - 3), 5, Paint()
      ..color = const Color(0xFFFF6600).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(Offset(fuseTop.dx + 1, fuseTop.dy - 3), 3, Paint()
      ..color = const Color(0xFFFFDD00).withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawCircle(Offset(fuseTop.dx + 1, fuseTop.dy - 2), 1.5, Paint()..color = Colors.white);

    // Spark lines
    const sparkColor = Color(0xFFFF8800);
    for (var i = 0; i < 5; i++) {
      final a = (i * math.pi * 2 / 5) - math.pi * 0.6;
      final len = 4.0 + (i % 2) * 3;
      canvas.drawLine(
        Offset(fuseTop.dx + 1 + math.cos(a) * 3, fuseTop.dy - 3 + math.sin(a) * 3),
        Offset(fuseTop.dx + 1 + math.cos(a) * len, fuseTop.dy - 3 + math.sin(a) * len),
        Paint()..color = sparkColor.withValues(alpha: 0.6)..strokeWidth = 0.8..strokeCap = StrokeCap.round,
      );
    }

    // Skull mark — simple cross-bones
    final scx = cx - 1;
    final scy = cy + 2;
    // X mark
    canvas.drawLine(
      Offset(scx - r * 0.22, scy - r * 0.22),
      Offset(scx + r * 0.22, scy + r * 0.22),
      Paint()..color = const Color(0xFFff4444)..strokeWidth = 2.5..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(scx + r * 0.22, scy - r * 0.22),
      Offset(scx - r * 0.22, scy + r * 0.22),
      Paint()..color = const Color(0xFFff4444)..strokeWidth = 2.5..strokeCap = StrokeCap.round,
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
      ..color = const Color(0xFF6a11cb).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Magic circle background
    canvas.drawCircle(Offset(cx, cy + 2), r, Paint()..color = Colors.black.withValues(alpha: 0.2));
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [Color(0xFF9c27b0), Color(0xFF7b1fa2), Color(0xFF4a148c)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = const Color(0xFFce93d8).withValues(alpha: 0.5)
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
      if (i == 0) star.moveTo(px, py); else star.lineTo(px, py);
    }
    star.close();

    // Star shadow
    canvas.drawPath(star.shift(const Offset(0, 1.5)), Paint()..color = Colors.black.withValues(alpha: 0.3));

    // Star gradient
    canvas.drawPath(star, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Color(0xFFFFE082), Color(0xFFFFD700), Color(0xFFFF8C00)],
      ).createShader(Rect.fromLTWH(cx - starR, cy - starR, starR * 2, starR * 2)));
    canvas.drawPath(star, Paint()
      ..color = const Color(0xFF8B6914)
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
      canvas.drawCircle(Offset(sx, sy), 1.5, Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.6));
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
      ..color = const Color(0xFFff5252).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Circle background — dark gradient
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        colors: const [Color(0xFF3a3a4a), Color(0xFF2a2a38), Color(0xFF1a1a28)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // Circle border
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = const Color(0xFFff5252).withValues(alpha: 0.6)
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
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFff6b6b), Color(0xFFe53935)],
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
          fontFamily: 'Fredoka',
          shadows: const [
            Shadow(color: Color(0x55000000), offset: Offset(1, 1), blurRadius: 2),
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

// ═══════════════════════════════════════════════════════════════
// Premium Play icon — green circle with white triangle play symbol
// ═══════════════════════════════════════════════════════════════
class PlayIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;
    final r = w * 0.46;

    // Outer glow
    canvas.drawCircle(Offset(cx, cy), r + 4, Paint()
      ..color = const Color(0xFF00e676).withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Shadow
    canvas.drawCircle(Offset(cx, cy + 2), r, Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Circle — green gradient
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [Color(0xFF69f0ae), Color(0xFF00e676), Color(0xFF00c853)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // Border
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = const Color(0xFF00a843).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Play triangle — shifted right slightly for optical center
    final triW = r * 0.85;
    final triH = r * 1.0;
    final triCx = cx + r * 0.08;
    final triangle = Path()
      ..moveTo(triCx - triW * 0.35, cy - triH * 0.5)
      ..lineTo(triCx + triW * 0.55, cy)
      ..lineTo(triCx - triW * 0.35, cy + triH * 0.5)
      ..close();

    // Triangle shadow
    canvas.save();
    canvas.translate(1, 1.5);
    canvas.drawPath(triangle, Paint()..color = const Color(0xFF00a843).withValues(alpha: 0.3));
    canvas.restore();

    // Triangle fill
    canvas.drawPath(triangle, Paint()..color = Colors.white);

    // Shine on circle
    canvas.drawCircle(
      Offset(cx - r * 0.28, cy - r * 0.30),
      r * 0.14,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// Premium Back Arrow icon — translucent circle with stylized arrow
// ═══════════════════════════════════════════════════════════════
class BackArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;
    final r = w * 0.46;

    // Outer glow
    canvas.drawCircle(Offset(cx, cy), r + 3, Paint()
      ..color = const Color(0xFF90caf9).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Shadow
    canvas.drawCircle(Offset(cx, cy + 2), r, Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Circle background — dark glass
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        colors: const [Color(0xFF3a3a50), Color(0xFF2a2a3c), Color(0xFF1a1a2a)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // Border
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Arrow — chevron left + horizontal line
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final arrowLeft = cx - r * 0.38;
    final arrowRight = cx + r * 0.45;
    final chevronSize = r * 0.38;

    // Chevron <
    final chevron = Path()
      ..moveTo(arrowLeft + chevronSize, cy - chevronSize)
      ..lineTo(arrowLeft, cy)
      ..lineTo(arrowLeft + chevronSize, cy + chevronSize);
    canvas.drawPath(chevron, arrowPaint);

    // Horizontal line
    canvas.drawLine(
      Offset(arrowLeft + 2, cy),
      Offset(arrowRight, cy),
      arrowPaint,
    );

    // Shine
    canvas.drawCircle(
      Offset(cx - r * 0.25, cy - r * 0.30),
      r * 0.10,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Convenience widget for premium nav icons
class PremiumIcon extends StatelessWidget {
  final CustomPainter painter;
  final double size;

  const PremiumIcon.play({super.key, this.size = 32}) : painter = const _PlayPainterConst();
  const PremiumIcon.back({super.key, this.size = 32}) : painter = const _BackArrowPainterConst();
  const PremiumIcon.rocket({super.key, this.size = 32}) : painter = const _RocketPainterConst();
  const PremiumIcon.save({super.key, this.size = 32}) : painter = const _SavePainterConst();
  const PremiumIcon.logout({super.key, this.size = 32}) : painter = const _LogoutPainterConst();
  const PremiumIcon.resume({super.key, this.size = 32}) : painter = const _ResumePainterConst();
  const PremiumIcon.home({super.key, this.size = 32}) : painter = const _HomePainterConst();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: painter),
    );
  }
}

class _PlayPainterConst extends CustomPainter {
  const _PlayPainterConst();
  static final _delegate = PlayIconPainter();

  @override
  void paint(Canvas canvas, Size size) => _delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackArrowPainterConst extends CustomPainter {
  const _BackArrowPainterConst();
  static final _delegate = BackArrowPainter();

  @override
  void paint(Canvas canvas, Size size) => _delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RocketPainterConst extends CustomPainter {
  const _RocketPainterConst();
  static final _delegate = RocketPlayPainter();

  @override
  void paint(Canvas canvas, Size size) => _delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SavePainterConst extends CustomPainter {
  const _SavePainterConst();
  static final _delegate = SaveCheckPainter();

  @override
  void paint(Canvas canvas, Size size) => _delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoutPainterConst extends CustomPainter {
  const _LogoutPainterConst();
  static final _delegate = LogoutPainter();

  @override
  void paint(Canvas canvas, Size size) => _delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ResumePainterConst extends CustomPainter {
  const _ResumePainterConst();
  static final _delegate = ResumePainter();

  @override
  void paint(Canvas canvas, Size size) => _delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomePainterConst extends CustomPainter {
  const _HomePainterConst();
  static final _delegate = HomePainter();

  @override
  void paint(Canvas canvas, Size size) => _delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// Premium Logout icon — red circle with white power/exit arrow
// ═══════════════════════════════════════════════════════════════
class LogoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Red circle background
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFff4747), const Color(0xFFcc0000)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Subtle ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..color = const Color(0xFFffaaaa).withValues(alpha: 0.4);
    canvas.drawCircle(Offset(cx, cy), r * 0.82, ringPaint);

    // Door frame (left half arc)
    final doorPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    final doorRect = Rect.fromCircle(center: Offset(cx - r * 0.08, cy), radius: r * 0.45);
    canvas.drawArc(doorRect, 0.6, 4.1, false, doorPaint);

    // Arrow shaft (pointing right)
    final arrowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;
    final arrowStartX = cx - r * 0.05;
    final arrowEndX = cx + r * 0.5;
    canvas.drawLine(Offset(arrowStartX, cy), Offset(arrowEndX, cy), arrowPaint);

    // Arrow head
    final headPath = Path()
      ..moveTo(arrowEndX - r * 0.22, cy - r * 0.22)
      ..lineTo(arrowEndX, cy)
      ..lineTo(arrowEndX - r * 0.22, cy + r * 0.22);
    canvas.drawPath(headPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// Premium Save icon — golden shield with white checkmark
// ═══════════════════════════════════════════════════════════════
class SaveCheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Golden circle background
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFffd700), const Color(0xFFe5a000)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Subtle ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..color = const Color(0xFFfffde0).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(cx, cy), r * 0.82, ringPaint);

    // White checkmark
    final checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;

    final path = Path()
      ..moveTo(cx - r * 0.35, cy + r * 0.05)
      ..lineTo(cx - r * 0.05, cy + r * 0.35)
      ..lineTo(cx + r * 0.4, cy - r * 0.3);
    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// Premium Rocket icon — sleek rocket with flame trail
// ═══════════════════════════════════════════════════════════════
class RocketPlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    // ── Flame trail (bottom) ──
    // Outer flame glow
    final flameGlowPath = Path()
      ..moveTo(cx - w * 0.22, h * 0.72)
      ..quadraticBezierTo(cx - w * 0.08, h * 0.85, cx, h * 1.02)
      ..quadraticBezierTo(cx + w * 0.08, h * 0.85, cx + w * 0.22, h * 0.72);
    canvas.drawPath(flameGlowPath, Paint()
      ..color = const Color(0xFFFF6600).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Outer flame — orange
    final outerFlamePath = Path()
      ..moveTo(cx - w * 0.18, h * 0.70)
      ..quadraticBezierTo(cx - w * 0.06, h * 0.82, cx, h * 0.96)
      ..quadraticBezierTo(cx + w * 0.06, h * 0.82, cx + w * 0.18, h * 0.70);
    canvas.drawPath(outerFlamePath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFFF6600), Color(0xFFFF3300), Color(0xFFFF0000)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, h * 0.70, w, h * 0.26)));

    // Inner flame — yellow/white
    final innerFlamePath = Path()
      ..moveTo(cx - w * 0.10, h * 0.70)
      ..quadraticBezierTo(cx - w * 0.03, h * 0.80, cx, h * 0.90)
      ..quadraticBezierTo(cx + w * 0.03, h * 0.80, cx + w * 0.10, h * 0.70);
    canvas.drawPath(innerFlamePath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFFFE082), Color(0xFFFFD54F), Color(0xFFFF8F00)],
      ).createShader(Rect.fromLTWH(0, h * 0.70, w, h * 0.20)));

    // White-hot core
    final coreFlamePath = Path()
      ..moveTo(cx - w * 0.04, h * 0.70)
      ..quadraticBezierTo(cx, h * 0.80, cx, h * 0.82)
      ..quadraticBezierTo(cx, h * 0.80, cx + w * 0.04, h * 0.70);
    canvas.drawPath(coreFlamePath, Paint()
      ..color = Colors.white.withValues(alpha: 0.85));

    // ── Rocket body shadow ──
    canvas.save();
    canvas.translate(1.5, 3);
    final shadowBody = Path()
      ..moveTo(cx, h * 0.04)
      ..quadraticBezierTo(cx + w * 0.22, h * 0.18, cx + w * 0.22, h * 0.45)
      ..lineTo(cx + w * 0.22, h * 0.62)
      ..quadraticBezierTo(cx + w * 0.22, h * 0.72, cx, h * 0.72)
      ..quadraticBezierTo(cx - w * 0.22, h * 0.72, cx - w * 0.22, h * 0.62)
      ..lineTo(cx - w * 0.22, h * 0.45)
      ..quadraticBezierTo(cx - w * 0.22, h * 0.18, cx, h * 0.04)
      ..close();
    canvas.drawPath(shadowBody, Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.restore();

    // ── Fins (side boosters) ──
    // Left fin
    final leftFin = Path()
      ..moveTo(cx - w * 0.20, h * 0.52)
      ..lineTo(cx - w * 0.38, h * 0.72)
      ..lineTo(cx - w * 0.32, h * 0.72)
      ..lineTo(cx - w * 0.20, h * 0.62)
      ..close();
    canvas.drawPath(leftFin, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF42a5f5), Color(0xFF1565c0)],
      ).createShader(Rect.fromLTWH(0, h * 0.52, w, h * 0.20)));

    // Right fin
    final rightFin = Path()
      ..moveTo(cx + w * 0.20, h * 0.52)
      ..lineTo(cx + w * 0.38, h * 0.72)
      ..lineTo(cx + w * 0.32, h * 0.72)
      ..lineTo(cx + w * 0.20, h * 0.62)
      ..close();
    canvas.drawPath(rightFin, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF42a5f5), Color(0xFF1565c0)],
      ).createShader(Rect.fromLTWH(0, h * 0.52, w, h * 0.20)));

    // ── Rocket body ──
    final bodyPath = Path()
      ..moveTo(cx, h * 0.04)
      ..quadraticBezierTo(cx + w * 0.22, h * 0.18, cx + w * 0.22, h * 0.45)
      ..lineTo(cx + w * 0.22, h * 0.62)
      ..quadraticBezierTo(cx + w * 0.22, h * 0.72, cx, h * 0.72)
      ..quadraticBezierTo(cx - w * 0.22, h * 0.72, cx - w * 0.22, h * 0.62)
      ..lineTo(cx - w * 0.22, h * 0.45)
      ..quadraticBezierTo(cx - w * 0.22, h * 0.18, cx, h * 0.04)
      ..close();

    // Body gradient — silver/white metallic
    canvas.drawPath(bodyPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [Color(0xFFe0e0e0), Color(0xFFfafafa), Color(0xFFffffff), Color(0xFFe8e8e8)],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(cx - w * 0.22, 0, w * 0.44, h * 0.72)));

    // Body border
    canvas.drawPath(bodyPath, Paint()
      ..color = const Color(0xFF90a4ae).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);

    // ── Nose cone tip ──
    final nosePath = Path()
      ..moveTo(cx, h * 0.04)
      ..quadraticBezierTo(cx + w * 0.15, h * 0.14, cx + w * 0.18, h * 0.24)
      ..lineTo(cx - w * 0.18, h * 0.24)
      ..quadraticBezierTo(cx - w * 0.15, h * 0.14, cx, h * 0.04)
      ..close();
    canvas.drawPath(nosePath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFef5350), Color(0xFFc62828)],
      ).createShader(Rect.fromLTWH(0, h * 0.04, w, h * 0.20)));

    // ── Window (porthole) ──
    final windowCy = h * 0.36;
    final windowR = w * 0.09;

    // Window rim
    canvas.drawCircle(Offset(cx, windowCy), windowR + 2, Paint()
      ..color = const Color(0xFF78909c));

    // Window glass — blue gradient
    canvas.drawCircle(Offset(cx, windowCy), windowR, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [Color(0xFF81d4fa), Color(0xFF29b6f6), Color(0xFF0277bd)],
      ).createShader(Rect.fromCircle(center: Offset(cx, windowCy), radius: windowR)));

    // Window shine
    canvas.drawCircle(
      Offset(cx - windowR * 0.3, windowCy - windowR * 0.3),
      windowR * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // ── Stripes on body ──
    final stripePaint = Paint()
      ..color = const Color(0xFF42a5f5).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(
      Offset(cx - w * 0.18, h * 0.56),
      Offset(cx + w * 0.18, h * 0.56),
      stripePaint,
    );
    canvas.drawLine(
      Offset(cx - w * 0.16, h * 0.60),
      Offset(cx + w * 0.16, h * 0.60),
      stripePaint,
    );

    // ── Body highlight (left shine streak) ──
    final shinePath = Path()
      ..moveTo(cx - w * 0.12, h * 0.12)
      ..quadraticBezierTo(cx - w * 0.16, h * 0.30, cx - w * 0.16, h * 0.50)
      ..lineTo(cx - w * 0.12, h * 0.50)
      ..quadraticBezierTo(cx - w * 0.12, h * 0.30, cx - w * 0.08, h * 0.12)
      ..close();
    canvas.drawPath(shinePath, Paint()
      ..color = Colors.white.withValues(alpha: 0.25));

    // ── Small sparkle dots ──
    canvas.drawCircle(Offset(w * 0.15, h * 0.20), 1.5, Paint()..color = Colors.white.withValues(alpha: 0.5));
    canvas.drawCircle(Offset(w * 0.82, h * 0.35), 1.2, Paint()..color = Colors.white.withValues(alpha: 0.4));
    canvas.drawCircle(Offset(w * 0.12, h * 0.55), 1.0, Paint()..color = Colors.white.withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// Premium Resume icon — green circle with white play triangle
// ═══════════════════════════════════════════════════════════════
class ResumePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Outer glow
    canvas.drawCircle(Offset(cx, cy), r + 4, Paint()
      ..color = const Color(0xFF00e676).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Shadow
    canvas.drawCircle(Offset(cx, cy + 2), r, Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Green gradient circle
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [Color(0xFF69f0ae), Color(0xFF00e676), Color(0xFF00c853)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // Subtle inner ring
    canvas.drawCircle(Offset(cx, cy), r * 0.82, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..color = const Color(0xFFb9f6ca).withValues(alpha: 0.4));

    // Border
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = const Color(0xFF00a843).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Play triangle — optically centered
    final triCx = cx + r * 0.06;
    final triScale = r * 0.42;
    final triangle = Path()
      ..moveTo(triCx - triScale * 0.45, cy - triScale)
      ..lineTo(triCx + triScale * 0.75, cy)
      ..lineTo(triCx - triScale * 0.45, cy + triScale)
      ..close();

    // Triangle shadow
    canvas.save();
    canvas.translate(1, 1.5);
    canvas.drawPath(triangle, Paint()..color = const Color(0xFF00a843).withValues(alpha: 0.3));
    canvas.restore();

    // Triangle fill
    canvas.drawPath(triangle, Paint()..color = Colors.white);

    // Shine
    canvas.drawCircle(
      Offset(cx - r * 0.28, cy - r * 0.30),
      r * 0.14,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// Premium Home icon — orange circle with white house silhouette
// ═══════════════════════════════════════════════════════════════
class HomePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Outer glow
    canvas.drawCircle(Offset(cx, cy), r + 4, Paint()
      ..color = const Color(0xFFff9800).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Shadow
    canvas.drawCircle(Offset(cx, cy + 2), r, Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Orange gradient circle
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [Color(0xFFffcc80), Color(0xFFff9800), Color(0xFFe65100)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // Subtle inner ring
    canvas.drawCircle(Offset(cx, cy), r * 0.82, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..color = const Color(0xFFffe0b2).withValues(alpha: 0.4));

    // Border
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = const Color(0xFFe65100).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // House — roof (triangle)
    final roofPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final hs = r * 0.72; // house scale
    final houseTop = cy - hs * 0.55;
    final houseBot = cy + hs * 0.50;
    final houseLeft = cx - hs * 0.6;
    final houseRight = cx + hs * 0.6;

    final roofPath = Path()
      ..moveTo(cx, houseTop)
      ..lineTo(houseRight + hs * 0.1, cy - hs * 0.02)
      ..lineTo(houseLeft - hs * 0.1, cy - hs * 0.02)
      ..close();

    // Roof shadow
    canvas.save();
    canvas.translate(0.5, 1);
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFFe65100).withValues(alpha: 0.3));
    canvas.restore();

    canvas.drawPath(roofPath, roofPaint);

    // House body (rectangle)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(houseLeft, cy - hs * 0.05, houseRight, houseBot),
      Radius.circular(hs * 0.06),
    );
    canvas.drawRRect(bodyRect, roofPaint);

    // Door
    final doorW = hs * 0.28;
    final doorH = hs * 0.40;
    final doorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, houseBot - doorH * 0.5), width: doorW, height: doorH),
      Radius.circular(doorW * 0.2),
    );
    canvas.drawRRect(doorRect, Paint()..color = const Color(0xFFff9800));

    // Shine
    canvas.drawCircle(
      Offset(cx - r * 0.28, cy - r * 0.30),
      r * 0.14,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
