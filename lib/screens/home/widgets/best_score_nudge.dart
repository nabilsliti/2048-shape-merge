import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';

/// Small floating nudge under the best score that motivates the player:
///
/// Priority (first matching wins):
///   1. Player has bestScore == 0  → "Tente ton premier record !"
///   2. Player is #1 worldwide     → "Tu es N°1 mondial 👑"
///   3. There is a player just above → "Bats {name} : {score}"
///   4. Otherwise                  → "À {gap} pts du Top Mondial"
///
/// Always one short line. Uses pulsing chip styling for visibility.
/// Silently renders nothing if the leaderboard hasn't loaded yet (lazy).
class BestScoreNudge extends ConsumerWidget {
  const BestScoreNudge({super.key});

  String _formatScore(int n) {
    if (n >= 1000) {
      final k = (n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1);
      return '${k}k';
    }
    return '$n';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bestScore = ref.watch(gameStateProvider).bestScore;
    final user = ref.watch(authStateProvider).valueOrNull;

    // First-record case → always show, no leaderboard fetch needed.
    if (bestScore == 0) {
      return _NudgeChip(
        text: l10n.homeNudgeFirstBest,
        gradient: const [AppTheme.greenTop, AppTheme.greenBot],
        icon: Icons.flag_rounded,
      );
    }

    // Watch leaderboard lazily; if loading/error, render nothing.
    final lbAsync = ref.watch(leaderboardProvider);
    return lbAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();

        final topScore = entries.first.score;
        final myUid = user?.uid;

        // I'm ranked #1 → trophy nudge.
        if (myUid != null && entries.first.uid == myUid) {
          return _NudgeChip(
            text: l10n.homeNudgeYouAreTop,
            gradient: const [AppTheme.gold, AppTheme.goldLight],
            icon: Icons.emoji_events_rounded,
            textDark: true,
          );
        }

        // Find the player just above me (smallest score > bestScore).
        final above = entries
            .where((e) => e.score > bestScore && e.uid != myUid)
            .toList();
        if (above.isNotEmpty) {
          // entries are sorted desc → the closest is the LAST element in `above`.
          final target = above.last;
          return _NudgeChip(
            text: l10n.homeNudgeBeatPlayer(
              target.displayName,
              _formatScore(target.score),
            ),
            gradient: const [AppTheme.hubStreakPurple1, AppTheme.hubStreakPurple2],
            icon: Icons.flash_on_rounded,
          );
        }

        // No one above in top N → show gap to absolute top.
        final gap = topScore - bestScore;
        if (gap <= 0) return const SizedBox.shrink();
        return _NudgeChip(
          text: l10n.homeNudgeTopWorld(_formatScore(gap)),
          gradient: const [AppTheme.hubStreakPurple1, AppTheme.hubStreakPurple2],
          icon: Icons.trending_up_rounded,
        );
      },
    );
  }
}

class _NudgeChip extends StatelessWidget {
  const _NudgeChip({
    required this.text,
    required this.gradient,
    required this.icon,
    this.textDark = false,
  });

  final String text;
  final List<Color> gradient;
  final IconData icon;
  final bool textDark;

  @override
  Widget build(BuildContext context) {
    final fg = textDark ? Colors.black87 : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: fg,
                fontSize: AppTheme.fontTiny,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
