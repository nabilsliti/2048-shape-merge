import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/core/widgets/ad_banner_widget.dart';

import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/core/services/iap_service.dart';
import 'package:shape_merge/providers/ads_provider.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/iap_provider.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

/// Standalone screen (used by router for /shop fallback).
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SpaceBackground()),
          const ShopScreenContent(),
        ],
      ),
    );
  }
}

/// Embeddable content widget used inside MainHubScreen tab.
class ShopScreenContent extends ConsumerStatefulWidget {
  const ShopScreenContent({super.key});

  @override
  ConsumerState<ShopScreenContent> createState() => _ShopScreenContentState();
}

class _ShopScreenContentState extends ConsumerState<ShopScreenContent> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inventory = ref.watch(gameStateProvider).jokerInventory;
    final noAds = ref.watch(noAdsPurchasedProvider);

    // Init IAP (idempotent)
    ref.watch(iapReadyProvider);
    final iap = ref.read(iapServiceProvider);

    // Preload rewarded ad
    final adsService = ref.read(adsServiceProvider);
    adsService.loadRewardedAd();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
            child: SizedBox(
              height: 50,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Button3D.yellow(
                      padding: EdgeInsets.zero,
                      borderRadius: 22,
                      onPressed: () => context.go('/home'),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(l10n.shop.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontH2)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Current inventory ──
                  _InventoryCard(inventory: inventory),
                  const SizedBox(height: 20),

                  // ── ZÉRO PUB section ──
                  if (!noAds) ...[
                    const _NoAdsSectionHeader(
                      gradStart: AppTheme.gold,
                      gradEnd: AppTheme.victoryBadgeBot,
                    ),
                    const SizedBox(height: 4),
                    _NoAdsCard(
                      price: iap.price(IapProducts.noAds),
                      onBuy: () => _buyProduct(context, ref, IapProducts.noAds),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── PACKS JOKERS section ──
                  _SectionHeader(
                    title: '🎁 ${l10n.sectionJokerPacks}',
                    gradStart: AppTheme.shopSectionCyan,
                    gradEnd: AppTheme.shopSectionPurple,
                  ),
                  const SizedBox(height: 12),

                  // Pack Étoile (small)
                  _JokerPackCard(
                    emoji: '⭐',
                    name: l10n.packStarName,
                    descriptionWidget: _buildPackContents(5, 1, 0, 0),
                    price: iap.price(IapProducts.packStar),
                    badge: l10n.badgeStarter,
                    gradStart: AppTheme.shopPackStar1,
                    gradEnd: AppTheme.shopPackStar2,
                    onBuy: () => _buyProduct(context, ref, IapProducts.packStar),
                  ),
                  const SizedBox(height: 12),

                  // Pack Comète (medium)
                  _JokerPackCard(
                    emoji: '☄️',
                    name: l10n.packCometName,
                    descriptionWidget: _buildPackContents(15, 3, 2, 2),
                    price: iap.price(IapProducts.packComet),
                    badge: l10n.badgePopular,
                    gradStart: AppTheme.shopPackComet1,
                    gradEnd: AppTheme.shopPackComet2,
                    onBuy: () => _buyProduct(context, ref, IapProducts.packComet),
                  ),
                  const SizedBox(height: 12),

                  // Pack Diamant (large)
                  _JokerPackCard(
                    emoji: '💎',
                    name: l10n.packDiamondName,
                    descriptionWidget: _buildPackContents(40, 8, 5, 5),
                    price: iap.price(IapProducts.packDiamond),
                    badge: l10n.badgeBestValue,
                    gradStart: AppTheme.shopPackDiamond1,
                    gradEnd: AppTheme.shopPackDiamond2,
                    onBuy: () => _buyProduct(context, ref, IapProducts.packDiamond),
                  ),
                  const SizedBox(height: 24),

                  // ── Watch ad for free joker ──
                  _SectionHeader(
                    title: '🎬 ${l10n.sectionFreeJoker}',
                    gradStart: AppTheme.orangeTop,
                    gradEnd: AppTheme.radarColor,
                  ),
                  const SizedBox(height: 12),
                  _WatchAdCard(
                    onTap: () => _watchAdAndChooseJoker(context, ref),
                    label: l10n.watchAd.toUpperCase(),
                    subtitle: l10n.watchAdReward,
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Ad banner
          if (!noAds) const AdBannerWidget(),
        ],
      ),
    );
  }

  Future<void> _buyProduct(BuildContext context, WidgetRef ref, String productId) async {
    final iap = ref.read(iapServiceProvider);

    // Register a one-shot status listener for feedback
    iap.onStatusChanged = (result) {

      // Update noAds provider reactively
      if (result.productId == IapProducts.noAds &&
          (result.status == IapStatus.purchased || result.status == IapStatus.restored)) {
        ref.read(noAdsPurchasedProvider.notifier).state = true;
      }

      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;

      if (result.status == IapStatus.purchased) {
        // Scroll to top to show inventory animation
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${l10n.purchaseSuccess}', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: AppTheme.greenTop,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (result.status == IapStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? l10n.purchaseError,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: AppTheme.redTop,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };

    await iap.buy(productId);
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    final iap = ref.read(iapServiceProvider);

    iap.onStatusChanged = (result) {
      if (result.productId == IapProducts.noAds &&
          (result.status == IapStatus.purchased || result.status == IapStatus.restored)) {
        ref.read(noAdsPurchasedProvider.notifier).state = true;
      }

      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;

      if (result.status == IapStatus.restored) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${l10n.purchasesRestored}', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: AppTheme.greenTop,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    };

    await iap.restorePurchases();

    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.restoringPurchases,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: AppTheme.blueTop,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildPackContents(int free, int radar, int evolution, int megaBomb) {
    Widget item(Widget icon, int count, Color color) {
      if (count <= 0) return const SizedBox.shrink();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 3),
          Text('×$count', style: GoogleFonts.fredoka(fontSize: AppTheme.fontXSmall, fontWeight: FontWeight.w800, color: color)),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        item(JokerUI.icon(JokerType.bomb, size: 18), free, JokerUI.color(JokerType.bomb)),
        item(JokerUI.icon(JokerType.wildcard, size: 18), free, JokerUI.color(JokerType.wildcard)),
        item(JokerUI.icon(JokerType.reducer, size: 16), free, JokerUI.color(JokerType.reducer)),
        if (radar > 0) item(JokerUI.icon(JokerType.radar, size: 16), radar, JokerUI.color(JokerType.radar)),
        if (evolution > 0) item(JokerUI.icon(JokerType.evolution, size: 16), evolution, JokerUI.color(JokerType.evolution)),
        if (megaBomb > 0) item(JokerUI.icon(JokerType.megaBomb, size: 16), megaBomb, JokerUI.color(JokerType.megaBomb)),
      ],
    );
  }

  Future<void> _watchAdAndChooseJoker(BuildContext context, WidgetRef ref) async {
    final adsService = ref.read(adsServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    final rewarded = await adsService.showRewardedAd(onRewarded: () {});

    if (!rewarded) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adNotReady, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: AppTheme.redTop,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      adsService.loadRewardedAd();
      return;
    }

    if (context.mounted) {
      await _showJokerChoiceDialog(context, ref);
    }
  }

  Future<void> _showJokerChoiceDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final chosenType = await showDialog<JokerType>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        fit: StackFit.expand,
        children: [
          const SpaceBackground(darken: 0.5),
          Center(
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: _JokerChoicePanel(),
            ),
          ),
        ],
      ),
    );

    if (chosenType == null) return; // user tapped RETOUR

    // Scroll to top so the inventory animation is visible
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }

    // Small pause then add joker → triggers the animation in view
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      debugPrint('🎯 Adding joker: $chosenType');
      ref.read(gameStateProvider.notifier).addJokers(chosenType);
    }
  }
}

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

  int _displayCount = 0;
  int _prevCount = 0;

  // Random sparkle offsets (generated once per trigger)
  final List<_SparkleData> _sparkleParticles = [];

  @override
  void initState() {
    super.initState();
    _displayCount = widget.count;
    _prevCount = widget.count;
    _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..addListener(() => setState(() {}));
    _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..addListener(() => setState(() {}));
    _sparkles = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..addListener(() => setState(() {}));
    _plusOne = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..addListener(() => setState(() {}));
    _counterRoll = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _displayCount = widget.count;
        }
      })
      ..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _JokerStock oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('🔄 didUpdateWidget: old=${oldWidget.count} new=${widget.count}');
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
  }
}

