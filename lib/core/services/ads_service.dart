import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shape_merge/core/constants/ad_units.dart';

class AdsService {
  BannerAd? bannerAd;
  RewardedAd? _rewardedAd;
  bool _disposed = false;

  String get _bannerAdUnitId => AdUnits.banner;

  String get _rewardedAdUnitId => AdUnits.rewarded;

  Future<void> init() async {
    await MobileAds.instance.initialize();
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

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
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

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    bannerAd?.dispose();
    bannerAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
