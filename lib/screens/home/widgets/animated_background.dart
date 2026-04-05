import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_FloatingShape> _shapes;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    final rng = Random(42);
    _shapes = List.generate(12, (i) {
      return _FloatingShape(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 20 + rng.nextDouble() * 40,
        speed: 0.3 + rng.nextDouble() * 0.7,
        color: [AppTheme.blue, AppTheme.green, AppTheme.purple, AppTheme.gold][
            i % 4],
        isCircle: rng.nextBool(),
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
        return CustomPaint(
          painter: _BackgroundPainter(_shapes, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _FloatingShape {
  final double x;
  final double y;
  final double size;
  final double speed;
  final Color color;
  final bool isCircle;

  _FloatingShape({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    required this.isCircle,
  });
}

class _BackgroundPainter extends CustomPainter {
  final List<_FloatingShape> shapes;
  final double progress;

  _BackgroundPainter(this.shapes, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final shape in shapes) {
      final yOffset = ((shape.y + progress * shape.speed) % 1.2) - 0.1;
      final xPos = shape.x * size.width;
      final yPos = yOffset * size.height;

      final paint = Paint()
        ..color = shape.color.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;

      if (shape.isCircle) {
        canvas.drawCircle(Offset(xPos, yPos), shape.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(xPos, yPos),
                width: shape.size,
                height: shape.size),
            Radius.circular(shape.size * 0.2),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) =>
      old.progress != progress;
}
