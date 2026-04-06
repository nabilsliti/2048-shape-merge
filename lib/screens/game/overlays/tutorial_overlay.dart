import 'package:flutter/material.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({required this.onDismiss, super.key});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const SpaceBackground(darken: 0.6),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.panelBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.panelBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.purpleTop.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
                const BoxShadow(
                  color: Colors.black54,
                  offset: Offset(0, 8),
                  blurRadius: 16,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    '🧬 SHAPE MERGE 2048',
                    style: AppTheme.titleStyle(24),
                  ),
                  const SizedBox(height: 20),

                  // Objectif
                  const _InstructionRow(
                    icon: '🎯',
                    label: 'OBJECTIF',
                    text: 'Fusionne les formes identiques (même forme + même couleur + même niveau) pour monter de niveau et atteindre le score max !',
                  ),
                  const SizedBox(height: 14),

                  // Contrôles
                  const _InstructionRow(
                    icon: '🕹️',
                    label: 'CONTRÔLES',
                    text: '👆 Glisse une forme sur une forme identique pour fusionner. Si pas de match, elle revient à sa place.',
                  ),
                  const SizedBox(height: 14),

                  // Jokers
                  _JokerSection(),
                  const SizedBox(height: 14),

                  // Game Over
                  const _InstructionRow(
                    icon: '💀',
                    label: 'FIN DE PARTIE',
                    text: 'Le plateau se remplit à chaque mouvement. Plus de place + aucune fusion possible = Game Over !',
                  ),
                  const SizedBox(height: 24),

                  // GO button
                  Button3D.green(
                    onPressed: onDismiss,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 14,
                    ),
                    child: Text('GO !', style: AppTheme.titleStyle(24)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({
    required this.icon,
    required this.label,
    required this.text,
  });

  final String icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JokerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🃏', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'JOKERS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              _jokerRow(const JokerIcon.bomb(size: 22), 'Bombe', 'Détruit une forme'),
              const SizedBox(height: 6),
              _jokerRow(const JokerIcon.wildcard(size: 22), 'Wildcard', 'Fusionne avec n\'importe quelle forme'),
              const SizedBox(height: 6),
              _jokerRow(const JokerIcon.reducer(size: 18), 'Réducteur', 'Baisse le niveau d\'une forme'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _jokerRow(Widget icon, String name, String desc) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$name — ',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: desc),
              ],
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
