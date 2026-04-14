part of 'premium_icons.dart';


// ═══════════════════════════════════════════════════════════════
// Premium Close X icon — bold stylized X (no background circle)
// ═══════════════════════════════════════════════════════════════
class CloseXPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;
    final xSize = w * 0.32;
    final strokeW = w * 0.16;

    // X shadow — offset down-right
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - xSize + 1.5, cy - xSize + 2), Offset(cx + xSize + 1.5, cy + xSize + 2), shadowPaint);
    canvas.drawLine(Offset(cx + xSize + 1.5, cy - xSize + 2), Offset(cx - xSize + 1.5, cy + xSize + 2), shadowPaint);

    // X strokes — bold white with slight outer glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW + 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawLine(Offset(cx - xSize, cy - xSize), Offset(cx + xSize, cy + xSize), glowPaint);
    canvas.drawLine(Offset(cx + xSize, cy - xSize), Offset(cx - xSize, cy + xSize), glowPaint);

    // X main strokes — crisp white
    final xPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - xSize, cy - xSize), Offset(cx + xSize, cy + xSize), xPaint);
    canvas.drawLine(Offset(cx + xSize, cy - xSize), Offset(cx - xSize, cy + xSize), xPaint);
  }

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
      ..shader = const RadialGradient(
        colors: [AppTheme.megaBombRing1, AppTheme.megaBombRing2],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Subtle ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..color = AppTheme.megaBombRingShine.withValues(alpha: 0.4);
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
      ..shader = const RadialGradient(
        colors: [AppTheme.radarStarGold, AppTheme.radarStarDark],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Subtle ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..color = AppTheme.radarStarShine.withValues(alpha: 0.6);
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
      ..color = AppTheme.rocketGlow.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Outer flame — orange
    final outerFlamePath = Path()
      ..moveTo(cx - w * 0.18, h * 0.70)
      ..quadraticBezierTo(cx - w * 0.06, h * 0.82, cx, h * 0.96)
      ..quadraticBezierTo(cx + w * 0.06, h * 0.82, cx + w * 0.18, h * 0.70);
    canvas.drawPath(outerFlamePath, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.rocketFlame1, AppTheme.rocketFlame2, AppTheme.rocketFlame3],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, h * 0.70, w, h * 0.26)));

    // Inner flame — yellow/white
    final innerFlamePath = Path()
      ..moveTo(cx - w * 0.10, h * 0.70)
      ..quadraticBezierTo(cx - w * 0.03, h * 0.80, cx, h * 0.90)
      ..quadraticBezierTo(cx + w * 0.03, h * 0.80, cx + w * 0.10, h * 0.70);
    canvas.drawPath(innerFlamePath, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.rocketNozzle1, AppTheme.rocketNozzle2, AppTheme.rocketNozzle3],
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
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.rocketBody1, AppTheme.rocketBody2],
      ).createShader(Rect.fromLTWH(0, h * 0.52, w, h * 0.20)));

    // Right fin
    final rightFin = Path()
      ..moveTo(cx + w * 0.20, h * 0.52)
      ..lineTo(cx + w * 0.38, h * 0.72)
      ..lineTo(cx + w * 0.32, h * 0.72)
      ..lineTo(cx + w * 0.20, h * 0.62)
      ..close();
    canvas.drawPath(rightFin, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.rocketBody1, AppTheme.rocketBody2],
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
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [AppTheme.rocketPanel1, AppTheme.rocketPanel2, AppTheme.rocketPanel3, AppTheme.rocketPanel4],
        stops: [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(cx - w * 0.22, 0, w * 0.44, h * 0.72)));

    // Body border
    canvas.drawPath(bodyPath, Paint()
      ..color = AppTheme.rocketBodyBorder.withValues(alpha: 0.6)
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
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.rocketNoseCone1, AppTheme.rocketNoseCone2],
      ).createShader(Rect.fromLTWH(0, h * 0.04, w, h * 0.20)));

    // ── Window (porthole) ──
    final windowCy = h * 0.36;
    final windowR = w * 0.09;

    // Window rim
    canvas.drawCircle(Offset(cx, windowCy), windowR + 2, Paint()
      ..color = AppTheme.rocketWindow);

    // Window glass — blue gradient
    canvas.drawCircle(Offset(cx, windowCy), windowR, Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [AppTheme.rocketGlass1, AppTheme.rocketGlass2, AppTheme.rocketGlass3],
      ).createShader(Rect.fromCircle(center: Offset(cx, windowCy), radius: windowR)));

    // Window shine
    canvas.drawCircle(
      Offset(cx - windowR * 0.3, windowCy - windowR * 0.3),
      windowR * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // ── Stripes on body ──
    final stripePaint = Paint()
      ..color = AppTheme.rocketBody1.withValues(alpha: 0.6)
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
    final w = size.width;
    final cx = w * 0.5;
    final cy = w * 0.5;
    final s = w * 0.34;

    // Play triangle — shifted right for optical center
    final triCx = cx + s * 0.10;
    final triangle = Path()
      ..moveTo(triCx - s * 0.50, cy - s * 0.85)
      ..lineTo(triCx + s * 0.80, cy)
      ..lineTo(triCx - s * 0.50, cy + s * 0.85)
      ..close();

    // Shadow
    canvas.save();
    canvas.translate(1, 2);
    canvas.drawPath(triangle, Paint()
      ..color = Colors.black.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill);
    canvas.restore();

    // Glow
    canvas.drawPath(triangle, Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Fill white
    canvas.drawPath(triangle, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill);
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
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;
    final s = w * 0.36; // half-size of house
    final strokeW = w * 0.12;

    // ── House path: roof + body as a single shape ──
    final roofPeak = cy - s * 0.85;
    final roofBase = cy - s * 0.05;
    final bodyBot = cy + s * 0.75;
    final left = cx - s * 0.80;
    final right = cx + s * 0.80;
    final roofLeft = cx - s * 1.05;
    final roofRight = cx + s * 1.05;
    final r = s * 0.12;

    final house = Path()
      // Start at roof peak
      ..moveTo(cx, roofPeak)
      // Roof right slope
      ..lineTo(roofRight, roofBase)
      // Right wall down
      ..lineTo(right, roofBase)
      ..lineTo(right, bodyBot - r)
      ..arcToPoint(Offset(right - r, bodyBot), radius: Radius.circular(r))
      // Bottom
      ..lineTo(left + r, bodyBot)
      ..arcToPoint(Offset(left, bodyBot - r), radius: Radius.circular(r))
      // Left wall up
      ..lineTo(left, roofBase)
      ..lineTo(roofLeft, roofBase)
      ..close();

    // Shadow
    canvas.save();
    canvas.translate(1, 2);
    canvas.drawPath(house, Paint()
      ..color = Colors.black.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill);
    canvas.restore();

    // Glow
    canvas.drawPath(house, Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW + 4
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Fill white
    canvas.drawPath(house, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill);

    // Door cutout (dark)
    final doorW = s * 0.40;
    final doorH = s * 0.55;
    final doorRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx, bodyBot - doorH * 0.45), width: doorW, height: doorH),
      topLeft: Radius.circular(doorW * 0.5),
      topRight: Radius.circular(doorW * 0.5),
    );
    canvas.drawRRect(doorRect, Paint()..color = AppTheme.homePainterFill3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// Premium Replay icon — bold white circular refresh arrow
// ═══════════════════════════════════════════════════════════════
class ReplayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = w * 0.5;
    final cy = w * 0.5;
    final r = w * 0.30;
    final strokeW = w * 0.11;

    // Shadow
    canvas.save();
    canvas.translate(1, 2);
    _draw(canvas, cx, cy, r, strokeW, Colors.black.withValues(alpha: 0.30));
    canvas.restore();

    // Glow
    canvas.save();
    _draw(canvas, cx, cy, r, strokeW + 3, Colors.white.withValues(alpha: 0.20),
        blur: const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.restore();

    // Main white
    _draw(canvas, cx, cy, r, strokeW, Colors.white);
  }

  void _draw(Canvas canvas, double cx, double cy, double r, double sw, Color c, {MaskFilter? blur}) {
    // Open arc: starts at top-left, sweeps clockwise ~280°
    const start = -math.pi * 0.65;
    const sweep = math.pi * 1.55;
    const end = start + sweep;

    final arcPaint = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    if (blur != null) arcPaint.maskFilter = blur;

    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), start, sweep, false, arcPaint);

    // Arrowhead at arc end — a solid chevron pointing along the tangent
    final ex = cx + r * math.cos(end);
    final ey = cy + r * math.sin(end);

    // Tangent direction (perpendicular to radius, clockwise)
    final tx = -math.sin(end);
    final ty = math.cos(end);
    // Normal direction (outward from center)
    final nx = math.cos(end);
    final ny = math.sin(end);

    final aLen = r * 0.55;
    final aSpread = r * 0.45;

    final tipPath = Path()
      ..moveTo(ex + tx * aLen, ey + ty * aLen) // tip (forward along tangent)
      ..lineTo(ex + nx * aSpread, ey + ny * aSpread) // outer wing
      ..lineTo(ex - nx * aSpread, ey - ny * aSpread) // inner wing
      ..close();

    final tipPaint = Paint()
      ..color = c
      ..style = PaintingStyle.fill;
    if (blur != null) tipPaint.maskFilter = blur;

    canvas.drawPath(tipPath, tipPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
