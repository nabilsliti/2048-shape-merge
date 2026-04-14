import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/audio_provider.dart';
import 'package:shape_merge/screens/game/widgets/coach_overlay.dart';

part 'hud_painters.dart';

/// Modern flat HUD — 4 elements distributed flexibly inside the card.
class HudBar extends ConsumerStatefulWidget {
  final int score;
  final int bestScore;
  final int shapeCount;
  final int mergeCount;
  final VoidCallback? onPause;

  const HudBar({
    super.key,
    required this.score,
    required this.bestScore,
    required this.shapeCount,
    required this.mergeCount,
    this.onPause,
  });

  @override
  ConsumerState<HudBar> createState() => _HudBarState();
}

class _HudBarState extends ConsumerState<HudBar> with TickerProviderStateMixin {
  late final AnimationController _celebCtrl;
  late final AnimationController _confettiCtrl;
  late final AnimationController _glowCtrl;
  late final List<_Confetti> _confettiPieces;
  bool _celebrationPlayed = false;
  /// The bestScore captured at the start of each game.
  /// This is the threshold the player must beat.
  int _recordAtGameStart = 0;

  @override
  void initState() {
    super.initState();
    _celebCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _confettiPieces = _generateConfetti();
    // Capture initial best score when HUD is first created
    _recordAtGameStart = widget.bestScore;
  }

  @override
  void didUpdateWidget(covariant HudBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When a new game starts (score drops to 0), snapshot the bestScore as
    // the threshold for this game and reset the celebration flag.
    if (widget.score == 0 && oldWidget.score > 0) {
      _celebrationPlayed = false;
      _recordAtGameStart = widget.bestScore;
      _glowCtrl.reset();
    }
    // Play celebration exactly once per game when STRICTLY beating the record
    final isNewBest = widget.score > 0 && widget.score > _recordAtGameStart;
    if (isNewBest && !_celebrationPlayed) {
      _celebrationPlayed = true;
      _celebCtrl.forward(from: 0);
      _confettiCtrl.forward(from: 0);
      _glowCtrl.repeat(reverse: true);
      AudioService.instance.playNewRecord();
    }
  }

