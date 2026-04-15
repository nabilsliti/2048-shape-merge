import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shape_merge/core/constants/ad_units.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/offline_banner.dart';
import 'package:shape_merge/providers/iap_provider.dart';
import 'package:vibration/vibration.dart';

/// Persistent shell that keeps a single [AdBannerWidget] alive across routes.
class AdShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AdShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isGameScreen = GoRouterState.of(context).uri.path == '/home/game';
    return Stack(
      children: [
        Column(
          children: [
            Expanded(child: navigationShell),
            if (!isGameScreen) _BottomNavBar(navigationShell: navigationShell),
            const AdBannerWidget(),
            SizedBox(height: bottomPadding),
          ],
        ),
        if (!isGameScreen) const OfflineIndicator(),
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _BottomNavBar({required this.navigationShell});

  static const _navBarHeight = 70.0;

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Container(
      height: _navBarHeight,
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: AppTheme.navBarBg,
        border: const Border(top: BorderSide(color: AppTheme.navBarBorder, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            offset: const Offset(0, -5),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            index: 0, currentIndex: currentIndex,
            imagePath: 'assets/images/shop.webp',
            onTap: () => _goBranch(0),
          ),
          _NavItem(
            index: 1, currentIndex: currentIndex,
            imagePath: 'assets/images/podium.webp',
            onTap: () => _goBranch(1),
          ),
          _NavItem(
            index: 2, currentIndex: currentIndex,
            imagePath: 'assets/images/play.webp',
            onTap: () => _goBranch(2),
          ),
          _NavItem(
            index: 3, currentIndex: currentIndex,
            imagePath: 'assets/images/profil.webp',
            onTap: () => _goBranch(3),
          ),
          _NavItem(
            index: 4, currentIndex: currentIndex,
            imagePath: 'assets/images/settings.webp',
            onTap: () => _goBranch(4),
          ),
        ],
      ),
    );
  }

  void _goBranch(int index) {
    AudioService.instance.playButtonTap();
    if (Button3D.vibrationEnabled) Vibration.vibrate(duration: 30);
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.imagePath,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final String imagePath;
  final VoidCallback onTap;

  static const _activeCircleColor = AppTheme.navActiveCircle;
  static const _activeShadowColor = AppTheme.navActiveShadow;

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (!isActive)
              Image.asset(
                imagePath,
                width: 58,
                height: 58,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                opacity: const AlwaysStoppedAnimation(0.7),
              ),
            if (isActive)
              Positioned(
                top: -28,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _activeCircleColor,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      const BoxShadow(color: _activeShadowColor, offset: Offset(0, 6)),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
  bool _isLoading = false;

  static String get _adUnitId => AdUnits.banner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !_isLoading) _loadAd();
  }

  void _loadAd() async {
    _isLoading = true;
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
          _isLoading = false;
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
