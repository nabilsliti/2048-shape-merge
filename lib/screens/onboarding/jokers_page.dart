import 'package:flutter/material.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';

class JokersPage extends StatelessWidget {
  const JokersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.onboardingTitle2, style: AppTheme.titleStyle),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingDesc2,
            style: const TextStyle(color: AppTheme.text, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _JokerCard(
            icon: '💣',
            title: l10n.jokerBomb,
            description: l10n.jokerBombDesc,
            color: AppTheme.red,
          ),
          const SizedBox(height: 12),
          _JokerCard(
            icon: '🌀',
            title: l10n.jokerWildcard,
            description: l10n.jokerWildcardDesc,
            color: AppTheme.blue,
          ),
          const SizedBox(height: 12),
          _JokerCard(
            icon: '⬇️',
            title: l10n.jokerReducer,
            description: l10n.jokerReducerDesc,
            color: AppTheme.green,
          ),
        ],
      ),
    );
  }
}

class _JokerCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final Color color;

  const _JokerCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
