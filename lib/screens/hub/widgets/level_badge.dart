import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/services/progression_service.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';

/// Pill badge showing current player level — placed in TopHud.
class LevelBadge extends ConsumerWidget {
  const LevelBadge({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final player = ref.watch(playerProvider).valueOrNull;
    final localStorage = ref.watch(localStorageProvider).valueOrNull;

    final level = user != null
        ? (player?.level ?? localStorage?.playerLevel ?? 1)
        : (localStorage?.playerLevel ?? 1);

    return RetentionUI.levelBadge(level: level, levelShortLabel: AppLocalizations.of(context)!.levelShortLabel, onTap: onTap);
  }
}

/// Thin 3px XP progress bar shown directly below the TopHud.
class XpBar extends ConsumerWidget {
  const XpBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final player = ref.watch(playerProvider).valueOrNull;
    final localStorage = ref.watch(localStorageProvider).valueOrNull;

    final level = user != null
        ? (player?.level ?? localStorage?.playerLevel ?? 1)
        : (localStorage?.playerLevel ?? 1);
    final currentXP = user != null
        ? (player?.currentXP ?? localStorage?.currentXP ?? 0)
        : (localStorage?.currentXP ?? 0);

    final progress = ProgressionService.levelProgress(currentXP, level);
    final barColor = RetentionUI.xpBarColor(level);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      height: 3,
      child: RetentionUI.progressBar(value: progress, color: barColor, height: 3),
    );
  }
}
