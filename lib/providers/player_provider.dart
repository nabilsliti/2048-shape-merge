import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/models/player.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';

final playerProvider = FutureProvider<Player?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  final firestoreService = ref.watch(firestoreServiceProvider);
  final storage = await ref.read(localStorageProvider.future);

  var player = await firestoreService.getPlayer(user.uid);

  if (player == null) {
    // First time sign-in: create player from Google profile + local guest data
    player = Player(
      uid: user.uid,
      displayName: user.displayName ?? user.email ?? 'Player',
      photoUrl: user.photoURL,
      bestScore: storage.bestScore,
      gamesPlayed: 0,
      totalMerges: 0,
      jokerInventory: storage.jokerInventory,
      noAdsPurchased: storage.noAdsPurchased,
      rewardClaimedDate: storage.rewardClaimedDate,
      level: storage.playerLevel,
      currentXP: storage.currentXP,
      totalXP: storage.totalXP,
    );
    await firestoreService.savePlayer(player);
    const _log = AppLogger('Game');
    _log.info('New player created from local data: bestScore=${player.bestScore}, level=${player.level}');
    return player;
  }

  // Existing player: Firestore is the single source of truth.
  // One-shot migration: if this is the first login after the v2 update,
  // migrate local data (jokers, noAdsPurchased, rewardClaimedDate) to Firestore.
  if (!storage.migrationV2Done) {
    var needsUpdate = false;
    var updated = player;

    // Migrate jokers if Firestore has none but localStorage does
    final localJokers = storage.jokerInventory;
    final fsJokers = player.jokerInventory;
    if (fsJokers.bomb == 0 && fsJokers.wildcard == 0 && fsJokers.reducer == 0 &&
        (localJokers.bomb > 0 || localJokers.wildcard > 0 || localJokers.reducer > 0 ||
         localJokers.radar > 0 || localJokers.evolution > 0 || localJokers.megaBomb > 0)) {
      updated = updated.copyWith(jokerInventory: localJokers);
      needsUpdate = true;
    }

    // Migrate noAdsPurchased
    if (!player.noAdsPurchased && storage.noAdsPurchased) {
      updated = updated.copyWith(noAdsPurchased: true);
      needsUpdate = true;
    }

    // Migrate rewardClaimedDate
    if (player.rewardClaimedDate == null && storage.rewardClaimedDate != null) {
      updated = updated.copyWith(rewardClaimedDate: storage.rewardClaimedDate);
      needsUpdate = true;
    }

    if (needsUpdate) {
      await firestoreService.savePlayer(updated);
      const AppLogger('Game').info('Migration v2: jokers/noAds/rewardClaimed migrated to Firestore');
      player = updated;
    }
    await storage.setMigrationV2Done();
  }

  return player;
});
