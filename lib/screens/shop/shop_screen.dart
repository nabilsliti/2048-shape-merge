import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/config/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_random_reveal_dialog.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';

import 'package:shape_merge/core/config/shop_catalog.dart';
import 'package:shape_merge/core/services/remote_config_service.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/core/services/iap_service.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shape_merge/providers/ads_provider.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/iap_provider.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';
import 'package:vibration/vibration.dart';


part 'widgets/joker_stock_card.dart';
part 'widgets/shop_items.dart';
part 'widgets/shop_packs.dart';
part 'widgets/shop_painters.dart';
part 'widgets/purchase_result_overlay.dart';

const _log = AppLogger('Shop');

// ── L10n resolvers for shop packs ───────────────────────────────
String _packName(AppLocalizations l10n, ShopPack pack) => switch (pack.productId) {
      'pack_star' => l10n.packStarName,
      'pack_rescue' => l10n.packRescueName,
      'pack_comet' => l10n.packCometName,
      'pack_boost' => l10n.packBoostName,
      'pack_diamond' => l10n.packDiamondName,
      _ => pack.emoji,
    };

String? _packBadge(AppLocalizations l10n, ShopPack pack) => switch (pack.productId) {
      'pack_star' => l10n.badgeStarter,
      'pack_rescue' => l10n.badgeRescue,
      'pack_comet' => l10n.badgePopular,
      'pack_boost' => l10n.badgeBoost,
      'pack_diamond' => l10n.badgeBestValue,
      _ => null,
    };

