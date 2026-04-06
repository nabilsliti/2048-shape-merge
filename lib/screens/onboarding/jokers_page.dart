import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          Text(l10n.onboardingTitle2, style: AppTheme.titleStyle(28)),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingDesc2,
            style: GoogleFonts.nunito(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _JokerCard(
            icon: Icons.local_fire_department_rounded,
            title: l10n.jokerBomb,
            description: l10n.jokerBombDesc,
            color: AppTheme.redTop,
          ),
          const SizedBox(height: 16),
          _JokerCard(
            icon: Icons.auto_awesome_rounded,
            title: l10n.jokerWildcard,
            description: l10n.jokerWildcardDesc,
            color: AppTheme.blueTop,
          ),
          const SizedBox(height: 16),
          _JokerCard(
            icon: Icons.keyboard_double_arrow_down_rounded,
            title: l10n.jokerReducer,
            description: l10n.jokerReducerDesc,
            color: AppTheme.greenTop,
          ),
        ],
      ),
    );
  }
}

class _JokerCard extends StatelessWidget {
  final IconData icon;
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0xFF111827), offset: Offset(0, 3)),
          BoxShadow(color: Colors.black54, offset: Offset(0, 4), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 42, color: color, shadows: [Shadow(color: color, blurRadius: 10)]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w700, color: color,
                      shadows: const [Shadow(color: Colors.black38, offset: Offset(0, 2))]),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF8ad1ff)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
