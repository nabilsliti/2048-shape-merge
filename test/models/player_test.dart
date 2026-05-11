import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/models/player.dart';

void main() {
  group('Player', () {
    test('defaults are sensible for a brand-new account', () {
      const p = Player(uid: 'u', displayName: 'Anon');
      expect(p.bestScore, 0);
      expect(p.totalMerges, 0);
      expect(p.gamesPlayed, 0);
      expect(p.level, 1);
      expect(p.currentXP, 0);
      expect(p.totalXP, 0);
      expect(p.currentStreak, 0);
      expect(p.longestStreak, 0);
      expect(p.unlockedRewards, isEmpty);
      expect(p.noAdsPurchased, false);
      expect(p.emojiPackPurchased, false);
      expect(p.lastClaimAt, isNull);
    });

    test('copyWith overrides supplied fields and preserves uid', () {
      const p = Player(uid: 'u1', displayName: 'A');
      final updated = p.copyWith(displayName: 'B', bestScore: 999);
      expect(updated.uid, 'u1');
      expect(updated.displayName, 'B');
      expect(updated.bestScore, 999);
    });

    test('toFirestore + fromFirestore round-trip preserves all written fields',
        () {
      const original = Player(
        uid: 'uid42',
        displayName: 'Charlie',
        photoUrl: 'https://x/y.png',
        avatarId: 'fox',
        bestScore: 4242,
        totalMerges: 100,
        gamesPlayed: 12,
        jokerInventory: JokerInventory(
          bomb: 1, wildcard: 2, reducer: 3,
          radar: 4, evolution: 5, megaBomb: 6,
        ),
        currentStreak: 5,
        longestStreak: 9,
        lastLoginDate: '2026-05-10',
        nextRewardIndex: 4,
        level: 12,
        currentXP: 333,
        totalXP: 9999,
        unlockedRewards: ['avatar_unicorn', 'avatar_dragon'],
        noAdsPurchased: true,
        emojiPackPurchased: true,
        rewardClaimedDate: '2026-05-11',
      );
      final restored = Player.fromFirestore('uid42', original.toFirestore());
      expect(restored.uid, 'uid42');
      expect(restored.displayName, 'Charlie');
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.avatarId, 'fox');
      expect(restored.bestScore, 4242);
      expect(restored.totalMerges, 100);
      expect(restored.gamesPlayed, 12);
      expect(restored.jokerInventory.bomb, 1);
      expect(restored.jokerInventory.megaBomb, 6);
      expect(restored.currentStreak, 5);
      expect(restored.longestStreak, 9);
      expect(restored.lastLoginDate, '2026-05-10');
      expect(restored.nextRewardIndex, 4);
      expect(restored.level, 12);
      expect(restored.currentXP, 333);
      expect(restored.totalXP, 9999);
      expect(restored.unlockedRewards, ['avatar_unicorn', 'avatar_dragon']);
      expect(restored.noAdsPurchased, true);
      expect(restored.emojiPackPurchased, true);
      expect(restored.rewardClaimedDate, '2026-05-11');
    });

    test('fromFirestore with empty data uses safe defaults', () {
      final p = Player.fromFirestore('u', const {});
      expect(p.displayName, '');
      expect(p.bestScore, 0);
      expect(p.level, 1);
      // Default JokerInventory uses starting counts when no map is supplied.
      expect(p.jokerInventory.bomb, const JokerInventory().bomb);
      expect(p.unlockedRewards, isEmpty);
    });

    test('fromFirestore reads lastClaimAt when it is a Timestamp', () {
      final ts = Timestamp.fromDate(DateTime.utc(2026, 5, 1, 10, 0));
      final p = Player.fromFirestore('u', {'lastClaimAt': ts});
      expect(p.lastClaimAt, isNotNull);
      expect(p.lastClaimAt!.toUtc(), DateTime.utc(2026, 5, 1, 10, 0));
    });

    test('fromFirestore ignores lastClaimAt of unexpected type', () {
      final p = Player.fromFirestore('u', {'lastClaimAt': 'not-a-timestamp'});
      expect(p.lastClaimAt, isNull);
    });
  });
}
