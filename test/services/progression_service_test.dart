import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/services/progression_service.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ProgressionService.computeXP', () {
    test('combines all sources additively', () {
      final xp = ProgressionService.computeXP(
        score: 1000,           // 1000 / 500 = 2
        mergeCount: 10,        // 10 × 1   = 10
        maxLevelReached: 4,    // 4  × 3   = 12
        currentStreak: 0,      // no bonus
        completedObjectives: 1, // 1  × 5   = 5
      );
      expect(xp, 2 + 10 + 12 + 5);
    });

    test('applies streak multiplier when threshold is reached', () {
      final base = ProgressionService.computeXP(
        score: 5000, mergeCount: 10, maxLevelReached: 5,
        currentStreak: 0, completedObjectives: 0,
      );
      final boosted = ProgressionService.computeXP(
        score: 5000, mergeCount: 10, maxLevelReached: 5,
        currentStreak: Progression.streakBonusThreshold,
        completedObjectives: 0,
      );
      expect(boosted, greaterThan(base));
      expect(boosted, (base * Progression.streakMultiplier).toInt());
    });

    test('returns at least 1 XP', () {
      final xp = ProgressionService.computeXP(
        score: 0, mergeCount: 0, maxLevelReached: 0,
        currentStreak: 0, completedObjectives: 0,
      );
      expect(xp, 1);
    });
  });

  group('ProgressionService.levelProgress', () {
    test('returns 0..1 fraction within current level', () {
      final needed = Progression.xpForLevel(2);
      expect(ProgressionService.levelProgress(0, 2), 0.0);
      expect(ProgressionService.levelProgress(needed ~/ 2, 2),
          closeTo(0.5, 0.01));
      expect(ProgressionService.levelProgress(needed, 2), 1.0);
    });

    test('returns 1.0 at max level', () {
      expect(ProgressionService.levelProgress(0, Progression.maxLevel), 1.0);
    });
  });

  group('ProgressionService.cumulativeXPForLevel', () {
    test('targetLevel = 1 → 0', () {
      expect(ProgressionService.cumulativeXPForLevel(1), 0);
    });

    test('targetLevel = 2 → xpForLevel(1)', () {
      expect(
        ProgressionService.cumulativeXPForLevel(2),
        Progression.xpForLevel(1),
      );
    });

    test('strictly increasing across levels', () {
      var prev = 0;
      for (var l = 1; l <= 10; l++) {
        final v = ProgressionService.cumulativeXPForLevel(l);
        expect(v, greaterThanOrEqualTo(prev));
        prev = v;
      }
    });
  });

  group('ProgressionService.addXPGuest', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persists xp without level-up when below threshold', () async {
      final storage = LocalStorageService(await SharedPreferences.getInstance());
      const service = ProgressionService();

      final r = await service.addXPGuest(storage, xpToAdd: 10);
      expect(r.level, 1);
      expect(r.currentXP, 10);
      expect(r.leveledUp, 0);
      expect(storage.currentXP, 10);
      expect(storage.totalXP, 10);
    });

    test('levels up when xp ≥ xpForLevel(currentLevel)', () async {
      final storage = LocalStorageService(await SharedPreferences.getInstance());
      const service = ProgressionService();
      final needed = Progression.xpForLevel(1);

      final r = await service.addXPGuest(storage, xpToAdd: needed + 5);
      expect(r.level, 2);
      expect(r.leveledUp, 1);
      expect(r.currentXP, 5);
      expect(storage.playerLevel, 2);
    });

    test('chains multiple level-ups in one call', () async {
      final storage = LocalStorageService(await SharedPreferences.getInstance());
      const service = ProgressionService();
      final big = Progression.xpForLevel(1) +
          Progression.xpForLevel(2) +
          Progression.xpForLevel(3);

      final r = await service.addXPGuest(storage, xpToAdd: big);
      expect(r.level, 4);
      expect(r.leveledUp, 3);
    });

    test('caps at maxLevel', () async {
      // Pre-fill nearly max
      SharedPreferences.setMockInitialValues({
        'playerLevel': Progression.maxLevel - 1,
        'currentXP': 0,
        'totalXP': 0,
      });
      final storage = LocalStorageService(await SharedPreferences.getInstance());
      const service = ProgressionService();

      final r = await service.addXPGuest(storage, xpToAdd: 999999999);
      expect(r.level, Progression.maxLevel);
    });
  });
}
