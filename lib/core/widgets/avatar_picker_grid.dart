import 'package:flutter/material.dart';
import 'package:shape_merge/core/config/avatar_catalog.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

/// Reusable avatar picker grid.
///
/// [selectedAvatarId] — currently selected avatar.
/// [onAvatarSelected] — called when the user taps an avatar.
/// [showCheckmark] — whether to overlay a checkmark on the selected avatar.
/// [spacing] — grid spacing between cells.
class AvatarPickerGrid extends StatelessWidget {
  final String? selectedAvatarId;
  final ValueChanged<String> onAvatarSelected;
  final bool showCheckmark;
  final double spacing;

  const AvatarPickerGrid({
    super.key,
    required this.selectedAvatarId,
    required this.onAvatarSelected,
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
        return GestureDetector(
          key: ValueKey(avatar.id),
          onTap: () => onAvatarSelected(avatar.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.gold.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
              border: Border.all(
                color: isSelected ? AppTheme.gold : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  avatar.emoji,
                  style: TextStyle(
                    fontSize: isSelected ? AppTheme.fontH1 : AppTheme.fontH2,
                  ),
                ),
                if (showCheckmark && isSelected)
                  const Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      Icons.check_circle,
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
