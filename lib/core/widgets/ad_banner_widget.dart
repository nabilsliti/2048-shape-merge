import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shape_merge/core/constants/ad_units.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/providers/iap_provider.dart';

/// Persistent shell that keeps a single [AdBannerWidget] alive across routes.
class AdShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AdShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        Expanded(child: navigationShell),
        const AdBannerWidget(),
        SizedBox(height: bottomPadding),
      ],
    );
  }
}

class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  static String get _adUnitId => AdUnits.banner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) _loadAd();
  }

  void _loadAd() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final adSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      width,
    ) ?? AdSize.banner;

    if (!mounted) return;

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          const AppLogger('Ads').warning('Banner ad failed to load: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noAds = ref.watch(noAdsPurchasedProvider);
    if (noAds) return const SizedBox.shrink();
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
