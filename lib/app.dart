import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/screens/splash/splash_screen.dart';
import 'package:shape_merge/screens/hub/main_hub_screen.dart';
import 'package:shape_merge/screens/game/game_screen.dart';
import 'package:shape_merge/screens/shop/shop_screen.dart';
import 'package:shape_merge/screens/leaderboard/leaderboard_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const MainHubScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (_, __) => const GameScreen(),
    ),
    GoRoute(
      path: '/shop',
      builder: (_, __) => const ShopScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (_, __) => const LeaderboardScreen(),
    ),
  ],
);

class ShapeMergeApp extends ConsumerStatefulWidget {
  const ShapeMergeApp({super.key});

  @override
  ConsumerState<ShapeMergeApp> createState() => _ShapeMergeAppState();
}

class _ShapeMergeAppState extends ConsumerState<ShapeMergeApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        AudioService.instance.pauseMusic();
      case AppLifecycleState.resumed:
        AudioService.instance.resumeMusic();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Shape Merge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
