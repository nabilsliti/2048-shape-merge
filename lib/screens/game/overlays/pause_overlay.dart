import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/glass_card.dart';
import 'package:shape_merge/core/widgets/gradient_button.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';

class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;

  const PauseOverlay({super.key, required this.onResume});

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
              Text(l10n.pause, style: AppTheme.titleStyle),
              const SizedBox(height: 24),
              GradientButton(
                label: l10n.resume,
                icon: Icons.play_arrow,
                onPressed: onResume,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: Icon(Icons.home, color: AppTheme.muted),
                label: Text(l10n.quit, style: TextStyle(color: AppTheme.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
