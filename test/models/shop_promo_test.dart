import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/models/shop_promo.dart';

void main() {
  group('ShopPromo.fromJson', () {
    test('parses all fields', () {
      final p = ShopPromo.fromJson({
        'productId': 'pack_comet',
        'badge': '-50%',
        'discountPercent': 50,
        'startDate': '2026-04-17T00:00:00Z',
        'endDate': '2026-04-23T23:59:59Z',
      });
      expect(p.productId, 'pack_comet');
      expect(p.badge, '-50%');
      expect(p.discountPercent, 50);
      expect(p.startDate.isUtc, true);
    });

    test('defaults badge to "PROMO" and discountPercent to 0', () {
      final p = ShopPromo.fromJson({
        'productId': 'pack_x',
        'startDate': '2026-01-01T00:00:00Z',
        'endDate': '2026-01-02T00:00:00Z',
      });
      expect(p.badge, 'PROMO');
      expect(p.discountPercent, 0);
    });
  });

  ShopPromo promo({int discount = 50}) => ShopPromo(
        productId: 'p',
        badge: 'b',
        discountPercent: discount,
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2027, 1, 1),
      );

  group('ShopPromo.discountedPriceFrom', () {
    test('null when discount is 0 or 100+', () {
      expect(promo(discount: 0).discountedPriceFrom('4,99 €'), isNull);
      expect(promo(discount: 100).discountedPriceFrom('4,99 €'), isNull);
    });

    test('EU comma format: "4,99 €" with -50% → "2,50 €"', () {
      expect(promo(discount: 50).discountedPriceFrom('4,99 €'), '2,50 €');
    });

    test('US dot format: "\$4.99" with -50% → "\$2,50" (re-formatted)', () {
      // Note: implementation always re-formats with comma (FR locale).
      expect(promo(discount: 50).discountedPriceFrom(r'$4.99'), r'$2,50');
    });

    test('null when string contains no parseable number', () {
      expect(promo().discountedPriceFrom('FREE'), isNull);
    });

    test('thousands separator EU: "1.299,99 €" parsed correctly', () {
      // 1299.99 × 0.5 = 649.995 → toStringAsFixed(2) rounds to "650.00".
      expect(promo(discount: 50).discountedPriceFrom('1.299,99 €'), '650,00 €');
    });
  });

  group('ShopPromo.isActiveAt', () {
    final p = ShopPromo(
      productId: 'p', badge: 'b',
      startDate: DateTime.utc(2026, 4, 17),
      endDate: DateTime.utc(2026, 4, 24),
    );

    test('false before start', () {
      expect(p.isActiveAt(DateTime.utc(2026, 4, 16, 23, 59)), false);
    });

    test('true at start (inclusive)', () {
      expect(p.isActiveAt(DateTime.utc(2026, 4, 17)), true);
    });

    test('true during window', () {
      expect(p.isActiveAt(DateTime.utc(2026, 4, 20)), true);
    });

    test('false at end (exclusive)', () {
      expect(p.isActiveAt(DateTime.utc(2026, 4, 24)), false);
    });
  });
}
