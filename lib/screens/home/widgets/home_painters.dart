part of '../home_screen.dart';

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
          AppTheme.bgTop.withValues(alpha: 0.45),
          AppTheme.bgTop.withValues(alpha: 0.0),
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
          AppTheme.nebulaPink.withValues(alpha: 0.35),
          AppTheme.nebulaPink.withValues(alpha: 0.0),
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
          AppTheme.bgBot.withValues(alpha: 0.3),
          AppTheme.bgBot.withValues(alpha: 0.0),
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
          ..color = AppTheme.goldLight.withValues(alpha: alpha * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = AppTheme.goldLight.withValues(alpha: alpha * 0.7)
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

  // [phaseX, phaseY, size, speedX, speedY, rotSpeed, shapeType, ampX, ampY]
  static const _shapes = [
    [0.0, 0.5, 55.0, 1.0, 0.7, 1.0, 0, 0.9, 0.8],
    [0.6, 1.3, 45.0, 0.6, 1.2, 1.0, 1, 0.7, 0.9],
    [1.3, 2.1, 60.0, 1.3, 0.5, 1.0, 2, 0.8, 0.6],
    [1.9, 0.3, 50.0, 0.8, 1.0, 1.0, 3, 0.6, 1.0],
    [2.5, 1.8, 58.0, 1.1, 0.9, 1.0, 4, 1.0, 0.5],
    [3.1, 0.9, 42.0, 0.5, 1.4, 1.0, 0, 0.5, 0.9],
    [3.8, 2.5, 65.0, 1.0, 0.6, 1.0, 3, 0.9, 0.7],
    [4.4, 1.1, 48.0, 0.7, 1.1, 1.0, 1, 0.6, 1.0],
    [5.0, 2.8, 55.0, 1.2, 0.4, 1.0, 2, 1.0, 0.8],
    [5.7, 0.2, 52.0, 0.4, 1.3, 1.0, 4, 0.8, 0.6],
    [0.3, 1.7, 38.0, 1.4, 0.8, 0.7, 2, 0.7, 0.5],
    [0.9, 2.6, 44.0, 0.9, 1.5, 1.3, 0, 0.5, 0.8],
    [1.6, 0.8, 35.0, 0.3, 0.6, 0.5, 4, 0.9, 1.0],
    [2.2, 2.3, 50.0, 1.5, 1.0, 0.9, 1, 0.6, 0.7],
    [2.8, 0.6, 40.0, 0.7, 0.3, 1.1, 3, 1.0, 0.9],
    [3.4, 1.5, 32.0, 1.0, 1.3, 0.8, 0, 0.8, 0.4],
    [4.0, 0.1, 46.0, 0.5, 0.9, 1.4, 2, 0.4, 1.0],
    [4.7, 2.0, 36.0, 1.3, 0.5, 0.6, 4, 0.7, 0.6],
    [5.3, 1.4, 42.0, 0.8, 1.1, 1.2, 1, 0.9, 0.8],
    [5.9, 2.9, 30.0, 0.6, 0.7, 0.4, 3, 0.5, 0.9],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 40.0;
    final halfW = (size.width - margin) / 2;
    final halfH = (size.height - margin) / 2;
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (final s in _shapes) {
      final phaseX = s[0].toDouble();
      final phaseY = s[1].toDouble();
      final shapeSize = s[2].toDouble();
      final speedX = s[3].toDouble();
      final speedY = s[4].toDouble();
      final rotSpeed = s[5].toDouble();
      final shapeType = s[6].toInt();
      final ampX = s[7].toDouble();
      final ampY = s[8].toDouble();

      final t = progress * math.pi * 2;
      final x = cx + math.sin(t * speedX + phaseX) * halfW * ampX;
      final y = cy + math.cos(t * speedY + phaseY) * halfH * ampY;
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
            if (i == 0) {
              path.moveTo(px, py);
            } else {
              path.lineTo(px, py);
            }
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
            if (i == 0) {
              path.moveTo(px, py);
            } else {
              path.lineTo(px, py);
            }
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

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FloatingShapesPainter old) => old.progress != progress;
}

