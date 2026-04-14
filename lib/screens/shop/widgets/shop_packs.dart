part of '../shop_screen.dart';

// ═══════════════════════════════════════════════════════════════
// Joker Pack Card — premium holographic card
// ═══════════════════════════════════════════════════════════════
class _JokerPackCard extends StatefulWidget {
  final String emoji, name, price;
  final Widget descriptionWidget;
  final String? badge;
  final Color gradStart, gradEnd;
  final VoidCallback? onBuy;
  const _JokerPackCard({
    required this.emoji,
    required this.name,
    required this.descriptionWidget,
    required this.price,
    this.badge,
    required this.gradStart,
    required this.gradEnd,
    this.onBuy,
  });

  @override
  State<_JokerPackCard> createState() => _JokerPackCardState();
}

class _JokerPackCardState extends State<_JokerPackCard> with TickerProviderStateMixin {
  late final AnimationController _shimmer;
  late final AnimationController _pulse;
  late final AnimationController _stars;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _stars = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _pulse.dispose();
    _stars.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmer, _pulse]),
      builder: (context, child) {
        final glowAlpha = 0.25 + _pulse.value * 0.2;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: [
              BoxShadow(color: widget.gradStart.withValues(alpha: glowAlpha), blurRadius: 24, spreadRadius: 2),
              BoxShadow(color: widget.gradEnd.withValues(alpha: glowAlpha * 0.5), blurRadius: 32, spreadRadius: -4),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Stack(
              children: [
                // Background gradient
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.gradStart.withValues(alpha: 0.2),
                        AppTheme.sectionBg,
                        widget.gradEnd.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      width: 2,
                      color: widget.gradStart.withValues(alpha: 0.5 + glowAlpha * 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Animated emoji icon
                      _buildEmoji(),
                      const SizedBox(width: 16),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [widget.gradStart, Colors.white, widget.gradEnd],
                              ).createShader(bounds),
                              child: Text(widget.name.toUpperCase(), style: GoogleFonts.fredoka(fontSize: AppTheme.fontBody, fontWeight: FontWeight.w900, color: Colors.white)),
                            ),
                            const SizedBox(height: 5),
                            widget.descriptionWidget,
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Price button
                      _AnimatedPriceButton(price: widget.price, large: true, onTap: widget.onBuy),
                    ],
                  ),
                ),
                // Shimmer
                Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ShimmerPainter(_shimmer.value)))),
                // Sparkle particles
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _stars,
                      builder: (context, _) => CustomPaint(painter: _SparkleParticlesPainter(_stars.value)),
                    ),
                  ),
                ),
                // Top accent line
                Positioned(
                  top: 0,
                  left: 10,
                  right: 10,
                  child: IgnorePointer(
                    child: Container(
                      height: 2.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          widget.gradStart.withValues(alpha: 0),
                          widget.gradStart,
                          widget.gradStart.withValues(alpha: 0),
                        ]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                // Badge
                if (widget.badge != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) {
                        final badgePulse = 1.0 + math.sin(_shimmer.value * math.pi * 4) * 0.08;
                        return Transform.scale(
                          scale: badgePulse,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppTheme.deathBadgeTop, AppTheme.shopNoAdsRed]),
                              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(AppTheme.radiusTiny), topRight: Radius.circular(AppTheme.radiusMedium)),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                              boxShadow: [BoxShadow(color: AppTheme.deathBadgeTop.withValues(alpha: 0.5), blurRadius: 6)],
                            ),
                            child: Text(widget.badge!, style: GoogleFonts.fredoka(fontSize: AppTheme.fontPico, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmoji() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _shimmer]),
      builder: (context, child) {
        final scale = 1.0 + _pulse.value * 0.1;
        final bounce = math.sin(_pulse.value * math.pi * 2) * 3;
        final glow = 0.3 + _pulse.value * 0.4;
        return Transform.translate(
          offset: Offset(0, bounce),
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Laser ring (diamond only)
                  if (widget.emoji == '💎')
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LaserRingPainter(
                          progress: _shimmer.value,
                          color: widget.gradStart,
                        ),
                      ),
                    ),
                  // Glow circle
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: widget.gradStart.withValues(alpha: glow), blurRadius: 16)],
                    ),
                  ),
                  // Emoji
                  Text(
                    widget.emoji,
                    style: TextStyle(
                      fontSize: AppTheme.fontLarge,
                      shadows: [
                        Shadow(color: widget.gradStart.withValues(alpha: 0.8), blurRadius: 12),
                        const Shadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Watch Ad card — holographic free joker card
// ═══════════════════════════════════════════════════════════════
class _WatchAdCard extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final String subtitle;
  const _WatchAdCard({required this.onTap, required this.label, required this.subtitle});

  @override
  State<_WatchAdCard> createState() => _WatchAdCardState();
}

class _WatchAdCardState extends State<_WatchAdCard> with TickerProviderStateMixin {
  late final AnimationController _shimmer;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmer, _pulse]),
      builder: (context, _) {
        final glowAlpha = 0.2 + _pulse.value * 0.2;
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [
                BoxShadow(color: AppTheme.orangeTop.withValues(alpha: glowAlpha), blurRadius: 24, spreadRadius: 2),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.shopDarkCard1, AppTheme.shopDarkCard2, AppTheme.shopDarkCard3],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      border: Border.all(width: 2, color: AppTheme.orangeTop.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        // Ad icon
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, _) {
                            final bounce = math.sin(_pulse.value * math.pi * 2) * 3;
                            return Transform.translate(
                              offset: Offset(0, bounce),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [AppTheme.goldPale, AppTheme.gold],
                                  ),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                                  boxShadow: [BoxShadow(color: AppTheme.gold.withValues(alpha: 0.5), blurRadius: 10)],
                                ),
                                child: const Center(child: Icon(Icons.smart_display_rounded, color: AppTheme.shopDarkCard1, size: 28)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [AppTheme.orangeTop, AppTheme.radarColor, AppTheme.orangeTop],
                                ).createShader(bounds),
                                child: Text(widget.label, style: GoogleFonts.fredoka(fontSize: AppTheme.fontBody, fontWeight: FontWeight.w900, color: Colors.white)),
                              ),
                              const SizedBox(height: 5),
                              Text(widget.subtitle, style: GoogleFonts.nunito(fontSize: AppTheme.fontTiny, fontWeight: FontWeight.w700, color: Colors.white54, height: 1.3)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _AdGratuitButton(pulse: _pulse),
                      ],
                    ),
                  ),
                  // Shimmer
                  Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ShimmerPainter(_shimmer.value)))),
                  // Badge
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.shopPackStar1, AppTheme.shopPackStar2]),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(AppTheme.radiusTiny), topRight: Radius.circular(AppTheme.radiusMedium)),
                      ),
                      child: Text('🎬 ${l10n.badgeFree}', style: GoogleFonts.fredoka(fontSize: AppTheme.fontPico, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// "GRATUIT" button with pulsing glow
// ═══════════════════════════════════════════════════════════════
class _AdGratuitButton extends StatelessWidget {
  final AnimationController pulse;
  const _AdGratuitButton({required this.pulse});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final scale = 1.0 + pulse.value * 0.04;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.shopPackStar1, AppTheme.shopPackStar2]),
              borderRadius: BorderRadius.circular(AppTheme.radiusXXTiny),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25 + pulse.value * 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shopPackStar1.withValues(alpha: 0.3 + pulse.value * 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 10 + pulse.value * 6,
                  spreadRadius: pulse.value * 2,
                ),
              ],
            ),
            child: Text(l10n.freeLabel, style: GoogleFonts.fredoka(fontSize: AppTheme.fontRegular, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Animated price button — pulsing green CTA with tap bounce
// ═══════════════════════════════════════════════════════════════
class _AnimatedPriceButton extends StatefulWidget {
  final String price;
  final bool large;
  final VoidCallback? onTap;
  const _AnimatedPriceButton({required this.price, this.large = false, this.onTap});

  @override
  State<_AnimatedPriceButton> createState() => _AnimatedPriceButtonState();
}

class _AnimatedPriceButtonState extends State<_AnimatedPriceButton> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _tap;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _tap = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.80), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.80, end: 1.12), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.97), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _tap, curve: Curves.easeOut));
  }

  @override
  void dispose() { _pulse.dispose(); _tap.dispose(); super.dispose(); }

  void _handleTap() {
    _tap.forward(from: 0);
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulse, _tap]),
        builder: (context, child) {
          final pulseScale = 1.0 + _pulse.value * 0.04;
          final tapS = _tap.isAnimating ? _tapScale.value : 1.0;
          final glowBoost = _tap.isAnimating ? 0.4 : 0.0;
          return Transform.scale(
            scale: pulseScale * tapS,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.large ? 11 : 8,
                vertical: widget.large ? 8 : 6,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.shopPackStar1, AppTheme.shopPackStar2]),
                borderRadius: BorderRadius.circular(AppTheme.radiusXXTiny),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25 + _pulse.value * 0.2 + glowBoost), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shopPackStar1.withValues(alpha: 0.3 + _pulse.value * 0.3 + glowBoost),
                    offset: const Offset(0, 4),
                    blurRadius: 10 + _pulse.value * 6 + glowBoost * 10,
                    spreadRadius: _pulse.value * 2 + glowBoost * 4,
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.price,
                  style: GoogleFonts.fredoka(fontSize: widget.large ? AppTheme.fontH4 : AppTheme.fontH3, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

