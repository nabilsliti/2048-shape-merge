import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/models/player.dart';
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
    // First time: create player from Google profile + merge local data
    player = Player(
      uid: user.uid,
      displayName: user.displayName ?? user.email ?? 'Player',
      photoUrl: user.photoURL,
      bestScore: storage.bestScore,
      gamesPlayed: 0,
      totalMerges: 0,
      level: storage.playerLevel,
      currentXP: storage.currentXP,
      totalXP: storage.totalXP,
    );
    await firestoreService.savePlayer(player);
    debugPrint('✅ New player created with local data: bestScore=${player.bestScore}, level=${player.level}');
    return player;
  }

  // Existing player: merge local data if local is better (guest played before signing in)
  var p = player!;
  final mergedBest = storage.bestScore > p.bestScore ? storage.bestScore : p.bestScore;
  final mergedLevel = storage.playerLevel > p.level ? storage.playerLevel : p.level;
  final mergedXP = storage.totalXP > p.totalXP ? storage.totalXP : p.totalXP;
  final mergedCurrentXP = storage.playerLevel > p.level ? storage.currentXP : p.currentXP;

  if (mergedBest > p.bestScore || mergedLevel > p.level || mergedXP > p.totalXP) {
    try {
      await firestoreService.updateBestScore(user.uid, mergedBest);
      await firestoreService.updateXP(user.uid, level: mergedLevel, currentXP: mergedCurrentXP, totalXP: mergedXP);
      debugPrint('✅ Player synced: bestScore=$mergedBest, level=$mergedLevel, XP=$mergedCurrentXP');
      p = p.copyWith(bestScore: mergedBest, level: mergedLevel, currentXP: mergedCurrentXP, totalXP: mergedXP);
    } catch (e) {
      debugPrint('⚠️ Player merge failed: $e');
    }
  }

  // Also sync Firestore → local if Firestore has better data
  if (p.bestScore > storage.bestScore) await storage.setBestScore(p.bestScore);
  if (p.level > storage.playerLevel) await storage.setPlayerLevel(p.level);
  if (p.currentXP > storage.currentXP) await storage.setCurrentXP(p.currentXP);
  if (p.totalXP > storage.totalXP) await storage.setTotalXP(p.totalXP);

  return p;
});
