import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

/// Slot-machine style reveal: user taps SPIN, icons cycle horizontally
/// then decelerate and stop on the random joker, animated with bounce
/// + sparkles.
///
/// Returns the awarded [JokerType] (always non-null on dismiss after spin),
/// or `null` if the user closes the dialog before spinning.
class JokerRandomRevealDialog {
  JokerRandomRevealDialog._();

  /// [reward] is the joker the user wins. The dialog only animates — caller
  /// is responsible for crediting the joker afterwards.
  static Future<JokerType?> show(
    BuildContext context, {
    required JokerType reward,
  }) {
    return showDialog<JokerType>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (_) => Stack(
        fit: StackFit.expand,
        children: [
          const SpaceBackground(darken: 0.6),
          Center(
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: _RevealPanel(reward: reward),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevealPanel extends StatefulWidget {
  const _RevealPanel({required this.reward});
  final JokerType reward;

  @override
  State<_RevealPanel> createState() => _RevealPanelState();
}

class _RevealPanelState extends State<_RevealPanel>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _bounceCtrl;
  late final AnimationController _sparkleCtrl;

  static const _spinCycles = 8;
  late final List<JokerType> _track;
  late final int _finalIndex;

  bool _spinning = false;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    const pool = AdJokerTuning.rewardPool;
    // Long horizontal strip: many cycles + reward + one extra cycle so the
    // right slot of the 3-tile window is always filled at landing.
    _track = [
      for (var i = 0; i < _spinCycles; i++) ...pool,
      widget.reward,
      ...pool,
    ];
    _finalIndex = _spinCycles * pool.length; // index of reward tile
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _bounceCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSpin() async {
    if (_spinning || _revealed) return;
    setState(() => _spinning = true);
    HapticFeedback.mediumImpact();
    AudioService.instance.playSpinJoker();
    await _spinCtrl.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _spinning = false;
      _revealed = true;
    });
    HapticFeedback.heavyImpact();
    _bounceCtrl.forward(from: 0);
    _sparkleCtrl.forward(from: 0);
  }

  void _onCollect() {
    AudioService.instance.playReward();
    Navigator.pop(context, widget.reward);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = JokerUI.color(widget.reward);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.panelBorder, width: 3),
        boxShadow: const [
          BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 8)),
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 12),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.adJokerSpinTitle,
            textAlign: TextAlign.center,
            style: AppTheme.titleStyle(AppTheme.fontH2),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _revealed
                ? Text(
                    l10n.adJokerYouGot,
                    key: const ValueKey('got'),
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: AppTheme.fontRegular,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : const SizedBox(height: 20, key: ValueKey('placeholder')),
          ),
          const SizedBox(height: 16),

          // ── Horizontal slot reel ──
          _SlotReel(
            track: _track,
            finalIndex: _finalIndex,
            spin: _spinCtrl,
            bounce: _bounceCtrl,
            sparkle: _sparkleCtrl,
            revealed: _revealed,
            rewardColor: color,
          ),

