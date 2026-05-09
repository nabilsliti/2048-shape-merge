part of 'hud_bar.dart';


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

// ─── Ring painter — capacity arc gauge ──────────────────────
class _RingPainter extends CustomPainter {
  final double ratio;
  final Color color;
  _RingPainter({required this.ratio, required this.color});

  static final _trackPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = Colors.white.withValues(alpha: 0.06);
  static final _arcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final _dotPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.7);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;
    final sw = size.width * 0.14;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Track
    canvas.drawArc(rect, -pi / 2, 2 * pi, false, _trackPaint..strokeWidth = sw);

    // Arc
    canvas.drawArc(rect, -pi / 2, 2 * pi * ratio.clamp(0.0, 1.0), false, _arcPaint
      ..strokeWidth = sw
      ..color = color);

    // 3x3 grid dots in center
    final dotR = r * 0.12;
    final gap = r * 0.35;
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        canvas.drawCircle(
          Offset(cx + dx * gap, cy + dy * gap),
          dotR,
          _dotPaint,
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
    final paint = _confettiPaint;
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
      paint.color = c.color.withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.drawRect(rect, paint);

      canvas.restore();
    }
  }

  static final _confettiPaint = Paint()..style = PaintingStyle.fill;

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}
