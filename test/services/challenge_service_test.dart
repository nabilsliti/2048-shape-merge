import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/daily_challenge.dart';
import 'package:shape_merge/core/models/player_streak.dart';
import 'package:shape_merge/core/services/challenge_service.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ChallengeService service;
  setUp(() {
    service = const ChallengeService();
  });

  DailyChallenge mk(ChallengeType type, {int target = 10, int current = 0}) =>
      DailyChallenge(
        id: type.name,
        type: type,
        target: target,
        current: current,
        difficulty: ChallengeDifficulty.easy,
        reward: const XpReward(10),
      );

  group('applyLiveProgress', () {
    test('fusions: cumulative from baseline', () {
      final state = DailyChallengeState(
        date: 'd', challenges: [mk(ChallengeType.fusions, target: 10, current: 4)],
      );
      final result = service.applyLiveProgress(
        state,
        baselines: {'fusions': 4},
        fusionsSoFar: 5,
        scoreSoFar: 0,
        jokersUsedSoFar: 0,
        maxLevelSoFar: 0,
        shapesDestroyedSoFar: 0,
        wildcardMergesSoFar: 0,
        highLevelMergesSoFar: 0,
        maxComboSoFar: 0,
      );
      expect(result.challenges.first.current, 9);
      expect(result.challenges.first.completed, false);
    });

    test('fusions clamps to target', () {
      final state = DailyChallengeState(
        date: 'd', challenges: [mk(ChallengeType.fusions, target: 10)],
      );
      final result = service.applyLiveProgress(
        state, baselines: {}, fusionsSoFar: 999,
        scoreSoFar: 0, jokersUsedSoFar: 0, maxLevelSoFar: 0,
        shapesDestroyedSoFar: 0, wildcardMergesSoFar: 0,
        highLevelMergesSoFar: 0, maxComboSoFar: 0,
      );
      expect(result.challenges.first.current, 10);
      expect(result.challenges.first.completed, true);
    });

    test('score: max-not-cumulative semantics', () {
      final state = DailyChallengeState(
        date: 'd', challenges: [mk(ChallengeType.score, target: 1000, current: 500)],
      );
      // scoreSoFar 300 < current 500 → no change
      final r1 = service.applyLiveProgress(
        state, baselines: {}, fusionsSoFar: 0,
        scoreSoFar: 300, jokersUsedSoFar: 0, maxLevelSoFar: 0,
        shapesDestroyedSoFar: 0, wildcardMergesSoFar: 0,
        highLevelMergesSoFar: 0, maxComboSoFar: 0,
      );
      expect(r1.challenges.first.current, 500);

      // scoreSoFar 800 > current 500 → bumps
      final r2 = service.applyLiveProgress(
        state, baselines: {}, fusionsSoFar: 0,
        scoreSoFar: 800, jokersUsedSoFar: 0, maxLevelSoFar: 0,
        shapesDestroyedSoFar: 0, wildcardMergesSoFar: 0,
        highLevelMergesSoFar: 0, maxComboSoFar: 0,
      );
      expect(r2.challenges.first.current, 800);
    });

    test('parties type is never updated by live progress', () {
      final state = DailyChallengeState(
        date: 'd', challenges: [mk(ChallengeType.parties, target: 3, current: 1)],
      );
      final r = service.applyLiveProgress(
        state, baselines: {}, fusionsSoFar: 0,
        scoreSoFar: 0, jokersUsedSoFar: 0, maxLevelSoFar: 0,
        shapesDestroyedSoFar: 0, wildcardMergesSoFar: 0,
        highLevelMergesSoFar: 0, maxComboSoFar: 0,
      );
      expect(r.challenges.first.current, 1);
    });

    test('rewardCollected challenges are skipped', () {
      final challenge = mk(ChallengeType.fusions, target: 10, current: 10)
          .copyWith(completed: true, rewardCollected: true);
      final state = DailyChallengeState(date: 'd', challenges: [challenge]);
      final r = service.applyLiveProgress(
        state, baselines: {}, fusionsSoFar: 999,
        scoreSoFar: 0, jokersUsedSoFar: 0, maxLevelSoFar: 0,
        shapesDestroyedSoFar: 0, wildcardMergesSoFar: 0,
        highLevelMergesSoFar: 0, maxComboSoFar: 0,
      );
      expect(r.challenges.first.current, 10);
      expect(r.challenges.first.rewardCollected, true);
    });

    test('formeMax / maxCombo use max-not-cumulative semantics', () {
      final state = DailyChallengeState(date: 'd', challenges: [
        mk(ChallengeType.formeMax, target: 8, current: 4),
        mk(ChallengeType.maxCombo, target: 5, current: 2),
      ]);
      final r = service.applyLiveProgress(
        state, baselines: {}, fusionsSoFar: 0,
        scoreSoFar: 0, jokersUsedSoFar: 0, maxLevelSoFar: 6,
        shapesDestroyedSoFar: 0, wildcardMergesSoFar: 0,
        highLevelMergesSoFar: 0, maxComboSoFar: 3,
      );
      expect(r.challenges[0].current, 6);
      expect(r.challenges[1].current, 3);
    });
  });

  group('applyGameResult', () {
    test('parties always +1, capped at target', () {
      final state = DailyChallengeState(date: 'd', challenges: [
        mk(ChallengeType.parties, target: 3, current: 2),
      ]);
      final r = service.applyGameResult(
        state, fusionsThisGame: 0, scoreThisGame: 0,
        jokersUsedThisGame: 0, maxLevelReached: 0,
        shapesDestroyedThisGame: 0, wildcardMergesThisGame: 0,
        highLevelMergesThisGame: 0, maxComboReached: 0,
      );
      expect(r.challenges.first.current, 3);
      expect(r.challenges.first.completed, true);
    });

    test('cumulative types add this-game count to current', () {
      final state = DailyChallengeState(date: 'd', challenges: [
        mk(ChallengeType.fusions, target: 100, current: 30),
        mk(ChallengeType.jokersUses, target: 10, current: 2),
        mk(ChallengeType.shapesDestroyed, target: 50, current: 10),
        mk(ChallengeType.wildcardMerges, target: 5, current: 1),
        mk(ChallengeType.highLevelMerges, target: 3, current: 0),
      ]);
      final r = service.applyGameResult(
        state, fusionsThisGame: 20, scoreThisGame: 0,
        jokersUsedThisGame: 3, maxLevelReached: 0,
        shapesDestroyedThisGame: 5, wildcardMergesThisGame: 2,
        highLevelMergesThisGame: 1, maxComboReached: 0,
      );
      expect(r.challenges[0].current, 50);
      expect(r.challenges[1].current, 5);
      expect(r.challenges[2].current, 15);
      expect(r.challenges[3].current, 3);
      expect(r.challenges[4].current, 1);
    });

    test('rewardCollected challenges are skipped', () {
      final c = mk(ChallengeType.fusions, target: 10, current: 10)
          .copyWith(completed: true, rewardCollected: true);
      final state = DailyChallengeState(date: 'd', challenges: [c]);
      final r = service.applyGameResult(
        state, fusionsThisGame: 100, scoreThisGame: 0,
        jokersUsedThisGame: 0, maxLevelReached: 0,
        shapesDestroyedThisGame: 0, wildcardMergesThisGame: 0,
        highLevelMergesThisGame: 0, maxComboReached: 0,
      );
      expect(r.challenges.first.current, 10);
    });
  });

  group('loadOrGenerateGuest (deterministic)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'guestName': 'Tester_1234'});
    });

    test('generates 3 challenges for today', () async {
      final storage = LocalStorageService(await SharedPreferences.getInstance());
      final state = await service.loadOrGenerateGuest(storage, playerLevel: 1);
      expect(state.date, PlayerStreak.todayKey());
      expect(state.challenges.length, 3);
    });

    test('returns same challenges on second call (same day, persisted)', () async {
      final storage = LocalStorageService(await SharedPreferences.getInstance());
      final s1 = await service.loadOrGenerateGuest(storage, playerLevel: 1);
      final s2 = await service.loadOrGenerateGuest(storage, playerLevel: 1);
      expect(
        s1.challenges.map((c) => c.id).toList(),
        s2.challenges.map((c) => c.id).toList(),
      );
    });

    test('first challenge gives a JokerReward (the hardest)', () async {
      final storage = LocalStorageService(await SharedPreferences.getInstance());
      final state = await service.loadOrGenerateGuest(storage, playerLevel: 1);
      expect(state.challenges.first.reward, isA<JokerReward>());
    });

    test('other challenges give XP rewards', () async {
      final storage = LocalStorageService(await SharedPreferences.getInstance());
      final state = await service.loadOrGenerateGuest(storage, playerLevel: 1);
      for (final c in state.challenges.skip(1)) {
        expect(c.reward, isA<XpReward>());
      }
    });

    test('high-level player → first challenge has hard difficulty', () async {
      final storage = LocalStorageService(await SharedPreferences.getInstance());
      final state = await service.loadOrGenerateGuest(storage, playerLevel: 25);
      expect(state.challenges.first.difficulty, ChallengeDifficulty.hard);
    });

    test('low-level player → first challenge has easy difficulty', () async {
      final storage = LocalStorageService(await SharedPreferences.getInstance());
      final state = await service.loadOrGenerateGuest(storage, playerLevel: 1);
      expect(state.challenges.first.difficulty, ChallengeDifficulty.easy);
    });
  });
}
