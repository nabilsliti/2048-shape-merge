import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';

class JokersPage extends StatelessWidget {
  const JokersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Text(l10n.onboardingTitle2, style: AppTheme.titleStyle(AppTheme.fontH1)),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingDesc2,
            style: GoogleFonts.nunito(color: Colors.white, fontSize: AppTheme.fontRegular, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _JokerCard(
            icon: JokerUI.icon(JokerType.bomb, size: 42),
            color: JokerUI.color(JokerType.bomb),
            title: l10n.jokerBomb,
            description: l10n.jokerBombDesc,
          ),
          const SizedBox(height: 12),
          _JokerCard(
            icon: JokerUI.icon(JokerType.wildcard, size: 42),
            color: JokerUI.color(JokerType.wildcard),
            title: l10n.jokerWildcard,
            description: l10n.jokerWildcardDesc,
          ),
          const SizedBox(height: 12),
          _JokerCard(
            icon: JokerUI.icon(JokerType.reducer, size: 42),
            color: JokerUI.color(JokerType.reducer),
            title: l10n.jokerReducer,
            description: l10n.jokerReducerDesc,
          ),
          const SizedBox(height: 12),
          _JokerCard(
            icon: JokerUI.icon(JokerType.radar, size: 42),
            color: JokerUI.color(JokerType.radar),
            title: l10n.jokerRadar,
            description: l10n.jokerRadarDesc,
          ),
          const SizedBox(height: 12),
          _JokerCard(
            icon: JokerUI.icon(JokerType.evolution, size: 42),
            color: JokerUI.color(JokerType.evolution),
            title: l10n.jokerEvolution,
            description: l10n.jokerEvolutionDesc,
          ),
          const SizedBox(height: 12),
          _JokerCard(
            icon: JokerUI.icon(JokerType.megaBomb, size: 42),
            color: JokerUI.color(JokerType.megaBomb),
            title: l10n.jokerMegaBomb,
            description: l10n.jokerMegaBombDesc,
          ),
        ],
      ),
      ),
    );
  }
}

class _JokerCard extends StatelessWidget {
  final Widget icon;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color, width: 1.5),
        boxShadow: const [
          BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 3)),
          BoxShadow(color: Colors.black54, offset: Offset(0, 4), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 14)],
            ),
            child: icon,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.fredoka(fontSize: AppTheme.fontBody, fontWeight: FontWeight.w700, color: color,
                      shadows: const [Shadow(color: Colors.black38, offset: Offset(0, 2))]),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.nunito(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w600, color: AppTheme.blueLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
