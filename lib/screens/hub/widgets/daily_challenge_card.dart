import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/models/daily_challenge.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';

class DailyChallengeCard extends ConsumerWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeState = ref.watch(dailyChallengeProvider);
    final l10n = AppLocalizations.of(context)!;

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
                        l10n.dailyObjectivesTitle,
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
                  ...challengeState.challenges.map((c) =>
                    _ChallengeRow(
                      challenge: c,
                      onCollect: () => ref.read(dailyChallengeProvider.notifier)
                          .collectReward(c.id),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Row per challenge
// ─────────────────────────────────────────────────────────────────────────────

class _ChallengeRow extends StatefulWidget {
  const _ChallengeRow({
    required this.challenge,
    required this.onCollect,
  });

  final DailyChallenge challenge;
  final VoidCallback onCollect;

  @override
  State<_ChallengeRow> createState() => _ChallengeRowState();
}

class _ChallengeRowState extends State<_ChallengeRow>
    with TickerProviderStateMixin {
  bool _showCollectAnim = false;
  late final AnimationController _bounceCtrl;
  late final AnimationController _plusOneCtrl;
  late final AnimationController _sparkleCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _plusOneCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _sparkleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  }

  @override
  void didUpdateWidget(covariant _ChallengeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge.id != widget.challenge.id ||
        widget.challenge.rewardCollected != oldWidget.challenge.rewardCollected) {
      _showCollectAnim = false;
      _bounceCtrl.reset();
      _plusOneCtrl.reset();
      _sparkleCtrl.reset();
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _plusOneCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  void _onCollectTap() {
    setState(() => _showCollectAnim = true);
    HapticFeedback.heavyImpact();
    _bounceCtrl.forward(from: 0);
    _plusOneCtrl.forward(from: 0);
    _sparkleCtrl.forward(from: 0);

    // Delay actual collect so the animation plays first;
    // sound is played by collectReward() in sync with the actual delivery.
    Future.delayed(const Duration(milliseconds: 900), () {
      widget.onCollect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
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
              else if (_showCollectAnim)
                _buildRewardAnimation(challenge)
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
    );
  }

  Widget _buildRewardAnimation(DailyChallenge challenge) {
    final rewardColor = switch (challenge.reward) {
      JokerReward(:final joker) => JokerUI.color(joker),
      XpReward() => AppTheme.gold,
    };
    final rewardIcon = switch (challenge.reward) {
      JokerReward(:final joker) => JokerUI.icon(joker, size: 22),
      XpReward() => const Icon(Icons.star_rounded, color: AppTheme.gold, size: 22),
    };
    final rewardLabel = switch (challenge.reward) {
      JokerReward() => '+1',
      XpReward(:final xp) => '+$xp',
    };

    return AnimatedBuilder(
      animation: Listenable.merge([_bounceCtrl, _plusOneCtrl, _sparkleCtrl]),
      builder: (context, _) {
        // Bounce: 1→1.5→0.9→1
        final double bounceScale;
        if (_bounceCtrl.value < 0.3) {
          bounceScale = 1.0 + (_bounceCtrl.value / 0.3) * 0.5;
        } else if (_bounceCtrl.value < 0.6) {
          bounceScale = 1.5 - ((_bounceCtrl.value - 0.3) / 0.3) * 0.6;
        } else {
          bounceScale = 0.9 + ((_bounceCtrl.value - 0.6) / 0.4) * 0.1;
        }

        // +1 float up
        final plusT = Curves.easeOutCubic.transform(_plusOneCtrl.value);
        final plusOpacity = (1.0 - _plusOneCtrl.value * 0.8).clamp(0.0, 1.0);
        final plusOffset = -35.0 * plusT;

        // Glow
        final glowIntensity = _bounceCtrl.value < 0.5
            ? _bounceCtrl.value * 2
            : 2 - _bounceCtrl.value * 2;

        return SizedBox(
          width: 80,
          height: 36,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Sparkles
              if (_sparkleCtrl.isAnimating)
                for (var i = 0; i < 6; i++)
                  Positioned(
                    top: 18 + math.sin((i / 6) * 2 * math.pi) * 20 * _sparkleCtrl.value,
                    left: 40 + math.cos((i / 6) * 2 * math.pi) * 25 * _sparkleCtrl.value,
                    child: Opacity(
                      opacity: (1.0 - _sparkleCtrl.value).clamp(0.0, 1.0),
                      child: Container(
                        width: 4 * (1 - _sparkleCtrl.value * 0.5),
                        height: 4 * (1 - _sparkleCtrl.value * 0.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rewardColor,
                          boxShadow: [BoxShadow(color: rewardColor.withValues(alpha: 0.6), blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
              // Icon bouncing
              Transform.scale(
                scale: _bounceCtrl.isAnimating ? bounceScale : 1.0,
                child: Container(
                  decoration: glowIntensity > 0
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: rewardColor.withValues(alpha: glowIntensity * 0.7), blurRadius: 16, spreadRadius: 2),
                          ],
                        )
                      : null,
                  child: rewardIcon,
                ),
              ),
              // Floating "+1" / "+50 XP"
              if (_plusOneCtrl.isAnimating)
                Positioned(
                  top: plusOffset,
                  child: Opacity(
                    opacity: plusOpacity,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rewardLabel,
                          style: GoogleFonts.fredoka(
                            fontSize: AppTheme.fontH4,
                            fontWeight: FontWeight.w900,
                            color: rewardColor,
                            shadows: [
                              Shadow(color: rewardColor.withValues(alpha: 0.8), blurRadius: 8),
                            ],
                          ),
                        ),
                        if (challenge.reward is XpReward)
                          Text(
                            ' XP',
                            style: GoogleFonts.fredoka(
                              fontSize: AppTheme.fontTiny,
                              fontWeight: FontWeight.w700,
                              color: rewardColor.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _collectButton(DailyChallenge challenge) {
    final l10n = AppLocalizations.of(context)!;
    final active = challenge.canCollect;

    final Widget rewardWidget = switch (challenge.reward) {
      JokerReward(:final joker) => Opacity(
          opacity: active ? 1.0 : 0.3,
          child: JokerUI.icon(joker, size: 14),
        ),
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
              l10n.collectReward,
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
        onPressed: _onCollectTap,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        borderRadius: 8,
        depth: 3,
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
      depth: 3,
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

  String _labelFor(DailyChallenge c) {
    final l10n = AppLocalizations.of(context)!;
    return switch (c.type) {
      ChallengeType.fusions    => l10n.objectiveFusions(c.target),
      ChallengeType.score      => l10n.objectiveScore(c.target),
      ChallengeType.parties    => l10n.objectiveParties(c.target),
      ChallengeType.formeMax   => l10n.objectiveFormeMax(c.target),
      ChallengeType.jokersUses => l10n.objectiveJokersUses(c.target),
    };
  }
}
