import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shape_merge/core/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════
// Streak Calendar Button — static image with ripple + zoom when
// a reward is pending, to attract the player's attention.
// ═══════════════════════════════════════════════════════════════
class StreakFlameButton extends StatefulWidget {
  const StreakFlameButton({
    super.key,
    required this.streakCount,
    required this.dayLabel,
    this.hasReward = false,
    this.onTap,
  });

  final int streakCount;
  final String dayLabel;
  final bool hasReward;
  final VoidCallback? onTap;

  @override
  State<StreakFlameButton> createState() => _StreakFlameButtonState();
}

class _StreakFlameButtonState extends State<StreakFlameButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _ripple;

  @override
  void initState() {
    super.initState();
    _startRippleIfNeeded();
  }

  @override
  void didUpdateWidget(StreakFlameButton old) {
    super.didUpdateWidget(old);
    if (widget.hasReward != old.hasReward) {
      if (widget.hasReward) {
        _startRippleIfNeeded();
      } else {
        _ripple?.dispose();
        _ripple = null;
      }
    }
  }

  void _startRippleIfNeeded() {
    if (!widget.hasReward) return;
    _ripple?.dispose();
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ripple?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 56,
        height: 68,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Ripple radiation rings (only when reward pending)
            if (_ripple != null)
              Positioned(
                top: -10,
                left: -10,
                right: -10,
                bottom: 4,
                child: AnimatedBuilder(
                  animation: _ripple!,
                  builder: (context, _) {
                    final zoomT = Curves.easeInOutSine
                        .transform((_ripple!.value * 2).clamp(0.0, 1.0));
                    final scale = 1.0 + zoomT * 0.08 - (_ripple!.value > 0.5 ? (_ripple!.value - 0.5) * 0.16 : 0);
                    return Transform.scale(
                      scale: scale,
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _RadiationPainter(
                            progress: _ripple!.value,
                            color: AppTheme.streakColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            // Static glow behind image
            Positioned(
              top: 6,
              left: 4,
              right: 4,
              bottom: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.streakColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: AppTheme.hubPurpleGlow.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            // Calendar image + badge "1" (zoom together when reward pending)
            Positioned(
              top: 0,
              left: 2,
              right: 2,
              bottom: 0,
              child: _ripple != null
                  ? AnimatedBuilder(
                      animation: _ripple!,
                      builder: (context, child) {
                        final t = Curves.easeInOutSine
                            .transform((_ripple!.value * 2).clamp(0.0, 1.0));
                        final scale = 1.0 +
                            t * 0.08 -
                            (_ripple!.value > 0.5
                                ? (_ripple!.value - 0.5) * 0.16
                                : 0);
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: _calendarWithBadges(),
                    )
                  : _calendarWithBadges(),
            ),
          ],
        ),
      ),
    );

    return child;
  }

  Widget _calendarWithBadges() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Calendar image
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 14,
          child: Image.asset(
            'assets/images/calendar.webp',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
        // Streak count badge
        if (widget.streakCount > 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.hubStreakPurple1,
                      AppTheme.hubStreakPurple2,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${widget.streakCount}🔥',
                  style: GoogleFonts.fredoka(
                    fontSize: AppTheme.fontTiny,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        // Red notification badge
        if (widget.hasReward)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.hubDangerRed1, AppTheme.hubDangerRed2],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '1',
                  style: GoogleFonts.fredoka(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 3 concentric rings expanding outward — adapted from joker_orb.dart
class _RadiationPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadiationPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;

    for (var i = 0; i < 3; i++) {
      final delay = i * 0.15;
      final t = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final eased = Curves.easeOut.transform(t);
      final radius = maxRadius * 0.4 + maxRadius * 0.6 * eased;
      final opacity = (1.0 - eased) * 0.7;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - eased * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_RadiationPainter old) => progress != old.progress;
}