/// Standalone screen (used by router for /shop fallback).
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: SpaceBackground()),
          ShopScreenContent(),
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
  _PurchaseResult? _purchaseResult;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Granular watches: rebuild only when these specific fields change.
    final inventory = ref.watch(
      gameStateProvider.select((s) => s.jokerInventory),
    );
    final shopContext = ref.watch(
      gameStateProvider.select(
        (s) => (gameActive: s.gameActive, bestScore: s.bestScore),
      ),
    );
    final noAds = ref.watch(noAdsPurchasedProvider);
    final emojiPack = ref.watch(emojiPackPurchasedProvider);

    // Init IAP (idempotent)
    ref.watch(iapReadyProvider);
    final iap = ref.read(iapServiceProvider);

    // Listen for purchase results to show overlay
    ref.listen<IapResult?>(lastPurchaseResultProvider, (prev, next) {
      if (next == null) return;
      if (next.status == IapStatus.purchased) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut);
        }
        _showPurchaseResult(_PurchaseResult(
          type: _PurchaseResultType.success,
          productId: next.productId,
        ));
      } else if (next.status == IapStatus.error) {
        _showPurchaseResult(_PurchaseResult(
          type: _PurchaseResultType.error,
          productId: next.productId,
          errorMessage: next.errorMessage,
        ));
      }
      ref.read(lastPurchaseResultProvider.notifier).state = null;
    });

    // Preload rewarded ad
    final adsService = ref.read(adsServiceProvider);
    adsService.loadRewardedAd();

    // ── Dynamic 3rd slot logic ──
    final altPack = _pickAlternativePack(shopContext, emojiPack);

    // ── Scroll section: remaining packs (exclude rescue + alt) ──
    final scrollPacks = ShopCatalog.packs
        .where((p) => p.productId != 'pack_rescue' && p.productId != altPack.productId)
        .toList();

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
                child: SizedBox(
                  height: 50,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Button3D.gold(
                          padding: EdgeInsets.zero,
                          borderRadius: 22,
                          onPressed: () {
                            final fromGame = GoRouterState.of(context).extra == 'from_game';
                            if (fromGame) {
                              StatefulNavigationShell.of(context).goBranch(2);
                            } else if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.home);
                            }
                          },
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: PremiumIcon.back(size: 22),
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

              // ── Main content (scroll) ──
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // ── Inventory (compact) ──
                      _InventoryCard(inventory: inventory),
                      const SizedBox(height: 16),

                      // ── Slot 1: Free — Watch Ad (compact) ──
                      _FreeJokerSlot(
                        onTap: () => _watchAdAndChooseJoker(context, ref),
                        label: l10n.freeJokerShort,
                      ),
                      const SizedBox(height: 14),

                      // ── Slot 2: HERO — Pack Rescue (dominant) ──
                      Builder(builder: (_) {
                        final rescue = ShopCatalog.byId('pack_rescue')!;
                        final promo = RemoteConfigService.instance.promoFor(rescue.productId);
                        final basePrice = iap.price(rescue.productId);
                        final discountedPrice = promo?.discountedPriceFrom(basePrice);
                        return _HeroPackCard(
                          emoji: rescue.emoji,
                          name: l10n.packRescueName.toUpperCase(),
                          description: l10n.rescueHeroDesc,
                          contentsWidget: _buildPackContents(
                            rescue.freeJokers, rescue.radar, rescue.evolution, rescue.megaBomb,
                          ),
                          price: discountedPrice ?? basePrice,
                          originalPrice: discountedPrice != null ? basePrice : null,
                          badge: l10n.bestChoice,
                          gradStart: rescue.gradStart,
                          gradEnd: rescue.gradEnd,
                          onBuy: () => _buyProduct(context, ref, rescue.productId),
                        );
                      }),
                      const SizedBox(height: 14),

                      // ── Slot 3: Alternative (secondary) ──
                      Builder(builder: (_) {
                        final promo = RemoteConfigService.instance.promoFor(altPack.productId);
                        final basePrice = iap.price(altPack.productId);
                        final discountedPrice = promo?.discountedPriceFrom(basePrice);
                        // Emoji pack uses its own card style
                        if (altPack.productId == 'pack_emoji') {
                          return _EmojiPackCard(
                            price: discountedPrice ?? basePrice,
                            onBuy: () => _buyProduct(context, ref, altPack.productId),
                          );
                        }
                        return _JokerPackCard(
                          emoji: altPack.emoji,
                          name: _packName(l10n, altPack),
                          descriptionWidget: _buildPackContents(
                            altPack.freeJokers, altPack.radar, altPack.evolution, altPack.megaBomb,
                          ),
                          price: discountedPrice ?? basePrice,
                          originalPrice: discountedPrice != null ? basePrice : null,
                          badge: _packBadge(l10n, altPack),
                          promoBadge: promo?.badge,
                          gradStart: altPack.gradStart,
                          gradEnd: altPack.gradEnd,
                          onBuy: () => _buyProduct(context, ref, altPack.productId),
                        );
                      }),

                      const SizedBox(height: 24),

                      // ── Scroll section: more offers ──
                      _SectionHeader(
                        title: '🎁 ${l10n.sectionMoreOffers}',
                        gradStart: AppTheme.shopSectionCyan,
                        gradEnd: AppTheme.shopSectionPurple,
                      ),
                      const SizedBox(height: 12),

                      for (final pack in scrollPacks) ...[
                        Builder(builder: (_) {
                          final promo = RemoteConfigService.instance.promoFor(pack.productId);
                          final basePrice = iap.price(pack.productId);
                          final discountedPrice = promo?.discountedPriceFrom(basePrice);
                          return _JokerPackCard(
                            emoji: pack.emoji,
                            name: _packName(l10n, pack),
                            descriptionWidget: _buildPackContents(
                              pack.freeJokers, pack.radar, pack.evolution, pack.megaBomb,
                            ),
                            price: discountedPrice ?? basePrice,
                            originalPrice: discountedPrice != null ? basePrice : null,
                            badge: _packBadge(l10n, pack),
                            promoBadge: promo?.badge,
                            gradStart: pack.gradStart,
                            gradEnd: pack.gradEnd,
                            onBuy: () => _buyProduct(context, ref, pack.productId),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],

                      // ── ZÉRO PUB ──
                      if (!noAds) ...[
                        _NoAdsCard(
                          price: iap.price(IapProducts.noAds),
                          onBuy: () => _buyProduct(context, ref, IapProducts.noAds),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Emoji pack (if not shown as alt slot) ──
                      if (!emojiPack && altPack.productId != 'pack_emoji') ...[
                        _EmojiPackCard(
                          price: iap.price(IapProducts.emojiPack),
                          onBuy: () => _buyProduct(context, ref, IapProducts.emojiPack),
                        ),
                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Purchase result overlay
        if (_purchaseResult != null)
          Positioned.fill(
            child: _PurchaseResultOverlay(
              result: _purchaseResult!,
              onDismiss: () {
                if (mounted) setState(() => _purchaseResult = null);
              },
            ),
          ),
      ],
    );
  }

  /// Pick the best alternative pack for slot 3 based on player context.
  ShopPack _pickAlternativePack(
    ({bool gameActive, int bestScore}) ctx,
    bool emojiPurchased,
  ) {
    // Player stuck (game over) → Comet (more powerful)
    if (!ctx.gameActive) return ShopCatalog.byId('pack_comet')!;
    // Casual player (low score) → Emoji cosmetic
    if (!emojiPurchased && ctx.bestScore < 500) return ShopCatalog.emojiPack;
    // Engaged player (high score) → Diamond (max value)
    if (ctx.bestScore >= 2000) return ShopCatalog.byId('pack_diamond')!;
    // Default → Comet
    return ShopCatalog.byId('pack_comet')!;
  }

  void _showPurchaseResult(_PurchaseResult result) {
    if (mounted) setState(() => _purchaseResult = result);
  }

  Future<void> _buyProduct(BuildContext context, WidgetRef ref, String productId) async {
    final iap = ref.read(iapServiceProvider);

    // Debug: show store status
    if (!iap.storeAvailable) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.storeNotAvailable), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (!iap.products.containsKey(productId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "$productId" not found. Loaded: ${iap.products.keys.toList()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    await iap.buy(productId);
  }

  // ignore: unused_element — Required for App Store review (restore purchases button)
  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    final iap = ref.read(iapServiceProvider);

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
    Widget orb(JokerType type, int count, {double size = 18}) {
      if (count <= 0) return const SizedBox.shrink();
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

    final hasPremium = radar > 0 || evolution > 0 || megaBomb > 0;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          orb(JokerType.bomb, free),
          const SizedBox(width: 6),
          orb(JokerType.wildcard, free),
          const SizedBox(width: 6),
          orb(JokerType.reducer, free, size: 16),
          if (hasPremium) ...[
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
            if (radar > 0) orb(JokerType.radar, radar, size: 16),
            if (radar > 0) const SizedBox(width: 6),
            if (evolution > 0) orb(JokerType.evolution, evolution, size: 16),
            if (evolution > 0) const SizedBox(width: 6),
            if (megaBomb > 0) orb(JokerType.megaBomb, megaBomb, size: 16),
          ],
        ],
      ),
    );
  }

  Future<void> _watchAdAndChooseJoker(BuildContext context, WidgetRef ref) async {
    final adsService = ref.read(adsServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    // Cooldown / daily-cap gate (defensive — UI also disables the slot).
    final storage = await ref.read(localStorageProvider.future);
    if (!storage.canWatchAdJoker) {
      if (context.mounted) {
        final isCap = storage.adJokerAdsLeftToday == 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCap ? l10n.adJokerLimitTomorrow : l10n.adJokerLimitReached,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppTheme.redTop,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

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
      await _showRandomJokerReveal(context, ref, storage);
    }
  }

  Future<void> _showRandomJokerReveal(
    BuildContext context,
    WidgetRef ref,
    LocalStorageService storage,
  ) async {
    const pool = AdJokerTuning.rewardPool;
    final reward = pool[math.Random().nextInt(pool.length)];
    final got = await JokerRandomRevealDialog.show(context, reward: reward);
    if (got == null) return;

    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }

    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      _log.debug('Adding random joker: $got');
      ref.read(gameStateProvider.notifier).addJokers(got);
      await storage.recordAdJokerWatched();
    }
  }
}

