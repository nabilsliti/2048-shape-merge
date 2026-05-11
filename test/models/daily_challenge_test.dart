import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/daily_challenge.dart';

void main() {
  group('DailyChallenge', () {
    DailyChallenge make({int current = 0, int target = 10, bool collected = false}) =>
        DailyChallenge(
          id: 'id',
          type: ChallengeType.fusions,
          target: target,
          current: current,
          completed: current >= target,
          rewardCollected: collected,
          difficulty: ChallengeDifficulty.easy,
          reward: const JokerReward(JokerType.bomb),
        );

    test('progress is current/target clamped 0..1', () {
      expect(make(current: 0).progress, 0.0);
      expect(make(current: 5).progress, 0.5);
      expect(make(current: 10).progress, 1.0);
      expect(make(current: 999).progress, 1.0);
    });

    test('progress is 0 when target is 0', () {
      expect(make(target: 0, current: 5).progress, 0.0);
    });

    test('canCollect true only when completed and not collected', () {
      expect(make(current: 10).canCollect, true);
      expect(make(current: 5).canCollect, false);
      expect(make(current: 10, collected: true).canCollect, false);
    });

    test('copyWith preserves immutable fields', () {
      final c = make(current: 1).copyWith(current: 5, completed: true);
      expect(c.id, 'id');
      expect(c.type, ChallengeType.fusions);
      expect(c.target, 10);
      expect(c.current, 5);
      expect(c.completed, true);
      expect(c.difficulty, ChallengeDifficulty.easy);
    });
  });

  group('ChallengeReward serialization', () {
    test('JokerReward toMap/fromMap round-trip', () {
      const r = JokerReward(JokerType.wildcard);
      final restored = ChallengeReward.fromMap(r.toMap()) as JokerReward;
      expect(restored.joker, JokerType.wildcard);
    });

    test('XpReward toMap/fromMap round-trip', () {
      const r = XpReward(42);
      final restored = ChallengeReward.fromMap(r.toMap()) as XpReward;
      expect(restored.xp, 42);
    });
  });

  group('DailyChallenge.fromMap legacy formats', () {
    DailyChallenge fromMap(Object reward) => DailyChallenge.fromMap({
          'id': 'x',
          'type': 'fusions',
          'target': 10,
          'current': 3,
          'completed': false,
          'rewardCollected': false,
          'difficulty': 'easy',
          'reward': reward,
        });

    test('legacy string reward → JokerReward of that name', () {
      final c = fromMap('wildcard');
      final r = c.reward as JokerReward;
      expect(r.joker, JokerType.wildcard);
    });

    test('modern map reward (xp)', () {
      final c = fromMap({'kind': 'xp', 'xp': 25});
      expect((c.reward as XpReward).xp, 25);
    });

    test('modern map reward (joker)', () {
      final c = fromMap({'kind': 'joker', 'joker': 'reducer'});
      expect((c.reward as JokerReward).joker, JokerType.reducer);
    });
  });

  group('DailyChallengeState', () {
    DailyChallenge complete([JokerType j = JokerType.bomb]) => DailyChallenge(
          id: j.name,
          type: ChallengeType.fusions,
          target: 1,
          current: 1,
          completed: true,
          difficulty: ChallengeDifficulty.easy,
          reward: JokerReward(j),
        );

    DailyChallenge incomplete() => const DailyChallenge(
          id: 'pending',
          type: ChallengeType.score,
          target: 100,
          current: 50,
          difficulty: ChallengeDifficulty.medium,
          reward: XpReward(10),
        );

    test('allCompleted false on empty list', () {
      const s = DailyChallengeState(date: '2026-01-01', challenges: []);
      expect(s.allCompleted, false);
    });

    test('allCompleted true when every challenge completed', () {
      final s = DailyChallengeState(
        date: '2026-01-01',
        challenges: [complete(), complete(JokerType.wildcard)],
      );
      expect(s.allCompleted, true);
    });

    test('canCollectBonus true only if allCompleted && !bonusCollected', () {
      final s = DailyChallengeState(
        date: '2026-01-01',
        challenges: [complete()],
      );
      expect(s.canCollectBonus, true);
      expect(s.copyWith(bonusCollected: true).canCollectBonus, false);
    });

    test('completedCount counts only completed', () {
      final s = DailyChallengeState(
        date: '2026-01-01',
        challenges: [complete(), incomplete(), complete(JokerType.reducer)],
      );
      expect(s.completedCount, 2);
    });

    test('toMap/fromMap round-trip preserves all fields', () {
      final s = DailyChallengeState(
        date: '2026-04-15',
        challenges: [complete(), incomplete()],
        bonusCollected: true,
      );
      final restored = DailyChallengeState.fromMap(s.toMap());
      expect(restored.date, '2026-04-15');
      expect(restored.challenges.length, 2);
      expect(restored.bonusCollected, true);
      expect(restored.challenges.first.id, 'bomb');
      expect(restored.challenges.last.target, 100);
    });

    test('fromMap with missing/invalid challenges returns empty list', () {
      final s = DailyChallengeState.fromMap(const {'date': '2026-01-01'});
      expect(s.challenges, isEmpty);
    });
  });
}
