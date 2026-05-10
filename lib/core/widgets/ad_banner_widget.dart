import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shape_merge/core/constants/ad_units.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/offline_banner.dart';
import 'package:shape_merge/providers/ads_provider.dart';
import 'package:shape_merge/providers/iap_provider.dart';
import 'package:shape_merge/providers/nav_provider.dart';
import 'package:vibration/vibration.dart';

const _log = AppLogger('Ads');

// ═══════════════════════════════════════════════════════════════
// Banner refresh strategy constants
// ═══════════════════════════════════════════════════════════════
abstract final class _BannerTuning {
  /// Minimum time between two manual reloads (navigation, resume, etc.)
  /// 45s gives a safe margin above AdMob's 30s minimum while allowing
  /// enough reloads on high-value user actions (tab switch, game exit).
  static const cooldown = Duration(seconds: 45);

  /// Initial delay before retrying after a load failure.
  static const retryDelayInitial = Duration(seconds: 15);

  /// Cap on the exponential backoff between retries.
  static const retryDelayMax = Duration(minutes: 5);

  /// Banner slot height in logical pixels.
  static const slotHeight = 60.0;
}

/// Persistent shell that keeps a single [AdBannerWidget] alive across routes.
/// Detects tab navigation and notifies the banner to reload.
class AdShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AdShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AdShell> createState() => _AdShellState();
}

class _AdShellState extends ConsumerState<AdShell> {
  final _bannerKey = GlobalKey<_AdBannerWidgetState>();
  int _previousIndex = -1;
  bool _wasGameScreen = false;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final currentIndex = widget.navigationShell.currentIndex;
    final isGameScreen = GoRouterState.of(context).uri.path == '/home/game';

