import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/config/app_routes.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';
import 'package:shape_merge/providers/streak_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    final storage = await LocalStorageService.create();
    if (!mounted) return;

    // Run init work concurrently with the minimum splash animation
    await Future.wait([
      _initProviders(storage),
      _precacheAssets(),
      _preloadFonts(),
      Future<void>.delayed(const Duration(milliseconds: 1500)),
    ]);
    if (!mounted) return;

    context.go(AppRoutes.home);
  }

  /// Precache hot-path images so first frames after splash don't stall on
  /// asset decoding (especially on cold-start).
  Future<void> _precacheAssets() async {
    if (!mounted) return;
    const images = [
      AssetImage('assets/images/pub.webp'),
      AssetImage('assets/images/trophy.png'),
      AssetImage('assets/images/calendar.webp'),
      AssetImage('assets/images/shop-cart.webp'),
    ];
    await Future.wait([
      for (final img in images)
        precacheImage(img, context).catchError((_) {}),
    ]);
  }

  /// Preload Google Fonts so first text render doesn't trigger a network
  /// fetch / cache miss (warms up Fredoka & Nunito families used app-wide).
  Future<void> _preloadFonts() async {
    try {
      await Future.wait([
        GoogleFonts.pendingFonts([
          GoogleFonts.fredoka(),
          GoogleFonts.nunito(),
        ]),
      ]);
    } catch (_) {/* Font fetch can fail offline — fallbacks render fine. */}
  }

  Future<void> _initProviders(LocalStorageService storage) async {
    final notifier = ref.read(gameStateProvider.notifier);
    notifier.setStorage(storage);
    notifier.setRadarHighlightNotifier(ref.read(radarHighlightProvider.notifier));
    notifier.setRadarActivationTickNotifier(ref.read(radarActivationTickProvider.notifier));
    notifier.loadSavedState(
      bestScore: storage.bestScore,
      jokers: storage.jokerInventory,
    );
    await ref.read(streakProvider.notifier).checkAndUpdate();
    await ref.read(dailyChallengeProvider.notifier).checkRenewal();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.bgTop, AppTheme.bgBot],
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.orbPink.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.orbCyan.withValues(alpha: 0.3),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: -0.05,
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: 'SHAPE ',
                            style: AppTheme.titleStyle(AppTheme.fontHuge),
                          ),
                          TextSpan(
                            text: 'MERGE\n',
                            style: AppTheme.titleStyle(AppTheme.fontHuge)
                                .copyWith(color: AppTheme.orangeTop),
                          ),
                          TextSpan(
                            text: '2048',
                            style: AppTheme.titleStyle(AppTheme.fontHuge)
                                .copyWith(color: AppTheme.orangeTop),
                          ),
                        ]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
