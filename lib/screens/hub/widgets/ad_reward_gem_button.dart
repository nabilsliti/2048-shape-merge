import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shape_merge/core/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════
// Ad Reward Button — premium floating pub image + glow
// ═══════════════════════════════════════════════════════════════
class AdRewardGemButton extends StatefulWidget {
  const AdRewardGemButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<AdRewardGemButton> createState() => _AdRewardGemButtonState();
}

class _AdRewardGemButtonState extends State<AdRewardGemButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
          final translateY = -2.5 + floatCurve * 5.0;
          final breathScale = 1.0 + floatCurve * 0.05;
          final glowAlpha = 0.15 + floatCurve * 0.25;

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
                            color: AppTheme.hubPurpleGlow.withValues(alpha: glowAlpha),
                            blurRadius: 22,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: AppTheme.gold.withValues(alpha: glowAlpha * 0.4),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Pub image
                  Positioned(
                    top: 0,
                    left: 2,
                    right: 2,
                    bottom: 14,
                    child: Transform.scale(
                      scale: breathScale,
                      child: Image.asset(
                        'assets/images/pub.webp',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  // "AD" badge top-right
                  Positioned(
                    top: -2,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.hubDangerRed1, AppTheme.hubDangerRed2],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 1.2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Text(
                        'AD',
                        style: GoogleFonts.fredoka(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  // "+1 🃏" label bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.hubStreakPurple1, AppTheme.hubStreakPurple2],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Text(
                          '+1 🃏',
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
