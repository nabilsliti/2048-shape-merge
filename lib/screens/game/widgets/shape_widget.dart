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
  final bool isRadarHighlighted;
  final int radarGroupIndex;
  final bool isMergeResult;

  const ShapeWidget({
    super.key,
    required this.shape,
    this.isDragging = false,
    this.isHighlighted = false,
    this.isRadarHighlighted = false,
    this.radarGroupIndex = -1,
    this.isMergeResult = false,
  });

  @override
  State<ShapeWidget> createState() => _ShapeWidgetState();
}

class _ShapeWidgetState extends State<ShapeWidget>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _entranceController;
  late final List<_SpawnParticle> _spawnParticles;

  @override
  void initState() {
    super.initState();
    final rng = Random();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isMergeResult ? 400 : 600),
    );

    // Spawn particles for entrance sparkle effect
    _spawnParticles = List.generate(8, (i) {
      final angle = (i / 8) * pi * 2 + rng.nextDouble() * 0.5;
      return _SpawnParticle(
        angle: angle,
        speed: 20 + rng.nextDouble() * 35,
        size: 2 + rng.nextDouble() * 3,
      );
    });

    // Merge results appear immediately; others use stagger delay
    if (widget.isMergeResult) {
      _entranceController.forward();
    } else {
      Future.delayed(Duration(milliseconds: rng.nextInt(150)), () {
        if (mounted) _entranceController.forward();
      });
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = shapeSize(widget.shape.level);
    final scale = widget.isDragging ? 1.18 : 1.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _entranceController]),
      builder: (context, child) {
        final eT = _entranceController.value;

        // Entrance: scale bounce (punchier for merge results)
        final entranceScale = eT == 0
            ? 0.0
            : widget.isMergeResult
                ? Curves.easeOutBack.transform(eT)
                : Curves.elasticOut.transform(eT);
        // Entrance: quick fade in (done by 40%)
        final entranceOpacity = (eT / 0.4).clamp(0.0, 1.0);
        // Float: only after entrance finishes
        final floatOffset = widget.isDragging
            ? -8.0
            : (eT >= 1.0 ? sin(_floatController.value * pi) * 3.0 : 0.0);

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Transform.scale(
            scale: scale * entranceScale,
            child: Opacity(opacity: entranceOpacity, child: child),
          ),
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Spawn glow & sparkle particles
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _entranceController,
                builder: (context, _) {
                  final t = _entranceController.value;
                  if (t <= 0 || t >= 1) return const SizedBox.shrink();
                  return CustomPaint(
                    painter: _SpawnEffectPainter(
                      color: widget.shape.isWildcard
                          ? AppTheme.blueTop
                          : widget.shape.color,
                      progress: t,
                      particles: _spawnParticles,
                    ),
                  );
                },
              ),
            ),
            // Shape itself
            CustomPaint(
              size: Size(size, size),
              painter: _ShapePainter(
                shape: widget.shape,
                isDragging: widget.isDragging,
                isHighlighted: widget.isHighlighted,
                isRadarHighlighted: widget.isRadarHighlighted,
                radarGroupIndex: widget.radarGroupIndex,
              ),
              child: Center(
                child: Text(
                  '${widget.shape.value}',
                  style: AppTheme.titleStyle(
                    size * _fontScale(widget.shape.value),
                  ).copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _fontScale(int value) {
    final digits = value.toString().length;
    if (digits <= 2) return 0.38;
    if (digits == 3) return 0.30;
    return 0.24; // 4+ digits (1024, 2048, etc.)
  }
}

class _ShapePainter extends CustomPainter {
  final GameShape shape;
  final bool isDragging;
  final bool isHighlighted;
  final bool isRadarHighlighted;
  final int radarGroupIndex;

  // Distinct bright colors for each radar group
  static const _radarGroupColors = [
    Color(0xFFFFEA00), // yellow (original radar)
    Color(0xFF00E5FF), // cyan
    Color(0xFFFF4081), // pink
    Color(0xFF76FF03), // lime green
    Color(0xFFE040FB), // purple
    Color(0xFFFF6D00), // orange
    Color(0xFF00E676), // green
    Color(0xFF448AFF), // blue
  ];

  _ShapePainter({
    required this.shape,
    required this.isDragging,
    required this.isHighlighted,
    this.isRadarHighlighted = false,
    this.radarGroupIndex = -1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final color = shape.isWildcard ? AppTheme.blueTop : shape.color;
    final type = shape.type;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: isDragging ? 0.5 : 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.3);
    _drawPath(canvas, type, center, radius * 1.05, glowPaint);

    // Main fill with radial gradient (3D look)
    final fillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Color.lerp(color, Colors.white, 0.35)!,
          color,
          Color.lerp(color, Colors.black, 0.35)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    if (shape.isWildcard) {
      // Rainbow sweep for wildcards
      final rainbowPaint = Paint()
        ..shader = SweepGradient(
          colors: [
            AppTheme.blueTop,
            AppTheme.greenTop,
            AppTheme.orangeTop,
            AppTheme.redTop,
            AppTheme.purpleTop,
            AppTheme.blueTop,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      _drawPath(canvas, type, center, radius, rainbowPaint);
    } else {
      _drawPath(canvas, type, center, radius, fillPaint);
    }

    // Crisp border stroke
    final borderPaint = Paint()
      ..color = Color.lerp(color, Colors.white, 0.6)!.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _drawPath(canvas, type, center, radius, borderPaint);

    // Specular highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      center + Offset(-radius * 0.2, -radius * 0.25),
      radius * 0.18,
      highlightPaint,
    );

    // Highlighted merge target ring
    if (isHighlighted) {
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, radius + 4, ringPaint);
    }

    // Radar highlight ring (colored per group)
    if (isRadarHighlighted) {
      final groupColor = radarGroupIndex >= 0
          ? _radarGroupColors[radarGroupIndex % _radarGroupColors.length]
          : AppTheme.radarColor;
      final radarPaint = Paint()
        ..color = groupColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(center, radius + 6, radarPaint);
      // Soft glow in group color
      final glowRadar = Paint()
        ..color = groupColor.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, radius + 6, glowRadar);
    }
  }

  void _drawPath(Canvas canvas, ShapeType type, Offset center, double radius, Paint paint) {
    switch (type) {
      case ShapeType.circle:
        canvas.drawCircle(center, radius, paint);
      case ShapeType.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: radius * 1.7, height: radius * 1.7),
            Radius.circular(radius * 0.15),
          ),
          paint,
        );

      case ShapeType.triangle:
        final triPath = _roundedPolygonPath([
          Offset(center.dx, center.dy - radius),
          Offset(center.dx + radius * 0.87, center.dy + radius * 0.5),
          Offset(center.dx - radius * 0.87, center.dy + radius * 0.5),
        ], radius * 0.12);
        canvas.drawPath(triPath, paint);
      case ShapeType.diamond:
        final diaPath = _roundedPolygonPath([
          Offset(center.dx, center.dy - radius),
          Offset(center.dx + radius * 0.7, center.dy),
          Offset(center.dx, center.dy + radius),
          Offset(center.dx - radius * 0.7, center.dy),
        ], radius * 0.10);
        canvas.drawPath(diaPath, paint);
      case ShapeType.star:
        final path = _starPath(center, radius, 5);
        canvas.drawPath(path, paint);
      case ShapeType.hexagon:
        final path = _roundedRegularPolygonPath(center, radius, 6, radius * 0.10);
        canvas.drawPath(path, paint);
    }
  }

  static Path _starPath(Offset center, double outerRadius, int points) {
    final path = Path();
    final innerRadius = outerRadius * 0.45;
    final totalPoints = points * 2;
    for (var i = 0; i < totalPoints; i++) {
      final angle = (i * pi / points) - (pi / 2);
      final r = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    path.close();
    return path;
  }

  /// Rounded polygon from a list of vertices.
  static Path _roundedPolygonPath(List<Offset> vertices, double cornerRadius) {
    final path = Path();
    final n = vertices.length;
    for (var i = 0; i < n; i++) {
      final prev = vertices[(i - 1 + n) % n];
      final curr = vertices[i];
      final next = vertices[(i + 1) % n];
      // Direction vectors from current vertex
      final dPrev = (prev - curr);
      final dNext = (next - curr);
      final lenPrev = dPrev.distance;
      final lenNext = dNext.distance;
      final r = cornerRadius.clamp(0.0, (lenPrev / 2).clamp(0.0, lenNext / 2));
      final pStart = curr + dPrev / lenPrev * r;
      final pEnd = curr + dNext / lenNext * r;
      if (i == 0) {
        path.moveTo(pStart.dx, pStart.dy);
      } else {
        path.lineTo(pStart.dx, pStart.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, pEnd.dx, pEnd.dy);
    }
    path.close();
    return path;
  }

  /// Rounded regular polygon (e.g. hexagon with rounded corners).
  static Path _roundedRegularPolygonPath(Offset center, double radius, int sides, double cornerRadius) {
    final vertices = <Offset>[];
    for (var i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - (pi / 2);
      vertices.add(Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)));
    }
    return _roundedPolygonPath(vertices, cornerRadius);
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) =>
      oldDelegate.isHighlighted != isHighlighted ||
      oldDelegate.isDragging != isDragging ||
      oldDelegate.isRadarHighlighted != isRadarHighlighted ||
      oldDelegate.radarGroupIndex != radarGroupIndex;
}

