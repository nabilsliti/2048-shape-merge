import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/services/iap_service.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shape_merge/providers/game_state_provider.dart';

// ──────────────────────────────────────────────────────────────
// IAP Provider — singleton that initializes and exposes IapService
// ──────────────────────────────────────────────────────────────

final iapServiceProvider = Provider<IapService>((ref) => IapService());

/// Provider that initializes IAP and wires delivery callbacks.
/// Must be read once at app start (e.g. in main or hub screen).
final iapInitProvider = FutureProvider<void>((ref) async {
  final iap = ref.read(iapServiceProvider);
  final storage = await ref.read(localStorageProvider.future);

  // Wire delivery: when a product is purchased → add jokers
  iap.onProductDelivered = (productId) {
    final freeAmount = IapProducts.packContents[productId] ?? 0;
    final premium = IapProducts.premiumContents[productId];
    final notifier = ref.read(gameStateProvider.notifier);
    if (freeAmount > 0) {
      for (final type in [JokerType.bomb, JokerType.wildcard, JokerType.reducer]) {
        notifier.addJokers(type, freeAmount);
      }
    }
    if (premium != null) {
      if (premium.$1 > 0) notifier.addJokers(JokerType.radar, premium.$1);
      if (premium.$2 > 0) notifier.addJokers(JokerType.evolution, premium.$2);
      if (premium.$3 > 0) notifier.addJokers(JokerType.megaBomb, premium.$3);
    }
    debugPrint('💰 Delivered $productId: free×$freeAmount, radar×${premium?.$1}, evo×${premium?.$2}, mega×${premium?.$3}');
  };

  await iap.initialize(storage);
});

/// Reactive state: whether no-ads has been purchased.
final noAdsPurchasedProvider = StateProvider<bool>((ref) {
  return ref.watch(iapServiceProvider).noAdsPurchased;
});

/// Combined init: reads storage + IAP and exposes noAds flag.
/// Call `ref.read(iapReadyProvider)` once to bootstrap everything.
final iapReadyProvider = FutureProvider<bool>((ref) async {
  await ref.watch(iapInitProvider.future);
  final iap = ref.read(iapServiceProvider);
  ref.read(noAdsPurchasedProvider.notifier).state = iap.noAdsPurchased;

  // Also listen for future changes
  iap.onStatusChanged = (result) {
    if (result.productId == IapProducts.noAds &&
        (result.status == IapStatus.purchased ||
         result.status == IapStatus.restored)) {
      ref.read(noAdsPurchasedProvider.notifier).state = true;
    }
  };

  return iap.storeAvailable;
});
