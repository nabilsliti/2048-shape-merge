import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/models/daily_challenge.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';

class DailyChallengeCard extends ConsumerWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeState = ref.watch(dailyChallengeProvider);

    if (challengeState == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.challengeCardTop, AppTheme.challengeCardBot],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Neon top bar
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.challengeNeonCyan,
                    AppTheme.challengeNeonBlue,
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [AppTheme.challengeNeonCyan, Colors.white, AppTheme.challengeNeonBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(r),
                        child: const Icon(Icons.rocket_launch_rounded, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'MISSIONS DU JOUR',
                        style: AppTheme.titleStyle(AppTheme.fontTiny).copyWith(
                          color: AppTheme.goldLabel,
                          letterSpacing: 1,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Challenges list
                  ...challengeState.challenges.asMap().entries.map((e) =>
                    _ChallengeRow(
                      challenge: e.value,
                      delay: e.key * 80,
                      onCollect: () => ref.read(dailyChallengeProvider.notifier)
                          .collectReward(e.value.id),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Row per challenge
// ─────────────────────────────────────────────────────────────────────────────

class _ChallengeRow extends StatelessWidget {
  const _ChallengeRow({
    required this.challenge,
    required this.delay,
    required this.onCollect,
  });

  final DailyChallenge challenge;
  final int delay;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final done = challenge.rewardCollected;
    final color = challenge.completed ? RetentionUI.goalColor : Colors.white54;
    final labelColor = done ? Colors.white24 : Colors.white70;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(challenge.type), color: color, size: 13),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _labelFor(challenge),
                  style: GoogleFonts.fredoka(
                    fontSize: AppTheme.fontTiny,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    height: 1.1,
                  ),
                ),
              ),
              if (challenge.rewardCollected)
                const Icon(Icons.check_circle_rounded, color: RetentionUI.goalColor, size: 18)
              else
                _collectButton(challenge),
            ],
          ),
          const SizedBox(height: 3),
          RetentionUI.progressBar(
            value: challenge.progress,
            color: challenge.completed ? RetentionUI.goalColor : RetentionUI.levelColor,
          ),
          const SizedBox(height: 1),
          Text(
            '${challenge.current.clamp(0, challenge.target)} / ${challenge.target}',
            style: GoogleFonts.fredoka(
              fontSize: AppTheme.fontMini,
              color: Colors.white38,
              fontWeight: FontWeight.w700,
              height: 1,
              shadows: const [Shadow(color: Colors.black45, blurRadius: 3)],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn(duration: 300.ms);
  }

  Widget _collectButton(DailyChallenge challenge) {
    final active = challenge.canCollect;

    final Widget rewardWidget = switch (challenge.reward) {
      JokerReward(:final joker) => JokerUI.icon(joker, size: 14),
      XpReward(:final xp) => Text(
          '+$xp XP',
          style: GoogleFonts.fredoka(
              fontSize: AppTheme.fontMini,
              color: active ? Colors.white70 : Colors.white24,
              fontWeight: FontWeight.w600),
        ),
    };

    final content = SizedBox(
      width: 80,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Collecter',
              style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontTiny,
                  color: active ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 4),
            rewardWidget,
          ],
        ),
      ),
    );
    if (active) {
      final btn = Button3D.green(
        onPressed: onCollect,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        borderRadius: 8,
        child: content,
      );
      return btn
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.10,
            duration: 700.ms,
            curve: Curves.easeInOut,
          );
    }
    return Button3D.gray(
      onPressed: null,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      borderRadius: 8,
      child: content,
    );
  }

  IconData _iconFor(ChallengeType type) => switch (type) {
    ChallengeType.fusions    => RetentionUI.fusionIcon,
    ChallengeType.score      => RetentionUI.scoreIcon,
    ChallengeType.parties    => RetentionUI.gamesIcon,
    ChallengeType.formeMax   => RetentionUI.levelUpIcon,
    ChallengeType.jokersUses => Icons.auto_fix_high_rounded,
  };

  String _labelFor(DailyChallenge c) => switch (c.type) {
    ChallengeType.fusions    => 'Réaliser ${c.target} fusion${c.target > 1 ? 's' : ''}',
    ChallengeType.score      => 'Atteindre un score de ${c.target}',
    ChallengeType.parties    => 'Jouer ${c.target} partie${c.target > 1 ? 's' : ''}',
    ChallengeType.formeMax   => 'Atteindre la forme rang ${c.target}',
    ChallengeType.jokersUses => 'Utiliser ${c.target} joker${c.target > 1 ? 's' : ''}',
  };
}
