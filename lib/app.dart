import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/services/notification_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/core/models/player.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/providers/streak_provider.dart';
import 'package:shape_merge/screens/splash/splash_screen.dart';
import 'package:shape_merge/screens/hub/main_hub_screen.dart';
import 'package:shape_merge/screens/game/game_screen.dart';
import 'package:shape_merge/screens/shop/shop_screen.dart';
import 'package:shape_merge/screens/leaderboard/leaderboard_screen.dart';
import 'package:shape_merge/core/widgets/ad_banner_widget.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, __, navigationShell) => AdShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (_, __) => const MainHubScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/game', builder: (_, __) => const GameScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/shop', builder: (_, __) => const ShopScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
        ]),
      ],
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
  StreamSubscription<String>? _notifSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen for notification taps and navigate to the hub.
    _notifSub = NotificationService.instance.onNotificationTap.listen((payload) {
      if (payload == 'streak_reminder') {
        _router.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
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
        // Re-check streak when user brings the app to foreground (next day scenario)
        ref.read(streakProvider.notifier).checkAndUpdate();
        ref.read(dailyChallengeProvider.notifier).checkRenewal();
        // Reschedule streak reminder in case user opened without playing
        NotificationService.instance.scheduleStreakReminder();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Migrate guest streak → Firestore on sign-in
    ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
      final prevUser = prev?.valueOrNull;
      final nextUser = next.valueOrNull;
      if (prevUser == null && nextUser != null) {
        ref.read(streakProvider.notifier).migrateAndRefresh(nextUser);
      }
    });

    // Sync gameState (bestScore, level, XP) when player data is available
    ref.listen<AsyncValue<Player?>>(playerProvider, (prev, next) {
      final player = next.valueOrNull;
      if (player == null) return;
      final gameState = ref.read(gameStateProvider);
      // Sync bestScore: also check leaderboard asynchronously
      if (player.bestScore > gameState.bestScore) {
        ref.read(gameStateProvider.notifier).loadSavedState(
          bestScore: player.bestScore,
          jokers: gameState.jokerInventory,
        );
      }
      // Also fetch leaderboard score (may be higher than Player.bestScore)
      ref.read(firestoreServiceProvider).getLeaderboardScore(player.uid).then((lbScore) {
        final best = [player.bestScore, lbScore, gameState.bestScore]
            .reduce((a, b) => a > b ? a : b);
        if (best > ref.read(gameStateProvider).bestScore) {
          ref.read(gameStateProvider.notifier).loadSavedState(
            bestScore: best,
            jokers: ref.read(gameStateProvider).jokerInventory,
          );
          // Persist everywhere
          ref.read(localStorageProvider.future).then((s) => s.setBestScore(best));
          if (best > player.bestScore) {
            ref.read(firestoreServiceProvider).updateBestScore(player.uid, best);
          }
        }
      });
    });

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
