import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

class CapacityBar extends StatelessWidget {
  final int current;

  const CapacityBar({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final ratio = current / maxShapes;
    final color = ratio < 0.6
        ? AppTheme.greenTop
        : ratio < 0.85
            ? AppTheme.orangeTop
            : AppTheme.redTop;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$current / $maxShapes',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              if (ratio >= 0.85)
                Text(
                  '⚠ FULL SOON',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.redTop,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.panelBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.panelBorder.withValues(alpha: 0.4), width: 1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