  @override
  void dispose() {
    _celebCtrl.dispose();
    _confettiCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  static List<_Confetti> _generateConfetti() {
    final rng = Random();
    return List.generate(24, (i) => _Confetti(
      x: rng.nextDouble(),
      speed: 0.5 + rng.nextDouble() * 0.8,
      drift: (rng.nextDouble() - 0.5) * 0.4,
      rotation: rng.nextDouble() * pi * 2,
      rotSpeed: (rng.nextDouble() - 0.5) * 8,
      width: 3 + rng.nextDouble() * 4,
      height: 5 + rng.nextDouble() * 6,
      color: [
        const Color(0xFFFF4444),
        const Color(0xFF44AAFF),
        const Color(0xFFFFD700),
        const Color(0xFF44FF88),
        const Color(0xFFFF44FF),
        const Color(0xFFFF8800),
        const Color(0xFF8844FF),
      ][i % 7],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.score;
    final bestScore = widget.bestScore;
    final shapeCount = widget.shapeCount;
    final mergeCount = widget.mergeCount;
    final capacityRatio = shapeCount / maxShapes;
    final capColor = capacityRatio < 0.6
        ? AppTheme.capGood
        : capacityRatio < 0.85
            ? AppTheme.capWarn
            : AppTheme.capDanger;
    final isNewBest = score > 0 && score > _recordAtGameStart;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          // ── Score (hero — gets more space) ────────
          Expanded(
            flex: 3,
            child: KeyedSubtree(
              key: CoachKeys.hudScore,
              child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Confetti rain — overflows above/below the score area
                AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (context, _) {
                    if (!_confettiCtrl.isAnimating) return const SizedBox.shrink();
                    return Positioned(
                      left: -10,
                      top: -20,
                      right: -10,
                      bottom: -20,
                      child: CustomPaint(
                        painter: _ConfettiPainter(
                          pieces: _confettiPieces,
                          progress: _confettiCtrl.value,
                        ),
                      ),
                    );
                  },
                ),
                Row(
                    children: [
                      // Star with premium bounce + golden glow pulse
                      AnimatedBuilder(
                        animation: _celebCtrl,
                        builder: (context, child) {
                          final double s;
                          final double glowExtra;
                          if (_celebCtrl.isAnimating) {
                            if (_celebCtrl.value < 0.12) {
                              s = 1.0 + (_celebCtrl.value / 0.12) * 0.6;
                              glowExtra = _celebCtrl.value / 0.12;
                            } else if (_celebCtrl.value < 0.25) {
                              s = 1.6 - ((_celebCtrl.value - 0.12) / 0.13) * 0.5;
                              glowExtra = 1.0 - ((_celebCtrl.value - 0.12) / 0.13) * 0.6;
                            } else if (_celebCtrl.value < 0.4) {
                              final t = (_celebCtrl.value - 0.25) / 0.15;
                              s = 1.1 + sin(t * pi * 2) * 0.08;
                              glowExtra = 0.4 * (1 - t);
                            } else {
                              s = 1.0;
                              glowExtra = 0.0;
                            }
                          } else {
                            s = 1.0;
                            glowExtra = 0.0;
                          }
                          return Transform.scale(
                            scale: s,
                            child: Container(
                              decoration: glowExtra > 0
                                  ? BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.gold.withValues(alpha: glowExtra * 0.8),
                                          blurRadius: 18,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    )
                                  : null,
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CustomPaint(painter: _StarPainter(glow: isNewBest)),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Score text with premium pulse + shimmer + glow
                            AnimatedBuilder(
                              animation: Listenable.merge([_celebCtrl, _glowCtrl]),
                              builder: (context, _) {
                                final double s;
                                if (_celebCtrl.isAnimating && _celebCtrl.value < 0.4) {
                                  final t = _celebCtrl.value / 0.4;
                                  s = 1.0 + sin(t * pi) * 0.18;
                                } else {
                                  s = 1.0;
                                }
                                // Shimmer sweep — spread across more of the animation
                                final shimmerActive = _celebCtrl.isAnimating &&
                                    _celebCtrl.value > 0.05 && _celebCtrl.value < 0.55;
                                final shimmerT = shimmerActive
                                    ? ((_celebCtrl.value - 0.05) / 0.5).clamp(0.0, 1.0)
                                    : 0.0;
                                // Persistent golden glow pulse when holding record
                                final glowAlpha = isNewBest && _glowCtrl.isAnimating
                                    ? 0.4 + _glowCtrl.value * 0.6
                                    : (isNewBest ? 0.7 : 0.0);
                                final glowBlur = isNewBest
                                    ? 12.0 + (_glowCtrl.isAnimating ? _glowCtrl.value * 10 : 0.0)
                                    : 0.0;

                                return Transform.scale(
                                  scale: s,
                                  alignment: Alignment.centerLeft,
                                  child: ShaderMask(
                                    shaderCallback: (bounds) {
                                      if (!shimmerActive) {
                                        return const LinearGradient(
                                          colors: [Colors.white, Colors.white],
                                        ).createShader(bounds);
                                      }
                                      final shimmerX = bounds.width * (shimmerT * 2 - 0.3);
                                      return LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: const [
                                          Colors.white,
                                          Color(0xFFFFF8E0),
                                          Colors.white,
                                        ],
                                        stops: [
                                          (shimmerX / bounds.width - 0.15).clamp(0.0, 1.0),
                                          (shimmerX / bounds.width).clamp(0.0, 1.0),
                                          (shimmerX / bounds.width + 0.15).clamp(0.0, 1.0),
                                        ],
                                      ).createShader(bounds);
                                    },
                                    blendMode: BlendMode.modulate,
                                    child: Text(
                                      _fmt(score),
                                      style: AppTheme.titleStyle(AppTheme.fontH1).copyWith(
                                        color: isNewBest ? AppTheme.gold : Colors.white,
                                        height: 1.1,
                                        shadows: [
                                          Shadow(
                                            color: AppTheme.gold.withValues(alpha: isNewBest ? glowAlpha : 0.7),
                                            blurRadius: isNewBest ? glowBlur : 10,
                                          ),
                                          const Shadow(
                                            color: Colors.black54,
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isNewBest ? AppLocalizations.of(context)!.hudNewBest : AppLocalizations.of(context)!.hudBest(_fmt(bestScore)),
                              style: AppTheme.titleStyle(AppTheme.fontPico).copyWith(
                                color: isNewBest
                                    ? AppTheme.goldLight
                                    : AppTheme.goldLabel,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          _divider(),

          // ── Capacity ──────────────────────────────
          Expanded(
            flex: 2,
            child: KeyedSubtree(
              key: CoachKeys.hudCapacity,
              child: _StatColumn(
              icon: SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(
                  painter: _RingPainter(ratio: capacityRatio, color: capColor),
                ),
              ),
              value: '$shapeCount',
              label: '/$maxShapes',
              color: capColor,
              valueColor: shapeCount >= 25 ? AppTheme.capDanger : null,
            ),
            ),
          ),

          _divider(),

          // ── Merges ────────────────────────────────
          Expanded(
            flex: 2,
            child: KeyedSubtree(
              key: CoachKeys.hudMerges,
              child: _StatColumn(
              icon: SizedBox(
                width: 18,
                height: 18,
                child: CustomPaint(painter: _BoltPainter()),
              ),
              value: '$mergeCount',
              color: AppTheme.statMerge,
            ),
            ),
          ),

          _divider(),

          // ── Audio Controls ────────────────────────
          Consumer(
            builder: (context, ref, _) {
              final soundEnabled = ref.watch(audioProvider);
              final musicEnabled = ref.watch(musicProvider);
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sound toggle 🔊
                  Button3D.blue(
                    padding: const EdgeInsets.all(6),
                    borderRadius: 8,
                    onPressed: () {
                      AudioService.instance.playButtonTap();
                      ref.read(audioProvider.notifier).toggle();
                    },
                    child: Icon(
                      soundEnabled ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Music toggle 🎵
                  Button3D.blue(
                    padding: const EdgeInsets.all(6),
                    borderRadius: 8,
                    onPressed: () {
                      AudioService.instance.playButtonTap();
                      ref.read(musicProvider.notifier).toggle();
                    },
                    child: Icon(
                      musicEnabled ? Icons.music_note : Icons.music_off,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(width: 6),

          // ── Pause button ──────────────────────────
          Button3D.red(
            padding: const EdgeInsets.all(8),
            borderRadius: 10,
            onPressed: () {
              AudioService.instance.playButtonTap();
              widget.onPause?.call();
            },
            child: const Icon(Icons.pause, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  static Widget _divider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.white.withValues(alpha: 0.08),
      );

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
