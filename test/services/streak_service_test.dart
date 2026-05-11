import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/player_streak.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shape_merge/core/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StreakService service;

  setUp(() {
    service = const StreakService();
  });

  group('StreakService guest mode', () {
    test('first login ever → streak 1, reward given', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService(await SharedPreferences.getInstance());

      final result = await service.checkAndUpdateGuest(storage);

      expect(result.streakIncremented, true);
      expect(result.streak.currentStreak, 1);
      expect(result.streak.lastLoginDate, PlayerStreak.todayKey());
      expect(result.reward, isNotNull);
    });

    test('same day login → no increment, reward still available', () async {
      SharedPreferences.setMockInitialValues({
        'currentStreak': 3,
        'longestStreak': 5,
        'lastLoginDate': PlayerStreak.todayKey(),
        'nextRewardIndex': 3,
      });
      final storage = LocalStorageService(await SharedPreferences.getInstance());

      final result = await service.checkAndUpdateGuest(storage);

      expect(result.streakIncremented, false);
      expect(result.streakReset, false);
      expect(result.streak.currentStreak, 3);
    });

    test('consecutive day → streak incremented', () async {
      SharedPreferences.setMockInitialValues({
        'currentStreak': 3,
        'longestStreak': 5,
        'lastLoginDate': PlayerStreak.yesterdayKey(),
        'nextRewardIndex': 2,
      });
      final storage = LocalStorageService(await SharedPreferences.getInstance());

      final result = await service.checkAndUpdateGuest(storage);

      expect(result.streakIncremented, true);
      expect(result.streakReset, false);
      expect(result.streak.currentStreak, 4);
      expect(result.streak.longestStreak, 5);
      expect(result.reward, isNotNull);
    });

    test('missed day → streak reset to 1', () async {
      SharedPreferences.setMockInitialValues({
        'currentStreak': 10,
        'longestStreak': 10,
        'lastLoginDate': '2020-01-01',
        'nextRewardIndex': 4,
      });
      final storage = LocalStorageService(await SharedPreferences.getInstance());

      final result = await service.checkAndUpdateGuest(storage);

      expect(result.streakIncremented, true);
      expect(result.streakReset, true);
      expect(result.streak.currentStreak, 1);
      expect(result.streak.longestStreak, 10);
    });

    test('consecutive day surpasses longest → longest updated', () async {
      SharedPreferences.setMockInitialValues({
        'currentStreak': 5,
        'longestStreak': 5,
        'lastLoginDate': PlayerStreak.yesterdayKey(),
        'nextRewardIndex': 2,
      });
      final storage = LocalStorageService(await SharedPreferences.getInstance());

      final result = await service.checkAndUpdateGuest(storage);

      expect(result.streak.currentStreak, 6);
      expect(result.streak.longestStreak, 6);
    });

    test('guest nudge shown at streak >= 3', () async {
      SharedPreferences.setMockInitialValues({
        'currentStreak': 2,
        'longestStreak': 2,
        'lastLoginDate': PlayerStreak.yesterdayKey(),
        'nextRewardIndex': 1,
      });
      final storage = LocalStorageService(await SharedPreferences.getInstance());

      final result = await service.checkAndUpdateGuest(storage);

      expect(result.streak.currentStreak, 3);
      expect(result.showGuestNudge, true);
    });

    test('guest nudge not shown again after flag set', () async {
      SharedPreferences.setMockInitialValues({
        'currentStreak': 3,
        'longestStreak': 3,
        'lastLoginDate': PlayerStreak.yesterdayKey(),
        'nextRewardIndex': 2,
        'nudgeStreak3Shown': true,
      });
      final storage = LocalStorageService(await SharedPreferences.getInstance());

      final result = await service.checkAndUpdateGuest(storage);

      expect(result.streak.currentStreak, 4);
      expect(result.showGuestNudge, false);
    });
  });

  group('PlayerStreak', () {
    test('todayKey format is YYYY-MM-DD', () {
      final key = PlayerStreak.todayKey();
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key), true);
    });

    test('yesterdayKey is one day before today', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final expectedKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      expect(PlayerStreak.yesterdayKey(), expectedKey);
    });

    test('rewardForStreak J1 is XP and J2 is joker', () {
      expect(PlayerStreak.rewardForStreak(1), isA<StreakXpReward>());
      expect(PlayerStreak.rewardForStreak(2), isA<StreakJokerReward>());
    });

    test('rewardForStreak J7 rotates premium joker by week', () {
      final w1 = PlayerStreak.rewardForStreak(7) as StreakJokerReward;
      final w2 = PlayerStreak.rewardForStreak(14) as StreakJokerReward;
      final w3 = PlayerStreak.rewardForStreak(21) as StreakJokerReward;
      final w4 = PlayerStreak.rewardForStreak(28) as StreakJokerReward;
      expect(w1.type, isNot(w2.type));
      expect(w2.type, isNot(w3.type));
      expect(w4.type, w1.type, reason: 'rotation has length 3');
      // J7 is always amount 1
      expect(w1.amount, 1);
      expect(w2.amount, 1);
    });

    test('rewardForStreak handles 0/negative as J1 default', () {
      expect(PlayerStreak.rewardForStreak(0), isA<StreakXpReward>());
      expect(PlayerStreak.rewardForStreak(-5), isA<StreakXpReward>());
    });

    test('milestoneFor returns rewards at 14 / 30 / 100, null otherwise', () {
      expect(PlayerStreak.milestoneFor(14), isNotNull);
      expect(PlayerStreak.milestoneFor(30), isNotNull);
      expect(PlayerStreak.milestoneFor(100), isNotNull);
      expect(PlayerStreak.milestoneFor(1), isNull);
      expect(PlayerStreak.milestoneFor(15), isNull);
      expect(PlayerStreak.milestoneFor(99), isNull);
    });

    test('weekNumber computed from currentStreak', () {
      const a = PlayerStreak(currentStreak: 1, longestStreak: 1, nextRewardIndex: 0);
      const b = PlayerStreak(currentStreak: 7, longestStreak: 7, nextRewardIndex: 6);
      const c = PlayerStreak(currentStreak: 8, longestStreak: 8, nextRewardIndex: 0);
      const d = PlayerStreak(currentStreak: 0, longestStreak: 0, nextRewardIndex: 0);
      expect(a.weekNumber, 1);
      expect(b.weekNumber, 1);
      expect(c.weekNumber, 2);
      expect(d.weekNumber, 1);
    });

    test('StreakJokerReward.canDoubleWithAd false for premium types', () {
      expect(const StreakJokerReward(JokerType.bomb, 1).canDoubleWithAd, true);
      expect(const StreakJokerReward(JokerType.megaBomb, 1).canDoubleWithAd, false);
      expect(const StreakJokerReward(JokerType.evolution, 1).canDoubleWithAd, false);
    });

    test('StreakXpReward.canDoubleWithAd is always true', () {
      expect(const StreakXpReward(15).canDoubleWithAd, true);
    });
  });
}
