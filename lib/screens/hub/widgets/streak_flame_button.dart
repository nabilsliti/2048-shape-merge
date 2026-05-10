import 'dart:async';

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
    this.rewardClaimed = false,
    this.onTap,
  });

  final int streakCount;
  final String dayLabel;
  final bool hasReward;
  final bool rewardClaimed;
  final VoidCallback? onTap;

  @override
  State<StreakFlameButton> createState() => _StreakFlameButtonState();
}

class _StreakFlameButtonState extends State<StreakFlameButton>
    with TickerProviderStateMixin {
  AnimationController? _zoom;
  Timer? _clockTimer;
  String _countdown = '';

  @override
  void initState() {
    super.initState();
    _startZoomIfNeeded();
    _startClockIfNeeded();
  }

  @override
  void didUpdateWidget(StreakFlameButton old) {
    super.didUpdateWidget(old);
    if (widget.hasReward != old.hasReward) {
      if (widget.hasReward) {
        _startZoomIfNeeded();
      } else {
        _zoom?.dispose();
        _zoom = null;
      }
    }
    if (widget.rewardClaimed != old.rewardClaimed) {
      if (widget.rewardClaimed) {
        _startClockIfNeeded();
      } else {
        _clockTimer?.cancel();
        _clockTimer = null;
      }
    }
  }

  void _startZoomIfNeeded() {
    if (!widget.hasReward) return;
    _zoom?.dispose();
    _zoom = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _zoom?.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClockIfNeeded() {
    if (!widget.rewardClaimed) return;
    _updateCountdown();
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (mounted) setState(() => _countdown = '${h}h ${m.toString().padLeft(2, '0')}m');
  }

  static const _circleSize = 60.0;

  @override
  Widget build(BuildContext context) {
    // When the daily reward is already claimed, swap the badge below the
    // circle to the red countdown style used by AdRewardGemButton during
    // cooldown — so the user instantly sees it's blocked until midnight.
    final blocked = widget.rewardClaimed;

    final content = GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 70,
        height: 82,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Circle button
            _circleContent(),

            // Streak count / countdown badge — below circle
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
                      gradient: LinearGradient(
                        colors: blocked
                            ? const [
                                AppTheme.hubDangerRed1,
                                AppTheme.hubDangerRed2,
                              ]
                            : const [
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
                      blocked ? _countdown : '${widget.streakCount}🔥',
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.fredoka(
                        fontSize: blocked ? 9 : AppTheme.fontTiny,
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
                top: -2,
                right: 2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.hubDangerRed1,
                        AppTheme.hubDangerRed2,
                      ],
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
        ),
      ),
    );

    if (_zoom != null) {
      return AnimatedBuilder(
        animation: _zoom!,
        builder: (context, child) {
          final t = Curves.easeInOutSine
              .transform((_zoom!.value * 2).clamp(0.0, 1.0));
          final scale = 1.0 +
              t * 0.06 -
              (_zoom!.value > 0.5 ? (_zoom!.value - 0.5) * 0.12 : 0);
          return Transform.scale(scale: scale, child: child);
        },
        child: content,
      );
    }
    return content;
  }

  Widget _circleContent() {
    return Container(
      width: _circleSize,
      height: _circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.navActiveCircle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          const BoxShadow(
            color: AppTheme.navActiveShadow,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          'assets/images/calendar.webp',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
