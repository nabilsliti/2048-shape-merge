import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;

  const PauseOverlay({super.key, required this.onResume});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      fit: StackFit.expand,
      children: [
        const SpaceBackground(darken: 0.5),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pause icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.panelBg,
                    border: Border.all(color: AppTheme.panelBorder, width: 4),
                    boxShadow: [
                      BoxShadow(color: AppTheme.purpleTop.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 2),
                      const BoxShadow(color: Color(0xFF111827), offset: Offset(0, 6)),
                      const BoxShadow(color: Colors.black54, offset: Offset(0, 12), blurRadius: 16),
                    ],
                  ),
                  child: const Icon(Icons.pause, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 20),
                Text("PAUSE", style: AppTheme.titleStyle(48)),
                const SizedBox(height: 32),

                // Panel card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.panelBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.panelBorder, width: 4),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF111827), offset: Offset(0, 8)),
                      BoxShadow(color: Colors.black54, offset: Offset(0, 15), blurRadius: 20),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Button3D.green(
                          expand: true,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onPressed: onResume,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const PremiumIcon.resume(size: 28),
                              const SizedBox(width: 10),
                              Text(l10n.resume.toUpperCase(), style: AppTheme.titleStyle(18)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: Button3D.red(
                          expand: true,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onPressed: () => context.go('/home'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const PremiumIcon.home(size: 28),
                              const SizedBox(width: 10),
                              Text(l10n.quit.toUpperCase(), style: AppTheme.titleStyle(18)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
