import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';
import 'package:shape_merge/providers/progression_provider.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

class GameOverOverlay extends ConsumerStatefulWidget {
  final int score;
  final int mergeCount;
  final bool isVictory;
  final bool isNewRecord;
  final bool isSignedIn;
  final VoidCallback onReplay;
  final VoidCallback onSignIn;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.mergeCount,
    required this.isVictory,
    required this.isNewRecord,
    required this.isSignedIn,
    required this.onReplay,
    required this.onSignIn,
  });

  @override
  ConsumerState<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends ConsumerState<GameOverOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.isVictory ? l10n.victory : l10n.gameOver;
    final badgeEmoji = widget.isVictory ? '🏆' : '💀';
    final badgeColors = widget.isVictory
        ? const [AppTheme.victoryBadgeTop, AppTheme.victoryBadgeBot]
        : const [AppTheme.deathBadgeTop, AppTheme.deathBadgeBot];

    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (context, _) {
        final fade = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut).value;

        return Opacity(
          opacity: fade,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const SpaceBackground(darken: 0.65),
              if (widget.isVictory) ..._buildParticles(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge
                          _PulsingBadge(pulse: _pulseCtrl, emoji: badgeEmoji, colors: badgeColors),
                          const SizedBox(height: 10),

                          Text(title.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontH1b), textAlign: TextAlign.center),
                          const SizedBox(height: 14),

                          // Score panel
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.panelBg,
                              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                              border: Border.all(color: AppTheme.panelBorder, width: 3),
                              boxShadow: const [
                                BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 6)),
                                BoxShadow(color: Colors.black54, offset: Offset(0, 10), blurRadius: 14),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(l10n.scoreLabel, style: GoogleFonts.nunito(fontSize: AppTheme.fontTiny, fontWeight: FontWeight.w900, color: AppTheme.blueLabel, letterSpacing: 2)),
                                const SizedBox(height: 4),
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(begin: 0, end: widget.score),
                                  duration: const Duration(milliseconds: 1200),
                                  curve: Curves.easeOut,
                                  builder: (context, val, _) => Text(
                                    '$val',
                                    style: GoogleFonts.fredoka(fontSize: AppTheme.fontXXL, fontWeight: FontWeight.w900, color: widget.isNewRecord ? AppTheme.victoryBadgeTop : AppTheme.gold,
                                        shadows: [
                                          const Shadow(color: Colors.black38, offset: Offset(0, 3)),
                                          if (widget.isNewRecord) Shadow(color: AppTheme.victoryBadgeTop.withValues(alpha: 0.4), blurRadius: 12),
                                        ]),
                                  ),
                                ),
                                if (widget.isNewRecord) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [AppTheme.victoryBadgeTop, AppTheme.victoryBadgeBot]),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
                                      boxShadow: [BoxShadow(color: AppTheme.victoryBadgeTop.withValues(alpha: 0.267), blurRadius: 10, spreadRadius: 1)],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(l10n.newRecord.toUpperCase(), style: GoogleFonts.nunito(fontSize: AppTheme.fontTiny, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.star, color: Colors.white, size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _StatChip(label: l10n.merges, value: '${widget.mergeCount}', color: AppTheme.purpleBorder),
                                // ── XP + Objectifs — résumé rétention ──
                                _XpAndObjectivesSummary(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign in
                          if (!widget.isSignedIn) ...[
                            SizedBox(
                              width: double.infinity,
                              child: Button3D.blue(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                borderRadius: 18,
                                onPressed: widget.onSignIn,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text('G', style: GoogleFonts.fredoka(fontSize: AppTheme.fontBody, fontWeight: FontWeight.w900, color: AppTheme.googleBlue)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(l10n.signInGoogle.toUpperCase(), style: GoogleFonts.nunito(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w900, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(l10n.signInToSave, style: GoogleFonts.nunito(fontSize: AppTheme.fontMini, fontWeight: FontWeight.w600, color: AppTheme.blueLabel), textAlign: TextAlign.center),
                            const SizedBox(height: 14),
                          ],

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: Button3D.red(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  borderRadius: 18,
                                  onPressed: () => context.go('/home'),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.home, color: Colors.white, size: 24),
                                      const SizedBox(width: 8),
                                      Text(l10n.menu.toUpperCase(), style: GoogleFonts.nunito(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w900, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Button3D.green(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  borderRadius: 18,
                                  onPressed: widget.onReplay,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.refresh, color: Colors.white, size: 24),
                                      const SizedBox(width: 8),
                                      Text(l10n.replay.toUpperCase(), style: GoogleFonts.nunito(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w900, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    final rng = Random(99);
    const colors = [AppTheme.confetti1, AppTheme.confetti2, AppTheme.confetti3, AppTheme.confetti4];

    return List.generate(12, (i) {
      final color = colors[rng.nextInt(colors.length)];
      final startX = rng.nextDouble();
      final speed = 0.3 + rng.nextDouble() * 0.5;
      final size = 3.0 + rng.nextDouble() * 4;

      return AnimatedBuilder(
        animation: _confettiCtrl,
        builder: (ctx, _) {
          final t = (_confettiCtrl.value * speed + i * 0.08) % 1.0;
          final screenH = MediaQuery.of(ctx).size.height;
          final screenW = MediaQuery.of(ctx).size.width;
          final y = -10.0 + t * (screenH + 20);
          final x = startX * screenW + sin(t * 3 * pi) * 20;

          return Positioned(
            left: x,
            top: y,
            child: Opacity(
              opacity: (1.0 - t).clamp(0.0, 0.4),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          );
        },
      );
    });
  }
}

class _PulsingBadge extends StatelessWidget {
  const _PulsingBadge({required this.pulse, required this.emoji, required this.colors});
  final AnimationController pulse;
  final String emoji;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (ctx, _) {
        final glow = 0.2 + pulse.value * 0.3;
        return Transform.scale(
          scale: 1.0 + pulse.value * 0.05,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [BoxShadow(color: colors[0].withValues(alpha: glow), blurRadius: 20, spreadRadius: 2)],
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: AppTheme.fontH1))),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: GoogleFonts.nunito(fontSize: AppTheme.fontPico, fontWeight: FontWeight.w900, color: AppTheme.blueLabel, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.fredoka(fontSize: AppTheme.fontH3, fontWeight: FontWeight.w900, color: color, shadows: const [Shadow(color: Colors.black38, offset: Offset(0, 2))])),
        ],
      ),
    );
  }
}

/// XP gain + daily objectives summary shown in GameOverOverlay.
class _XpAndObjectivesSummary extends ConsumerWidget {
  const _XpAndObjectivesSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progression = ref.watch(progressionProvider);
    final challenges = ref.watch(dailyChallengeProvider);
    if (progression == null && challenges == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          if (progression != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(RetentionUI.xpIcon, color: RetentionUI.levelColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  '+${progression.xpGained} XP',
                  style: GoogleFonts.nunito(
                      fontSize: AppTheme.fontXSmall,
                      color: RetentionUI.levelColor,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
          if (challenges != null && challenges.completedCount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(RetentionUI.goalIcon, color: RetentionUI.goalColor, size: 12),
                const SizedBox(width: 4),
                Text(
                  l10n.objectivesSummary(challenges.completedCount, challenges.challenges.length),
                  style: GoogleFonts.nunito(
                      fontSize: AppTheme.fontMini,
                      color: RetentionUI.goalColor,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

