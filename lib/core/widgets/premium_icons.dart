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

  const PremiumIcon._({super.key, required this.painter, this.size = 32});

  factory PremiumIcon.play({Key? key, double size = 32}) =>
      PremiumIcon._(key: key, painter: _DelegatingPainter(_playDelegate), size: size);
  factory PremiumIcon.back({Key? key, double size = 32}) =>
      PremiumIcon._(key: key, painter: _DelegatingPainter(_backArrowDelegate), size: size);
  factory PremiumIcon.rocket({Key? key, double size = 32}) =>
      PremiumIcon._(key: key, painter: _DelegatingPainter(_rocketDelegate), size: size);
  factory PremiumIcon.save({Key? key, double size = 32}) =>
      PremiumIcon._(key: key, painter: _DelegatingPainter(_saveDelegate), size: size);
  factory PremiumIcon.logout({Key? key, double size = 32}) =>
      PremiumIcon._(key: key, painter: _DelegatingPainter(_logoutDelegate), size: size);
  factory PremiumIcon.resume({Key? key, double size = 32}) =>
      PremiumIcon._(key: key, painter: _DelegatingPainter(_resumeDelegate), size: size);
  factory PremiumIcon.home({Key? key, double size = 32}) =>
      PremiumIcon._(key: key, painter: _DelegatingPainter(_homeDelegate), size: size);
  factory PremiumIcon.replay({Key? key, double size = 32}) =>
      PremiumIcon._(key: key, painter: _DelegatingPainter(_replayDelegate), size: size);
  factory PremiumIcon.close({Key? key, double size = 32}) =>
      PremiumIcon._(key: key, painter: _DelegatingPainter(_closeXDelegate), size: size);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: painter),
    );
  }
}

/// Generic const-compatible wrapper that delegates to a static painter instance.
/// Eliminates 9 identical boilerplate classes.
class _DelegatingPainter extends CustomPainter {
  final CustomPainter _delegate;
  const _DelegatingPainter(this._delegate);

  @override
  void paint(Canvas canvas, Size size) => _delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Static painter instances — created once, reused forever.
final _playDelegate = PlayIconPainter();
final _backArrowDelegate = BackArrowPainter();
final _rocketDelegate = RocketPlayPainter();
final _saveDelegate = SaveCheckPainter();
final _logoutDelegate = LogoutPainter();
final _resumeDelegate = ResumePainter();
final _homeDelegate = HomePainter();
final _replayDelegate = ReplayPainter();
final _closeXDelegate = CloseXPainter();
