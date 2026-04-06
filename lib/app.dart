import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class ShapeMergeApp extends ConsumerWidget {
  const ShapeMergeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
