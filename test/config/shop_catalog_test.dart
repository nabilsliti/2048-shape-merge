import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/config/shop_catalog.dart';

void main() {
  group('ShopCatalog', () {
    test('byId returns the matching pack', () {
      expect(ShopCatalog.byId('pack_star'), ShopCatalog.packStar);
      expect(ShopCatalog.byId('no_ads'), ShopCatalog.noAds);
    });

    test('byId returns null for unknown product id', () {
      expect(ShopCatalog.byId('does_not_exist'), isNull);
    });

    test('allIds contains every product id exactly once', () {
      final ids = ShopCatalog.allProducts.map((p) => p.productId).toList();
      expect(ShopCatalog.allIds.length, ids.length);
      for (final id in ids) {
        expect(ShopCatalog.allIds.contains(id), true);
      }
    });

    test('nonConsumableIds contains only flagged packs', () {
      expect(ShopCatalog.nonConsumableIds, contains('no_ads'));
      expect(ShopCatalog.nonConsumableIds, contains('pack_emoji'));
      expect(ShopCatalog.nonConsumableIds, isNot(contains('pack_star')));
    });

    test('packContents maps each product id to its freeJokers count', () {
      final contents = ShopCatalog.packContents;
      expect(contents['pack_star'], ShopCatalog.packStar.freeJokers);
      expect(contents['pack_diamond'], ShopCatalog.packDiamond.freeJokers);
      expect(contents['pack_emoji'], 0);
    });

    test('premiumContents bundles radar/evolution/megaBomb per product', () {
      final premium = ShopCatalog.premiumContents['pack_diamond']!;
      expect(premium.radar, ShopCatalog.packDiamond.radar);
      expect(premium.evolution, ShopCatalog.packDiamond.evolution);
      expect(premium.megaBomb, ShopCatalog.packDiamond.megaBomb);
    });

    test('fallbackPrices are non-empty for all products', () {
      for (final pack in ShopCatalog.allProducts) {
        final price = ShopCatalog.fallbackPrices[pack.productId];
        expect(price, isNotNull);
        expect(price!.isNotEmpty, true);
      }
    });

    test('packs list is the displayed (consumable) subset', () {
      for (final p in ShopCatalog.packs) {
        expect(p.isNonConsumable, false);
      }
    });
  });
}