    // Publish current branch index so tab content can pause animations when
    // not visible (saves CPU/battery). See `currentBranchIndexProvider`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(currentBranchIndexProvider.notifier).state = currentIndex;
    });

    // Detect tab change → request banner reload
    if (_previousIndex != -1 && _previousIndex != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bannerKey.currentState?.onNavigationChanged();
      });
    }
    _previousIndex = currentIndex;

    // Detect game exit → force-reload the banner (high-value moment)
    if (_wasGameScreen && !isGameScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bannerKey.currentState?.onGameExited();
      });
    }
    _wasGameScreen = isGameScreen;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(child: widget.navigationShell),
            if (!isGameScreen) _BottomNavBar(navigationShell: widget.navigationShell),
            AdBannerWidget(key: _bannerKey),
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

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget>
    with WidgetsBindingObserver {
  /// Currently displayed banner. Stays mounted until [_pendingBanner]
  /// finishes loading, so the slot is never visually empty during a
  /// navigation-triggered refresh.
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  /// Banner being loaded in background. Swapped into [_bannerAd] once
  /// the [BannerAdListener] confirms a successful load.
  BannerAd? _pendingBanner;
  bool _isLoading = false;

  /// Tracks the last successful (or attempted) load time for cooldown.
  DateTime _lastLoadTime = DateTime(2000);

  /// Consecutive failures since last successful load.
  int _failCount = 0;

  /// One-shot timer for retry after failure.
  Timer? _retryTimer;

  /// Cached ad size so we don't re-query on every reload.
  AdSize? _cachedAdSize;

  static String get _adUnitId => AdUnits.banner;

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always pre-load the ad, even for no-ads users, so it's ready
    // instantly on sign-out. AdMob only counts impressions when displayed.
    if (_bannerAd == null && !_isLoading) _loadAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadIfCooldownPassed();
    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _teardown();
    super.dispose();
  }

  // ── Public API (called by AdShell) ─────────────────────────

  /// Called by [_AdShellState] when the user switches bottom-nav tab.
  void onNavigationChanged() {
    _reloadIfCooldownPassed();
  }

  /// Called when returning from the game screen.
  void onGameExited() {
    // Force-reload immediately (cooldown = 0) because the user just
    // finished a session — high engagement moment, fresh ad is valuable.
    _reload();
  }

  // ── Core load/reload ──────────────────────────────────────

  void _reloadIfCooldownPassed() {
    if (ref.read(noAdsPurchasedProvider)) return;
    final elapsed = DateTime.now().difference(_lastLoadTime);
    if (elapsed >= _BannerTuning.cooldown) {
      _reload();
    } else {
      _log.info(
        'Banner reload skipped — ${elapsed.inSeconds}s < '
        '${_BannerTuning.cooldown.inSeconds}s cooldown',
      );
    }
  }

  void _reload() {
    _cancelTimers();
    // Graceful swap: keep the current banner on screen while the new one
    // loads in the background. The displayed banner is only replaced once
    // [_pendingBanner] reports onAdLoaded.
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (_isLoading) return;

    // Try to consume the banner pre-warmed at app startup. This avoids
    // showing an empty slot on first render.
    final preloaded = ref.read(adsServiceProvider).takePreloadedBanner();
    if (preloaded != null) {
      _cachedAdSize ??= preloaded.size;
      _lastLoadTime = DateTime.now();
      _swapInNewBanner(preloaded);
      return;
    }

    _isLoading = true;
    _lastLoadTime = DateTime.now();

    // Resolve ad size once, cache for subsequent reloads.
    _cachedAdSize ??= await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      MediaQuery.of(context).size.width.truncate(),
    ) ?? AdSize.banner;

    if (!mounted) return;

    _pendingBanner = BannerAd(
      adUnitId: _adUnitId,
      size: _cachedAdSize!,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => _swapInNewBanner(ad as BannerAd),
        onAdFailedToLoad: (ad, error) => _onAdFailed(ad, error),
      ),
    )..load();
  }

  /// Atomically replace the visible banner with [newBanner]. The old one
  /// is disposed only after the new one is in place, so the slot never
  /// flashes empty between two refreshes.
  void _swapInNewBanner(BannerAd newBanner) {
    if (!mounted) {
      newBanner.dispose();
      return;
    }
    final old = _bannerAd;
    _bannerAd = newBanner;
    _pendingBanner = null;
    _isLoading = false;
    _failCount = 0;
    setState(() => _isLoaded = true);
    old?.dispose();
    _log.info('Banner loaded (swapped)');
  }

  void _onAdFailed(Ad ad, LoadAdError error) {
    ad.dispose();
    _pendingBanner = null;
    _isLoading = false;
    _failCount++;
    _log.warning('Banner failed (attempt $_failCount): $error');

    // Exponential backoff capped at retryDelayMax. Retry indefinitely so the
    // banner slot is eventually filled even if early loads fail.
    final backoffSeconds = (_BannerTuning.retryDelayInitial.inSeconds *
            (1 << (_failCount - 1).clamp(0, 5)))
        .clamp(
      _BannerTuning.retryDelayInitial.inSeconds,
      _BannerTuning.retryDelayMax.inSeconds,
    );
    _retryTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (mounted) _loadAd();
    });
  }

  // ── Cleanup helpers ───────────────────────────────────────

  void _cancelTimers() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Dispose both displayed and pending BannerAd instances.
  void _disposeBannerOnly() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _pendingBanner?.dispose();
    _pendingBanner = null;
    _isLoaded = false;
    _isLoading = false;
  }

  /// Full teardown: ad + timers.
  void _teardown() {
    _cancelTimers();
    _disposeBannerOnly();
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final noAds = ref.watch(noAdsPurchasedProvider);
    if (noAds) return const SizedBox.shrink();

    // Always reserve the banner slot so layout never jumps. While the ad is
    // (re)loading, paint the slot with the nav-bar background colour so the
    // empty placeholder visually blends with the navigation bar above
    // instead of looking like a broken black void.
    final hasAd = _isLoaded && _bannerAd != null;
    return Container(
      width: double.infinity,
      height: _BannerTuning.slotHeight,
      color: AppTheme.navBarBg,
      alignment: Alignment.center,
      child: hasAd ? AdWidget(ad: _bannerAd!) : const SizedBox.shrink(),
    );
  }
}
