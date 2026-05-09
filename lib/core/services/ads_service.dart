import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/constants/ad_units.dart';

class AdsService {
  BannerAd? bannerAd;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _disposed = false;

  // Interstitial load state
  bool _loadingInterstitial = false;
  int _interstitialFailCount = 0;
  Timer? _interstitialRetryTimer;

  /// Number of game-overs since app launch. Persists across
  /// `GameScreen` re-creations (this service has app-scoped lifetime via
  /// Riverpod), so the cadence isn't reset every time the user navigates
  /// back to the home and replays.
  int _gameOverCount = 0;

  /// Returns true if an interstitial should be shown for this game-over
  /// (cadence-based). Always increments the counter — call **once** per
  /// game over.
  bool noteGameOverAndShouldShowInterstitial() {
    _gameOverCount++;
    return _gameOverCount % InterstitialTuning.showEveryNGameOvers == 0;
  }

  /// Whether an interstitial is currently loaded and ready to display.
  bool get isInterstitialReady => _interstitialAd != null;

  String get _bannerAdUnitId => AdUnits.banner;

  String get _rewardedAdUnitId => AdUnits.rewarded;

  String get _interstitialAdUnitId => AdUnits.interstitial;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    loadRewardedAd();
    loadInterstitialAd();
  }

  void loadBannerAd({required void Function(BannerAd) onLoaded}) {
    bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(ad as BannerAd),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  bool _loadingRewarded = false;

  void loadRewardedAd() {
    if (_rewardedAd != null || _loadingRewarded) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loadingRewarded = false;
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
          _loadingRewarded = false;
        },
      ),
    );
  }

  Future<bool> showRewardedAd({
    required void Function() onRewarded,
  }) async {
    if (_rewardedAd == null) return false;

    var rewarded = false;
    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        completer.complete(false);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) {
        rewarded = true;
        onRewarded();
      },
    );

    return completer.future;
  }

  void loadInterstitialAd() {
    if (_disposed) return;
    if (_interstitialAd != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    _interstitialRetryTimer?.cancel();
    if (kDebugMode) {
      debugPrint('[AdsService] interstitial load start (unit=$_interstitialAdUnitId)');
    }
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _loadingInterstitial = false;
          _interstitialFailCount = 0;
          if (kDebugMode) debugPrint('[AdsService] interstitial loaded ✓');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _loadingInterstitial = false;
          _interstitialFailCount++;
          debugPrint('[AdsService] interstitial load failed: $error '
              '(attempt $_interstitialFailCount)');
          // Exponential backoff: 15s, 30s, 60s, 120s, capped at 5 min.
          final delaySec =
              (15 * (1 << math.min(_interstitialFailCount - 1, 5))).clamp(15, 300);
          _interstitialRetryTimer =
              Timer(Duration(seconds: delaySec), loadInterstitialAd);
        },
      ),
    );
  }

  void showInterstitialAd({required VoidCallback onDismissed}) {
    if (_interstitialAd == null) {
      // Ad not ready — make sure a load is in flight for next time.
      debugPrint('[AdsService] showInterstitialAd skipped: not ready '
          '(loading=$_loadingInterstitial, failCount=$_interstitialFailCount)');
      loadInterstitialAd();
      onDismissed();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDismissed();
      },
    );
    _interstitialAd!.show();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = null;
    bannerAd?.dispose();
    bannerAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
