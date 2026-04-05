import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

class HudBar extends StatelessWidget {
  final int score;
  final int bestScore;
  final int shapeCount;
  final int mergeCount;

  const HudBar({
    super.key,
    required this.score,
    required this.bestScore,
    required this.shapeCount,
    required this.mergeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.panel.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _HudItem(label: 'Score', value: '$score', color: AppTheme.gold),
          _HudItem(label: 'Best', value: '$bestScore', color: AppTheme.blue),
          _HudItem(label: 'Shapes', value: '$shapeCount', color: AppTheme.green),
          _HudItem(label: 'Merges', value: '$mergeCount', color: AppTheme.purple),
        ],
      ),
    );
  }
}

class _HudItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HudItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: AppTheme.muted, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
