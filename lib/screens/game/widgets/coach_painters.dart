part of 'coach_overlay.dart';

// ── Spotlight painter ─────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Rect? spotlightRect;
  final bool passThrough;
  final double pulse; // 0.0 → 1.0

  _SpotlightPainter({this.spotlightRect, this.passThrough = false, this.pulse = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final dimColor = Colors.black.withValues(alpha: passThrough ? 0.45 : 0.70);
    final fullRect = Offset.zero & size;

    if (spotlightRect == null) {
      canvas.drawRect(fullRect, Paint()..color = dimColor);
      return;
    }

    final rrect = RRect.fromRectAndRadius(
      spotlightRect!,
      const Radius.circular(AppTheme.radiusXTiny),
    );

    // Dim everything except spotlight cutout
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(rrect);
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = dimColor);

    // Pulsing outer glow — cyan/teal neon aura
    final glowAlpha = 0.08 + pulse * 0.12; // 0.08 → 0.20
    final glowSpread = 10.0 + pulse * 6.0; // 10 → 16
    canvas.drawRRect(
      rrect.inflate(glowSpread),
      Paint()
        ..color = AppTheme.orbCyan.withValues(alpha: glowAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSpread),
    );

    // Inner glow — subtle cyan fill inside
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppTheme.orbCyan.withValues(alpha: 0.06 + pulse * 0.04)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 16),
    );

    // Primary border — bright cyan
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppTheme.orbCyan.withValues(alpha: 0.7 + pulse * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Secondary outer border — gold highlight
    canvas.drawRRect(
      rrect.inflate(3),
      Paint()
        ..color = AppTheme.gold.withValues(alpha: 0.15 + pulse * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      spotlightRect != old.spotlightRect ||
      passThrough != old.passThrough ||
      pulse != old.pulse;

  @override
  bool? hitTest(Offset position) {
    // When passThrough is true and position is inside the spotlight, let it pass
    if (passThrough && spotlightRect != null) {
      if (spotlightRect!.contains(position)) return false;
    }
    return true;
  }
}

// ── Arrow side enum ───────────────────────────────────────────

enum _ArrowSide { none, top, bottom }

// ── Bubble painter (rounded rect + arrow) ─────────────────────

class _BubblePainter extends CustomPainter {
  final _ArrowSide arrowSide;
  final double arrowOffset;
  final double arrowSize;

  _BubblePainter({
    required this.arrowSide,
    required this.arrowOffset,
    required this.arrowSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 14.0;

    final bodyRect = switch (arrowSide) {
      _ArrowSide.top => Rect.fromLTWH(0, arrowSize, size.width, size.height - arrowSize),
      _ArrowSide.bottom => Rect.fromLTWH(0, 0, size.width, size.height - arrowSize),
      _ArrowSide.none => Offset.zero & size,
    };
    final rrect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(radius));

    // Build continuous path
    final path = Path();

    if (arrowSide == _ArrowSide.none) {
      path.addRRect(rrect);
    } else {
      final tipX = arrowOffset.clamp(radius + arrowSize, size.width - radius - arrowSize);

      if (arrowSide == _ArrowSide.top) {
        path.moveTo(bodyRect.left + radius, bodyRect.top);
        path.lineTo(tipX - arrowSize, bodyRect.top);
        path.lineTo(tipX, 0);
        path.lineTo(tipX + arrowSize, bodyRect.top);
        path.lineTo(bodyRect.right - radius, bodyRect.top);
        path.arcToPoint(Offset(bodyRect.right, bodyRect.top + radius),
            radius: const Radius.circular(radius));
        path.lineTo(bodyRect.right, bodyRect.bottom - radius);
        path.arcToPoint(Offset(bodyRect.right - radius, bodyRect.bottom),
            radius: const Radius.circular(radius));
        path.lineTo(bodyRect.left + radius, bodyRect.bottom);
        path.arcToPoint(Offset(bodyRect.left, bodyRect.bottom - radius),
            radius: const Radius.circular(radius));
        path.lineTo(bodyRect.left, bodyRect.top + radius);
        path.arcToPoint(Offset(bodyRect.left + radius, bodyRect.top),
            radius: const Radius.circular(radius));
      } else {
        final bodyBottom = size.height - arrowSize;
        path.moveTo(bodyRect.left + radius, bodyRect.top);
        path.lineTo(bodyRect.right - radius, bodyRect.top);
        path.arcToPoint(Offset(bodyRect.right, bodyRect.top + radius),
            radius: const Radius.circular(radius));
        path.lineTo(bodyRect.right, bodyBottom - radius);
        path.arcToPoint(Offset(bodyRect.right - radius, bodyBottom),
            radius: const Radius.circular(radius));
        path.lineTo(tipX + arrowSize, bodyBottom);
        path.lineTo(tipX, size.height);
        path.lineTo(tipX - arrowSize, bodyBottom);
        path.lineTo(bodyRect.left + radius, bodyBottom);
        path.arcToPoint(Offset(bodyRect.left, bodyBottom - radius),
            radius: const Radius.circular(radius));
        path.lineTo(bodyRect.left, bodyRect.top + radius);
        path.arcToPoint(Offset(bodyRect.left + radius, bodyRect.top),
            radius: const Radius.circular(radius));
      }
      path.close();
    }

    // Gradient fill: deep cosmic purple → dark blue
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xF5140030), // deep purple
        Color(0xF5080020), // dark navy
        Color(0xF5100028), // deep violet
      ],
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(bodyRect)
        ..style = PaintingStyle.fill,
    );

    // Inner top-edge highlight (subtle glass reflection)
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(bodyRect.left, bodyRect.top, bodyRect.width, bodyRect.height * 0.35),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(bodyRect),
    );
    canvas.restore();

    // Cyan neon border
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.orbCyan.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Subtle gold outer glow on border
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.gold.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      arrowSide != old.arrowSide || arrowOffset != old.arrowOffset;
}
