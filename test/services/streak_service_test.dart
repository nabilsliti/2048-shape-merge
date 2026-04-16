import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/models/player_streak.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shape_merge/core/services/streak_service.dart';

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

    test('rewardForIndex cycles through 7 rewards with scaling', () {
      final rewards = List.generate(7, PlayerStreak.rewardForIndex);
      expect(rewards.length, 7);
      // Week 1 day 1: bomb ×1
      final (type0, amount0) = PlayerStreak.rewardForIndex(0);
      // Week 2 day 1: same type, ×2
      final (type7, amount7) = PlayerStreak.rewardForIndex(7);
      expect(type0, type7); // same joker type in the cycle
      expect(amount7, amount0 * 2); // week 2 scales ×2
    });
  });
}
