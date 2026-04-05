import 'package:flutter/material.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

class CapacityBar extends StatelessWidget {
  final int current;

  const CapacityBar({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final ratio = current / maxShapes;
    final color = ratio < 0.6
        ? AppTheme.green
        : ratio < 0.85
            ? AppTheme.gold
            : AppTheme.red;

    return Container(
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: ratio.clamp(0.0, 1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
