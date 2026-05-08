import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/services/progression_service.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/progression_provider.dart';

/// Overlay shown for 2.5s after a level-up.
/// Displayed as a Stack layer in MainHubScreen.
class LevelUpOverlay extends ConsumerStatefulWidget {
  const LevelUpOverlay({super.key});

  @override
  ConsumerState<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends ConsumerState<LevelUpOverlay> {
  int? _shownLevel;

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(progressionProvider);
    if (result == null || result.levelsGained == 0) {
      _shownLevel = null;
      return const SizedBox.shrink();
    }

    // Only schedule dismiss once per level-up (guard against rebuild re-triggers)
    if (_shownLevel != result.newLevel) {
      _shownLevel = result.newLevel;
      AudioService.instance.playLevelUp();
      Future.delayed(const Duration(milliseconds: 5500), () {
        if (mounted) ref.read(progressionProvider.notifier).clearResult();
      });
    }

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
                AppLocalizations.of(context)!.levelUp(result.newLevel),
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontH1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

              const SizedBox(height: 4),

              Text(
                AppLocalizations.of(context)!.xpAmount(ProgressionService.xpForLevel(result.newLevel - 1)),
                style: GoogleFonts.nunito(fontSize: AppTheme.fontXSmall, color: color, fontWeight: FontWeight.w700),
              ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

              if (result.rewards.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final (type, amount) in result.rewards)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          JokerUI.icon(type, size: 22),
                          const SizedBox(width: 3),
                          Text(
                            AppLocalizations.of(context)!.rewardPlusN(amount),
                            style: GoogleFonts.fredoka(
                              fontSize: AppTheme.fontBody,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.gold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
              ],
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
