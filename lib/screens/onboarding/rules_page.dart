import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          Text(l10n.onboardingTitle1, style: AppTheme.titleStyle(AppTheme.fontH1)),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingDesc1,
            style: GoogleFonts.nunito(color: Colors.white, fontSize: AppTheme.fontRegular, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Shape types preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShapePreview(color: AppTheme.blueTop, label: '⬤'),
              _ShapePreview(color: AppTheme.greenTop, label: '⬛'),
              _ShapePreview(color: AppTheme.purpleTop, label: '⭐'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.panelBg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXTiny),
                    border: Border.all(color: AppTheme.panelBorder),
                    boxShadow: const [
                      BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 3)),
                      BoxShadow(color: Colors.black54, offset: Offset(0, 4), blurRadius: 6),
                    ],
                  ),
                  child: Text(
                    '${1 << i}',
                    style: GoogleFonts.fredoka(fontSize: AppTheme.fontBody, fontWeight: FontWeight.w900, color: AppTheme.gold,
                        shadows: const [Shadow(color: Colors.black38, offset: Offset(0, 2))]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.redTop.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: AppTheme.redTop, width: 1.5),
            ),
            child: Text(
              'Max 30 shapes',
              style: GoogleFonts.nunito(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w900, color: AppTheme.redBorder),
            ),
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
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2),
          const BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Center(
        child: Text(label, style: const TextStyle(fontSize: AppTheme.fontH1, shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))])),
      ),
    );
  }
}
