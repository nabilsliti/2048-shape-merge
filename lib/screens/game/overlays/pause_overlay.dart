import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback? onQuit;

  const PauseOverlay({super.key, required this.onResume, this.onQuit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      fit: StackFit.expand,
      children: [
        const SpaceBackground(darken: 0.5),
        Center(
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.panelBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(color: AppTheme.panelBorder, width: 3),
                boxShadow: const [
                  BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 8)),
                  BoxShadow(color: Colors.black54, offset: Offset(0, 12), blurRadius: 20),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pause icon — circular gradient like profile avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.profileGradTop, AppTheme.profileGradBot],
                      ),
                      border: Border.all(color: AppTheme.gold, width: 3),
                      boxShadow: [
                        BoxShadow(color: AppTheme.gold.withValues(alpha: 0.3), blurRadius: 12),
                      ],
                    ),
                    child: const Icon(Icons.pause_rounded, color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(l10n.pause.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontH4)),
                  const SizedBox(height: 20),

                  // Resume button
                  SizedBox(
                    width: double.infinity,
                    child: Button3D.green(
                      expand: true,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: () {
                        AudioService.instance.playButtonTap();
                        onResume();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PremiumIcon.resume(size: 28),
                          const SizedBox(width: 10),
                          Text(l10n.resume.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quit button
                  SizedBox(
                    width: double.infinity,
                    child: Button3D.red(
                      expand: true,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: () {
                        AudioService.instance.playButtonTap();
                        if (onQuit != null) {
                          onQuit!();
                        } else {
                          context.go('/home');
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PremiumIcon.home(size: 28),
                          const SizedBox(width: 10),
                          Text(l10n.quit.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -12,
              right: -12,
              child: Button3D.red(
                padding: const EdgeInsets.all(8),
                borderRadius: 20,
                onPressed: () {
                  AudioService.instance.playButtonTap();
                  onResume();
                },
                child: const PremiumIcon.close(size: 22),
              ),
            ),
          ]),
          ),
        ),
      ],
    );
  }
}
