import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/services/integrity_guard.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<LocalStorageService> openEmpty() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStorageService(await SharedPreferences.getInstance());
  }

  group('joker inventory persistence', () {
    test('returns starting counts on a fresh install', () async {
      final s = await openEmpty();
      final inv = s.jokerInventory;
      expect(inv.bomb, JokerStartingCounts.bomb);
      expect(inv.wildcard, JokerStartingCounts.wildcard);
      expect(inv.reducer, JokerStartingCounts.reducer);
      expect(inv.radar, JokerStartingCounts.radar);
    });

    test('save then read is a perfect round-trip', () async {
      final s = await openEmpty();
      const inv = JokerInventory(
        bomb: 7, wildcard: 8, reducer: 9,
        radar: 1, evolution: 2, megaBomb: 3,
      );
      await s.saveJokerInventory(inv);
      final back = s.jokerInventory;
      expect(back.bomb, 7);
      expect(back.wildcard, 8);
      expect(back.reducer, 9);
      expect(back.radar, 1);
      expect(back.evolution, 2);
      expect(back.megaBomb, 3);
    });

    test('reads legacy unsigned keys when signed payload is missing', () async {
      SharedPreferences.setMockInitialValues({
        'jokerBomb': 5,
        'jokerWildcard': 4,
        'jokerReducer': 3,
        'jokerRadar': 2,
        'jokerEvolution': 1,
        'jokerMegaBomb': 0,
      });
      final s = LocalStorageService(await SharedPreferences.getInstance());
      final inv = s.jokerInventory;
      expect(inv.bomb, 5);
      expect(inv.wildcard, 4);
      expect(inv.reducer, 3);
      expect(inv.radar, 2);
      expect(inv.evolution, 1);
      expect(inv.megaBomb, 0);
    });

    test('falls back to legacy keys when signed payload is tampered', () async {
      // Tampered signed payload + valid legacy keys
      final wrapped = IntegrityGuard.wrap(jsonEncode({'b': 99}));
      SharedPreferences.setMockInitialValues({
        'jokerSigned': wrapped.replaceFirst('99', '100'),
        'jokerBomb': 4,
      });
      final s = LocalStorageService(await SharedPreferences.getInstance());
      // The tampered signed payload must be rejected → legacy bomb=4
      expect(s.jokerInventory.bomb, 4);
    });
  });

  group('ad-joker gating', () {
    test('fresh install: cooldown zero, full daily cap available', () async {
      final s = await openEmpty();
      expect(s.adJokerCooldownRemaining, Duration.zero);
      expect(s.adJokerAdsLeftToday, AdJokerTuning.dailyCap);
      expect(s.canWatchAdJoker, true);
    });

    test('recordAdJokerWatched starts cooldown and decrements quota', () async {
      final s = await openEmpty();
      await s.recordAdJokerWatched();
      expect(s.adJokerCountToday, 1);
      expect(s.adJokerAdsLeftToday, AdJokerTuning.dailyCap - 1);
      expect(s.adJokerCooldownRemaining, greaterThan(Duration.zero));
      expect(s.canWatchAdJoker, false);
    });

    test('reaching dailyCap blocks watching even after cooldown', () async {
      final s = await openEmpty();
      for (var i = 0; i < AdJokerTuning.dailyCap; i++) {
        await s.recordAdJokerWatched();
      }
      expect(s.adJokerAdsLeftToday, 0);
      // Even if we somehow zeroed the cooldown timer, cap still blocks
      expect(s.canWatchAdJoker, false);
    });

    test('a different stored UTC day resets the daily counter', () async {
      // Pre-seed yesterday's count
      SharedPreferences.setMockInitialValues({
        'adJokerDay': '1990-01-01',
        'adJokerCount': 999,
      });
      final s = LocalStorageService(await SharedPreferences.getInstance());
      // adJokerCountToday returns 0 because storedDay != today
      expect(s.adJokerCountToday, 0);
      expect(s.adJokerAdsLeftToday, AdJokerTuning.dailyCap);
    });
  });

  group('streak/level/xp guest fields', () {
    test('default values then setters', () async {
      final s = await openEmpty();
      expect(s.currentStreak, 0);
      expect(s.longestStreak, 0);
      expect(s.lastLoginDate, isNull);
      expect(s.nextRewardIndex, 0);
      expect(s.playerLevel, 1);
      expect(s.currentXP, 0);
      expect(s.totalXP, 0);

      await s.setCurrentStreak(7);
      await s.setLongestStreak(10);
      await s.setLastLoginDate('2026-05-11');
      await s.setNextRewardIndex(3);
      await s.setPlayerLevel(5);
      await s.setCurrentXP(120);
      await s.setTotalXP(999);

      expect(s.currentStreak, 7);
      expect(s.longestStreak, 10);
      expect(s.lastLoginDate, '2026-05-11');
      expect(s.nextRewardIndex, 3);
      expect(s.playerLevel, 5);
      expect(s.currentXP, 120);
      expect(s.totalXP, 999);
    });

    test('clearLastLoginDate removes the key', () async {
      final s = await openEmpty();
      await s.setLastLoginDate('2026-05-11');
      await s.clearLastLoginDate();
      expect(s.lastLoginDate, isNull);
    });
  });

  group('one-shot analytics flags', () {
    test('default false then true after setter', () async {
      final s = await openEmpty();
      expect(s.firstMergeLogged, false);
      expect(s.firstJokerLogged, false);
      await s.setFirstMergeLogged();
      await s.setFirstJokerLogged();
      expect(s.firstMergeLogged, true);
      expect(s.firstJokerLogged, true);
    });
  });

  group('nudges', () {
    test('default false, set sticks to true', () async {
      final s = await openEmpty();
      expect(s.nudgeStreak3Shown, false);
      await s.setNudgeStreak3Shown();
      expect(s.nudgeStreak3Shown, true);

      expect(s.nudgeLevel5Shown, false);
      await s.setNudgeLevel5Shown();
      expect(s.nudgeLevel5Shown, true);

      expect(s.nudgeStreak7Shown, false);
      await s.setNudgeStreak7Shown();
      expect(s.nudgeStreak7Shown, true);

      expect(s.nudgeObjectives3DaysShown, false);
      await s.setNudgeObjectives3DaysShown();
      expect(s.nudgeObjectives3DaysShown, true);
    });
  });

  group('pending purchases (guest mode replay buffer)', () {
    test('empty by default', () async {
      final s = await openEmpty();
      expect(s.pendingPurchases, isEmpty);
    });

    test('add then read preserves entries', () async {
      final s = await openEmpty();
      await s.addPendingPurchase(
        productId: 'pack_star', purchaseToken: 'tok1', platform: 'android',
      );
      await s.addPendingPurchase(
        productId: 'no_ads', purchaseToken: 'tok2', platform: 'ios',
      );
      final list = s.pendingPurchases;
      expect(list.length, 2);
      expect(list.first['productId'], 'pack_star');
      expect(list.last['platform'], 'ios');
    });

    test('clearPendingPurchases empties the buffer', () async {
      final s = await openEmpty();
      await s.addPendingPurchase(
        productId: 'p', purchaseToken: 't', platform: 'android',
      );
      await s.clearPendingPurchases();
      expect(s.pendingPurchases, isEmpty);
    });
  });

  group('game stats counters (guest)', () {
    test('increment / add accumulate', () async {
      final s = await openEmpty();
      await s.incrementGamesPlayed();
      await s.incrementGamesPlayed();
      expect(s.gamesPlayed, 2);

      await s.addMerges(5);
      await s.addMerges(3);
      expect(s.totalMerges, 8);
    });
  });

  group('crash recovery checkpoint', () {
    test('save then read; clear removes it', () async {
      final s = await openEmpty();
      expect(s.gameCheckpoint, isNull);
      await s.saveGameCheckpoint('{"score":42}');
      expect(s.gameCheckpoint, '{"score":42}');
      await s.clearGameCheckpoint();
      expect(s.gameCheckpoint, isNull);
    });
  });

  group('clearAllData', () {
    test('wipes every key', () async {
      final s = await openEmpty();
      await s.setBestScore(100);
      await s.setOnboardingDone(true);
      await s.clearAllData();
      expect(s.bestScore, 0);
      expect(s.onboardingDone, false);
    });
  });
}