class _SparkleData {
  final double angle;
  final double distance;
  final double size;
  final bool isStar;
  const _SparkleData({required this.angle, required this.distance, required this.size, required this.isStar});
}

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
                    Icon(Icons.videogame_asset_rounded, color: AppTheme.blueTop, size: 11),
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
                    Icon(Icons.star_rounded, color: AppTheme.gold, size: 11),
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
class _NoAdsSectionHeader extends StatefulWidget {
  final Color gradStart, gradEnd;
  const _NoAdsSectionHeader({required this.gradStart, required this.gradEnd});

  @override
  State<_NoAdsSectionHeader> createState() => _NoAdsSectionHeaderState();
}

class _NoAdsSectionHeaderState extends State<_NoAdsSectionHeader> with SingleTickerProviderStateMixin {
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
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
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
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _NoAdsIcon(size: 22),
                  const SizedBox(width: 8),
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
                      l10n.noAdsTitle,
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
// Generic section header with neon glow
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
                          GestureDetector(
                            onTap: widget.onBuy,
                            child: _AnimatedPriceButton(price: widget.price, large: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Shimmer
                Positioned.fill(child: CustomPaint(painter: _ShimmerPainter(_shimmer.value))),
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
                      GestureDetector(
                        onTap: widget.onBuy,
                        child: _AnimatedPriceButton(price: widget.price, large: true),
                      ),
                    ],
                  ),
                ),
                // Shimmer
                Positioned.fill(child: CustomPaint(painter: _ShimmerPainter(_shimmer.value))),
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
      animation: _pulse,
      builder: (context, child) {
        final scale = 1.0 + _pulse.value * 0.1;
        final bounce = math.sin(_pulse.value * math.pi * 2) * 3;
        final glow = 0.3 + _pulse.value * 0.4;
        return Transform.translate(
          offset: Offset(0, bounce),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: widget.gradStart.withValues(alpha: glow), blurRadius: 16)],
              ),
              child: Center(
                child: Text(
                  widget.emoji,
                  style: TextStyle(
                    fontSize: AppTheme.fontLarge,
                    shadows: [
                      Shadow(color: widget.gradStart.withValues(alpha: 0.8), blurRadius: 12),
                      const Shadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 2),
                    ],
                  ),
                ),
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
                  Positioned.fill(child: CustomPaint(painter: _ShimmerPainter(_shimmer.value))),
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
// Animated price button — pulsing green CTA
// ═══════════════════════════════════════════════════════════════
class _AnimatedPriceButton extends StatefulWidget {
  final String price;
  final bool large;
  const _AnimatedPriceButton({required this.price, this.large = false});

