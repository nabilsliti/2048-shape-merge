import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/services/iap_service.dart';

import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';

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
    AudioService.instance.playReward();
    final freeAmount = IapProducts.packContents[productId] ?? 0;
    final premium = IapProducts.premiumContents[productId];
    final notifier = ref.read(gameStateProvider.notifier);
    if (freeAmount > 0) {
      for (final type in [JokerType.bomb, JokerType.wildcard, JokerType.reducer]) {
        notifier.addJokers(type, freeAmount);
      }
    }
    if (premium != null) {
      if (premium.radar > 0) notifier.addJokers(JokerType.radar, premium.radar);
      if (premium.evolution > 0) notifier.addJokers(JokerType.evolution, premium.evolution);
      if (premium.megaBomb > 0) notifier.addJokers(JokerType.megaBomb, premium.megaBomb);
    }
    const AppLogger('IAP').info('Delivered $productId: free×$freeAmount, radar×${premium?.radar}, evo×${premium?.evolution}, mega×${premium?.megaBomb}');
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
      // Sync to Firestore if signed in
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        ref.read(firestoreServiceProvider).updateNoAdsPurchased(user.uid, value: true);
      }
    }
  };

  return iap.storeAvailable;
});
