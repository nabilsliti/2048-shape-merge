import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';

/// Compact footer for the daily challenges card:
///   • countdown to next UTC reset (H:MM)
///
/// Watches `dailyChallengeProvider`. Hides itself if state is null.
/// Updates the countdown every 30s via a `Timer.periodic`.
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

    final remaining = _untilNextReset();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Center(
        child: Text(
          l10n.objectivesResetIn(_formatRemaining(remaining)),
          style: GoogleFonts.nunito(
            color: Colors.white70,
            fontSize: AppTheme.fontTiny,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
