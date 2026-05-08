import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shape_merge/core/constants/ad_units.dart';

class AdsService {
  BannerAd? bannerAd;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _disposed = false;

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
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  void showInterstitialAd({required VoidCallback onDismissed}) {
    if (_interstitialAd == null) {
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
    bannerAd?.dispose();
    bannerAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