// ─── Spawn entrance effect ───────────────────────────────────────────

class _SpawnParticle {
  final double angle;
  final double speed;
  final double size;
  _SpawnParticle({required this.angle, required this.speed, required this.size});
}

class _SpawnEffectPainter extends CustomPainter {
  final Color color;
  final double progress;
  final List<_SpawnParticle> particles;

  _SpawnEffectPainter({
    required this.color,
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // 1. Expanding coloured glow (peaks at ~30%, then fades)
    final glowT = progress < 0.3
        ? progress / 0.3
        : 1.0 - ((progress - 0.3) / 0.7);
    final glowOpacity = glowT.clamp(0.0, 1.0) * 0.6;
    final glowRadius = radius * (1.0 + progress * 0.8);
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..color = color.withValues(alpha: glowOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5),
    );

    // 2. White core flash (first 20%)
    if (progress < 0.2) {
      final flashOpacity = (1.0 - progress / 0.2) * 0.5;
      canvas.drawCircle(
        center,
        radius * 0.5,
        Paint()
          ..color = Colors.white.withValues(alpha: flashOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // 3. Sparkle particles scatter outward
    if (progress > 0.1) {
      final pT = ((progress - 0.1) / 0.9).clamp(0.0, 1.0);
      final pOpacity = (1.0 - pT).clamp(0.0, 1.0);

      for (final p in particles) {
        final dist = p.speed * Curves.easeOut.transform(pT);
        final px = center.dx + cos(p.angle) * (radius + dist);
        final py = center.dy + sin(p.angle) * (radius + dist);
        final pSize = p.size * (1 - pT * 0.6);

        // Coloured glow
        canvas.drawCircle(
          Offset(px, py),
          pSize,
          Paint()
            ..color = color.withValues(alpha: pOpacity * 0.7)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, pSize * 0.8),
        );
        // Bright white core
        canvas.drawCircle(
          Offset(px, py),
          pSize * 0.4,
          Paint()..color = Colors.white.withValues(alpha: pOpacity * 0.9),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpawnEffectPainter old) =>
      old.progress != progress;
}
