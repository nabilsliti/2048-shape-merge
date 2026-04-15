import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shape_merge/core/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════
// Streak Calendar Button — premium floating image + glow
// ═══════════════════════════════════════════════════════════════
class StreakFlameButton extends StatefulWidget {
  const StreakFlameButton({
    super.key,
    required this.streakCount,
    required this.dayLabel,
    this.onTap,
  });

  final int streakCount;
  final String dayLabel;
  final VoidCallback? onTap;

  @override
  State<StreakFlameButton> createState() => _StreakFlameButtonState();
}

class _StreakFlameButtonState extends State<StreakFlameButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: RepaintBoundary(
        child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) {
          final floatCurve = Curves.easeInOutSine.transform(_float.value);
          final translateY = -3.0 + floatCurve * 6.0;
          final breathScale = 1.0 + floatCurve * 0.04;
          final glowAlpha = 0.2 + floatCurve * 0.25;

          return Transform.translate(
            offset: Offset(0, translateY),
            child: SizedBox(
              width: 72,
              height: 84,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Glow behind image
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
                            color: AppTheme.streakColor.withValues(alpha: glowAlpha),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: AppTheme.hubPurpleGlow.withValues(alpha: glowAlpha * 0.5),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Calendar image
                  Positioned(
                    top: 0,
                    left: 2,
                    right: 2,
                    bottom: 14,
                    child: Transform.scale(
                      scale: breathScale,
                      child: Image.asset(
                        'assets/images/calendar.webp',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  // Streak count badge
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.hubAdRewardOrange1, AppTheme.hubAdRewardOrange2],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.streakColor.withValues(alpha: 0.6),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${widget.streakCount}🔥',
                          style: GoogleFonts.fredoka(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}
