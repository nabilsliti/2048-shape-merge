import 'package:flutter/material.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.onboardingTitle1, style: AppTheme.titleStyle),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingDesc1,
            style: const TextStyle(color: AppTheme.text, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Shape types preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShapePreview(color: AppTheme.blue, label: '⬤'),
              _ShapePreview(color: AppTheme.green, label: '⬛'),
              _ShapePreview(color: AppTheme.purple, label: '⭐'),
              _ShapePreview(color: AppTheme.gold, label: '⬡'),
            ],
          ),
          const SizedBox(height: 24),
          // Level progression
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 1; i <= 8; i++)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.panel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    '${1 << i}',
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Max 30 shapes',
            style: TextStyle(color: AppTheme.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ShapePreview extends StatelessWidget {
  final Color color;
  final String label;

  const _ShapePreview({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
