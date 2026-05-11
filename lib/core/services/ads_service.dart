import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/constants/ad_units.dart';
import 'package:shape_merge/core/services/analytics_service.dart';

class AdsService {
  BannerAd? bannerAd;

  /// Banner pre-warmed at app launch so the first impression renders
  /// without a visible empty slot. Consumed once by [AdBannerWidget]
  /// via [takePreloadedBanner].
  BannerAd? _preloadedBanner;
  bool _preloadingBanner = false;

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
    unawaited(_preloadBanner());
  }

  /// Returns the pre-warmed banner (if any) and clears the internal slot,
  /// transferring ownership to the caller. Caller is responsible for
  /// disposing the returned ad.
  BannerAd? takePreloadedBanner() {
    final ad = _preloadedBanner;
    _preloadedBanner = null;
    return ad;
  }

  Future<void> _preloadBanner() async {
    if (_disposed || _preloadingBanner || _preloadedBanner != null) return;
    _preloadingBanner = true;

    // Resolve adaptive size using the platform window so we don't depend
    // on a BuildContext (this runs at app launch).
    final view = WidgetsBinding.instance.platformDispatcher.views.isEmpty
        ? null
        : WidgetsBinding.instance.platformDispatcher.views.first;
    final widthPx = view == null
        ? 360
        : (view.physicalSize.width / view.devicePixelRatio).truncate();
    AdSize size;
    try {
      // NOTE: google_mobile_ads 8 deprecates this in favour of
      // `getLargeAnchoredAdaptiveBannerAdSizeWithOrientation`, but "Large"
      // returns 90-180px banners — our slot is 60px, switching would clip the
      // ad. Keep the (still-functional) regular adaptive size instead.
      // ignore: deprecated_member_use
      size = await AdSize.getAnchoredAdaptiveBannerAdSize(
            Orientation.portrait,
            widthPx,
          ) ??
          AdSize.banner;
    } catch (_) {
      size = AdSize.banner;
    }
    if (_disposed) {
      _preloadingBanner = false;
      return;
    }

    final ad = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (_disposed) {
            loaded.dispose();
            return;
          }
          _preloadedBanner = loaded as BannerAd;
          _preloadingBanner = false;
          if (kDebugMode) debugPrint('[AdsService] banner pre-warmed ✓');
        },
        onAdFailedToLoad: (loaded, error) {
          loaded.dispose();
          _preloadedBanner = null;
          _preloadingBanner = false;
          if (kDebugMode) {
            debugPrint('[AdsService] banner pre-warm failed: $error');
          }
        },
      ),
    );
    await ad.load();
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
        unawaited(AnalyticsService.instance
            .logAdFailed(type: 'rewarded', error: error.message));
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        completer.complete(false);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) {
        rewarded = true;
        unawaited(AnalyticsService.instance.logAdRewarded(placement: 'rewarded'));
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
      onAdFailedToShowFullScreenContent: (ad, err) {
        unawaited(AnalyticsService.instance
            .logAdFailed(type: 'interstitial', error: err.message));
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDismissed();
      },
    );
    unawaited(AnalyticsService.instance.logAdInterstitialShown());
    _interstitialAd!.show();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = null;
    bannerAd?.dispose();
    bannerAd = null;
    _preloadedBanner?.dispose();
    _preloadedBanner = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
