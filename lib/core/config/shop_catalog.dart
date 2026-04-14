import 'dart:ui';

// ─────────────────────────────────────────────────────────────
// Shop Catalog — IAP packs, product IDs, contents, UI config.
//
// To add a new pack:
//   1. Add a ShopPack entry to [ShopCatalog.packs]
//   2. Create the matching product in Google Play / App Store
//   3. Add l10n keys: pack<Name>Name, badge<Name>
// To remove a pack: remove its entry from the list.
// ─────────────────────────────────────────────────────────────

class ShopPack {
  /// Product ID — must match Google Play / App Store Connect.
  final String productId;

  /// Display emoji.
  final String emoji;

  /// Number of free jokers (bomb, wildcard, reducer) included.
  final int freeJokers;

  /// Number of premium jokers included.
  final int radar;
  final int evolution;
  final int megaBomb;

  /// Whether this is a one-time purchase (non-consumable).
  final bool isNonConsumable;

  /// Fallback price string when store is unreachable.
  final String fallbackPrice;

  /// Gradient colors for the pack card in the shop.
  final Color gradStart;
  final Color gradEnd;

  /// L10n key suffix for the pack name and badge.
  /// Resolved at runtime: l10n.pack{lKey}Name / l10n.badge{lKey}
  final String lKey;

  const ShopPack({
    required this.productId,
    required this.emoji,
    required this.freeJokers,
    this.radar = 0,
    this.evolution = 0,
    this.megaBomb = 0,
    this.isNonConsumable = false,
    required this.fallbackPrice,
    required this.gradStart,
    required this.gradEnd,
    required this.lKey,
  });
}

abstract final class ShopCatalog {
  // ── Pack definitions ──────────────────────────────────────

  static const packStar = ShopPack(
    productId: 'pack_star',
    emoji: '⭐',
    freeJokers: 5,
    radar: 1,
    fallbackPrice: '1,99 €',
    gradStart: Color(0xFF00E676),
    gradEnd: Color(0xFF00A84E),
    lKey: 'Star',
  );

  static const packComet = ShopPack(
    productId: 'pack_comet',
    emoji: '☄️',
    freeJokers: 15,
    radar: 3,
    evolution: 2,
    megaBomb: 2,
    fallbackPrice: '4,99 €',
    gradStart: Color(0xFFAA00FF),
    gradEnd: Color(0xFF6200EA),
    lKey: 'Comet',
  );

  static const packDiamond = ShopPack(
    productId: 'pack_diamond',
    emoji: '💎',
    freeJokers: 40,
    radar: 8,
    evolution: 5,
    megaBomb: 5,
    fallbackPrice: '9,99 €',
    gradStart: Color(0xFFFF00FF),
    gradEnd: Color(0xFF00FFFF),
    lKey: 'Diamond',
  );

  static const noAds = ShopPack(
    productId: 'no_ads',
    emoji: '🚫',
    freeJokers: 10,
    radar: 3,
    evolution: 2,
    megaBomb: 2,
    isNonConsumable: true,
    fallbackPrice: '5,49 €',
    gradStart: Color(0xFFFFD700),
    gradEnd: Color(0xFFFFA000),
    lKey: 'NoAds',
  );

  /// All purchasable joker packs (in display order).
  static const List<ShopPack> packs = [packStar, packComet, packDiamond];

  /// All products (including no-ads).
  static const List<ShopPack> allProducts = [packStar, packComet, packDiamond, noAds];

  // ── Derived helpers (used by IapService) ──────────────────

  /// All product IDs.
  static Set<String> get allIds => {for (final p in allProducts) p.productId};

  /// Non-consumable product IDs.
  static Set<String> get nonConsumableIds =>
      {for (final p in allProducts) if (p.isNonConsumable) p.productId};

  /// Free joker count per product ID.
  static Map<String, int> get packContents =>
      {for (final p in allProducts) p.productId: p.freeJokers};

  /// Premium joker counts per product ID.
  static Map<String, ({int radar, int evolution, int megaBomb})> get premiumContents => {
        for (final p in allProducts)
          p.productId: (radar: p.radar, evolution: p.evolution, megaBomb: p.megaBomb),
      };

  /// Fallback prices per product ID.
  static Map<String, String> get fallbackPrices =>
      {for (final p in allProducts) p.productId: p.fallbackPrice};

  /// Lookup a pack by product ID.
  static ShopPack? byId(String productId) {
    for (final p in allProducts) {
      if (p.productId == productId) return p;
    }
    return null;
  }
}
