import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shape_merge/core/constants/joker_types.dart';

/// Centralized analytics events for gameplay tracking.
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  final _analytics = FirebaseAnalytics.instance;

  Future<void> logGameStart() =>
      _analytics.logEvent(name: 'game_start');

  Future<void> logGameOver({
    required int score,
    required int maxLevel,
    required int mergeCount,
    required int shapesOnBoard,
  }) =>
      _analytics.logEvent(name: 'game_over', parameters: {
        'score': score,
        'max_level': maxLevel,
        'merge_count': mergeCount,
        'shapes_on_board': shapesOnBoard,
      });

  Future<void> logJokerUsed(JokerType type) =>
      _analytics.logEvent(name: 'joker_used', parameters: {
        'type': type.name,
      });

  Future<void> logLevelReached(int level) =>
      _analytics.logEvent(name: 'level_reached', parameters: {
        'level': level,
      });

  Future<void> logChallengeCompleted({required String challengeId}) =>
      _analytics.logEvent(name: 'challenge_completed', parameters: {
        'challenge_id': challengeId,
      });

  Future<void> logIapAttempt(String productId) =>
      _analytics.logEvent(name: 'iap_attempt', parameters: {
        'product_id': productId,
      });

  Future<void> logIapSuccess(String productId) =>
      _analytics.logEvent(name: 'iap_success', parameters: {
        'product_id': productId,
      });

  Future<void> logStreakDay(int streakCount) =>
      _analytics.logEvent(name: 'streak_day', parameters: {
        'streak_count': streakCount,
      });

  Future<void> logReviveWatched() =>
      _analytics.logEvent(name: 'revive_watched');

  Future<void> logAdWatched({required String type}) =>
      _analytics.logEvent(name: 'ad_watched', parameters: {
        'type': type,
      });

  Future<void> logSessionDuration(int seconds) =>
      _analytics.logEvent(name: 'session_duration', parameters: {
        'seconds': seconds,
      });

  Future<void> logTutorialStep(int step) =>
      _analytics.logEvent(name: 'tutorial_step', parameters: {
        'step': step,
      });

  Future<void> logTutorialCompleted() =>
      _analytics.logEvent(name: 'tutorial_completed');

  Future<void> logTutorialSkipped(int atStep) =>
      _analytics.logEvent(name: 'tutorial_skipped', parameters: {
        'at_step': atStep,
      });

  Future<void> logFirstMerge() =>
      _analytics.logEvent(name: 'first_merge');

  Future<void> logFirstJokerUsed() =>
      _analytics.logEvent(name: 'first_joker_used');

  Future<void> logStreakLost(int wasStreak) =>
      _analytics.logEvent(name: 'streak_lost', parameters: {
        'was_streak': wasStreak,
      });
}
