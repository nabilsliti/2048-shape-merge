import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/glass_card.dart';
import 'package:shape_merge/core/widgets/gradient_button.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/audio_provider.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final gameState = ref.watch(gameStateProvider);
    final soundOn = ref.watch(audioProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Sound toggle
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(
                          soundOn ? Icons.volume_up : Icons.volume_off,
                          color: AppTheme.muted,
                        ),
                        onPressed: () =>
                            ref.read(audioProvider.notifier).toggle(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('SHAPE\nMERGE', style: AppTheme.titleStyle, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    // Best score card
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      child: Column(
                        children: [
                          Text(
                            l10n.bestScore,
                            style: TextStyle(
                                color: AppTheme.muted, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${gameState.bestScore}',
                            style: AppTheme.scoreStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Play button
                    GradientButton(
                      label: '🎮 ${l10n.play}',
                      onPressed: () => context.go('/game'),
                      width: double.infinity,
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      icon: Icons.leaderboard,
                      label: '🏆 ${l10n.leaderboard}',
                      onTap: () => context.go('/leaderboard'),
                    ),
                    const SizedBox(height: 12),
                    _MenuButton(
                      icon: Icons.store,
                      label: '🃏 ${l10n.shop}',
                      onTap: () => context.go('/shop'),
                    ),
                    const SizedBox(height: 12),
                    _MenuButton(
                      icon: Icons.settings,
                      label: '⚙️ ${l10n.settings}',
                      onTap: () => context.go('/settings'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.text,
          side: const BorderSide(color: AppTheme.border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
