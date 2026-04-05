import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logGameStart() =>
      _analytics.logEvent(name: 'game_start');

  Future<void> logGameOver({required int score, required int merges}) =>
      _analytics.logEvent(
        name: 'game_over',
        parameters: {'score': score, 'merges': merges},
      );

  Future<void> logMerge({required int level}) =>
      _analytics.logEvent(
        name: 'merge',
        parameters: {'level': level},
      );

  Future<void> logJokerUsed({required String jokerType}) =>
      _analytics.logEvent(
        name: 'joker_used',
        parameters: {'type': jokerType},
      );

  Future<void> logPurchase({required String productId}) =>
      _analytics.logEvent(
        name: 'iap_purchase',
        parameters: {'product_id': productId},
      );
}
