part of '../home_screen.dart';

// ═══════════════════════════════════════════════════════════════
// Icon shape types for mode buttons
// ═══════════════════════════════════════════════════════════════
enum _IconShape { circle, triangle, square, hexagon }

// ═══════════════════════════════════════════════════════════════
// Mode Island — shape-rush style game mode card with press effect
// ═══════════════════════════════════════════════════════════════
class _ModeIsland extends StatefulWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color topBg;
  final Color botBg;
  final Color iconColor;
  final _IconShape iconShape;
  final VoidCallback onTap;

  const _ModeIsland({
    required this.title,
    required this.desc,
    required this.icon,
    required this.topBg,
    required this.botBg,
    required this.iconColor,
    required this.iconShape,
    required this.onTap,
  });

  @override
  State<_ModeIsland> createState() => _ModeIslandState();
}

class _ModeIslandState extends State<_ModeIsland> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(top: _isPressed ? 4 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: widget.topBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: widget.botBg.withValues(alpha: 0.5),
                offset: Offset(0, _isPressed ? 1 : 3),
                blurRadius: 0),
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: Offset(0, _isPressed ? 2 : 4),
                blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CustomPaint(
                painter: _IconShapePainter(widget.iconShape),
                child: Center(
                  child: Icon(widget.icon,
                      size: 28,
                      color: widget.iconColor,
                      shadows: const [
                        Shadow(
                            color: Colors.black38,
                            offset: Offset(0, 4),
                            blurRadius: 6)
                      ]),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: GoogleFonts.nunito(
                          fontSize: AppTheme.fontH3,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                                color: Colors.black38, offset: Offset(2, 2))
                          ])),
                  Text(widget.desc,
                      style: GoogleFonts.nunito(
                          fontSize: AppTheme.fontTiny,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Painter for geometric icon borders
// ═══════════════════════════════════════════════════════════════
class _IconShapePainter extends CustomPainter {
  final _IconShape shape;
  _IconShapePainter(this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    switch (shape) {
      case _IconShape.circle:
        canvas.drawCircle(Offset(cx, cy), r, fillPaint);
        canvas.drawCircle(Offset(cx, cy), r, borderPaint);

      case _IconShape.triangle:
        final tr = r * 1.25;
        final tyOff = cy + 2;
        final path = Path();
        for (var i = 0; i < 3; i++) {
          final a = (i * math.pi * 2 / 3) - math.pi / 2;
          final px = cx + math.cos(a) * tr;
          final py = tyOff + math.sin(a) * tr;
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);

      case _IconShape.square:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, cy), width: r * 1.8, height: r * 1.8),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, fillPaint);
        canvas.drawRRect(rect, borderPaint);

      case _IconShape.hexagon:
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final a = (i * math.pi / 3) - math.pi / 2;
          final px = cx + math.cos(a) * r;
          final py = cy + math.sin(a) * r;
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
  }

  @override
  bool shouldRepaint(_IconShapePainter old) => old.shape != shape;
}

// ── Animated rocket with subtle hover + tilt ────────────────────
class _AnimatedRocket extends StatefulWidget {
  const _AnimatedRocket({required this.size});
  final double size;

  @override
  State<_AnimatedRocket> createState() => _AnimatedRocketState();
}

class _AnimatedRocketState extends State<_AnimatedRocket>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        // Hover: bottom (+5) to top (-5)
        final dy = 5.0 - t * 10.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: PremiumIcon.rocket(size: widget.size),
    );
  }
}

/// Button styled exactly like the level badge chip (same gradient, border, boxShadow)
/// with press-down effect matching the play button style.
class _LevelBadgeButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const _LevelBadgeButton({this.onPressed, required this.child});

  @override
  State<_LevelBadgeButton> createState() => _LevelBadgeButtonState();
}

class _LevelBadgeButtonState extends State<_LevelBadgeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          HapticFeedback.lightImpact();
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (widget.onPressed != null) {
          setState(() => _isPressed = false);
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (widget.onPressed != null) {
          setState(() => _isPressed = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.all(4),
        margin: EdgeInsets.only(top: _isPressed ? 4 : 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.xpBadgeTop, AppTheme.xpBadgeBot],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.xpBadgeBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.xpBadgeBot.withValues(alpha: 0.55),
              blurRadius: _isPressed ? 6 : 14,
              offset: Offset(0, _isPressed ? 1 : 4),
            ),
            BoxShadow(
              color: Colors.black54,
              offset: Offset(0, _isPressed ? 2 : 5),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
