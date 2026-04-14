import 'dart:math';
import 'package:flutter/material.dart';

class MergeEffect extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback onComplete;

  const MergeEffect({
    super.key,
    required this.position,
    required this.color,
    required this.onComplete,
  });

  @override
  State<MergeEffect> createState() => _MergeEffectState();
}

class _MergeEffectState extends State<MergeEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward().then((_) => widget.onComplete());

    final rng = Random();
    _particles = List.generate(12, (i) {
      final angle = (i / 12) * pi * 2 + rng.nextDouble() * 0.5;
      final speed = 40 + rng.nextDouble() * 60;
      return _Particle(
        angle: angle,
        speed: speed,
        size: 3 + rng.nextDouble() * 5,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final scale = 1.0 + Curves.easeOutCubic.transform(t) * 3.5;
        const baseSize = 40.0;
        final finalSize = baseSize * scale;

        return Positioned(
          left: widget.position.dx - finalSize / 2 - 20,
          top: widget.position.dy - finalSize / 2 - 20,
          child: SizedBox(
            width: finalSize + 40,
            height: finalSize + 40,
            child: CustomPaint(
              painter: _MergeParticlePainter(
                color: widget.color,
                progress: t,
                particles: _particles,
                ringSize: finalSize,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;

  _Particle({required this.angle, required this.speed, required this.size});
}

class _MergeParticlePainter extends CustomPainter {
  final Color color;
  final double progress;
  final List<_Particle> particles;
  final double ringSize;

  _MergeParticlePainter({
    required this.color,
    required this.progress,
    required this.particles,
    required this.ringSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    // Inner flash (white core)
    if (progress < 0.3) {
      final flashOpacity = (1.0 - progress / 0.3).clamp(0.0, 1.0);
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: flashOpacity * 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, 15 * (1 + progress * 2), flashPaint);
    }

    // Expanding ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + progress * 8);
    canvas.drawCircle(center, ringSize / 2, ringPaint);

    // Second ring (slower, wider)
    if (progress > 0.1) {
      final ring2Progress = ((progress - 0.1) / 0.9).clamp(0.0, 1.0);
      final ring2Paint = Paint()
        ..color = color.withValues(alpha: (1 - ring2Progress) * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1 - ring2Progress);
      canvas.drawCircle(
        center,
        ringSize / 2 + ring2Progress * 20,
        ring2Paint,
      );
    }

    // Particles flying outward
    for (final p in particles) {
      final dist = p.speed * Curves.easeOut.transform(progress);
      final px = center.dx + cos(p.angle) * dist;
      final py = center.dy + sin(p.angle) * dist;
      final pSize = p.size * (1 - progress * 0.5);

      final pPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.8)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, pSize * 0.5);
      canvas.drawCircle(Offset(px, py), pSize, pPaint);

      // Bright core
      canvas.drawCircle(
        Offset(px, py),
        pSize * 0.4,
        Paint()..color = Colors.white.withValues(alpha: opacity * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MergeParticlePainter old) =>
      old.progress != progress;
}
