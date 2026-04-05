import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/constants/shape_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

class ShapeWidget extends StatefulWidget {
  final GameShape shape;
  final bool isDragging;
  final bool isHighlighted;

  const ShapeWidget({
    super.key,
    required this.shape,
    this.isDragging = false,
    this.isHighlighted = false,
  });

  @override
  State<ShapeWidget> createState() => _ShapeWidgetState();
}

class _ShapeWidgetState extends State<ShapeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = shapeSize(widget.shape.level);
    final scale = widget.isDragging ? 1.18 : 1.0;

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final floatOffset =
            widget.isDragging ? 0.0 : sin(_floatController.value * pi) * 2.5;
        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: _buildShape(size),
    );
  }

  Widget _buildShape(double size) {
    final color = widget.shape.isWildcard ? null : widget.shape.color;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: widget.shape.isWildcard
            ? const SweepGradient(colors: [
                AppTheme.blue,
                AppTheme.green,
                AppTheme.purple,
                AppTheme.gold,
                AppTheme.blue,
              ])
            : null,
        color: color,
        shape: widget.shape.type == ShapeType.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: widget.shape.type == ShapeType.square
            ? BorderRadius.circular(8)
            : widget.shape.type == ShapeType.hexagon
                ? BorderRadius.circular(size * 0.2)
                : null,
        boxShadow: [
          BoxShadow(
            color: (color ?? AppTheme.blue)
                .withValues(alpha: widget.isDragging ? 0.6 : 0.3),
            blurRadius: widget.isDragging ? 20 : 8,
            spreadRadius: widget.isDragging ? 4 : 1,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ShapeDetailsPainter(
          shape: widget.shape,
          isHighlighted: widget.isHighlighted,
        ),
        child: Center(
          child: Text(
            '${widget.shape.value}',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(blurRadius: 4, color: Colors.black54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapeDetailsPainter extends CustomPainter {
  final GameShape shape;
  final bool isHighlighted;

  _ShapeDetailsPainter({required this.shape, required this.isHighlighted});

  @override
  void paint(Canvas canvas, Size size) {
    if (shape.type == ShapeType.star) {
      _drawStar(canvas, size);
    }

    if (isHighlighted) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(
        size.center(Offset.zero),
        size.width / 2 + 4,
        paint,
      );
    }

    // 3D highlight
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    if (shape.type == ShapeType.circle) {
      canvas.drawCircle(
        Offset(size.width * 0.35, size.height * 0.35),
        size.width * 0.2,
        highlightPaint,
      );
    }
  }

  void _drawStar(Canvas canvas, Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = outerR * 0.4;

    for (var i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;
      final ox = cx + outerR * cos(outerAngle);
      final oy = cy + outerR * sin(outerAngle);
      final ix = cx + innerR * cos(innerAngle);
      final iy = cy + innerR * sin(innerAngle);

      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();

    final paint = Paint()
      ..color = shape.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ShapeDetailsPainter oldDelegate) =>
      oldDelegate.isHighlighted != isHighlighted;
}
