part of '../shop_screen.dart';

// ═══════════════════════════════════════════════════════════════
// Joker inventory stock display — gem-earn style animation
// ═══════════════════════════════════════════════════════════════
class _JokerStock extends StatefulWidget {
  final Widget icon;
  final Color color;
  final int count;
  final String name;
  const _JokerStock({required this.icon, required this.color, required this.count, required this.name});

  @override
  State<_JokerStock> createState() => _JokerStockState();
}

class _JokerStockState extends State<_JokerStock> with TickerProviderStateMixin {
  late final AnimationController _bounce;
  late final AnimationController _ring;
  late final AnimationController _sparkles;
  late final AnimationController _plusOne;
  late final AnimationController _counterRoll;
  late final Listenable _allAnimations;

  int _displayCount = 0;
  int _prevCount = 0;

  // Random sparkle offsets (generated once per trigger)
  final List<_SparkleData> _sparkleParticles = [];

  @override
  void initState() {
    super.initState();
    _displayCount = widget.count;
    _prevCount = widget.count;
    _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _sparkles = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _plusOne = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _counterRoll = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _displayCount = widget.count;
        }
      });
    _allAnimations = Listenable.merge([_bounce, _ring, _sparkles, _plusOne, _counterRoll]);
  }

  @override
  void didUpdateWidget(covariant _JokerStock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _log.debug('didUpdateWidget: old=${oldWidget.count} new=${widget.count}');
    if (widget.count > oldWidget.count) {
      _prevCount = oldWidget.count;
      _generateSparkles();
      _bounce.forward(from: 0);
      _ring.forward(from: 0);
      _sparkles.forward(from: 0);
      _plusOne.forward(from: 0);
      _counterRoll.forward(from: 0);
    } else {
      _displayCount = widget.count;
    }
  }

  void _generateSparkles() {
    final rng = math.Random();
    _sparkleParticles.clear();
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi + rng.nextDouble() * 0.5;
      _sparkleParticles.add(_SparkleData(
        angle: angle,
        distance: 25.0 + rng.nextDouble() * 30.0,
        size: 3.0 + rng.nextDouble() * 4.0,
        isStar: rng.nextBool(),
      ));
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    _ring.dispose();
    _sparkles.dispose();
    _plusOne.dispose();
    _counterRoll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _allAnimations,
      builder: (context, _) {
    // Bounce: elastic feel — scale 1→1.5→0.9→1
    final double bounceScale;
    if (_bounce.value < 0.3) {
      bounceScale = 1.0 + (_bounce.value / 0.3) * 0.5; // 1→1.5
    } else if (_bounce.value < 0.6) {
      bounceScale = 1.5 - ((_bounce.value - 0.3) / 0.3) * 0.6; // 1.5→0.9
    } else {
      bounceScale = 0.9 + ((_bounce.value - 0.6) / 0.4) * 0.1; // 0.9→1
    }

    // Glow intensity
    final glowIntensity = _bounce.value < 0.5
        ? _bounce.value * 2
        : 2 - _bounce.value * 2;

    // Ring expanding outward
    final ringRadius = 20.0 + _ring.value * 40.0;
    final ringOpacity = (1.0 - _ring.value).clamp(0.0, 1.0) * 0.8;

    // +1 floats up with elastic fade
    final plusProgress = Curves.easeOutCubic.transform(_plusOne.value);
    final plusOpacity = (1.0 - _plusOne.value * 0.8).clamp(0.0, 1.0);
    final plusOffset = -50.0 * plusProgress;
    final plusScale = _plusOne.value < 0.15
        ? _plusOne.value / 0.15 * 1.3
        : 1.3 - (_plusOne.value - 0.15) * 0.35;

    // Counter roll
    final counterShown = _counterRoll.isAnimating
        ? _prevCount + ((_displayCount - _prevCount + 1) * Curves.easeOut.transform(_counterRoll.value)).round().clamp(0, widget.count)
        : _displayCount;

    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Expanding ring pulse
          if (_ring.isAnimating)
            Positioned(
              top: 10,
              child: Container(
                width: ringRadius * 2,
                height: ringRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: ringOpacity),
                    width: 2.5 * (1 - _ring.value),
                  ),
                ),
              ),
            ),

          // Sparkle particles
          if (_sparkles.isAnimating)
            for (final sp in _sparkleParticles)
              Positioned(
                top: 18 + math.sin(sp.angle) * sp.distance * _sparkles.value,
                left: 45 + math.cos(sp.angle) * sp.distance * _sparkles.value,
                child: Opacity(
                  opacity: (1.0 - _sparkles.value).clamp(0.0, 1.0),
                  child: sp.isStar
                      ? Icon(Icons.star, size: sp.size * (1 - _sparkles.value * 0.5), color: widget.color)
                      : Container(
                          width: sp.size * (1 - _sparkles.value * 0.5),
                          height: sp.size * (1 - _sparkles.value * 0.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.color,
                            boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.6), blurRadius: 4)],
                          ),
                        ),
                ),
              ),

          // Main icon + counter
          Transform.scale(
            scale: _bounce.isAnimating ? bounceScale : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: glowIntensity > 0
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: widget.color.withValues(alpha: glowIntensity * 0.8), blurRadius: 24, spreadRadius: 4),
                            BoxShadow(color: Colors.white.withValues(alpha: glowIntensity * 0.3), blurRadius: 12),
                          ],
                        )
                      : null,
                  child: SizedBox(
                    height: 36,
                    child: Center(child: widget.icon),
                  ),
                ),
                const SizedBox(height: 4),
                // Counter with flash
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: GoogleFonts.fredoka(
                    fontSize: _bounce.isAnimating ? AppTheme.fontH2 : AppTheme.fontH4,
                    fontWeight: FontWeight.w900,
                    color: _bounce.isAnimating ? Colors.white : (widget.count > 0 ? AppTheme.gold : AppTheme.muted),
                    shadows: _bounce.isAnimating
                        ? [Shadow(color: widget.color, blurRadius: 12)]
                        : [],
                  ),
                  child: Text('×$counterShown'),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.name,
                  style: GoogleFonts.fredoka(
                    fontSize: AppTheme.fontNano,
                    fontWeight: FontWeight.w600,
                    color: widget.color.withValues(alpha: 0.8),
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Floating "+1" text
          if (_plusOne.isAnimating)
            Positioned(
              top: plusOffset - 5,
              child: Transform.scale(
                scale: plusScale.clamp(0.5, 1.5),
                child: Opacity(
                  opacity: plusOpacity,
                  child: Text(
                    '+1',
                    style: GoogleFonts.fredoka(
                      fontSize: AppTheme.fontH1,
                      fontWeight: FontWeight.w900,
                      color: widget.color,
                      shadows: [
                        Shadow(color: widget.color.withValues(alpha: 0.8), blurRadius: 12),
                        const Shadow(color: Colors.white24, blurRadius: 4),
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
}

class _SparkleData {
  final double angle;
  final double distance;
  final double size;
  final bool isStar;
  const _SparkleData({required this.angle, required this.distance, required this.size, required this.isStar});
}

