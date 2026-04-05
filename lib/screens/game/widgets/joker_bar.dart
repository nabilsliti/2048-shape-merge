import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/providers/game_state_provider.dart';

class JokerBar extends ConsumerWidget {
  final JokerInventory inventory;

  const JokerBar({super.key, required this.inventory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(jokerModeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.panel.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _JokerButton(
            icon: '💣',
            label: 'Bomb',
            count: inventory.bomb,
            isActive: currentMode == JokerMode.bomb,
            onTap: () => _toggleJoker(ref, JokerMode.bomb),
          ),
          _JokerButton(
            icon: '🌀',
            label: 'Wild',
            count: inventory.wildcard,
            isActive: currentMode == JokerMode.wildcard,
            onTap: () => _toggleJoker(ref, JokerMode.wildcard),
          ),
          _JokerButton(
            icon: '⬇️',
            label: 'Reduce',
            count: inventory.reducer,
            isActive: currentMode == JokerMode.reducer,
            onTap: () => _toggleJoker(ref, JokerMode.reducer),
          ),
        ],
      ),
    );
  }

  void _toggleJoker(WidgetRef ref, JokerMode mode) {
    final current = ref.read(jokerModeProvider);
    ref.read(jokerModeProvider.notifier).state =
        current == mode ? JokerMode.none : mode;
  }
}

class _JokerButton extends StatelessWidget {
  final String icon;
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _JokerButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: count > 0 ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.blue.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.blue : AppTheme.border,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                color: count > 0 ? AppTheme.text : AppTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
