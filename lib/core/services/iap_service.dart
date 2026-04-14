import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shape_merge/core/config/shop_catalog.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';

const _log = AppLogger('IAP');

// ──────────────────────────────────────────────────────────────
// Product catalogue — delegates to ShopCatalog config
// ──────────────────────────────────────────────────────────────

/// Product IDs — must match Google Play Console / App Store Connect.
class IapProducts {
  IapProducts._();

  static const packStar = 'pack_star';
  static const packComet = 'pack_comet';
  static const packDiamond = 'pack_diamond';
  static const noAds = 'no_ads';

  static Set<String> get allIds => ShopCatalog.allIds;

  static Map<String, int> get packContents => ShopCatalog.packContents;

  static Map<String, ({int radar, int evolution, int megaBomb})> get premiumContents =>
      ShopCatalog.premiumContents;

  static Set<String> get nonConsumable => ShopCatalog.nonConsumableIds;

  static Map<String, String> get fallbackPrices => ShopCatalog.fallbackPrices;
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
      _log.warning('Store not available');
      return;
    }

    noAdsPurchased = storage.noAdsPurchased;

    _sub = _iap.purchaseStream.listen(
      (updates) => _onPurchaseUpdates(updates, storage),
      onError: (e) {
        _log.error('Purchase stream error', error: e);
        onStatusChanged?.call(const IapResult(
          status: IapStatus.error,
          errorMessage: 'Purchase stream error',
        ));
      },
    );

    final response = await _iap.queryProductDetails(IapProducts.allIds);
    _log.debug('Queried ${IapProducts.allIds}, found ${response.productDetails.length}, notFound ${response.notFoundIDs}');
    if (response.notFoundIDs.isNotEmpty) {
      _log.warning('Products not found: ${response.notFoundIDs}');
    }
    for (final p in response.productDetails) {
      products[p.id] = p;
      _log.debug('Loaded ${p.id} → ${p.price}');
    }
    if (products.isEmpty) {
      _log.error('NO products loaded! Check Play Console product IDs and app signing.');
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
      _log.error('Buy failed for $productId', error: e);
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
      _log.error('Restore failed', error: e);
      onStatusChanged?.call(const IapResult(
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
      _log.debug('Update: ${p.productID} → ${p.status} error=${p.error?.message}');

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
