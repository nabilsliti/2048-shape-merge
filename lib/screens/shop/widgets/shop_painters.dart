part of '../shop_screen.dart';

// ═══════════════════════════════════════════════════════════════
// Shield + "No Ads" painter (for ZÉRO PUB card)
// ═══════════════════════════════════════════════════════════════
class _ShieldNoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.9;
    final h = size.height * 0.9;
    final ox = (size.width - w) / 2;
    final oy = (size.height - h) / 2;

    // Shield shape
    final shield = Path()
      ..moveTo(cx, oy)
      ..quadraticBezierTo(ox + w * 0.05, oy, ox + w * 0.05, oy + h * 0.15)
      ..lineTo(ox + w * 0.05, oy + h * 0.55)
      ..quadraticBezierTo(ox + w * 0.05, oy + h * 0.8, cx, oy + h)
      ..quadraticBezierTo(ox + w * 0.95, oy + h * 0.8, ox + w * 0.95, oy + h * 0.55)
      ..lineTo(ox + w * 0.95, oy + h * 0.15)
      ..quadraticBezierTo(ox + w * 0.95, oy, cx, oy)
      ..close();

    // Shadow
    canvas.drawPath(shield.shift(const Offset(0, 3)), Paint()..color = Colors.black.withValues(alpha: 0.3));

    // Gold gradient fill
    canvas.drawPath(shield, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.goldPale, AppTheme.gold, AppTheme.goldAntique, AppTheme.goldBronze],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(ox, oy, w, h)));

    // Border
    canvas.drawPath(shield, Paint()..color = AppTheme.goldDark..style = PaintingStyle.stroke..strokeWidth = 1.8);

    // Inner shield line
    final innerShield = Path()
      ..moveTo(cx, oy + 5)
      ..quadraticBezierTo(ox + w * 0.12, oy + 5, ox + w * 0.12, oy + h * 0.18)
      ..lineTo(ox + w * 0.12, oy + h * 0.53)
      ..quadraticBezierTo(ox + w * 0.12, oy + h * 0.76, cx, oy + h - 5)
      ..quadraticBezierTo(ox + w * 0.88, oy + h * 0.76, ox + w * 0.88, oy + h * 0.53)
      ..lineTo(ox + w * 0.88, oy + h * 0.18)
      ..quadraticBezierTo(ox + w * 0.88, oy + 5, cx, oy + 5)
      ..close();
    canvas.drawPath(innerShield, Paint()..color = AppTheme.goldPale.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Red circle with strikethrough
    final circCx = cx;
    final circCy = cy + 2;
    final circR = w * 0.30;

    // Red glow
    canvas.drawCircle(Offset(circCx, circCy), circR + 3, Paint()
      ..color = AppTheme.shopNoAdsRed.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    // Red circle fill
    canvas.drawCircle(Offset(circCx, circCy), circR, Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [AppTheme.capDanger, AppTheme.shopNoAdsRed, AppTheme.redDeep],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(circCx, circCy), radius: circR)));

    // Red circle border
    canvas.drawCircle(Offset(circCx, circCy), circR, Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0);

    // AD text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'AD',
        style: TextStyle(
          fontSize: circR * 1.0, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5,
          shadows: const [Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(circCx - textPainter.width / 2, circCy - textPainter.height / 2));

    // Diagonal strikethrough
    canvas.save();
    canvas.translate(circCx, circCy);
    canvas.rotate(-0.4);
    final strikeW = circR * 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0.5, 0.5), width: strikeW, height: 3), const Radius.circular(1.5)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: strikeW, height: 2.5), const Radius.circular(1.5)),
      Paint()..color = Colors.white,
    );
    canvas.restore();

    // Top shine
    final shinePath = Path()
      ..moveTo(cx - w * 0.15, oy + 6)
      ..quadraticBezierTo(cx, oy + 3, cx + w * 0.15, oy + 6)
      ..quadraticBezierTo(cx, oy + 10, cx - w * 0.15, oy + 6)
      ..close();
    canvas.drawPath(shinePath, Paint()..color = Colors.white.withValues(alpha: 0.45));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// Laser ring painter — rotating arc with glow trail (from shape-rush)
// ═══════════════════════════════════════════════════════════════
class _LaserRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _LaserRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final startAngle = progress * 2 * math.pi;

    // Main bright arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      math.pi * 0.5,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Glow trail
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      math.pi * 0.5,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Opposite faint arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + math.pi,
      math.pi * 0.35,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Sparkle dot at arc tip
    final tipAngle = startAngle + math.pi * 0.5;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);
    canvas.drawCircle(
      Offset(tipX, tipY),
      3,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(_LaserRingPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
// Shimmer painter — diagonal light sweep
// ═══════════════════════════════════════════════════════════════
class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width * (-0.3 + progress * 1.6);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(center - 80, 0, 160, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
// Sparkle particles — floating gold stars
// ═══════════════════════════════════════════════════════════════
class _SparkleParticlesPainter extends CustomPainter {
  final double progress;
  _SparkleParticlesPainter(this.progress);

  static const _seeds = [0.1, 0.25, 0.42, 0.58, 0.73, 0.88, 0.05, 0.35, 0.62, 0.91];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _seeds.length; i++) {
      final seed = _seeds[i];
      final t = (progress + seed) % 1.0;
      final x = seed * size.width;
      final y = size.height * (1.0 - t);
      final alpha = (t < 0.5 ? t * 2 : (1.0 - t) * 2).clamp(0.0, 1.0);
      final s = 1.5 + seed * 2.0;

      final paint = Paint()..color = AppTheme.gold.withValues(alpha: alpha * 0.7);
      _drawStar(canvas, x, y, s, paint);
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      path.moveTo(cx, cy);
      path.lineTo(cx + math.cos(angle) * r, cy + math.sin(angle) * r);
    }
    canvas.drawPath(path, paint..strokeWidth = 1.2..style = PaintingStyle.stroke);
    canvas.drawCircle(Offset(cx, cy), r * 0.3, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_SparkleParticlesPainter old) => old.progress != progress;
}

