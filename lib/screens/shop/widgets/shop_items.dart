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
// Section header (title + animated divider, no card background)
// ═══════════════════════════════════════════════════════════════
class _SectionHeader extends StatefulWidget {
  final String title;
  final Color gradStart, gradEnd;
  const _SectionHeader({required this.title, required this.gradStart, required this.gradEnd});

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
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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

class _NoAdsCardState extends State<_NoAdsCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
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
      child: AnimatedBuilder(
        animation: _pulse,
        child: _buildCardBody(l10n),
        builder: (context, cardBody) {
          final glowAlpha = 0.15 + _pulse.value * 0.1;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
              boxShadow: [
                BoxShadow(color: AppTheme.gold.withValues(alpha: glowAlpha), blurRadius: 16, spreadRadius: 1),
                BoxShadow(color: AppTheme.shopSectionPurple.withValues(alpha: glowAlpha * 0.3), blurRadius: 20, spreadRadius: -4),
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
            border: Border.all(width: 1.5, color: AppTheme.gold.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top: icon + title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text('PUB', style: GoogleFonts.fredoka(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.7))),
                      const Text('🚫', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Text(l10n.noAdsTitle, style: GoogleFonts.fredoka(fontSize: AppTheme.fontBody, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
              Text(l10n.noAdsDescription, style: GoogleFonts.nunito(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w600, color: Colors.white54)),
              const SizedBox(height: 10),
              // Middle: joker orbs (same style as packs)
              _buildNoAdsJokers(),
              const SizedBox(height: 10),
              // Bottom: price button
              _AnimatedPriceButton(price: widget.price, large: false, onTap: widget.onBuy),
            ],
          ),
        ),
        // ACHAT UNIQUE badge
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.gold, AppTheme.goldAntique]),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(AppTheme.radiusTiny), topRight: Radius.circular(AppTheme.radiusTiny)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            ),
            child: Text(l10n.badgeOneTimePurchase, style: GoogleFonts.fredoka(fontSize: AppTheme.fontPico, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildNoAdsJokers() {
    Widget orb(JokerType type, int count, {double size = 18}) {
      final color = JokerUI.glowColor(type);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: [color.withValues(alpha: 0.15), AppTheme.cardBg, AppTheme.jokerOrbBgDark],
              ),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Center(child: JokerUI.icon(type, size: size)),
          ),
          const SizedBox(height: 2),
          Text(
            AppLocalizations.of(context)!.quantityFormat(count),
            style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.gold),
          ),
        ],
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          orb(JokerType.bomb, 10),
          const SizedBox(width: 6),
          orb(JokerType.wildcard, 10),
          const SizedBox(width: 6),
          orb(JokerType.reducer, 10, size: 16),
          const SizedBox(width: 6),
          // ── séparateur premium ──
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 1, height: 14, color: AppTheme.gold.withValues(alpha: 0.5)),
              const SizedBox(height: 2),
              Text('★', style: TextStyle(fontSize: AppTheme.fontMicro, color: AppTheme.gold.withValues(alpha: 0.8))),
              const SizedBox(height: 2),
              Container(width: 1, height: 14, color: AppTheme.gold.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(width: 6),
          orb(JokerType.radar, 3, size: 16),
          const SizedBox(width: 6),
          orb(JokerType.evolution, 2, size: 16),
          const SizedBox(width: 6),
          orb(JokerType.megaBomb, 2, size: 16),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMOJI PACK card — holographic card (same style as JokerPackCard)
// ═══════════════════════════════════════════════════════════════
class _EmojiPackCard extends StatefulWidget {
  final String price;
  final VoidCallback? onBuy;
  const _EmojiPackCard({required this.price, this.onBuy});

  @override
  State<_EmojiPackCard> createState() => _EmojiPackCardState();
}

class _EmojiPackCardState extends State<_EmojiPackCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  static const _gradStart = Color(0xFFF48FB1);
  static const _gradEnd = Color(0xFFCE93D8);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulse,
        child: _buildCardBody(),
        builder: (context, cardBody) {
          final glowAlpha = 0.15 + _pulse.value * 0.1;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
              boxShadow: [
                BoxShadow(color: _gradStart.withValues(alpha: glowAlpha), blurRadius: 16, spreadRadius: 1),
                BoxShadow(color: _gradEnd.withValues(alpha: glowAlpha * 0.3), blurRadius: 20, spreadRadius: -4),
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
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x66F48FB1), // gradStart @ 0.4
                AppTheme.sectionBg,
                Color(0x59CE93D8), // gradEnd @ 0.35
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
            border: Border.all(width: 1.5, color: _gradStart.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top: emoji + title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(l10n.packEmojiPackName.toUpperCase(), style: GoogleFonts.fredoka(fontSize: AppTheme.fontBody, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 4),
              Text(l10n.emojiPackDesc, style: GoogleFonts.nunito(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w600, color: Colors.white54)),
              const SizedBox(height: 10),
              // Middle: emoji orbs preview
              _buildEmojiOrbs(),
              const SizedBox(height: 10),
              // Bottom: price button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AnimatedPriceButton(price: widget.price, large: false, onTap: widget.onBuy),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiOrbs() {
    Widget emojiOrb(String asset, Color color) {
      return SvgPicture.asset(asset, width: 24, height: 24, colorFilter: ColorFilter.mode(color, BlendMode.srcIn));
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          emojiOrb('assets/shapes/emoji/heart.svg', const Color(0xFFFF1744)),
          const SizedBox(width: 6),
          emojiOrb('assets/shapes/emoji/bolt.svg', const Color(0xFFFFEA00)),
          const SizedBox(width: 6),
          emojiOrb('assets/shapes/emoji/moon.svg', const Color(0xFFE040FB)),
          const SizedBox(width: 6),
          emojiOrb('assets/shapes/emoji/flame.svg', const Color(0xFFFF6D00)),
          const SizedBox(width: 6),
          emojiOrb('assets/shapes/emoji/clover.svg', const Color(0xFF00E676)),
          const SizedBox(width: 6),
          emojiOrb('assets/shapes/emoji/cloud.svg', const Color(0xFF40C4FF)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Free Joker Slot — compact row for Watch Ad.
//
// Cooldown-aware: when the rewarded-joker cooldown (5 min) is active OR
// the daily cap is reached, the card displays a padlock + countdown,
// dims to ~55% opacity, and the tap is intercepted to show a snackbar.
// ═══════════════════════════════════════════════════════════════
class _FreeJokerSlot extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  final String label;
  const _FreeJokerSlot({required this.onTap, required this.label});

  @override
  ConsumerState<_FreeJokerSlot> createState() => _FreeJokerSlotState();
}

class _FreeJokerSlotState extends ConsumerState<_FreeJokerSlot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  /// Per-second tick so the cooldown countdown stays live without forcing
  /// a provider re-emit.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  String _formatCooldown(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final storage = ref.watch(localStorageProvider).valueOrNull;

    final cooldown = storage?.adJokerCooldownRemaining ?? Duration.zero;
    final adsLeft = storage?.adJokerAdsLeftToday;
    final reachedCap = adsLeft == 0;
    final inCooldown = cooldown > Duration.zero;
    final blocked = reachedCap || inCooldown;

    // Subtitle is overridden when blocked so users instantly see why.
    final String subtitle;
    if (reachedCap) {
      subtitle = l10n.adJokerLimitTomorrow;
    } else if (inCooldown) {
      subtitle = '${l10n.adJokerCooldownLabel} ${_formatCooldown(cooldown)}';
    } else {
      subtitle = widget.label;
    }

    void handleTap() {
      if (!blocked) {
        widget.onTap();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reachedCap
                ? l10n.adJokerLimitTomorrow
                : '${l10n.adJokerCooldownLabel} ${_formatCooldown(cooldown)}',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppTheme.hubDangerRed1,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Opacity(
      opacity: blocked ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: handleTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.orangeTop.withValues(alpha: 0.3), AppTheme.sectionBg],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
            border: Border.all(
              color: blocked
                  ? Colors.white24
                  : AppTheme.orangeTop.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Ad icon with optional padlock overlay when blocked.
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset('assets/images/pub.webp', width: 40, height: 40),
                    if (blocked)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.watchAd.toUpperCase(),
                        style: GoogleFonts.fredoka(fontSize: AppTheme.fontBody, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text(subtitle,
                        style: GoogleFonts.nunito(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w600, color: Colors.white54)),
                  ],
                ),
              ),
              // Action chip: pulsing GRATUIT when available, static M:SS / cap
              // chip when blocked, so users see at-a-glance why they can't tap.
              if (blocked)
                _BlockedAdChip(
                  text: reachedCap
                      ? l10n.adJokerCapBadge
                      : _formatCooldown(cooldown),
                )
              else
                _AdGratuitButton(pulse: _pulse),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Static red chip shown in place of "GRATUIT" when the ad joker is on
// cooldown or has hit its daily cap. Mirrors the styling of the hub's
// AdRewardGemButton countdown badge for consistency.
// ═══════════════════════════════════════════════════════════════
class _BlockedAdChip extends StatelessWidget {
  final String text;
  const _BlockedAdChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.hubDangerRed1, AppTheme.hubDangerRed2],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXXTiny),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.fredoka(
              fontSize: AppTheme.fontRegular,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Hero Pack Card — dominant CTA for the main product (Pack Rescue)
// ═══════════════════════════════════════════════════════════════
class _HeroPackCard extends StatefulWidget {
  final String emoji, name, price;
  final String? originalPrice, badge, description;
  final Widget contentsWidget;
  final Color gradStart, gradEnd;
  final VoidCallback? onBuy;
  const _HeroPackCard({
    required this.emoji,
    required this.name,
    required this.contentsWidget,
    required this.price,
    this.originalPrice,
    this.badge,
    this.description,
    required this.gradStart,
    required this.gradEnd,
    this.onBuy,
  });

  @override
  State<_HeroPackCard> createState() => _HeroPackCardState();
}

class _HeroPackCardState extends State<_HeroPackCard> with TickerProviderStateMixin {
  late final AnimationController _shimmer;
  late final AnimationController _pulse;
  late final AnimationController _badgePulse;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _badgePulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _pulse.dispose();
    _badgePulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_shimmer, _pulse]),
        child: _buildCardBody(),
        builder: (context, cardBody) {
          final glowAlpha = 0.2 + _pulse.value * 0.12;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
              boxShadow: [
                BoxShadow(color: widget.gradStart.withValues(alpha: glowAlpha), blurRadius: 20, spreadRadius: 2),
                BoxShadow(color: widget.gradEnd.withValues(alpha: glowAlpha * 0.4), blurRadius: 24, spreadRadius: -2),
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
                widget.gradStart.withValues(alpha: 0.45),
                AppTheme.sectionBg,
                widget.gradEnd.withValues(alpha: 0.4),
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
                  Text(widget.name, style: GoogleFonts.fredoka(fontSize: AppTheme.fontBody, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
              if (widget.description != null) ...[
                const SizedBox(height: 2),
                Text(widget.description!, style: GoogleFonts.nunito(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w600, color: Colors.white54)),
              ],
              const SizedBox(height: 10),
              // Middle: joker orbs
              widget.contentsWidget,
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
                          fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w700, color: Colors.white38,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppTheme.shopStrikeRed, decorationThickness: 2,
                        ),
                      ),
                    ),
                  _AnimatedPriceButton(price: widget.price, large: false, onTap: widget.onBuy),
                ],
              ),
            ],
          ),
        ),

        // Badge "MEILLEUR CHOIX" (animated, red)
        if (widget.badge != null)
          Positioned(
            top: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _badgePulse,
              builder: (context, child) {
                final scale = 1.0 + _badgePulse.value * 0.12;
                final glowAlpha = 0.4 + _badgePulse.value * 0.4;
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.deathBadgeTop, AppTheme.shopNoAdsRed]),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppTheme.radiusTiny),
                        topRight: Radius.circular(AppTheme.radiusTiny),
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: AppTheme.shopNoAdsRed.withValues(alpha: glowAlpha), blurRadius: 12, spreadRadius: 1),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: Text(widget.badge!,
                  style: GoogleFonts.fredoka(fontSize: AppTheme.fontPico, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
            ),
          ),
      ],
    );
  }
}

