import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shape_merge/core/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════
// Ad Reward Button — static pub image + glow + badges
// ═══════════════════════════════════════════════════════════════
class AdRewardGemButton extends StatelessWidget {
  const AdRewardGemButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 68,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
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
                      color: AppTheme.hubPurpleGlow.withValues(alpha: 0.25),
                      blurRadius: 22,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: AppTheme.gold.withValues(alpha: 0.1),
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
              child: Image.asset(
                'assets/images/pub.webp',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
            // "AD" badge top-right
            Positioned(
              top: -2,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.hubDangerRed1, AppTheme.hubDangerRed2],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
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
  }
}
