import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/config/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';

import 'package:shape_merge/core/config/shop_catalog.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/core/services/iap_service.dart';
import 'package:shape_merge/providers/ads_provider.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/iap_provider.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';


part 'widgets/joker_stock_card.dart';
part 'widgets/shop_items.dart';
part 'widgets/shop_packs.dart';
part 'widgets/shop_painters.dart';
part 'widgets/joker_choice_panel.dart';

const _log = AppLogger('Shop');

// ── L10n resolvers for shop packs ───────────────────────────────
String _packName(AppLocalizations l10n, ShopPack pack) => switch (pack.productId) {
      'pack_star' => l10n.packStarName,
      'pack_comet' => l10n.packCometName,
      'pack_diamond' => l10n.packDiamondName,
      _ => pack.emoji,
    };

String _packBadge(AppLocalizations l10n, ShopPack pack) => switch (pack.productId) {
      'pack_star' => l10n.badgeStarter,
      'pack_comet' => l10n.badgePopular,
      'pack_diamond' => l10n.badgeBestValue,
      _ => '',
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
      bottom: false,
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
                    child: Button3D.gold(
                      padding: EdgeInsets.zero,
                      borderRadius: 22,
                      onPressed: () {
                        AudioService.instance.playButtonTap();
                        context.go(AppRoutes.home);
                      },
                      child: const SizedBox(
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
                    _SectionHeader(
                      title: l10n.noAdsTitle,
                      leading: const _NoAdsIcon(size: 22),
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

                  // ── Packs generated from ShopCatalog ──
                  for (final pack in ShopCatalog.packs) ...[
                    _JokerPackCard(
                      emoji: pack.emoji,
                      name: _packName(l10n, pack),
                      descriptionWidget: _buildPackContents(
                        pack.freeJokers, pack.radar, pack.evolution, pack.megaBomb,
                      ),
                      price: iap.price(pack.productId),
                      badge: _packBadge(l10n, pack),
                      gradStart: pack.gradStart,
                      gradEnd: pack.gradEnd,
                      onBuy: () => _buyProduct(context, ref, pack.productId),
                    ),
                    const SizedBox(height: 12),
                  ],
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

                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  // ignore: unused_element — Required for App Store review (restore purchases button)
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

    // Play reward sound immediately on validation
    AudioService.instance.playReward();

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
      _log.debug('Adding joker: $chosenType');
      ref.read(gameStateProvider.notifier).addJokers(chosenType);
    }
  }
}

