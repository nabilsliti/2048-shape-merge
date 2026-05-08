import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
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
  static const emojiPack = 'pack_emoji';

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

  /// Persisted flag — `true` after the user bought the emoji shape pack.
  bool emojiPackPurchased = false;

  /// Callback: a product was successfully delivered.
  /// [serverVerified] is true when Cloud Function credited jokers in Firestore.
  void Function(String productId, {required bool serverVerified})? onProductDelivered;

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
    emojiPackPurchased = storage.emojiPackPurchased;

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

  Future<void> _onPurchaseUpdates(
    List<PurchaseDetails> updates,
    LocalStorageService storage,
  ) async {
    for (final p in updates) {
      _log.debug('Update: ${p.productID} → ${p.status} error=${p.error?.message}');

      switch (p.status) {
        case PurchaseStatus.pending:
          onStatusChanged?.call(IapResult(
            status: IapStatus.purchasing,
            productId: p.productID,
          ));

        case PurchaseStatus.purchased:
          await _deliver(p, storage, restored: false);
          if (p.pendingCompletePurchase) _iap.completePurchase(p);

        case PurchaseStatus.restored:
          await _deliver(p, storage, restored: true);
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

  Future<void> _deliver(
    PurchaseDetails purchase,
    LocalStorageService storage, {
    required bool restored,
  }) async {
    final id = purchase.productID;

    // ── Server-side verification via Cloud Function ──
    if (!restored) {
      try {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('verifyPurchase');
        _log.info('Calling verifyPurchase for $id...');
        final result = await callable.call<Map<String, dynamic>>({
          'productId': id,
          'purchaseToken': purchase.verificationData.serverVerificationData,
          'platform': Platform.isIOS ? 'ios' : 'android',
        });
        final status = result.data['status'] as String?;
        if (status == 'ok' || status == 'already_processed') {
          _log.info('Purchase verified server-side: $id ($status)');
          onProductDelivered?.call(id, serverVerified: true);
        } else {
          _log.error('Unexpected verification status: $status');
          onStatusChanged?.call(IapResult(
            status: IapStatus.error,
            productId: id,
            errorMessage: 'Vérification échouée ($status)',
          ));
          return;
        }
      } catch (e) {
        _log.warning('Server verification failed for $id: $e');
        // User may not be signed in — deliver locally so they don't lose purchase
        _log.info('Delivering $id locally (no server verification)');
        // Save pending purchase for replay on sign-in
        await storage.addPendingPurchase(
          productId: id,
          purchaseToken: purchase.verificationData.serverVerificationData,
          platform: Platform.isIOS ? 'ios' : 'android',
        );
        _log.info('Saved pending purchase for $id');
        onProductDelivered?.call(id, serverVerified: false);
      }
    }

    // Persist no-ads flag locally
    if (id == IapProducts.noAds) {
      noAdsPurchased = true;
      await storage.setNoAdsPurchased(true);
      if (restored) {
        onStatusChanged?.call(IapResult(
          status: IapStatus.restored,
          productId: id,
        ));
        return;
      }
    }

    // Persist emoji pack flag locally
    if (id == IapProducts.emojiPack) {
      emojiPackPurchased = true;
      await storage.setEmojiPackPurchased(true);
      if (restored) {
        onStatusChanged?.call(IapResult(
          status: IapStatus.restored,
          productId: id,
        ));
        return;
      }
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
