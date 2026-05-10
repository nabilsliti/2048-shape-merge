import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';

/// Compact footer for the daily challenges card:
///   • global progress bar  X/Y
///   • countdown to next UTC reset (H:MM)
///
/// Watches `dailyChallengeProvider`. Hides itself if state is null.
/// Updates the countdown every minute via a `Timer.periodic`.
class DailyChallengeFooter extends ConsumerStatefulWidget {
  const DailyChallengeFooter({super.key});

  @override
  ConsumerState<DailyChallengeFooter> createState() =>
      _DailyChallengeFooterState();
}

class _DailyChallengeFooterState extends ConsumerState<DailyChallengeFooter> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Per-minute tick is enough — the format is H:MM.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Time until next 00:00 UTC.
  Duration _untilNextReset() {
    final now = DateTime.now().toUtc();
    final tomorrow = DateTime.utc(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  String _formatRemaining(Duration d) {
    if (d.inHours >= 1) {
      final h = d.inHours;
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      return '${h}h ${m}m';
    }
    final m = d.inMinutes;
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(dailyChallengeProvider);
    if (state == null || state.challenges.isEmpty) return const SizedBox.shrink();

    final total = state.challenges.length;
    final done = state.challenges.where((c) => c.completed).length;
    final progress = total == 0 ? 0.0 : done / total;
    final allDone = done == total;
    final remaining = _untilNextReset();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: allDone
                            ? const [AppTheme.gold, AppTheme.goldLight]
                            : const [
                                AppTheme.challengeNeonCyan,
                                AppTheme.challengeNeonBlue,
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (allDone
                                  ? AppTheme.gold
                                  : AppTheme.challengeNeonCyan)
                              .withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Bottom row: progress text — reset countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (allDone)
                Flexible(
                  child: Text(
                    l10n.objectivesAllDoneToday,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: AppTheme.gold,
                      fontSize: AppTheme.fontTiny,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Text(
                  l10n.objectivesProgress(done, total),
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: AppTheme.fontTiny,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.objectivesResetIn(_formatRemaining(remaining)),
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: AppTheme.fontTiny,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
