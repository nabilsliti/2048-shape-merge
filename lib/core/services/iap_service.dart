import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';

// ──────────────────────────────────────────────────────────────
// Product catalogue
// ──────────────────────────────────────────────────────────────

/// Product IDs — must match Google Play Console / App Store Connect.
class IapProducts {
  IapProducts._();

  static const packStar = 'pack_star';       // free jokers ×5 + radar ×1
  static const packComet = 'pack_comet';     // free jokers ×15 + radar ×3 + evolution ×2 + megabomb ×2
  static const packDiamond = 'pack_diamond'; // free jokers ×40 + radar ×8 + evolution ×5 + megabomb ×5
  static const noAds = 'no_ads';            // remove ads + free jokers ×10 + radar ×3 + evolution ×2 + megabomb ×2

  static const allIds = {packStar, packComet, packDiamond, noAds};

  /// Number of FREE jokers (bomb/wildcard/reducer) per product.
  static const packContents = <String, int>{
    packStar: 5,
    packComet: 15,
    packDiamond: 40,
    noAds: 10,
  };

  /// Premium joker counts per product: [radar, evolution, megaBomb]
  static const premiumContents = <String, (int radar, int evolution, int megaBomb)>{
    packStar:    (1, 0, 0),
    packComet:   (3, 2, 2),
    packDiamond: (8, 5, 5),
    noAds:       (3, 2, 2),
  };

  /// Non-consumable products (bought once, can be restored).
  static const nonConsumable = {noAds};

  /// Default display prices (used when store isn't reachable).
  static const fallbackPrices = <String, String>{
    packStar: '1,99 €',
    packComet: '4,99 €',
    packDiamond: '9,99 €',
    noAds: '5,49 €',
  };
}

// ──────────────────────────────────────────────────────────────
// Purchase result  (exposed to UI via callback)
// ──────────────────────────────────────────────────────────────

enum IapStatus { idle, purchasing, purchased, restored, error }

class IapResult {
  final IapStatus status;
  final String? productId;
  final String? errorMessage;
  const IapResult({required this.status, this.productId, this.errorMessage});
}

// ──────────────────────────────────────────────────────────────
// IAP Service
// ──────────────────────────────────────────────────────────────

class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// Loaded product details from store, keyed by ID.
  final Map<String, ProductDetails> products = {};

  /// Whether the billing client is available.
  bool storeAvailable = false;

  /// Persisted flag — `true` after the user bought the no-ads pack.
  bool noAdsPurchased = false;

  /// Callback: a product was successfully delivered (jokers should be added).
  void Function(String productId)? onProductDelivered;

  /// Callback: purchase flow status changed (for loading spinners, errors…).
  void Function(IapResult result)? onStatusChanged;

  // ── Lifecycle ──────────────────────────────────────────────

  Future<void> initialize(LocalStorageService storage) async {
    storeAvailable = await _iap.isAvailable();
    if (!storeAvailable) {
      debugPrint('💰 IAP: store not available');
      return;
    }

    noAdsPurchased = storage.noAdsPurchased;

    _sub = _iap.purchaseStream.listen(
      (updates) => _onPurchaseUpdates(updates, storage),
      onError: (e) {
        debugPrint('💰 IAP stream error: $e');
        onStatusChanged?.call(const IapResult(
          status: IapStatus.error,
          errorMessage: 'Purchase stream error',
        ));
      },
    );

    final response = await _iap.queryProductDetails(IapProducts.allIds);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('💰 IAP: products not found → ${response.notFoundIDs}');
    }
    for (final p in response.productDetails) {
      products[p.id] = p;
      debugPrint('💰 IAP: loaded ${p.id} → ${p.price}');
    }
  }

  // ── Public API ─────────────────────────────────────────────

  /// Start a purchase flow for [productId].
  Future<bool> buy(String productId) async {
    final product = products[productId];
    if (product == null) {
      onStatusChanged?.call(IapResult(
        status: IapStatus.error,
        productId: productId,
        errorMessage: 'Product not found in store',
      ));
      return false;
    }

    onStatusChanged?.call(IapResult(
      status: IapStatus.purchasing,
      productId: productId,
    ));

    try {
      final param = PurchaseParam(productDetails: product);
      if (IapProducts.nonConsumable.contains(productId)) {
        return await _iap.buyNonConsumable(purchaseParam: param);
      } else {
        return await _iap.buyConsumable(purchaseParam: param);
      }
    } catch (e) {
      debugPrint('💰 IAP buy error: $e');
      onStatusChanged?.call(IapResult(
        status: IapStatus.error,
        productId: productId,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Restore non-consumable purchases (no-ads).
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('💰 Restore error: $e');
      onStatusChanged?.call(IapResult(
        status: IapStatus.error,
        errorMessage: 'Restore failed',
      ));
    }
  }

  /// Store price or fallback string.
  String price(String productId) =>
      products[productId]?.price ??
      IapProducts.fallbackPrices[productId] ??
      '—';

  // ── Private ────────────────────────────────────────────────

  void _onPurchaseUpdates(
    List<PurchaseDetails> updates,
    LocalStorageService storage,
  ) {
    for (final p in updates) {
      debugPrint('💰 IAP update: ${p.productID} → ${p.status}');

      switch (p.status) {
        case PurchaseStatus.pending:
          onStatusChanged?.call(IapResult(
            status: IapStatus.purchasing,
            productId: p.productID,
          ));

        case PurchaseStatus.purchased:
          _deliver(p, storage, restored: false);
          if (p.pendingCompletePurchase) _iap.completePurchase(p);

        case PurchaseStatus.restored:
          _deliver(p, storage, restored: true);
          if (p.pendingCompletePurchase) _iap.completePurchase(p);

        case PurchaseStatus.error:
          onStatusChanged?.call(IapResult(
            status: IapStatus.error,
            productId: p.productID,
            errorMessage: p.error?.message,
          ));
          if (p.pendingCompletePurchase) _iap.completePurchase(p);

        case PurchaseStatus.canceled:
          onStatusChanged?.call(IapResult(
            status: IapStatus.idle,
            productId: p.productID,
          ));
      }
    }
  }

  void _deliver(
    PurchaseDetails purchase,
    LocalStorageService storage, {
    required bool restored,
  }) {
    final id = purchase.productID;

    // Persist no-ads flag
    if (id == IapProducts.noAds) {
      noAdsPurchased = true;
      storage.setNoAdsPurchased(true);
    }

    // On restore, we skip joker delivery (items are already credited).
    // On fresh purchase, we always deliver.
    if (!restored) {
      onProductDelivered?.call(id);
    } else if (id == IapProducts.noAds) {
      // For no-ads restores, just fire status (no jokers).
      onStatusChanged?.call(IapResult(
        status: IapStatus.restored,
        productId: id,
      ));
      return;
    }

    onStatusChanged?.call(IapResult(
      status: restored ? IapStatus.restored : IapStatus.purchased,
      productId: id,
    ));
  }

  void dispose() {
    _sub?.cancel();
  }
}
