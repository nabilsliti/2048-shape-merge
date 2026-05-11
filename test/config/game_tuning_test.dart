import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/constants/joker_types.dart';

void main() {
  group('Scoring.forMerge', () {
    test('points = 2^newLevel × 10', () {
      expect(Scoring.forMerge(1), 20);
      expect(Scoring.forMerge(2), 40);
      expect(Scoring.forMerge(3), 80);
      expect(Scoring.forMerge(10), 10240);
    });
  });

  group('ShapeSizing.forLevel', () {
    test('grows linearly until cap', () {
      expect(ShapeSizing.forLevel(0), ShapeSizing.baseSize);
      expect(
        ShapeSizing.forLevel(1),
        ShapeSizing.baseSize + ShapeSizing.growthPerLevel,
      );
    });

    test('caps at maxSize', () {
      expect(ShapeSizing.forLevel(999), ShapeSizing.maxSize);
    });
  });

  group('Progression.xpForLevel', () {
    test('floor(100 × level^1.4) at level 1 = 100', () {
      expect(Progression.xpForLevel(1), 100);
    });

    test('strictly increasing within typical range', () {
      var prev = Progression.xpForLevel(1);
      for (var l = 2; l <= 30; l++) {
        final v = Progression.xpForLevel(l);
        expect(v, greaterThanOrEqualTo(prev),
            reason: 'xpForLevel($l) must be >= xpForLevel(${l - 1})');
        prev = v;
      }
    });

    test('clamped to [100, 999999]', () {
      expect(Progression.xpForLevel(0), 100);
      expect(Progression.xpForLevel(99999), lessThanOrEqualTo(999999));
    });
  });

  group('LevelUpRewards.forLevel', () {
    test('returns the rewards for known levels', () {
      expect(LevelUpRewards.forLevel(2), isNotEmpty);
      expect(LevelUpRewards.forLevel(50).first.$1, JokerType.megaBomb);
    });

    test('returns empty list for unknown levels', () {
      expect(LevelUpRewards.forLevel(1), isEmpty);
      expect(LevelUpRewards.forLevel(6), isEmpty);
      expect(LevelUpRewards.forLevel(999), isEmpty);
    });
  });

  group('AdJokerTuning', () {
    test('reward pool excludes premium types', () {
      for (final t in AdJokerTuning.rewardPool) {
        expect(t.isPremium, false);
      }
    });

    test('cooldown is positive and dailyCap is finite small', () {
      expect(AdJokerTuning.cooldown, greaterThan(Duration.zero));
      expect(AdJokerTuning.dailyCap, greaterThan(0));
      expect(AdJokerTuning.dailyCap, lessThanOrEqualTo(8));
    });
  });

  group('JokerStartingCounts', () {
    test('every joker has a non-negative starting count', () {
      expect(JokerStartingCounts.bomb, greaterThanOrEqualTo(0));
      expect(JokerStartingCounts.wildcard, greaterThanOrEqualTo(0));
      expect(JokerStartingCounts.reducer, greaterThanOrEqualTo(0));
      expect(JokerStartingCounts.radar, greaterThanOrEqualTo(0));
      expect(JokerStartingCounts.evolution, greaterThanOrEqualTo(0));
      expect(JokerStartingCounts.megaBomb, greaterThanOrEqualTo(0));
    });
  });
}
