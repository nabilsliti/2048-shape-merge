import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';

class IapService {
  static const smallPackId = 'joker_pack_small';
  static const mediumPackId = 'joker_pack_medium';
  static const largePackId = 'joker_pack_large';

  static const _packAmounts = {
    smallPackId: 5,
    mediumPackId: 15,
    largePackId: 40,
  };

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> products = [];

  void Function(JokerInventory updatedInventory)? onPurchaseCompleted;

  Future<void> init(JokerInventory currentInventory) async {
    final available = await _iap.isAvailable();
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(
      (purchases) => _handlePurchases(purchases, currentInventory),
    );

    final response = await _iap.queryProductDetails(
      {smallPackId, mediumPackId, largePackId},
    );
    products = response.productDetails;
  }

  void _handlePurchases(
    List<PurchaseDetails> purchases,
    JokerInventory currentInventory,
  ) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final amount = _packAmounts[purchase.productID] ?? 0;
        var updated = currentInventory;
        for (final type in JokerType.values) {
          updated = updated.add(type, amount);
        }
        onPurchaseCompleted?.call(updated);

        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> buyPack(String productId) async {
    final product = products.firstWhere((p) => p.id == productId);
    final param = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: param);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
