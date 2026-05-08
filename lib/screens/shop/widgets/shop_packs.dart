part of '../shop_screen.dart';

// ═══════════════════════════════════════════════════════════════
// Joker Pack Card — premium holographic card
// ═══════════════════════════════════════════════════════════════
class _JokerPackCard extends StatefulWidget {
  final String emoji, name, price;
  final String? originalPrice;
  final Widget descriptionWidget;
  final String? badge;
  final String? promoBadge;
  final Color gradStart, gradEnd;
  final VoidCallback? onBuy;
  const _JokerPackCard({
    required this.emoji,
    required this.name,
    required this.descriptionWidget,
    required this.price,
    this.originalPrice,
    this.badge,
    this.promoBadge,
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
  late final AnimationController _promoPulse;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _promoPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _pulse.dispose();
    _promoPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_shimmer, _pulse]),
        child: _buildCardBody(),
        builder: (context, cardBody) {
          final glowAlpha = 0.15 + _pulse.value * 0.1;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
              boxShadow: [
                BoxShadow(color: widget.gradStart.withValues(alpha: glowAlpha), blurRadius: 16, spreadRadius: 1),
                BoxShadow(color: widget.gradEnd.withValues(alpha: glowAlpha * 0.3), blurRadius: 20, spreadRadius: -4),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
              child: cardBody!,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardBody() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.gradStart.withValues(alpha: 0.4),
                AppTheme.sectionBg,
                widget.gradEnd.withValues(alpha: 0.35),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
            border: Border.all(width: 1.5, color: widget.gradStart.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top: emoji + title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(widget.name.toUpperCase(), style: GoogleFonts.fredoka(fontSize: AppTheme.fontBody, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 10),
              // Middle: joker orbs
              widget.descriptionWidget,
              const SizedBox(height: 10),
              // Bottom: price button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.originalPrice != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        widget.originalPrice!,
                        style: GoogleFonts.fredoka(
                          fontSize: AppTheme.fontSmall,
                          fontWeight: FontWeight.w700,
                          color: Colors.white38,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppTheme.shopStrikeRed,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  _AnimatedPriceButton(price: widget.price, large: false, onTap: widget.onBuy),
                ],
              ),
            ],
          ),
        ),
        // Badge
        if (widget.badge != null)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [widget.gradStart, widget.gradEnd]),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(AppTheme.radiusTiny), topRight: Radius.circular(AppTheme.radiusTiny)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
              ),
              child: Text(widget.badge!, style: GoogleFonts.fredoka(fontSize: AppTheme.fontPico, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        // Promo badge (animated)
        if (widget.promoBadge != null)
          Positioned(
            top: 0,
            left: 0,
            child: AnimatedBuilder(
              animation: _promoPulse,
              builder: (context, child) {
                final scale = 1.0 + _promoPulse.value * 0.12;
                final glowAlpha = 0.4 + _promoPulse.value * 0.4;
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.deathBadgeTop, AppTheme.shopNoAdsRed]),
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(AppTheme.radiusTiny), topLeft: Radius.circular(AppTheme.radiusTiny)),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: AppTheme.shopNoAdsRed.withValues(alpha: glowAlpha), blurRadius: 12, spreadRadius: 1),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: Text(widget.promoBadge!, style: GoogleFonts.fredoka(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
      ],
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

class _WatchAdCardState extends State<_WatchAdCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulse,
          child: _buildCardBody(l10n),
          builder: (context, cardBody) {
            final glowAlpha = 0.12 + _pulse.value * 0.1;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
                boxShadow: [
                  BoxShadow(color: AppTheme.orangeTop.withValues(alpha: glowAlpha), blurRadius: 16, spreadRadius: 1),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
                child: cardBody!,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardBody(AppLocalizations l10n) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.shopDarkCard1, AppTheme.shopDarkCard2, AppTheme.shopDarkCard3],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
            border: Border.all(width: 1.5, color: AppTheme.orangeTop.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              // Ad icon
              Image.asset('assets/images/pub.webp', width: 40, height: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.label, style: GoogleFonts.fredoka(fontSize: AppTheme.fontBody, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(widget.subtitle, style: GoogleFonts.nunito(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w600, color: Colors.white54, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _AdGratuitButton(pulse: _pulse),
            ],
          ),
        ),
        // Badge
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.shopBuyButton1, AppTheme.shopBuyButton2]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(AppTheme.radiusTiny), topRight: Radius.circular(AppTheme.radiusMedium)),
            ),
            child: Text('🎬 ${l10n.badgeFree}', style: GoogleFonts.fredoka(fontSize: AppTheme.fontPico, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ],
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
              gradient: const LinearGradient(colors: [AppTheme.shopBuyButton1, AppTheme.shopBuyButton2]),
              borderRadius: BorderRadius.circular(AppTheme.radiusXXTiny),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25 + pulse.value * 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shopBuyButton1.withValues(alpha: 0.3 + pulse.value * 0.3),
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
    if (Button3D.vibrationEnabled) Vibration.vibrate(duration: 30);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulse, _tap]),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.price,
            style: GoogleFonts.fredoka(fontSize: widget.large ? AppTheme.fontH4 : AppTheme.fontH3, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
        builder: (context, priceText) {
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
                gradient: const LinearGradient(colors: [AppTheme.shopBuyButton1, AppTheme.shopBuyButton2]),
                borderRadius: BorderRadius.circular(AppTheme.radiusXXTiny),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25 + _pulse.value * 0.2 + glowBoost), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shopBuyButton1.withValues(alpha: 0.3 + _pulse.value * 0.3 + glowBoost),
                    offset: const Offset(0, 4),
                    blurRadius: 10 + _pulse.value * 6 + glowBoost * 10,
                    spreadRadius: _pulse.value * 2 + glowBoost * 4,
                  ),
                ],
              ),
              child: priceText,
            ),
          );
        },
      ),
    );
  }
}

