/// Represents a promotional offer for a shop pack.
///
/// Stored in Firebase Remote Config as a JSON array under key `shop_promos`.
///
/// Example Remote Config value:
/// ```json
/// [
///   {
///     "productId": "pack_comet",
///     "badge": "-50%",
///     "discountPercent": 50,
///     "startDate": "2026-04-17T00:00:00Z",
///     "endDate": "2026-04-23T23:59:59Z"
///   }
/// ]
/// ```
class ShopPromo {
  final String productId;

  /// Badge text displayed on the pack card (e.g. "-50%", "PROMO", "🔥 -30%").
  final String badge;

  /// Discount percentage (0–100). 0 means display-only badge, no price change.
  final int discountPercent;

  /// Start date of the promo (inclusive).
  final DateTime startDate;

  /// End date of the promo (inclusive).
  final DateTime endDate;

  const ShopPromo({
    required this.productId,
    required this.badge,
    this.discountPercent = 0,
    required this.startDate,
    required this.endDate,
  });

  factory ShopPromo.fromJson(Map<String, dynamic> json) {
    return ShopPromo(
      productId: json['productId'] as String,
      badge: json['badge'] as String? ?? 'PROMO',
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }

  /// Compute discounted price from a formatted price string (e.g. "4,99 €").
  /// Returns the discounted formatted price, or null if no discount.
  String? discountedPriceFrom(String formattedPrice) {
    if (discountPercent <= 0 || discountPercent >= 100) return null;
    // Extract numeric part: "4,99 €" → 4.99, "$4.99" → 4.99
    final digits = formattedPrice.replaceAll(RegExp(r'[^\d.,]'), '');
    // Normalize: "4,99" → "4.99", "1.299,99" → "1299.99"
    final normalized = digits.contains(',') && digits.contains('.')
        ? digits.replaceAll('.', '').replaceAll(',', '.')
        : digits.replaceAll(',', '.');
    final raw = double.tryParse(normalized);
    if (raw == null) return null;
    final discounted = raw * (100 - discountPercent) / 100;
    // Re-format with same currency by replacing number in original string
    final formatted = discounted.toStringAsFixed(2).replaceAll('.', ',');
    return formattedPrice.replaceAll(RegExp(r'[\d][\d.,]*[\d]'), formatted);
  }

  bool isActiveAt(DateTime now) {
    final utcNow = now.toUtc();
    return !utcNow.isBefore(startDate) && utcNow.isBefore(endDate);
  }
}
