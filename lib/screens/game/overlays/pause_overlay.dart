import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/audio_provider.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

class PauseOverlay extends ConsumerWidget {
  final VoidCallback onResume;
  final VoidCallback? onQuit;

  const PauseOverlay({super.key, required this.onResume, this.onQuit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final soundEnabled = ref.watch(audioProvider);
    final musicEnabled = ref.watch(musicProvider);
    final vibrationEnabled = ref.watch(vibrationProvider);

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
                        onResume();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PremiumIcon.resume(size: 28),
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
                        if (onQuit != null) {
                          onQuit!();
                        } else {
                          context.pop();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PremiumIcon.home(size: 28),
                          const SizedBox(width: 10),
                          Text(l10n.quit.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Audio toggles ─────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Button3D.blue(
                        padding: const EdgeInsets.all(10),
                        borderRadius: 12,
                        onPressed: () {
                          ref.read(musicProvider.notifier).toggle();
                        },
                        child: Icon(
                          musicEnabled ? Icons.music_note : Icons.music_off,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Button3D.blue(
                        padding: const EdgeInsets.all(10),
                        borderRadius: 12,
                        onPressed: () {
                          ref.read(audioProvider.notifier).toggle();
                        },
                        child: Icon(
                          soundEnabled ? Icons.volume_up : Icons.volume_off,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Button3D.blue(
                        padding: const EdgeInsets.all(10),
                        borderRadius: 12,
                        onPressed: () {
                          ref.read(vibrationProvider.notifier).toggle();
                        },
                        child: Icon(
                          vibrationEnabled ? Icons.vibration : Icons.phone_android,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
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
                  onResume();
                },
                child: PremiumIcon.close(size: 22),
              ),
            ),
          ]),
          ),
        ),
      ],
    );
  }
}
