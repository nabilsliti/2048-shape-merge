import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';

/// Visual effect played at a shape's position when a joker is used.
///
/// - **Bomb / MegaBomb**: expanding shockwave ring + radial debris particles
/// - **Wildcard**: sparkle burst with star particles
/// - **Reducer**: downward chevron cascade
/// - **Evolution**: upward energy column with rising particles
/// - **Radar**: concentric pulse rings
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
        JokerType.megaBomb => const Duration(milliseconds: 900),
        JokerType.bomb => const Duration(milliseconds: 700),
        _ => const Duration(milliseconds: 650),
      };

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const effectSize = 140.0;

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

  // ── Bomb: shockwave ring + debris ──────────────────────────────────────

  void _paintBomb(Canvas canvas, double cx, double cy, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final maxR = size.width * 0.45;

    // Shockwave ring
    final ringR = maxR * Curves.easeOutCubic.transform(progress);
    final ringWidth = 4.0 * (1 - progress);
    canvas.drawCircle(
      Offset(cx, cy),
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..color = color.withValues(alpha: opacity * 0.8),
    );

    // Flash
    if (progress < 0.2) {
      final flashOpacity = (1 - progress / 0.2) * 0.4;
      canvas.drawCircle(
        Offset(cx, cy),
        ringR * 0.6,
        Paint()..color = Colors.white.withValues(alpha: flashOpacity),
      );
    }

    // Debris particles
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * pi * 2;
      final dist = maxR * 0.8 * Curves.easeOutCubic.transform(progress);
      final px = cx + cos(angle) * dist;
      final py = cy + sin(angle) * dist;
      final pSize = 3.0 * (1 - progress * 0.7);
      canvas.drawCircle(
        Offset(px, py),
        pSize,
        Paint()..color = color.withValues(alpha: opacity * 0.9),
      );
    }
  }

  // ── MegaBomb: larger shockwave with double ring ────────────────────────

  void _paintMegaBomb(Canvas canvas, double cx, double cy, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final maxR = size.width * 0.5;

    // Outer ring
    final outerR = maxR * Curves.easeOutCubic.transform(progress);
    canvas.drawCircle(
      Offset(cx, cy),
      outerR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0 * (1 - progress)
        ..color = color.withValues(alpha: opacity * 0.9),
    );

    // Inner ring (delayed)
    if (progress > 0.1) {
      final innerP = ((progress - 0.1) / 0.9).clamp(0.0, 1.0);
      final innerR = maxR * 0.7 * Curves.easeOutCubic.transform(innerP);
      canvas.drawCircle(
        Offset(cx, cy),
        innerR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 * (1 - innerP)
          ..color = Colors.white.withValues(alpha: (1 - innerP) * 0.5),
      );
    }

    // Flash
    if (progress < 0.25) {
      final flashOpacity = (1 - progress / 0.25) * 0.5;
      canvas.drawCircle(
        Offset(cx, cy),
        outerR * 0.5,
        Paint()..color = color.withValues(alpha: flashOpacity),
      );
    }

    // Debris spread
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * pi * 2 + progress * 0.5;
      final dist = maxR * Curves.easeOutCubic.transform(progress);
      final px = cx + cos(angle) * dist;
      final py = cy + sin(angle) * dist;
      final pSize = 4.0 * (1 - progress * 0.6);
      canvas.drawCircle(
        Offset(px, py),
        pSize,
        Paint()..color = color.withValues(alpha: opacity * 0.8),
      );
    }
  }

  // ── Wildcard: sparkle star burst ───────────────────────────────────────

  void _paintWildcard(Canvas canvas, double cx, double cy, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final maxR = size.width * 0.4;

    // Central glow
    if (progress < 0.4) {
      final glowP = progress / 0.4;
      final glowR = 15.0 * (1 - glowP);
      canvas.drawCircle(
        Offset(cx, cy),
        glowR,
        Paint()..color = color.withValues(alpha: (1 - glowP) * 0.6),
      );
    }

    // Star particles bursting out
    for (var i = 0; i < 6; i++) {
      final angle = (i / 6) * pi * 2;
      final dist = maxR * Curves.easeOutCubic.transform(progress);
      final px = cx + cos(angle) * dist;
      final py = cy + sin(angle) * dist;

      // Draw tiny 4-point star
      final starSize = 5.0 * (1 - progress * 0.5);
      final starPath = Path()
        ..moveTo(px, py - starSize)
        ..lineTo(px + starSize * 0.3, py)
        ..lineTo(px, py + starSize)
        ..lineTo(px - starSize * 0.3, py)
        ..close();
      canvas.drawPath(
        starPath,
        Paint()..color = color.withValues(alpha: opacity),
      );
    }

    // Secondary sparkle dots (rotated offset)
    for (var i = 0; i < 6; i++) {
      final angle = (i / 6) * pi * 2 + pi / 6;
      final dist = maxR * 0.6 * Curves.easeOutCubic.transform(progress);
      final px = cx + cos(angle) * dist;
      final py = cy + sin(angle) * dist;
      canvas.drawCircle(
        Offset(px, py),
        2.5 * (1 - progress),
        Paint()..color = Colors.white.withValues(alpha: opacity * 0.7),
      );
    }
  }

  // ── Reducer: downward chevron cascade ──────────────────────────────────

  void _paintReducer(Canvas canvas, double cx, double cy, Size size) {
    final maxDrop = size.height * 0.4;

    for (var i = 0; i < 3; i++) {
      final delay = i * 0.15;
      final localP = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (localP <= 0) continue;

      final opacity = (1.0 - localP).clamp(0.0, 1.0);
      final yOff = maxDrop * Curves.easeOutCubic.transform(localP);
      final chevronY = cy - 10 + yOff;
      final halfW = 12.0 - i * 2.0;

      final chevron = Path()
        ..moveTo(cx - halfW, chevronY - 4)
        ..lineTo(cx, chevronY + 4)
        ..lineTo(cx + halfW, chevronY - 4);

      canvas.drawPath(
        chevron,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 * (1 - localP * 0.5)
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: opacity * 0.9),
      );
    }

    // Small dots falling
    for (var i = 0; i < 4; i++) {
      final delay = i * 0.1;
      final localP = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (localP <= 0) continue;
      final opacity = (1.0 - localP).clamp(0.0, 1.0);
      final xOff = (i - 1.5) * 10;
      final yOff = maxDrop * 0.8 * Curves.easeOutCubic.transform(localP);
      canvas.drawCircle(
        Offset(cx + xOff, cy + yOff),
        2.5 * (1 - localP),
        Paint()..color = color.withValues(alpha: opacity * 0.6),
      );
    }
  }

  // ── Evolution: upward energy column ────────────────────────────────────

  void _paintEvolution(Canvas canvas, double cx, double cy, Size size) {
    final maxRise = size.height * 0.45;

    // Central vertical beam
    if (progress < 0.6) {
      final beamP = progress / 0.6;
      final beamOpacity = (1 - beamP) * 0.4;
      final beamHeight = maxRise * beamP;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx, cy - beamHeight / 2),
          width: 6.0 * (1 - beamP * 0.5),
          height: beamHeight,
        ),
        Paint()..color = color.withValues(alpha: beamOpacity),
      );
    }

    // Rising particles
    for (var i = 0; i < 6; i++) {
      final delay = i * 0.08;
      final localP = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (localP <= 0) continue;
      final opacity = (1.0 - localP).clamp(0.0, 1.0);
      final xOff = sin(i * 1.2) * 12;
      final yOff = -maxRise * Curves.easeOutCubic.transform(localP);
      canvas.drawCircle(
        Offset(cx + xOff, cy + yOff),
        3.0 * (1 - localP * 0.5),
        Paint()..color = color.withValues(alpha: opacity * 0.8),
      );
    }

    // Arrow tip at top
    if (progress > 0.1 && progress < 0.7) {
      final arrowP = ((progress - 0.1) / 0.6).clamp(0.0, 1.0);
      final arrowY = cy - maxRise * Curves.easeOutCubic.transform(arrowP);
      final arrowOpacity = progress < 0.5 ? 1.0 : (1 - (progress - 0.5) / 0.2).clamp(0.0, 1.0);
      final arrow = Path()
        ..moveTo(cx, arrowY - 6)
        ..lineTo(cx - 5, arrowY + 2)
        ..lineTo(cx + 5, arrowY + 2)
        ..close();
      canvas.drawPath(
        arrow,
        Paint()..color = color.withValues(alpha: arrowOpacity * 0.9),
      );
    }
  }

  // ── Radar: concentric pulse rings ──────────────────────────────────────

  void _paintRadar(Canvas canvas, double cx, double cy, Size size) {
    final maxR = size.width * 0.45;

    for (var i = 0; i < 3; i++) {
      final delay = i * 0.2;
      final localP = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (localP <= 0) continue;

      final opacity = (1.0 - localP).clamp(0.0, 1.0);
      final ringR = maxR * Curves.easeOutCubic.transform(localP);
      canvas.drawCircle(
        Offset(cx, cy),
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - localP)
          ..color = color.withValues(alpha: opacity * 0.7),
      );
    }

    // Sweep line
    if (progress < 0.8) {
      final sweepAngle = progress / 0.8 * pi * 2;
      final sweepR = maxR * 0.7;
      final px = cx + cos(sweepAngle - pi / 2) * sweepR;
      final py = cy + sin(sweepAngle - pi / 2) * sweepR;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(px, py),
        Paint()
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: (1 - progress) * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _JokerEffectPainter old) =>
      old.progress != progress || old.type != type;
}
