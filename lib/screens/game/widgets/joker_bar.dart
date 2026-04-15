import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/screens/game/widgets/joker_orb.dart';

class JokerBar extends ConsumerWidget {
  final JokerInventory inventory;

  const JokerBar({super.key, required this.inventory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(jokerModeProvider);
    final suggestedType = ref.watch(jokerSuggestionProvider);
    final emptyTap = ref.watch(jokerEmptyTapProvider);
    final inv = inventory;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            JokerOrb(
            jokerType: JokerType.bomb,
            icon: JokerUI.icon(JokerType.bomb, size: 18),
            count: inv.bomb,
            isActive: currentMode == JokerMode.bomb,
            isSuggested: suggestedType == JokerType.bomb,
            glowColor: JokerUI.glowColor(JokerType.bomb),
            ringColors: JokerUI.ringColors(JokerType.bomb),
            onTap: () => _toggle(ref, JokerMode.bomb),
            emptyTapTrigger: currentMode == JokerMode.bomb ? emptyTap : 0,
          ),
          JokerOrb(
            jokerType: JokerType.wildcard,
            icon: JokerUI.icon(JokerType.wildcard, size: 18),
            count: inv.wildcard,
            isActive: currentMode == JokerMode.wildcard,
            isSuggested: suggestedType == JokerType.wildcard,
            glowColor: JokerUI.glowColor(JokerType.wildcard),
            ringColors: JokerUI.ringColors(JokerType.wildcard),
            onTap: () => _toggle(ref, JokerMode.wildcard),
            emptyTapTrigger: currentMode == JokerMode.wildcard ? emptyTap : 0,
          ),
          JokerOrb(
            jokerType: JokerType.reducer,
            icon: JokerUI.icon(JokerType.reducer, size: 16),
            count: inv.reducer,
            isActive: currentMode == JokerMode.reducer,
            isSuggested: suggestedType == JokerType.reducer,
            glowColor: JokerUI.glowColor(JokerType.reducer),
            ringColors: JokerUI.ringColors(JokerType.reducer),
            onTap: () => _toggle(ref, JokerMode.reducer),
            emptyTapTrigger: currentMode == JokerMode.reducer ? emptyTap : 0,
          ),
          // ── séparateur premium ──
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 1, height: 20, color: AppTheme.gold.withValues(alpha: 0.5)),
              const SizedBox(height: 2),
              Text('★', style: TextStyle(fontSize: AppTheme.fontMicro, color: AppTheme.gold.withValues(alpha: 0.8))),
              const SizedBox(height: 2),
              Container(width: 1, height: 20, color: AppTheme.gold.withValues(alpha: 0.5)),
            ],
          ),
          JokerOrb(
            jokerType: JokerType.radar,
            icon: JokerUI.icon(JokerType.radar, size: 16),
            count: inv.radar,
            isActive: currentMode == JokerMode.radar,
            isSuggested: suggestedType == JokerType.radar,
            glowColor: JokerUI.glowColor(JokerType.radar),
            ringColors: JokerUI.ringColors(JokerType.radar),
            onTap: () => _activateRadar(ref),
            isPremium: true,
            emptyTapTrigger: currentMode == JokerMode.radar ? emptyTap : 0,
          ),
          JokerOrb(
            jokerType: JokerType.evolution,
            icon: JokerUI.icon(JokerType.evolution, size: 16),
            count: inv.evolution,
            isActive: currentMode == JokerMode.evolution,
            isSuggested: suggestedType == JokerType.evolution,
            glowColor: JokerUI.glowColor(JokerType.evolution),
            ringColors: JokerUI.ringColors(JokerType.evolution),
            onTap: () => _toggle(ref, JokerMode.evolution),
            isPremium: true,
            emptyTapTrigger: currentMode == JokerMode.evolution ? emptyTap : 0,
          ),
          JokerOrb(
            jokerType: JokerType.megaBomb,
            icon: JokerUI.icon(JokerType.megaBomb, size: 16),
            count: inv.megaBomb,
            isActive: currentMode == JokerMode.megaBomb,
            isSuggested: suggestedType == JokerType.megaBomb,
            glowColor: JokerUI.glowColor(JokerType.megaBomb),
            ringColors: JokerUI.ringColors(JokerType.megaBomb),
            onTap: () => _toggle(ref, JokerMode.megaBomb),
            isPremium: true,
            emptyTapTrigger: currentMode == JokerMode.megaBomb ? emptyTap : 0,
          ),
        ],
      ),
    );
  }

  void _toggle(WidgetRef ref, JokerMode mode) {
    final current = ref.read(jokerModeProvider);
    ref.read(jokerModeProvider.notifier).state =
        current == mode ? JokerMode.none : mode;
  }

  void _activateRadar(WidgetRef ref) {
    final current = ref.read(jokerModeProvider);
    // Désélectionner tout joker actif avant d'activer le radar
    if (current != JokerMode.none) {
      ref.read(jokerModeProvider.notifier).state = JokerMode.none;
    }
    ref.read(gameStateProvider.notifier).activateRadar();
  }
}
