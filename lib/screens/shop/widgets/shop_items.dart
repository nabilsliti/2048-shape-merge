part of '../shop_screen.dart';

// ═══════════════════════════════════════════════════════════════
// Inventory card — all 6 jokers, free / premium separated
// ═══════════════════════════════════════════════════════════════
class _InventoryCard extends StatelessWidget {
  final JokerInventory inventory;
  const _InventoryCard({required this.inventory});

  @override
  Widget build(BuildContext context) {
    final inv = inventory;
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        // ── Classique ──
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: BoxDecoration(
              color: AppTheme.blueTop.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
              border: Border.all(color: AppTheme.blueTop.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videogame_asset_rounded, color: AppTheme.blueTop, size: 11),
                    const SizedBox(width: 4),
                    Text(l10n.jokerCategoryClassic,
                        style: GoogleFonts.fredoka(fontSize: AppTheme.fontNano, fontWeight: FontWeight.w700, color: AppTheme.blueTop, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Center(child: _JokerStock(icon: JokerUI.icon(JokerType.bomb, size: 22), color: JokerUI.color(JokerType.bomb), count: inv.bomb, name: l10n.jokerBomb))),
                    Expanded(child: Center(child: _JokerStock(icon: JokerUI.icon(JokerType.wildcard, size: 22), color: JokerUI.color(JokerType.wildcard), count: inv.wildcard, name: l10n.jokerWildcard))),
                    Expanded(child: Center(child: _JokerStock(icon: JokerUI.icon(JokerType.reducer, size: 18), color: JokerUI.color(JokerType.reducer), count: inv.reducer, name: l10n.jokerReducer))),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // ── Premium ──
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: AppTheme.gold, size: 11),
                    const SizedBox(width: 4),
                    Text(l10n.jokerCategoryPremium,
                        style: GoogleFonts.fredoka(fontSize: AppTheme.fontNano, fontWeight: FontWeight.w700, color: AppTheme.gold, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Center(child: _JokerStock(icon: JokerUI.icon(JokerType.radar, size: 22), color: JokerUI.color(JokerType.radar), count: inv.radar, name: l10n.jokerRadar))),
                    Expanded(child: Center(child: _JokerStock(icon: JokerUI.icon(JokerType.evolution, size: 22), color: JokerUI.color(JokerType.evolution), count: inv.evolution, name: l10n.jokerEvolution))),
                    Expanded(child: Center(child: _JokerStock(icon: JokerUI.icon(JokerType.megaBomb, size: 22), color: JokerUI.color(JokerType.megaBomb), count: inv.megaBomb, name: l10n.jokerMegaBomb))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// No-Ads icon: red circle with "AD" crossed out
// ═══════════════════════════════════════════════════════════════
class _NoAdsIcon extends StatelessWidget {
  final double size;
  const _NoAdsIcon({this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _NoAdsIconPainter()));
  }
}

class _NoAdsIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    canvas.drawCircle(center, radius, Paint()
      ..color = AppTheme.shopNoAdsRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'AD',
        style: TextStyle(color: Colors.white, fontSize: size.width * 0.38, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));

    final offset = radius * 0.7;
    canvas.drawLine(
      Offset(center.dx - offset, center.dy + offset),
      Offset(center.dx + offset, center.dy - offset),
      Paint()..color = AppTheme.shopNoAdsRed..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// No-Ads section header
// ═══════════════════════════════════════════════════════════════
class _SectionHeader extends StatefulWidget {
  final String title;
  final Widget? leading;
  final Color gradStart, gradEnd;
  const _SectionHeader({required this.title, this.leading, required this.gradStart, required this.gradEnd});

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() { _shimmer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final glow = 0.15 + math.sin(_shimmer.value * math.pi * 2) * 0.1;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.gradStart.withValues(alpha: 0.15),
                AppTheme.sectionBg,
                widget.gradEnd.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            boxShadow: [BoxShadow(color: widget.gradStart.withValues(alpha: glow), blurRadius: 12)],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: 8),
                  ],
                  ShaderMask(
                    shaderCallback: (bounds) {
                      final offset = _shimmer.value * bounds.width * 2 - bounds.width * 0.5;
                      return LinearGradient(
                        colors: [Colors.white, widget.gradStart, Colors.white.withValues(alpha: 0.95), widget.gradEnd, Colors.white],
                        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                        transform: GradientRotation(offset * 0.01),
                      ).createShader(bounds);
                    },
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(fontSize: AppTheme.fontRegular, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    widget.gradStart.withValues(alpha: 0),
                    widget.gradStart.withValues(alpha: 0.8),
                    widget.gradEnd.withValues(alpha: 0.8),
                    widget.gradEnd.withValues(alpha: 0),
                  ]),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: widget.gradStart.withValues(alpha: 0.5), blurRadius: 6)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ZÉRO PUB card — gold premium card
// ═══════════════════════════════════════════════════════════════
class _NoAdsCard extends StatefulWidget {
  final String price;
  final VoidCallback? onBuy;
  const _NoAdsCard({required this.price, this.onBuy});

  @override
  State<_NoAdsCard> createState() => _NoAdsCardState();
}

class _NoAdsCardState extends State<_NoAdsCard> with TickerProviderStateMixin {
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
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmer, _pulse]),
      builder: (context, child) {
        final glowAlpha = 0.25 + _pulse.value * 0.2;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: [
              BoxShadow(color: AppTheme.gold.withValues(alpha: glowAlpha), blurRadius: 24, spreadRadius: 2),
              BoxShadow(color: AppTheme.shopSectionPurple.withValues(alpha: glowAlpha * 0.5), blurRadius: 32, spreadRadius: -4),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Stack(
              children: [
                // Background gradient
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.shopDarkCard1, AppTheme.shopDarkCard2, AppTheme.shopDarkCard3],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(width: 2, color: AppTheme.gold),
                  ),
                  child: Row(
                    children: [
                      _buildShield(),
                      const SizedBox(width: 16),
                      Expanded(child: _buildContent()),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '10,99 €',
                            style: GoogleFonts.nunito(
                              fontSize: AppTheme.fontTiny, fontWeight: FontWeight.w700, color: Colors.white38,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppTheme.shopStrikeRed, decorationThickness: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _AnimatedPriceButton(price: widget.price, large: true, onTap: widget.onBuy),
                        ],
                      ),
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
                // ACHAT UNIQUE badge
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.gold, AppTheme.goldAntique]),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(AppTheme.radiusTiny), topRight: Radius.circular(AppTheme.radiusMedium)),
                    ),
                    child: Text(l10n.badgeOneTimePurchase, style: GoogleFonts.fredoka(fontSize: AppTheme.fontPico, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShield() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = 1.0 + _pulse.value * 0.08;
        final glow = 0.3 + _pulse.value * 0.4;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 72,
            height: 80,
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: AppTheme.gold.withValues(alpha: glow), blurRadius: 16)],
            ),
            child: CustomPaint(painter: _ShieldNoPainter()),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 2),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.gold, AppTheme.goldShimmer, AppTheme.gold],
          ).createShader(bounds),
          child: Text(l10n.noAdsTitle, style: GoogleFonts.fredoka(fontSize: AppTheme.fontBody, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        const SizedBox(height: 5),
        Text(
          l10n.noAdsDescription,
          style: GoogleFonts.nunito(fontSize: AppTheme.fontTiny, fontWeight: FontWeight.w700, color: Colors.white54, height: 1.3),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            JokerUI.icon(JokerType.bomb, size: 20),
            const SizedBox(width: 3),
            Text('×10', style: GoogleFonts.fredoka(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w800, color: JokerUI.color(JokerType.bomb))),
            const SizedBox(width: 10),
            JokerUI.icon(JokerType.wildcard, size: 20),
            const SizedBox(width: 3),
            Text('×10', style: GoogleFonts.fredoka(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w800, color: JokerUI.color(JokerType.wildcard))),
            const SizedBox(width: 10),
            JokerUI.icon(JokerType.reducer, size: 16),
            const SizedBox(width: 3),
            Text('×10', style: GoogleFonts.fredoka(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w800, color: JokerUI.color(JokerType.reducer))),
          ],
        ),
      ],
    );
  }
}

