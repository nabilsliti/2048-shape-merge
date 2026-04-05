import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final leaderboard = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.leaderboard, style: AppTheme.titleStyle),
        leading: const BackButton(color: AppTheme.text),
      ),
      body: leaderboard.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text(
                'No scores yet',
                style: TextStyle(color: AppTheme.muted),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isTop3 = index < 3;
              final medalColors = [AppTheme.gold, Colors.grey, const Color(0xFFCD7F32)];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isTop3 ? medalColors[index] : AppTheme.border,
                    width: isTop3 ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.orbitron(
                          color: isTop3 ? medalColors[index] : AppTheme.muted,
                          fontWeight: FontWeight.bold,
                          fontSize: isTop3 ? 20 : 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.displayName,
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.score}',
                      style: GoogleFonts.orbitron(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Error loading leaderboard',
            style: TextStyle(color: AppTheme.red),
          ),
        ),
      ),
    );
  }
}
