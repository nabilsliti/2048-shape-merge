import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';

// ═══════════════════════════════════════════════════════════════
// Animated XP Badge — bounce + rolling counter + floating +N XP
// ═══════════════════════════════════════════════════════════════
class AnimatedXpBadge extends StatefulWidget {
  const AnimatedXpBadge({super.key, required this.currentXP, required this.xpNeeded});

  final int currentXP;
  final int xpNeeded;

  @override
  State<AnimatedXpBadge> createState() => _AnimatedXpBadgeState();
}

class _AnimatedXpBadgeState extends State<AnimatedXpBadge>
    with TickerProviderStateMixin {
  late final AnimationController _bounce;
  late final AnimationController _plusLabel;
  late final AnimationController _counterRoll;
  late final AnimationController _ring;
  late final AnimationController _sparkles;

  int _displayXP = 0;
  int _prevXP = 0;
  int _gainedXP = 0;
  bool _isRolling = false;

  @override
  void initState() {
    super.initState();
    _displayXP = widget.currentXP;
    _prevXP = widget.currentXP;
    _bounce = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..addListener(() => setState(() {}));
    _plusLabel = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..addListener(() => setState(() {}));
    _counterRoll = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() {
            _isRolling = false;
            _displayXP = widget.currentXP;
          });
        }
      })
      ..addListener(() => setState(() {}));
    _ring = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..addListener(() => setState(() {}));
    _sparkles = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant AnimatedXpBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentXP == oldWidget.currentXP) return;

    _bounce.forward(from: 0);
    _ring.forward(from: 0);
    _sparkles.forward(from: 0);

    if (widget.currentXP > oldWidget.currentXP) {
      setState(() {
        _prevXP = oldWidget.currentXP;
        _gainedXP = widget.currentXP - oldWidget.currentXP;
        _isRolling = true;
      });
      _plusLabel.forward(from: 0);
      _counterRoll.forward(from: 0);
    } else {
      // Level-up reset — update display immediately
      setState(() {
        _isRolling = false;
        _displayXP = widget.currentXP;
      });
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    _plusLabel.dispose();
    _counterRoll.dispose();
    _ring.dispose();
    _sparkles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bounce: elastic scale 1 → 1.35 → 0.92 → 1
    final double bounceScale;
    if (_bounce.value < 0.3) {
      bounceScale = 1.0 + (_bounce.value / 0.3) * 0.35;
    } else if (_bounce.value < 0.6) {
      bounceScale = 1.35 - ((_bounce.value - 0.3) / 0.3) * 0.43;
    } else {
      bounceScale = 0.92 + ((_bounce.value - 0.6) / 0.4) * 0.08;
    }

    // Glow peaks at bounce peak
    final glowT =
        _bounce.value < 0.5 ? _bounce.value * 2 : 2 - _bounce.value * 2;

    // Rolling counter — fiable avec flag booléen
    final counterShown = _isRolling
        ? (_prevXP +
                (widget.currentXP - _prevXP) *
                    Curves.easeInOut.transform(_counterRoll.value))
            .round()
            .clamp(0, widget.xpNeeded)
        : _displayXP;

    // Floating +N XP label (floats downward to stay visible below status bar)
    final plusProgress = Curves.easeOutCubic.transform(_plusLabel.value);
    final plusOpacity = (1.0 - _plusLabel.value * 1.2).clamp(0.0, 1.0);
    final plusOffset = 50.0 * plusProgress;

    const color = AppTheme.xpBadgeBot;

    final badge = Transform.scale(
      scale: _bounce.isAnimating ? bounceScale : 1.0,
      child: Container(
        constraints: const BoxConstraints(minWidth: 80, minHeight: 46),
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.xpBadgeTop, AppTheme.xpBadgeBot],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.xpBadgeBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55 + glowT * 0.45),
              blurRadius: _bounce.isAnimating ? 14 + glowT * 16 : 14,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(color: Colors.black54, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('⚡', style: TextStyle(fontSize: AppTheme.fontRegular, height: 1)),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.xpLabel,
                    style: AppTheme.titleStyle(AppTheme.fontPico).copyWith(
                        color: AppTheme.goldLabel,
                        letterSpacing: 1,
                        height: 1)),
                Text(
                  '$counterShown/${widget.xpNeeded}',
                  style: GoogleFonts.fredoka(
                    fontSize: AppTheme.fontRegular,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    shadows: const [
                      Shadow(color: Colors.black38, blurRadius: 4)
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Expanding ring
    final ringRadius = 30.0 + _ring.value * 50.0;
    final ringOpacity = (1.0 - _ring.value).clamp(0.0, 1.0) * 0.7;

    return UnconstrainedBox(
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          badge,
          // Expanding ring pulse
          if (_ring.isAnimating)
            Positioned.fill(
              child: Center(
                child: Container(
                  width: ringRadius * 2,
                  height: ringRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: ringOpacity),
                      width: 2.5 * (1 - _ring.value),
                    ),
                  ),
                ),
              ),
            ),
          // Sparkle particles
          if (_sparkles.isAnimating)
            for (var i = 0; i < 8; i++)
              Positioned(
                top: 23 + sin((i / 8) * 2 * pi) * 35 * _sparkles.value - 4,
                left: 40 + cos((i / 8) * 2 * pi) * 45 * _sparkles.value - 4,
                child: Opacity(
                  opacity: (1.0 - _sparkles.value).clamp(0.0, 1.0),
                  child: i.isEven
                      ? Icon(Icons.star, size: 8 * (1 - _sparkles.value * 0.5), color: AppTheme.gold)
                      : Container(
                          width: 5 * (1 - _sparkles.value * 0.5),
                          height: 5 * (1 - _sparkles.value * 0.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)],
                          ),
                        ),
                ),
              ),
        if (_plusLabel.isAnimating && _gainedXP > 0)
          Positioned(
            bottom: plusOffset - 46,
            child: Opacity(
              opacity: plusOpacity,
              child: Text(
                '+$_gainedXP XP',
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontBody,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.gold,
                  shadows: [
                    Shadow(
                        color: AppTheme.gold.withValues(alpha: 0.8), blurRadius: 10),
                    const Shadow(color: Colors.black87, blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
