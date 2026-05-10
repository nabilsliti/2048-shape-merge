import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/services/app_logger.dart';

/// Centralized analytics & user-properties layer for gameplay, monetisation,
/// retention and funnel tracking. All events are mirrored to Crashlytics
/// breadcrumbs (so a crash report shows the player's last 64 actions) and to
/// the in-app logger (visible in `flutter logs` / Firebase DebugView when
/// `adb shell setprop debug.firebase.analytics.app <package>` is set).
///
/// Conventions:
/// * Event names: snake_case, ≤ 40 chars, ≤ 25 params (Firebase limits).
/// * Param values: bool → 0/1, double for currency, int for counts.
/// * User properties: max 25, name ≤ 24 chars, value ≤ 36 chars.
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  static const _log = AppLogger('Analytics');
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  FirebaseAnalytics get firebaseAnalytics => _analytics;

  // ─────────────────────────────────────────────────────────
  //  Internal helpers
  // ─────────────────────────────────────────────────────────

  Future<void> _send(
    String event, [
    Map<String, Object> params = const {},
  ]) async {
    try {
      await _analytics.logEvent(name: event, parameters: params);
      _crashlytics.log('analytics:$event ${params.isEmpty ? '' : params}');
      if (kDebugMode) {
        // Easy to grep in `flutter logs`:  "📊 analytics → game_start ..."
        _log.debug('📊 $event ${params.isEmpty ? '' : params}');
      }
    } catch (e, st) {
      _log.warning('logEvent($event) failed', error: e, stack: st);
    }
  }

  Future<void> _setProp(String name, String? value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) _log.debug('📊 user_property → $name=$value');
    } catch (e) {
      _log.warning('setUserProperty($name) failed', error: e);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Identity & user properties (segmentation in Firebase UI)
  // ─────────────────────────────────────────────────────────

  /// Bind the current user across Analytics + Crashlytics.
  Future<void> setUserId(String? uid) async {
    await _analytics.setUserId(id: uid);
    if (uid != null) await _crashlytics.setUserIdentifier(uid);
    if (kDebugMode) _log.debug('📊 user_id=$uid');
  }

  Future<void> setAuthState(User? user) async {
    await setUserId(user?.uid);
    await _setProp('auth_state', user == null ? 'guest' : 'signed_in');
    await _setProp('email_verified', user?.emailVerified == true ? '1' : '0');
  }

  Future<void> setBestScore(int score) =>
      _setProp('best_score', score.toString());

  Future<void> setPlayerLevel(int level) async {
    await _setProp('player_level', level.toString());
    // Native event so Firebase populates the "Level" report automatically.
    await _send('level_up', {'level': level});
  }

  Future<void> setPremiumStatus({required bool noAds, required bool emojiPack}) async {
    await _setProp('no_ads', noAds ? '1' : '0');
    await _setProp('emoji_pack', emojiPack ? '1' : '0');
    await _setProp(
      'premium_tier',
      noAds && emojiPack ? 'full' : noAds ? 'no_ads' : emojiPack ? 'emoji' : 'free',
    );
  }

  Future<void> setJokersInventory(JokerInventory inv) async {
    final total = JokerType.values
        .fold<int>(0, (sum, t) => sum + inv.countOf(t));
    await _setProp('jokers_total', total.toString());
    await _setProp('jokers_bomb', '${inv.countOf(JokerType.bomb)}');
    await _setProp('jokers_radar', '${inv.countOf(JokerType.radar)}');
  }

  Future<void> setStreakDays(int days) =>
      _setProp('streak_days', days.toString());

  // ─────────────────────────────────────────────────────────
  //  Funnel: navigation (called by FirebaseAnalyticsObserver in GoRouter)
  // ─────────────────────────────────────────────────────────

  Future<void> logScreenView(String screenName) => _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );

  // ─────────────────────────────────────────────────────────
  //  App lifecycle & sessions
  // ─────────────────────────────────────────────────────────

  Future<void> logAppOpen() => _send('app_open_custom');

  Future<void> logSessionDuration(int seconds) =>
      _send('session_duration', {'seconds': seconds});

  // ─────────────────────────────────────────────────────────
  //  Onboarding & tutorial funnel
  // ─────────────────────────────────────────────────────────

  Future<void> logTutorialBegin() async {
    await _analytics.logTutorialBegin();
    await _send('tutorial_begin');
  }

  Future<void> logTutorialStep(int step) =>
      _send('tutorial_step', {'step': step});

  Future<void> logTutorialCompleted() async {
    await _analytics.logTutorialComplete();
    await _send('tutorial_complete');
  }

  Future<void> logTutorialSkipped(int atStep) =>
      _send('tutorial_skipped', {'at_step': atStep});

  Future<void> logFirstMerge() => _send('first_merge');

  Future<void> logFirstJokerUsed() => _send('first_joker_used');

  // ─────────────────────────────────────────────────────────
  //  Gameplay
  // ─────────────────────────────────────────────────────────

  Future<void> logGameStart() => _send('game_start');

  Future<void> logGameOver({
    required int score,
    required int maxLevel,
    required int mergeCount,
    required int shapesOnBoard,
    int? durationSec,
  }) =>
      _send('game_over', {
        'score': score,
        'max_level': maxLevel,
        'merge_count': mergeCount,
        'shapes_on_board': shapesOnBoard,
        if (durationSec != null) 'duration_sec': durationSec,
      });

  Future<void> logJokerUsed(JokerType type) =>
      _send('joker_used', {'type': type.name});

  Future<void> logLevelReached(int level) =>
      _send('level_reached', {'level': level});

  Future<void> logHighScoreBeaten({required int oldScore, required int newScore}) =>
      _send('new_high_score', {'old': oldScore, 'new': newScore});

  // ─────────────────────────────────────────────────────────
  //  Retention: streaks & daily challenges
  // ─────────────────────────────────────────────────────────

  Future<void> logStreakDay(int streakCount) =>
      _send('streak_day', {'streak_count': streakCount});

  Future<void> logStreakLost(int wasStreak) =>
      _send('streak_lost', {'was_streak': wasStreak});

  Future<void> logStreakRewardClaimed({required int day, required bool doubled}) =>
      _send('streak_reward_claimed', {'day': day, 'doubled': doubled ? 1 : 0});

  Future<void> logChallengeStarted(String challengeId) =>
      _send('challenge_started', {'challenge_id': challengeId});

  Future<void> logChallengeCompleted({required String challengeId}) =>
      _send('challenge_completed', {'challenge_id': challengeId});

  // ─────────────────────────────────────────────────────────
  //  Monetisation: ads
  // ─────────────────────────────────────────────────────────

  Future<void> logAdImpression({required String type, String? placement}) => _send(
        'ad_impression_custom',
        {'type': type, if (placement != null) 'placement': placement},
      );

  Future<void> logAdRewarded({required String placement}) =>
      _send('ad_rewarded', {'placement': placement});

  Future<void> logAdInterstitialShown({String? placement}) => _send(
        'ad_interstitial_shown',
        {if (placement != null) 'placement': placement},
      );

  Future<void> logAdFailed({required String type, required String error}) =>
      _send('ad_failed', {'type': type, 'error': error});

  Future<void> logReviveWatched() => _send('revive_watched');

  // ─────────────────────────────────────────────────────────
  //  Monetisation: IAP (Firebase standard purchase event = revenue report)
  // ─────────────────────────────────────────────────────────

  Future<void> logIapAttempt(String productId) =>
      _send('iap_attempt', {'product_id': productId});

  Future<void> logIapCanceled(String productId) =>
      _send('iap_canceled', {'product_id': productId});

  Future<void> logIapError(String productId, String error) =>
      _send('iap_error', {'product_id': productId, 'error': error});

  /// Standard Firebase `purchase` event — appears in the **Monetisation report**
  /// with revenue. Use the `ProductDetails` from the store so currency and
  /// price come straight from Google/Apple, not the fallback string.
  Future<void> logIapSuccess({
    required String productId,
    ProductDetails? details,
    bool serverVerified = true,
  }) async {
    final priceMicros = _extractPriceMicros(details);
    final value = priceMicros != null ? priceMicros / 1000000.0 : 0.0;
    final currency = details?.currencyCode ?? 'EUR';

    // Firebase native "purchase" — feeds the revenue report.
    try {
      await _analytics.logPurchase(
        currency: currency,
        value: value,
        transactionId: productId,
        items: [
          AnalyticsEventItem(
            itemId: productId,
            itemName: details?.title ?? productId,
            itemCategory: 'iap_pack',
            price: value,
            currency: currency,
            quantity: 1,
          ),
        ],
      );
    } catch (e) {
      _log.warning('logPurchase failed', error: e);
    }

    // Custom mirror for funnel exploration.
    await _send('iap_success', {
      'product_id': productId,
      'value': value,
      'currency': currency,
      'server_verified': serverVerified ? 1 : 0,
    });
  }

  int? _extractPriceMicros(ProductDetails? details) {
    if (details == null) return null;
    // Both Google Play and App Store implementations expose `rawPrice` in
    // current plugin versions; fall back to parsing the formatted string.
    try {
      final dynamic d = details;
      final raw = d.rawPrice;
      if (raw is num) return (raw * 1000000).round();
    } catch (_) {/* fall through */}
    final parsed = double.tryParse(
      details.price.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.'),
    );
    return parsed != null ? (parsed * 1000000).round() : null;
  }

  // ─────────────────────────────────────────────────────────
  //  Misc UX events (helpful for product analysis)
  // ─────────────────────────────────────────────────────────

  Future<void> logShareScore(int score) =>
      _analytics.logShare(contentType: 'score', itemId: 'score_$score', method: 'system');

  Future<void> logSettingsChanged(String key, Object value) =>
      _send('settings_changed', {'key': key, 'value': value.toString()});

  Future<void> logShopOpened({required String source}) =>
      _send('shop_opened', {'source': source});

  Future<void> logPackViewed(String productId) =>
      _send('pack_viewed', {'product_id': productId});
}