  @override
  State<_AnimatedPriceButton> createState() => _AnimatedPriceButtonState();
}

class _AnimatedPriceButtonState extends State<_AnimatedPriceButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = 1.0 + _pulse.value * 0.04;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.large ? 11 : 8,
              vertical: widget.large ? 8 : 6,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.shopPackStar1, AppTheme.shopPackStar2]),
              borderRadius: BorderRadius.circular(AppTheme.radiusXXTiny),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25 + _pulse.value * 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shopPackStar1.withValues(alpha: 0.3 + _pulse.value * 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 10 + _pulse.value * 6,
                  spreadRadius: _pulse.value * 2,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Shield + "No Ads" painter (for ZÉRO PUB card)
// ═══════════════════════════════════════════════════════════════
class _ShieldNoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.9;
    final h = size.height * 0.9;
    final ox = (size.width - w) / 2;
    final oy = (size.height - h) / 2;

    // Shield shape
    final shield = Path()
      ..moveTo(cx, oy)
      ..quadraticBezierTo(ox + w * 0.05, oy, ox + w * 0.05, oy + h * 0.15)
      ..lineTo(ox + w * 0.05, oy + h * 0.55)
      ..quadraticBezierTo(ox + w * 0.05, oy + h * 0.8, cx, oy + h)
      ..quadraticBezierTo(ox + w * 0.95, oy + h * 0.8, ox + w * 0.95, oy + h * 0.55)
      ..lineTo(ox + w * 0.95, oy + h * 0.15)
      ..quadraticBezierTo(ox + w * 0.95, oy, cx, oy)
      ..close();

    // Shadow
    canvas.drawPath(shield.shift(const Offset(0, 3)), Paint()..color = Colors.black.withValues(alpha: 0.3));

    // Gold gradient fill
    canvas.drawPath(shield, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [AppTheme.goldPale, AppTheme.gold, AppTheme.goldAntique, AppTheme.goldBronze],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(ox, oy, w, h)));

    // Border
    canvas.drawPath(shield, Paint()..color = AppTheme.goldDark..style = PaintingStyle.stroke..strokeWidth = 1.8);

    // Inner shield line
    final innerShield = Path()
      ..moveTo(cx, oy + 5)
      ..quadraticBezierTo(ox + w * 0.12, oy + 5, ox + w * 0.12, oy + h * 0.18)
      ..lineTo(ox + w * 0.12, oy + h * 0.53)
      ..quadraticBezierTo(ox + w * 0.12, oy + h * 0.76, cx, oy + h - 5)
      ..quadraticBezierTo(ox + w * 0.88, oy + h * 0.76, ox + w * 0.88, oy + h * 0.53)
      ..lineTo(ox + w * 0.88, oy + h * 0.18)
      ..quadraticBezierTo(ox + w * 0.88, oy + 5, cx, oy + 5)
      ..close();
    canvas.drawPath(innerShield, Paint()..color = AppTheme.goldPale.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Red circle with strikethrough
    final circCx = cx;
    final circCy = cy + 2;
    final circR = w * 0.30;

    // Red glow
    canvas.drawCircle(Offset(circCx, circCy), circR + 3, Paint()
      ..color = AppTheme.shopNoAdsRed.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    // Red circle fill
    canvas.drawCircle(Offset(circCx, circCy), circR, Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [AppTheme.capDanger, AppTheme.shopNoAdsRed, AppTheme.redDeep],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(circCx, circCy), radius: circR)));

    // Red circle border
    canvas.drawCircle(Offset(circCx, circCy), circR, Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0);

    // AD text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'AD',
        style: TextStyle(
          fontSize: circR * 1.0, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5,
          shadows: const [Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(circCx - textPainter.width / 2, circCy - textPainter.height / 2));

    // Diagonal strikethrough
    canvas.save();
    canvas.translate(circCx, circCy);
    canvas.rotate(-0.4);
    final strikeW = circR * 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0.5, 0.5), width: strikeW, height: 3), const Radius.circular(1.5)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: strikeW, height: 2.5), const Radius.circular(1.5)),
      Paint()..color = Colors.white,
    );
    canvas.restore();

    // Top shine
    final shinePath = Path()
      ..moveTo(cx - w * 0.15, oy + 6)
      ..quadraticBezierTo(cx, oy + 3, cx + w * 0.15, oy + 6)
      ..quadraticBezierTo(cx, oy + 10, cx - w * 0.15, oy + 6)
      ..close();
    canvas.drawPath(shinePath, Paint()..color = Colors.white.withValues(alpha: 0.45));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// Shimmer painter — diagonal light sweep
