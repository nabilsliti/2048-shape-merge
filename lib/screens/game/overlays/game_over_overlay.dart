import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
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
  late final List<_ConfettiPiece> _confettiPieces;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    AudioService.instance.playGameOver();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _confettiPieces = _generateConfetti();
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
    final badgeEmoji = widget.isNewRecord ? '🏆' : '💀';
    final badgeColors = widget.isNewRecord
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
              if (widget.isNewRecord)
                AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (ctx, _) {
                    return Positioned.fill(
                      child: CustomPaint(
                        painter: _ConfettiRainPainter(
                          pieces: _confettiPieces,
                          progress: _confettiCtrl.value,
                        ),
                      ),
                    );
                  },
                ),
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
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [AppTheme.victoryBadgeTop, AppTheme.victoryBadgeBot]),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(color: AppTheme.victoryBadgeTop.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 2),
                                        BoxShadow(color: AppTheme.victoryBadgeBot.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 4),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🏆', style: TextStyle(fontSize: 20)),
                                        const SizedBox(width: 8),
                                        Text(l10n.newRecord.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
                                        const SizedBox(width: 8),
                                        const Text('🏆', style: TextStyle(fontSize: 20)),
                                      ],
                                    ),
                                  ),
                                ],
                                // ── XP + Objectifs — résumé rétention ──
                                const _XpAndObjectivesSummary(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign in
                          if (!widget.isSignedIn) ...[
                            SizedBox(
                              width: double.infinity,
                              child: Button3D.blue(
                                expand: true,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                onPressed: widget.onSignIn,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: Center(child: Text('G', style: GoogleFonts.fredoka(fontSize: AppTheme.fontGBtn, fontWeight: FontWeight.w900, color: AppTheme.googleBlue)))),
                                    const SizedBox(width: 10),
                                    Text(l10n.signInGoogle.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
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
                                child: Button3D.green(
                                  expand: true,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  onPressed: () {
                                    AudioService.instance.playButtonTap();
                                    widget.onReplay();
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const PremiumIcon.replay(size: 28),
                                      const SizedBox(width: 10),
                                      Text(l10n.replay.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Button3D.red(
                                  expand: true,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  onPressed: () {
                                    AudioService.instance.playButtonTap();
                                    context.pop();
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const PremiumIcon.home(size: 28),
                                      const SizedBox(width: 10),
                                      Text(l10n.menu.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
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

  static List<_ConfettiPiece> _generateConfetti() {
    final rng = Random();
    const colors = [
      Color(0xFFFF4444), Color(0xFF44AAFF), Color(0xFFFFD700),
      Color(0xFF44FF88), Color(0xFFFF44FF), Color(0xFFFF8800), Color(0xFF8844FF),
    ];
    return List.generate(32, (i) => _ConfettiPiece(
      x: rng.nextDouble(),
      speed: 0.5 + rng.nextDouble() * 0.8,
      drift: (rng.nextDouble() - 0.5) * 0.4,
      rotation: rng.nextDouble() * pi * 2,
      rotSpeed: (rng.nextDouble() - 0.5) * 8,
      width: 3 + rng.nextDouble() * 5,
      height: 5 + rng.nextDouble() * 7,
      color: colors[i % colors.length],
      phase: rng.nextDouble(),
    ));
  }
}

class _ConfettiPiece {
  final double x, speed, drift, rotation, rotSpeed, width, height, phase;
  final Color color;
  const _ConfettiPiece({
    required this.x, required this.speed, required this.drift,
    required this.rotation, required this.rotSpeed,
    required this.width, required this.height, required this.color,
    required this.phase,
  });
}

class _ConfettiRainPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;
  _ConfettiRainPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in pieces) {
      // Each piece has its own phase offset → continuous loop, no cut
      final t = (progress * (0.3 + c.speed * 0.7) + c.phase) % 1.0;

      final px = c.x * size.width + sin(t * pi * 2) * c.drift * size.width;
      final py = -10 + t * (size.height + 20);
      final rot = c.rotation + t * c.rotSpeed;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: c.width,
        height: c.height * (0.5 + 0.5 * cos(t * pi * 3).abs()),
      );
      canvas.drawRect(rect, Paint()
        ..color = c.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiRainPainter old) => old.progress != progress;
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
                const Icon(RetentionUI.xpIcon, color: RetentionUI.levelColor, size: 14),
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
                const Icon(RetentionUI.goalIcon, color: RetentionUI.goalColor, size: 12),
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

