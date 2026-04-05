import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/glass_card.dart';
import 'package:shape_merge/core/widgets/gradient_button.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';

class GameOverOverlay extends StatelessWidget {
  final int score;
  final int mergeCount;
  final int maxLevel;
  final bool isVictory;
  final bool isSignedIn;
  final VoidCallback onReplay;
  final VoidCallback onSignIn;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.mergeCount,
    required this.maxLevel,
    required this.isVictory,
    required this.isSignedIn,
    required this.onReplay,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.black54,
      child: Center(
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isVictory ? '🏆' : '💀',
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                isVictory ? l10n.victory : l10n.gameOver,
                style: AppTheme.titleStyle,
              ),
              const SizedBox(height: 20),
              Text(
                '$score',
                style: GoogleFonts.orbitron(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatChip(
                    label: l10n.merges,
                    value: '$mergeCount',
                    color: AppTheme.purple,
                  ),
                  const SizedBox(width: 16),
                  _StatChip(
                    label: l10n.maxLevel,
                    value: '$maxLevel',
                    color: AppTheme.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!isSignedIn) ...[
                GradientButton(
                  label: l10n.signInGoogle,
                  icon: Icons.login,
                  onPressed: onSignIn,
                  colors: [AppTheme.green, const Color(0xFF2E7D32)],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.signInToSave,
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              GradientButton(
                label: l10n.replay,
                icon: Icons.replay,
                onPressed: onReplay,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: Icon(Icons.home, color: AppTheme.muted),
                label: Text(l10n.menu, style: TextStyle(color: AppTheme.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: AppTheme.muted, fontSize: 11)),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
