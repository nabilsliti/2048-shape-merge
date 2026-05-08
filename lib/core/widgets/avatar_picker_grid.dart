import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/config/avatar_catalog.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

/// Reusable avatar picker grid.
///
/// [selectedAvatarId] — currently selected avatar.
/// [onAvatarSelected] — called when the user taps an unlocked avatar.
/// [playerLevel] — current player level to determine which avatars are unlocked.
/// [showCheckmark] — whether to overlay a checkmark on the selected avatar.
/// [spacing] — grid spacing between cells.
class AvatarPickerGrid extends StatelessWidget {
  final String? selectedAvatarId;
  final ValueChanged<String> onAvatarSelected;
  final int playerLevel;
  final bool showCheckmark;
  final double spacing;

  const AvatarPickerGrid({
    super.key,
    required this.selectedAvatarId,
    required this.onAvatarSelected,
    required this.playerLevel,
    this.showCheckmark = false,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
      ),
      itemCount: AvatarCatalog.all.length,
      itemBuilder: (ctx, index) {
        final avatar = AvatarCatalog.all[index];
        final isSelected = avatar.id == selectedAvatarId;
        final isLocked = !avatar.isUnlocked(playerLevel);
        return GestureDetector(
          key: ValueKey(avatar.id),
          onTap: isLocked ? null : () => onAvatarSelected(avatar.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isLocked
                  ? Colors.white.withValues(alpha: 0.03)
                  : isSelected
                      ? AppTheme.gold.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
              border: Border.all(
                color: isLocked
                    ? Colors.white.withValues(alpha: 0.06)
                    : isSelected
                        ? AppTheme.gold
                        : Colors.white.withValues(alpha: 0.1),
                width: isSelected && !isLocked ? 2.5 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Emoji (dimmed when locked)
                Opacity(
                  opacity: isLocked ? 0.25 : 1.0,
                  child: Text(
                    avatar.emoji,
                    style: TextStyle(
                      fontSize: isSelected && !isLocked ? AppTheme.fontH1 : AppTheme.fontH2,
                    ),
                  ),
                ),
                // Lock overlay + level badge
                if (isLocked) ...[
                  const Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(Icons.lock_rounded, color: Colors.white54, size: 14),
                  ),
                  Positioned(
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Lvl ${avatar.unlockLevel}',
                        style: GoogleFonts.fredoka(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.gold,
                        ),
                      ),
                    ),
                  ),
                ],
                // Checkmark for selected
                if (showCheckmark && isSelected && !isLocked)
                  const Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.gold,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
