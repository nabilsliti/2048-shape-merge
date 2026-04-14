import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';

/// Visual effect played at a shape's position when a joker is used.
///
/// Each joker has a unique premium animation:
/// - **Bomb**: fiery cross-blast + rotating debris
/// - **MegaBomb**: triple-ring shockwave + rotating ember field
/// - **Wildcard**: magic portal spiral + orbiting star burst
/// - **Reducer**: gravity implosion + descending chevrons
/// - **Evolution**: DNA helix rising + golden energy column
/// - **Radar**: sonar sweep with scan line + blip detections
class JokerEffect extends StatefulWidget {
  final Offset position;
  final JokerType jokerType;
  final VoidCallback onComplete;

  const JokerEffect({
    super.key,
    required this.position,
    required this.jokerType,
    required this.onComplete,
  });

  @override
  State<JokerEffect> createState() => _JokerEffectState();
}

class _JokerEffectState extends State<JokerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: _duration(widget.jokerType),
    )..forward().then((_) => widget.onComplete());
  }

  static Duration _duration(JokerType type) => switch (type) {
        JokerType.megaBomb => const Duration(milliseconds: 950),
        JokerType.bomb => const Duration(milliseconds: 700),
        JokerType.radar => const Duration(milliseconds: 800),
        JokerType.evolution => const Duration(milliseconds: 750),
        JokerType.wildcard => const Duration(milliseconds: 700),
        JokerType.reducer => const Duration(milliseconds: 600),
      };

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const effectSize = 150.0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Positioned(
          left: widget.position.dx - effectSize / 2,
          top: widget.position.dy - effectSize / 2,
          child: SizedBox(
            width: effectSize,
            height: effectSize,
            child: CustomPaint(
              painter: _JokerEffectPainter(
                type: widget.jokerType,
                progress: _ctrl.value,
                color: JokerUI.color(widget.jokerType),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _JokerEffectPainter extends CustomPainter {
  final JokerType type;
  final double progress;
  final Color color;

  _JokerEffectPainter({
    required this.type,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    switch (type) {
      case JokerType.bomb:
        _paintBomb(canvas, cx, cy, size);
      case JokerType.megaBomb:
        _paintMegaBomb(canvas, cx, cy, size);
      case JokerType.wildcard:
        _paintWildcard(canvas, cx, cy, size);
      case JokerType.reducer:
        _paintReducer(canvas, cx, cy, size);
      case JokerType.evolution:
        _paintEvolution(canvas, cx, cy, size);
      case JokerType.radar:
        _paintRadar(canvas, cx, cy, size);
    }
  }

  // ── Bomb: fiery cross-blast with rotating debris ──────────────────────

  void _paintBomb(Canvas canvas, double cx, double cy, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final maxR = size.width * 0.44;
    final eased = Curves.easeOutCubic.transform(progress);

    // Hot core flash — radial gradient
    if (progress < 0.35) {
      final flashT = progress / 0.35;
      final flashR = (maxR * 0.55 * flashT).clamp(0.1, double.infinity);
      canvas.drawCircle(
        Offset(cx, cy),
        flashR,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cx, cy),
            flashR,
            [
              Colors.white.withValues(alpha: (1 - flashT) * 0.7),
              color.withValues(alpha: (1 - flashT) * 0.5),
              color.withValues(alpha: 0),
            ],
            [0.0, 0.5, 1.0],
          ),
      );
    }

    // Cross-blast — 4 cardinal streaks expanding outward
    final blastLen = maxR * eased;
    final blastWidth = 7.0 * (1 - progress);
    final blastPaint = Paint()
      ..strokeWidth = blastWidth
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: opacity * 0.8);
    canvas.drawLine(
        Offset(cx - blastLen, cy), Offset(cx + blastLen, cy), blastPaint);
    canvas.drawLine(
        Offset(cx, cy - blastLen), Offset(cx, cy + blastLen), blastPaint);

    // Thinner diagonal streaks
    final diagLen = blastLen * 0.65;
    final diagPaint = Paint()
      ..strokeWidth = blastWidth * 0.45
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: opacity * 0.4);
    canvas.drawLine(Offset(cx - diagLen, cy - diagLen),
        Offset(cx + diagLen, cy + diagLen), diagPaint);
    canvas.drawLine(Offset(cx + diagLen, cy - diagLen),
        Offset(cx - diagLen, cy + diagLen), diagPaint);

    // Chunky rotating rectangular debris — 8 fragments
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * pi * 2 + 0.2;
      final dist = maxR * 0.75 * eased;
      final px = cx + cos(angle) * dist;
      final py = cy + sin(angle) * dist;
      final pSize = 3.5 * (1 - progress * 0.6);
      final rot = angle + progress * 2;
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: pSize * 2.0, height: pSize),
          Radius.circular(pSize * 0.25),
        ),
        Paint()..color = color.withValues(alpha: opacity * 0.85),
      );
      canvas.restore();
    }
  }

  // ── MegaBomb: triple-ring shockwave + rotating ember field ────────────

  void _paintMegaBomb(Canvas canvas, double cx, double cy, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final maxR = size.width * 0.52;
    final eased = Curves.easeOutCubic.transform(progress);

    // Massive radial flash
    if (progress < 0.3) {
      final flashT = progress / 0.3;
      final flashR = (maxR * 0.6 * flashT).clamp(0.1, double.infinity);
      canvas.drawCircle(
        Offset(cx, cy),
        flashR,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cx, cy),
            flashR,
            [
              color.withValues(alpha: (1 - flashT) * 0.7),
              color.withValues(alpha: (1 - flashT) * 0.3),
              Colors.transparent,
            ],
            [0.0, 0.5, 1.0],
          ),
      );
    }

    // Outer ring — thick expanding shockwave
    final outerR = maxR * eased;
    canvas.drawCircle(
      Offset(cx, cy),
      outerR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0 * (1 - progress)
        ..color = color.withValues(alpha: opacity * 0.9),
    );

    // Inner ring — delayed, white, thinner
    if (progress > 0.1) {
      final innerP = ((progress - 0.1) / 0.9).clamp(0.0, 1.0);
      final innerEased = Curves.easeOutCubic.transform(innerP);
      final innerR = maxR * 0.65 * innerEased;
      canvas.drawCircle(
        Offset(cx, cy),
        innerR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 * (1 - innerP)
          ..color = Colors.white.withValues(alpha: (1 - innerP) * 0.6),
      );
    }

    // Third pulse ring — even more delayed
    if (progress > 0.25) {
      final thirdP = ((progress - 0.25) / 0.75).clamp(0.0, 1.0);
      final thirdR = maxR * 0.4 * Curves.easeOutCubic.transform(thirdP);
      canvas.drawCircle(
        Offset(cx, cy),
        thirdR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * (1 - thirdP)
          ..color = color.withValues(alpha: (1 - thirdP) * 0.35),
      );
    }

    // Rotating ember field — 14 embers with spiral motion
    for (var i = 0; i < 14; i++) {
      final baseAngle = (i / 14) * pi * 2;
      final angle = baseAngle + progress * 1.5;
      final dist = maxR * 0.9 * eased;
      final px = cx + cos(angle) * dist;
      final py = cy + sin(angle) * dist;
      final pSize = (3.5 + (i % 3)) * (1 - progress * 0.5);
      canvas.drawCircle(
        Offset(px, py),
        pSize,
        Paint()..color = color.withValues(alpha: opacity * 0.75),
      );
      // Hot white core on every other ember
      if (i.isEven) {
        canvas.drawCircle(
          Offset(px, py),
          pSize * 0.4,
          Paint()..color = Colors.white.withValues(alpha: opacity * 0.5),
        );
      }
    }
  }

  // ── Wildcard: magic portal spiral + orbiting star burst ───────────────

  void _paintWildcard(Canvas canvas, double cx, double cy, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final maxR = size.width * 0.42;
    final eased = Curves.easeOutCubic.transform(progress);

    // Spinning portal rings — 2 tilted ellipses counter-rotating
    for (var ring = 0; ring < 2; ring++) {
      final sweep = ring == 0 ? progress * pi * 3 : -progress * pi * 2.5;
      final ringR = maxR * 0.5 * (0.4 + eased * 0.6);
      final ringOpacity = opacity * (ring == 0 ? 0.5 : 0.3);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(sweep);
      canvas.scale(1.0, 0.4 + ring * 0.15);
      canvas.drawCircle(
        Offset.zero,
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - progress * 0.4)
          ..color = color.withValues(alpha: ringOpacity),
      );
      canvas.restore();
    }

    // Central magic glow — pulsing
    if (progress < 0.5) {
      final glowT = progress / 0.5;
      final pulse = sin(glowT * pi) * 0.3 + 0.7;
      final glowR = (12.0 * pulse * (1 - glowT * 0.5)).clamp(0.1, double.infinity);
      canvas.drawCircle(
        Offset(cx, cy),
        glowR,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cx, cy),
            glowR,
            [
              Colors.white.withValues(alpha: (1 - glowT) * 0.6),
              color.withValues(alpha: (1 - glowT) * 0.4),
              Colors.transparent,
            ],
            [0.0, 0.5, 1.0],
          ),
      );
    }

    // Orbiting 4-point star particles — 8 stars spiraling out
    for (var i = 0; i < 8; i++) {
      final baseAngle = (i / 8) * pi * 2;
      final spiralAngle = baseAngle + progress * pi * 2;
      final dist = maxR * eased * (0.3 + (i % 3) * 0.25);
      final px = cx + cos(spiralAngle) * dist;
      final py = cy + sin(spiralAngle) * dist;
      final starSize = 5.0 * (1 - progress * 0.5);

      // 4-point star shape
      final star = Path()
        ..moveTo(px, py - starSize)
        ..lineTo(px + starSize * 0.28, py - starSize * 0.28)
        ..lineTo(px + starSize, py)
        ..lineTo(px + starSize * 0.28, py + starSize * 0.28)
        ..lineTo(px, py + starSize)
        ..lineTo(px - starSize * 0.28, py + starSize * 0.28)
        ..lineTo(px - starSize, py)
        ..lineTo(px - starSize * 0.28, py - starSize * 0.28)
        ..close();
      canvas.drawPath(
        star,
        Paint()
          ..color = (i.isEven ? color : Colors.white)
              .withValues(alpha: opacity * 0.85),
      );
    }

    // Sparkle dust — tiny dots fading outward
    for (var i = 0; i < 10; i++) {
      final angle = (i / 10) * pi * 2 + progress * pi;
      final dist = maxR * 0.8 * eased;
      canvas.drawCircle(
        Offset(cx + cos(angle) * dist, cy + sin(angle) * dist),
        1.5 * (1 - progress),
        Paint()..color = Colors.white.withValues(alpha: opacity * 0.5),
      );
    }
  }

  // ── Reducer: gravity implosion + descending chevrons ──────────────────

  void _paintReducer(Canvas canvas, double cx, double cy, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final maxR = size.width * 0.42;

    // Imploding ring — starts big, shrinks inward (reverse of explosion)
    final implodeP = Curves.easeInCubic.transform(progress);
    final ringR = maxR * (1.0 - implodeP * 0.8);
    canvas.drawCircle(
      Offset(cx, cy),
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * (1 - progress * 0.5)
        ..color = color.withValues(alpha: opacity * 0.6),
    );

    // Particles being sucked inward — 10 fragments converging to center
    for (var i = 0; i < 10; i++) {
      final angle = (i / 10) * pi * 2 + 0.5;
      final startDist = maxR * 0.9;
      final dist = startDist * (1.0 - implodeP);
      final px = cx + cos(angle) * dist;
      final py = cy + sin(angle) * dist;
      final pSize = 3.0 * (0.3 + (1 - progress) * 0.7);
      canvas.drawCircle(
        Offset(px, py),
        pSize,
        Paint()..color = color.withValues(alpha: opacity * 0.7),
      );
    }

    // Descending chevrons — 3 staggered downward arrows
    final maxDrop = size.height * 0.35;
    for (var i = 0; i < 3; i++) {
      final delay = i * 0.12;
      final localP = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (localP <= 0) continue;
      final localOpacity = (1.0 - localP).clamp(0.0, 1.0);
      final yOff = maxDrop * Curves.easeOutCubic.transform(localP);
      final chevronY = cy - 8 + yOff;
      final halfW = 10.0 - i * 2.0;

      final chevron = Path()
        ..moveTo(cx - halfW, chevronY - 3)
        ..lineTo(cx, chevronY + 3)
        ..lineTo(cx + halfW, chevronY - 3);
      canvas.drawPath(
        chevron,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - localP * 0.5)
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: localOpacity * 0.8),
      );
    }

    // Center shrink pulse — final compression flash
    if (progress > 0.6) {
      final pulseP = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
      final pulseR = 8.0 * (1 - pulseP);
      canvas.drawCircle(
        Offset(cx, cy),
        pulseR,
        Paint()..color = Colors.white.withValues(alpha: (1 - pulseP) * 0.5),
      );
    }
  }

  // ── Evolution: DNA helix rising + golden energy column ────────────────

  void _paintEvolution(Canvas canvas, double cx, double cy, Size size) {
    final maxRise = size.height * 0.48;
    final eased = Curves.easeOutCubic.transform(progress);

    // Central energy column — glowing vertical beam
    if (progress < 0.7) {
      final beamP = progress / 0.7;
      final beamH = (maxRise * beamP).clamp(0.1, double.infinity);
      final beamW = 8.0 * (1 - beamP * 0.4);
      final beamRect = Rect.fromCenter(
        center: Offset(cx, cy - beamH / 2),
        width: beamW,
        height: beamH,
      );
      canvas.drawRect(
        beamRect,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(cx, cy),
            Offset(cx, cy - beamH),
            [
              color.withValues(alpha: (1 - beamP) * 0.5),
              Colors.white.withValues(alpha: (1 - beamP) * 0.3),
            ],
          ),
      );
      // Outer glow on beam
      canvas.drawRect(
        beamRect.inflate(3),
        Paint()
          ..color = color.withValues(alpha: (1 - beamP) * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // DNA helix — two intertwined strands rising
    const helixAmplitude = 12.0;
    const strandCount = 12;
    for (var strand = 0; strand < 2; strand++) {
      final phaseOffset = strand * pi;
      for (var i = 0; i < strandCount; i++) {
        final t = i / strandCount;
        final delay = t * 0.3;
        final localP = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        if (localP <= 0) continue;
        final localOpacity = (1.0 - localP).clamp(0.0, 1.0);
        final rise = maxRise * Curves.easeOutCubic.transform(localP);
        final wavePhase = t * pi * 4 + phaseOffset + progress * pi * 2;
        final xOff = sin(wavePhase) * helixAmplitude;
        final dotY = cy - rise;
        final dotSize = 3.0 * (1 - localP * 0.4);
        canvas.drawCircle(
          Offset(cx + xOff, dotY),
          dotSize,
          Paint()
            ..color = (strand == 0 ? color : Colors.white)
                .withValues(alpha: localOpacity * 0.7),
        );
      }
    }

    // Arrow tip at peak
    if (progress > 0.15 && progress < 0.75) {
      final arrowP = ((progress - 0.15) / 0.6).clamp(0.0, 1.0);
      final arrowY = cy - maxRise * Curves.easeOutCubic.transform(arrowP);
      final arrowFade = progress < 0.55
          ? 1.0
          : (1 - (progress - 0.55) / 0.2).clamp(0.0, 1.0);
      const arrowSize = 7.0;
      final arrow = Path()
        ..moveTo(cx, arrowY - arrowSize)
        ..lineTo(cx - arrowSize * 0.7, arrowY + arrowSize * 0.4)
        ..lineTo(cx + arrowSize * 0.7, arrowY + arrowSize * 0.4)
        ..close();
      canvas.drawPath(
        arrow,
        Paint()..color = color.withValues(alpha: arrowFade * 0.9),
      );
    }

    // Sparkle burst at top when reaching peak
    if (progress > 0.4 && progress < 0.8) {
      final sparkP = ((progress - 0.4) / 0.4).clamp(0.0, 1.0);
      final sparkY = cy - maxRise * eased;
      for (var i = 0; i < 5; i++) {
        final angle = (i / 5) * pi * 2 - pi / 2;
        final dist = 10.0 * sparkP;
        canvas.drawCircle(
          Offset(cx + cos(angle) * dist, sparkY + sin(angle) * dist),
          2.0 * (1 - sparkP),
          Paint()
            ..color = Colors.white.withValues(alpha: (1 - sparkP) * 0.6),
        );
      }
    }
  }

  // ── Radar: sonar sweep with scan line + blip detections ───────────────

  void _paintRadar(Canvas canvas, double cx, double cy, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final maxR = size.width * 0.46;

    // Concentric pulse rings — 3 staggered
    for (var i = 0; i < 3; i++) {
      final delay = i * 0.18;
      final localP = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (localP <= 0) continue;
      final localOpacity = (1.0 - localP).clamp(0.0, 1.0);
      final ringR = maxR * Curves.easeOutCubic.transform(localP);
      canvas.drawCircle(
        Offset(cx, cy),
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - localP)
          ..color = color.withValues(alpha: localOpacity * 0.6),
      );
    }

    // Sweep line — rotating radar arm with trail
    if (progress < 0.85) {
      final sweepAngle = progress / 0.85 * pi * 2.5;
      final sweepR = maxR * 0.8;
      final px = cx + cos(sweepAngle - pi / 2) * sweepR;
      final py = cy + sin(sweepAngle - pi / 2) * sweepR;

      // Sweep trail — fading arc behind the arm
      const trailArc = pi * 0.4;
      final trailPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..shader = ui.Gradient.sweep(
          Offset(cx, cy),
          [Colors.transparent, color.withValues(alpha: opacity * 0.3)],
          [0.0, 1.0],
          TileMode.clamp,
          sweepAngle - pi / 2 - trailArc,
          sweepAngle - pi / 2,
        );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: sweepR),
        sweepAngle - pi / 2 - trailArc,
        trailArc,
        false,
        trailPaint,
      );

      // Sweep arm line
      canvas.drawLine(
        Offset(cx, cy),
        Offset(px, py),
        Paint()
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: opacity * 0.6),
      );
    }

    // Blip detections — 5 dots appearing and fading
    const blipPositions = <List<double>>[
      [0.3, 0.6, 0.25],
      [0.7, 0.4, 0.35],
      [1.2, 0.75, 0.45],
      [1.8, 0.55, 0.55],
      [2.4, 0.65, 0.65],
    ];
    for (final blip in blipPositions) {
      final blipAngle = blip[0] * pi;
      final blipDist = maxR * blip[1];
      final blipAppear = blip[2];
      if (progress < blipAppear) continue;
      final blipP =
          ((progress - blipAppear) / (1.0 - blipAppear)).clamp(0.0, 1.0);
      final blipOpacity =
          (blipP < 0.3 ? blipP / 0.3 : (1.0 - blipP)).clamp(0.0, 1.0);
      final blipX = cx + cos(blipAngle) * blipDist;
      final blipY = cy + sin(blipAngle) * blipDist;

      // Blip glow
      canvas.drawCircle(
        Offset(blipX, blipY),
        5.0,
        Paint()
          ..color = color.withValues(alpha: blipOpacity * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      // Blip dot
      canvas.drawCircle(
        Offset(blipX, blipY),
        2.5,
        Paint()..color = color.withValues(alpha: blipOpacity * 0.8),
      );
    }

    // Center dot — pulsing
    final pulse = sin(progress * pi * 4) * 0.3 + 0.7;
    canvas.drawCircle(
      Offset(cx, cy),
      3.0 * pulse,
      Paint()..color = color.withValues(alpha: opacity * 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _JokerEffectPainter old) =>
      old.progress != progress || old.type != type;
}
