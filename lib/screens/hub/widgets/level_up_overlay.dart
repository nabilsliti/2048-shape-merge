import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/services/progression_service.dart';
import 'package:shape_merge/providers/progression_provider.dart';

/// Overlay shown for 2.5s after a level-up.
/// Displayed as a Stack layer in MainHubScreen.
class LevelUpOverlay extends ConsumerWidget {
  const LevelUpOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(progressionProvider);
    if (result == null || result.levelsGained == 0) return const SizedBox.shrink();

    // Auto-dismiss after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      ref.read(progressionProvider.notifier).clearResult();
    });

    return _LevelUpContent(result: result);
  }
}

class _LevelUpContent extends StatelessWidget {
  const _LevelUpContent({required this.result});
  final ProgressionResult result;

  @override
  Widget build(BuildContext context) {
    final color = RetentionUI.xpBarColor(result.newLevel);

    return IgnorePointer(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
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
              Icon(RetentionUI.levelIcon, color: color, size: 48)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1, end: 1.2, duration: 700.ms, curve: Curves.easeInOut),

              const SizedBox(height: 12),

              Text(
                'NIVEAU ${result.newLevel} !',
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontH1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

              const SizedBox(height: 4),

              Text(
                '${ProgressionService.xpForLevel(result.newLevel - 1)} XP',
                style: GoogleFonts.nunito(fontSize: AppTheme.fontXSmall, color: color, fontWeight: FontWeight.w700),
              ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
            ],
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 300.ms),
      ),
    );
  }
}
