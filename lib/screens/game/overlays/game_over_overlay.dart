import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';
import 'package:shape_merge/providers/progression_provider.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

// ═══════════════════════════════════════════════════════════════
// Game Over Overlay — 2-step monetization flow
//
// Step 1: First game over → "Continue for free" (rewarded ad)
// Step 2: Second game over → "Save my game"     (rescue pack IAP)
// ═══════════════════════════════════════════════════════════════

class GameOverOverlay extends ConsumerStatefulWidget {
  final int score;
  final int mergeCount;
  final bool isNewRecord;
  final bool isSignedIn;

  /// true = Step 1 (free continue via ad), false = Step 2 (rescue pack purchase)
  final bool canFreeContinue;

  final VoidCallback onFreeContinue;
  final VoidCallback onSaveWithPack;
  final VoidCallback onNewGame;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.mergeCount,
    required this.isNewRecord,
    required this.isSignedIn,
    required this.canFreeContinue,
    required this.onFreeContinue,
    required this.onSaveWithPack,
    required this.onNewGame,
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
    if (widget.isNewRecord) {
      AudioService.instance.playNewRecord();
    } else {
      AudioService.instance.playGameOver();
    }
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
    final badgeEmoji = widget.isNewRecord ? '🏆' : '💀';
    final badgeColors = widget.isNewRecord
        ? const [AppTheme.victoryBadgeTop, AppTheme.victoryBadgeBot]
        : const [AppTheme.deathBadgeTop, AppTheme.deathBadgeBot];

    // Title: Step 1 = dynamic (record or no moves), Step 2 = "blocked again"
    final title = widget.canFreeContinue
        ? (widget.isNewRecord ? '${l10n.newRecord} 🎉' : l10n.noMoreMoves)
        : l10n.blockedAgain;

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

                          Text(title.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontH2), textAlign: TextAlign.center),
                          const SizedBox(height: 14),

                          // Score panel
                          _buildScorePanel(l10n),
                          const SizedBox(height: 20),

                          // Action buttons — Step 1 or Step 2
                          if (widget.canFreeContinue)
                            _buildStep1Buttons(l10n)
                          else
                            _buildStep2Buttons(l10n),
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

  // ── Score panel ──────────────────────────────────────────
  Widget _buildScorePanel(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: Container(
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
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontXXL,
                  fontWeight: FontWeight.w900,
                  color: widget.isNewRecord ? AppTheme.victoryBadgeTop : AppTheme.gold,
                  shadows: [
                    const Shadow(color: Colors.black38, offset: Offset(0, 3)),
                    if (widget.isNewRecord) Shadow(color: AppTheme.victoryBadgeTop.withValues(alpha: 0.4), blurRadius: 12),
                  ],
                ),
              ),
            ),
            if (widget.isNewRecord) ...[
              const SizedBox(height: 12),
              Text(
                '🏆 ${l10n.newRecord.toUpperCase()} 🏆',
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontH3,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.victoryBadgeTop,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: AppTheme.victoryBadgeTop.withValues(alpha: 0.6), blurRadius: 12),
                    Shadow(color: AppTheme.victoryBadgeBot.withValues(alpha: 0.4), blurRadius: 20),
                    const Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4),
                  ],
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.06, duration: 1200.ms, curve: Curves.easeInOut),
            ],
            const _XpAndObjectivesSummary(),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Free continue (rewarded ad) ─────────────────
  Widget _buildStep1Buttons(AppLocalizations l10n) {
    return Column(
      children: [
        Button3D.green(
          expand: true,
          borderRadius: 14,
          depth: 7,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onPressed: widget.onFreeContinue,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/pub.webp', width: 44, height: 44),
              const SizedBox(width: 8),
              Text(
                l10n.reviveAd.toUpperCase(),
                style: AppTheme.titleStyle(AppTheme.fontH3),
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.04, duration: 800.ms, curve: Curves.easeInOut),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: Button3D.orange(
            expand: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: widget.onNewGame,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                PremiumIcon.replay(size: 28),
                const SizedBox(width: 10),
                Text(l10n.newGame.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Save with rescue pack (IAP) ─────────────────
  Widget _buildStep2Buttons(AppLocalizations l10n) {
    return Column(
      children: [
        Button3D.green(
          expand: true,
          borderRadius: 14,
          depth: 7,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onPressed: widget.onSaveWithPack,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🛟', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 8),
              Text(
                l10n.saveMyGame.toUpperCase(),
                style: AppTheme.titleStyle(AppTheme.fontH3),
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.04, duration: 800.ms, curve: Curves.easeInOut),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: Button3D.orange(
            expand: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: widget.onNewGame,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                PremiumIcon.replay(size: 28),
                const SizedBox(width: 10),
                Text(l10n.newGame.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static List<_ConfettiPiece> _generateConfetti() {
    final rng = Random();
    const colors = AppTheme.hudConfettiColors;
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

// ── Reusable sub-widgets ──────────────────────────────────

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
    final paint = _confettiPaint;
    for (final c in pieces) {
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
      paint.color = c.color.withValues(alpha: 0.85);
      canvas.drawRect(rect, paint);

      canvas.restore();
    }
  }

  static final _confettiPaint = Paint()..style = PaintingStyle.fill;

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
                const Icon(RetentionUI.xpIcon, color: RetentionUI.xpColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  l10n.xpGained(progression.xpGained),
                  style: GoogleFonts.nunito(
                      fontSize: AppTheme.fontXSmall,
                      color: RetentionUI.xpColor,
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