// ═══════════════════════════════════════════════════════════════
class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width * (-0.3 + progress * 1.6);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(center - 80, 0, 160, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
// Sparkle particles — floating gold stars
// ═══════════════════════════════════════════════════════════════
class _SparkleParticlesPainter extends CustomPainter {
  final double progress;
  _SparkleParticlesPainter(this.progress);

  static const _seeds = [0.1, 0.25, 0.42, 0.58, 0.73, 0.88, 0.05, 0.35, 0.62, 0.91];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _seeds.length; i++) {
      final seed = _seeds[i];
      final t = (progress + seed) % 1.0;
      final x = seed * size.width;
      final y = size.height * (1.0 - t);
      final alpha = (t < 0.5 ? t * 2 : (1.0 - t) * 2).clamp(0.0, 1.0);
      final s = 1.5 + seed * 2.0;

      final paint = Paint()..color = AppTheme.gold.withValues(alpha: alpha * 0.7);
      _drawStar(canvas, x, y, s, paint);
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      path.moveTo(cx, cy);
      path.lineTo(cx + math.cos(angle) * r, cy + math.sin(angle) * r);
    }
    canvas.drawPath(path, paint..strokeWidth = 1.2..style = PaintingStyle.stroke);
    canvas.drawCircle(Offset(cx, cy), r * 0.3, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_SparkleParticlesPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
// Joker choice button (for dialog)
// ═══════════════════════════════════════════════════════════════
// ── Joker choice panel (stateful — tracks selection, validates on button) ──
class _JokerChoicePanel extends StatefulWidget {
  @override
  State<_JokerChoicePanel> createState() => _JokerChoicePanelState();
}

class _JokerChoicePanelState extends State<_JokerChoicePanel> {
  JokerType? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.panelBorder, width: 3),
        boxShadow: const [
          BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 8)),
          BoxShadow(color: Colors.black54, offset: Offset(0, 12), blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gift icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.profileGradTop, AppTheme.profileGradBot],
              ),
              border: Border.all(color: AppTheme.gold, width: 3),
              boxShadow: [
                BoxShadow(color: AppTheme.gold.withValues(alpha: 0.3), blurRadius: 12),
              ],
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 12),
          Text(l10n.chooseJoker.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontH4)),
          const SizedBox(height: 20),

          // Joker choices
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _JokerChoiceButton(
                icon: JokerUI.icon(JokerType.bomb, size: 36),
                color: JokerUI.color(JokerType.bomb),
                selected: _selected == JokerType.bomb,
                onTap: () => setState(() => _selected = JokerType.bomb),
              ),
              _JokerChoiceButton(
                icon: JokerUI.icon(JokerType.wildcard, size: 36),
                color: JokerUI.color(JokerType.wildcard),
                selected: _selected == JokerType.wildcard,
                onTap: () => setState(() => _selected = JokerType.wildcard),
              ),
              _JokerChoiceButton(
                icon: JokerUI.icon(JokerType.reducer, size: 30),
                color: JokerUI.color(JokerType.reducer),
                selected: _selected == JokerType.reducer,
                onTap: () => setState(() => _selected = JokerType.reducer),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Validate button — only pops with selection
          SizedBox(
            width: double.infinity,
            child: Button3D.green(
              expand: true,
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: _selected == null ? null : () => Navigator.pop(context, _selected),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(l10n.validateButton, style: AppTheme.titleStyle(AppTheme.fontBody)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single joker choice tile (visual only, no pop) ──
class _JokerChoiceButton extends StatelessWidget {
  final Widget icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _JokerChoiceButton({required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.2) : AppTheme.panelBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: color, width: selected ? 3 : 1.5),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: selected ? 0.6 : 0.3), blurRadius: selected ? 20 : 10),
                  const BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 3)),
                ],
              ),
              child: icon,
            ),
            if (selected)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
                    ],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