          const SizedBox(height: 16),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _revealed
                ? Text(
                    JokerUI.localizedLabel(widget.reward, l10n),
                    key: const ValueKey('label'),
                    style: GoogleFonts.fredoka(
                      color: color,
                      fontSize: AppTheme.fontH2,
                      fontWeight: FontWeight.w700,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(height: 28, key: ValueKey('label-placeholder')),
          ),

          const SizedBox(height: 22),

          // ── Action button (intrinsic height, prominent) ──
          // NOTE: do NOT wrap Button3D in a fixed-height SizedBox — it
          // squeezes the inner padded content and clips the text shadow
          // (the button's natural height = padding*2 + content + depth).
          // Width is forced via `expand: true`.
          _revealed
              ? Button3D.green(
                  expand: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  onPressed: _onCollect,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.collectReward,
                        style: AppTheme.titleStyle(AppTheme.fontBody),
                      ),
                    ],
                  ),
                )
              : Button3D.purple(
                  expand: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  onPressed: _spinning ? null : _onSpin,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.casino_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.adJokerSpinCta,
                        style: AppTheme.titleStyle(AppTheme.fontBody),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

/// Horizontal slot reel: tiles slide left, decelerating to land with
/// the reward tile centered in a 3-tile window.
class _SlotReel extends StatelessWidget {
  const _SlotReel({
    required this.track,
    required this.finalIndex,
    required this.spin,
    required this.bounce,
    required this.sparkle,
    required this.revealed,
    required this.rewardColor,
  });

  final List<JokerType> track;
  final int finalIndex;
  final AnimationController spin;
  final AnimationController bounce;
  final AnimationController sparkle;
  final bool revealed;
  final Color rewardColor;

  static const _tileWidth = 96.0;
  static const _tileHeight = 96.0;
  static const _visibleTiles = 3;
  static const _windowWidth = _tileWidth * _visibleTiles;

  @override
  Widget build(BuildContext context) {
    // Tile [finalIndex] should be centered in the window (slot 1 of 3).
    // Tile i top-left x in strip = i * tw. Center of tile i = i*tw + tw/2.
    // We want that == 1.5 * tw  →  dx = (1 - i) * tw.
    final totalTravel = (finalIndex - 1) * _tileWidth;

    return SizedBox(
      width: _windowWidth,
      height: _tileHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Frame + glow
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: rewardColor.withValues(alpha: 0.55),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: rewardColor.withValues(alpha: revealed ? 0.55 : 0.15),
                  blurRadius: revealed ? 28 : 10,
                ),
              ],
            ),
          ),

          // Reel — clipped strip that slides horizontally
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 2),
            child: SizedBox(
              width: _windowWidth,
              height: _tileHeight,
              child: AnimatedBuilder(
                animation: Listenable.merge([spin, bounce]),
                builder: (_, __) {
                  final t = Curves.easeOutQuart.transform(spin.value);
                  final dx = -t * totalTravel;
                  final bounceScale = revealed
                      ? 1.0 + (math.sin(bounce.value * math.pi) * 0.14)
                      : 1.0;
                  // OverflowBox lets the giant strip exceed the parent
                  // SizedBox without triggering Flutter's overflow stripe
                  // in debug mode (ClipRRect already handles visual clip).
                  return OverflowBox(
                    minWidth: 0,
                    maxWidth: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: Offset(dx, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < track.length; i++)
                            SizedBox(
                              width: _tileWidth,
                              height: _tileHeight,
                              child: Center(
                                child: Transform.scale(
                                  scale: i == finalIndex ? bounceScale : 1.0,
                                  child: _ReelTile(type: track[i]),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Center-slot indicator (helps the user see where the reel will stop)
          IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: revealed ? 0.0 : 1.0,
              child: Container(
                width: _tileWidth,
                height: _tileHeight,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium - 4),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Sparkles when revealed
          if (revealed)
            AnimatedBuilder(
              animation: sparkle,
              builder: (_, __) => IgnorePointer(
                child: CustomPaint(
                  size: const Size(_windowWidth, _tileHeight),
                  painter: _SparklePainter(
                    progress: sparkle.value,
                    color: rewardColor,
                  ),
                ),
              ),
            ),

          // Edge fades on left/right so tiles fade as they enter/exit.
          IgnorePointer(
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusMedium - 2),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _EdgeFade(width: 60, fromLeft: true),
                  _EdgeFade(width: 60, fromLeft: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.width, required this.fromLeft});
  final double width;
  final bool fromLeft;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
            end: fromLeft ? Alignment.centerRight : Alignment.centerLeft,
            colors: const [
              Color(0xCC000000),
              Color(0x00000000),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReelTile extends StatelessWidget {
  const _ReelTile({required this.type});
  final JokerType type;

  @override
  Widget build(BuildContext context) {
    final color = JokerUI.color(type);
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(child: JokerUI.icon(type, size: 44)),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  static final _rng = math.Random(42);
  static final _seeds = List.generate(
    14,
    (_) => (
      angle: _rng.nextDouble() * math.pi * 2,
      radius: 24 + _rng.nextDouble() * 70,
      offset: _rng.nextDouble(),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final s in _seeds) {
      final t = ((progress + s.offset) % 1.0);
      final radius = s.radius * t;
      final alpha = (1 - t).clamp(0.0, 1.0);
      final p = Offset(
        center.dx + math.cos(s.angle) * radius,
        center.dy + math.sin(s.angle) * radius,
      );
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 2.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) =>
      old.progress != progress || old.color != color;
}
