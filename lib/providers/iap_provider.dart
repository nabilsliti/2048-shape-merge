import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/config/shop_catalog.dart';
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

  // Wire delivery: server verified → read Firestore, not verified → add locally
  iap.onProductDelivered = (productId, {required bool serverVerified}) {
    AudioService.instance.playReward();
    final notifier = ref.read(gameStateProvider.notifier);

    if (notifier.isSignedIn) {
      // Connected: ALWAYS read from Firestore (single source of truth)
      notifier.refreshJokersFromFirestore().then((_) {
        const AppLogger('IAP').info('Jokers refreshed from Firestore for $productId');
      }).catchError((Object e) {
        const AppLogger('IAP').error('Firestore refresh failed for $productId: $e');
      });
    } else {
      // Not signed in: add locally
      const AppLogger('IAP').info('Adding jokers locally for $productId');
      _addJokersLocally(notifier, productId);
    }
  };

  await iap.initialize(storage);
});

/// Reactive state: whether no-ads has been purchased.
final noAdsPurchasedProvider = StateProvider<bool>((ref) {
  return ref.watch(iapServiceProvider).noAdsPurchased;
});

/// Reactive state: whether emoji shape pack has been purchased.
final emojiPackPurchasedProvider = StateProvider<bool>((ref) {
  return ref.watch(iapServiceProvider).emojiPackPurchased;
});

/// Last purchase result — watched by shop overlay to show success/error.
final lastPurchaseResultProvider = StateProvider<IapResult?>((ref) => null);

/// Combined init: reads storage + IAP and exposes noAds flag.
/// Call `ref.read(iapReadyProvider)` once to bootstrap everything.
final iapReadyProvider = FutureProvider<bool>((ref) async {
  await ref.watch(iapInitProvider.future);
  final iap = ref.read(iapServiceProvider);
  ref.read(noAdsPurchasedProvider.notifier).state = iap.noAdsPurchased;
  ref.read(emojiPackPurchasedProvider.notifier).state = iap.emojiPackPurchased;

  // Single onStatusChanged — handles non-consumable sync + exposes result to UI
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
    if (result.productId == IapProducts.emojiPack &&
        (result.status == IapStatus.purchased ||
         result.status == IapStatus.restored)) {
      ref.read(emojiPackPurchasedProvider.notifier).state = true;
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        ref.read(firestoreServiceProvider).updateEmojiPackPurchased(user.uid, value: true);
      }
    }
    // Expose result to UI (shop overlay)
    ref.read(lastPurchaseResultProvider.notifier).state = result;
  };

  return iap.storeAvailable;
});

// ──────────────────────────────────────────────────────────────
// Local joker delivery (mirrors Cloud Function creditJokers)
// ──────────────────────────────────────────────────────────────

void _addJokersLocally(GameStateNotifier notifier, String productId) {
  final pack = ShopCatalog.byId(productId);
  if (pack == null) return;

  // Free jokers: bomb, wildcard, reducer each get freeJokers count
  if (pack.freeJokers > 0) {
    notifier.addJokers(JokerType.bomb, pack.freeJokers);
    notifier.addJokers(JokerType.wildcard, pack.freeJokers);
    notifier.addJokers(JokerType.reducer, pack.freeJokers);
  }
  // Premium jokers
  if (pack.radar > 0) notifier.addJokers(JokerType.radar, pack.radar);
  if (pack.evolution > 0) notifier.addJokers(JokerType.evolution, pack.evolution);
  if (pack.megaBomb > 0) notifier.addJokers(JokerType.megaBomb, pack.megaBomb);
}
