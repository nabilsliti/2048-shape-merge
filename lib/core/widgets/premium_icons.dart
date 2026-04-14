import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

part 'premium_painters.dart';

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
      ..color = AppTheme.evolutionGlow.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Shadow
    canvas.drawCircle(Offset(cx, cy + 2), r, Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Circle — green gradient
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [AppTheme.evolutionFill1, AppTheme.evolutionFill2, AppTheme.evolutionFill3],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // Border
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = AppTheme.evolutionDark.withValues(alpha: 0.5)
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
    canvas.drawPath(triangle, Paint()..color = AppTheme.evolutionDark.withValues(alpha: 0.3));
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
      ..color = AppTheme.radarRingBlue.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Shadow
    canvas.drawCircle(Offset(cx, cy + 2), r, Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Circle background — dark glass
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        colors: [AppTheme.radarBody1, AppTheme.radarBody2, AppTheme.radarBody3],
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
  const PremiumIcon.replay({super.key, this.size = 32}) : painter = const _ReplayPainterConst();
  const PremiumIcon.close({super.key, this.size = 32}) : painter = const _CloseXPainterConst();

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

class _ReplayPainterConst extends CustomPainter {
  const _ReplayPainterConst();
  static final _delegate = ReplayPainter();

  @override
  void paint(Canvas canvas, Size size) => _delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CloseXPainterConst extends CustomPainter {
  const _CloseXPainterConst();
  static final _delegate = CloseXPainter();

  @override
  void paint(Canvas canvas, Size size) => _delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
