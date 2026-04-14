import 'package:flutter/material.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

/// Reusable game panel — ClipRRect + SpaceBackground + border overlay.
/// Used for HUD, game board, joker bar, and overlays.
class GamePanel extends StatelessWidget {
  final Widget child;
  final bool lite;

  const GamePanel({super.key, required this.child, this.lite = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXTiny),
      child: Stack(
        children: [
          Positioned.fill(child: SpaceBackground(lite: lite)),
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXTiny),
                  border: Border.all(
                    color: AppTheme.panelBorder.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
