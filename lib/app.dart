import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/config/app_routes.dart';
import 'package:shape_merge/core/constants/shape_pack.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shape_merge/core/services/notification_service.dart';
import 'package:shape_merge/core/widgets/account_sync_overlay.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/core/models/player.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/iap_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/providers/progression_provider.dart';
import 'package:shape_merge/providers/shape_pack_provider.dart';
import 'package:shape_merge/providers/streak_provider.dart';
import 'package:shape_merge/providers/account_sync_provider.dart';
import 'package:shape_merge/screens/splash/splash_screen.dart';
import 'package:shape_merge/screens/hub/main_hub_screen.dart';
import 'package:shape_merge/screens/game/game_screen.dart';
import 'package:shape_merge/screens/shop/shop_screen.dart';
import 'package:shape_merge/screens/leaderboard/leaderboard_screen.dart';
import 'package:shape_merge/screens/profile/profile_screen.dart';
import 'package:shape_merge/screens/settings/settings_screen.dart';
import 'package:shape_merge/core/widgets/ad_banner_widget.dart';

const _log = AppLogger('App');

final _router = GoRouter(
  initialLocation: AppRoutes.splash,
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(AppLocalizations.of(context)!.pageNotFound(state.uri.toString())),
    ),
  ),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (_, state) => NoTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
      ),
    ),
    StatefulShellRoute.indexedStack(
      pageBuilder: (_, state, navigationShell) => NoTransitionPage(
        key: state.pageKey,
        child: AdShell(navigationShell: navigationShell),
      ),
      branches: [
        // Index 0 — Shop
        StatefulShellBranch(routes: [
          GoRoute(path: AppRoutes.shop, builder: (_, __) => const ShopScreen()),
        ]),
        // Index 1 — Leaderboard
        StatefulShellBranch(routes: [
          GoRoute(path: AppRoutes.leaderboard, builder: (_, __) => const LeaderboardScreen()),
        ]),
        // Index 2 — Home (center)
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const MainHubScreen(),
            routes: [
              GoRoute(path: 'game', builder: (_, __) => const GameScreen()),
            ],
          ),
        ]),
        // Index 3 — Profile
        StatefulShellBranch(routes: [
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
        ]),
        // Index 4 — Settings
        StatefulShellBranch(routes: [
          GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Boot the local-notifications plugin, ask for permission on Android 13+/iOS,
    // then schedule the streak-reminder so users who don't open a game today
    // still get pinged tomorrow.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.init();
      await NotificationService.instance.requestPermission();
      if (!mounted) return;
      await _rescheduleStreakReminder();
    });
  }

  Future<void> _rescheduleStreakReminder() async {
    if (!mounted) return;
    final streakDays = ref.read(streakProvider)?.streak.currentStreak ?? 0;
    await NotificationService.instance.scheduleStreakReminder(
      l10n: AppLocalizations.of(context),
      streakDays: streakDays,
    );
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
        break;
      case AppLifecycleState.resumed:
        // Re-check streak when user brings the app to foreground (next day scenario)
        ref.read(streakProvider.notifier).checkAndUpdate();
        ref.read(dailyChallengeProvider.notifier).checkRenewal();
        // Re-arm the streak reminder for the next 23 h.
        unawaited(_rescheduleStreakReminder());
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle sign-in / sign-out / account-switch
    ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
      final prevUser = prev?.valueOrNull;
      final nextUser = next.valueOrNull;

      final isSameUser = prevUser?.uid == nextUser?.uid;
      if (isSameUser) return;

      final notifier = ref.read(gameStateProvider.notifier);

      // Always reset account-scoped providers on any change (sign-in, sign-out,
      // or direct switch). This prevents race conditions when Google fires
      // A→null then null→B as two separate events.
      ref.invalidate(playerProvider);
      ref.invalidate(streakProvider);
      ref.read(dailyChallengeProvider.notifier).reset();
      ref.invalidate(progressionProvider);

      // ── Entering an account ──
      if (nextUser != null) {
        notifier.setSignedIn(nextUser.uid, ref.read(firestoreServiceProvider));
        ref.read(streakProvider.notifier).migrateAndRefresh(nextUser);
        // Show full-screen sync spinner so the user doesn't see jokers /
        // best-score "jump" while we replay purchases and merge guest data.
        ref.read(accountSyncProvider.notifier).state = true;
        // Load the new account's data from Firestore, merge guest jokers
        // (max per type) so locally-purchased jokers are never lost,
        // then clear localStorage.
        ref.read(playerProvider.future).then((player) async {
          final storage = await ref.read(localStorageProvider.future);
          final fs = ref.read(firestoreServiceProvider);
          final uid = nextUser.uid;

          // ── Replay pending guest purchases via CF ──
          final pending = storage.pendingPurchases;
          if (pending.isNotEmpty) {
            for (final p in pending) {
              try {
                final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
                    .httpsCallable('verifyPurchase');
                final result = await callable.call<Map<String, dynamic>>({
                  'productId': p['productId'],
                  'purchaseToken': p['purchaseToken'],
                  'platform': p['platform'],
                });
                final status = result.data['status'] as String?;
                _log.info('Replayed pending purchase ${p['productId']}: $status');
              } catch (e) {
                _log.warning('Failed to replay pending purchase ${p['productId']}: $e');
              }
            }
            await storage.clearPendingPurchases();
          }

          // ── After replaying purchases, reload player to get updated jokers ──
          final freshPlayer = pending.isNotEmpty
              ? await fs.getPlayer(uid)
              : player;

          // Jokers: server is source of truth (purchases verified via CF)
          final serverJokers = freshPlayer?.jokerInventory ?? const JokerInventory.initial();

          // Merge scalar fields: max(local, server) so no progression is lost
          final mergedBestScore = math.max(storage.bestScore, freshPlayer?.bestScore ?? 0);
          final mergedLevel = math.max(storage.playerLevel, freshPlayer?.level ?? 1);
          final mergedCurrentXP = math.max(storage.currentXP, freshPlayer?.currentXP ?? 0);
          final mergedTotalXP = math.max(storage.totalXP, freshPlayer?.totalXP ?? 0);
          final mergedGamesPlayed = math.max(storage.gamesPlayed, freshPlayer?.gamesPlayed ?? 0);
          final mergedTotalMerges = math.max(storage.totalMerges, freshPlayer?.totalMerges ?? 0);

          notifier.loadSavedState(
            bestScore: mergedBestScore,
            jokers: serverJokers,
          );

          // Sync noAdsPurchased from Firestore immediately
          final isNoAds = freshPlayer?.noAdsPurchased ?? false;
          ref.read(noAdsPurchasedProvider.notifier).state = isNoAds;
          ref.read(iapServiceProvider).noAdsPurchased = isNoAds;

          // Sync emojiPackPurchased from Firestore immediately
          final isEmojiPack = freshPlayer?.emojiPackPurchased ?? false;
          ref.read(emojiPackPurchasedProvider.notifier).state = isEmojiPack;
          ref.read(iapServiceProvider).emojiPackPurchased = isEmojiPack;

          // Persist merged scalar fields to Firestore if anything changed
          if (mergedBestScore > (freshPlayer?.bestScore ?? 0)) {
            fs.updateBestScore(uid, mergedBestScore);
          }
          if (mergedLevel > (freshPlayer?.level ?? 1) ||
              mergedTotalXP > (freshPlayer?.totalXP ?? 0)) {
            fs.updateXP(uid,
              level: mergedLevel,
              currentXP: mergedCurrentXP,
              totalXP: mergedTotalXP,
            );
          }
          if (mergedGamesPlayed > (freshPlayer?.gamesPlayed ?? 0) ||
              mergedTotalMerges > (freshPlayer?.totalMerges ?? 0)) {
            await fs.savePlayer(
              (freshPlayer ?? Player(uid: uid, displayName: 'Guest')).copyWith(
                gamesPlayed: mergedGamesPlayed,
                totalMerges: mergedTotalMerges,
              ),
            );
          }

          await _resetLocalToDefaults(storage);
        }).whenComplete(() {
          ref.read(accountSyncProvider.notifier).state = false;
        });
        // Reload daily challenges for the new account
        ref.read(dailyChallengeProvider.notifier).checkRenewal();
      } else {
        // ── Going to guest mode — localStorage was already reset at sign-in
        // (_resetLocalToDefaults), so just load fresh defaults.
        notifier.clearSignedIn();
        notifier.loadSavedState(
          bestScore: 0,
          jokers: const JokerInventory.initial(),
        );
        // Reset no-ads state: guest profile is blank
        ref.read(noAdsPurchasedProvider.notifier).state = false;
        ref.read(iapServiceProvider).noAdsPurchased = false;
        ref.read(emojiPackPurchasedProvider.notifier).state = false;
        ref.read(iapServiceProvider).emojiPackPurchased = false;
        // Reset emoji shape pack to classic if selected
        if (ref.read(shapePackProvider) == ShapePack.emoji) {
          ref.read(shapePackProvider.notifier).select(ShapePack.classic);
        }
        ref.read(streakProvider.notifier).checkAndUpdate();
        ref.read(dailyChallengeProvider.notifier).checkRenewal();
      }
    });

    // Sync gameState when player data becomes available (also on re-fetch)
    ref.listen<AsyncValue<Player?>>(playerProvider, (prev, next) {
      final player = next.valueOrNull;
      if (player == null) return;

      // Guard: ignore stale cached data if user is signed out
      final currentUser = ref.read(authStateProvider).valueOrNull;
      if (currentUser == null) return;

      // Always set the player's bestScore + jokers (may be lower on new account)
      final notifier = ref.read(gameStateProvider.notifier);
      notifier.loadSavedState(
        bestScore: player.bestScore,
        jokers: player.jokerInventory,
      );

      // Sync noAdsPurchased from Firestore (single source of truth when signed in)
      if (player.noAdsPurchased) {
        ref.read(noAdsPurchasedProvider.notifier).state = true;
        ref.read(iapServiceProvider).noAdsPurchased = true;
      }

      // Sync emojiPackPurchased from Firestore
      if (player.emojiPackPurchased) {
        ref.read(emojiPackPurchasedProvider.notifier).state = true;
        ref.read(iapServiceProvider).emojiPackPurchased = true;
      }

      // Also fetch leaderboard score (may be higher than Player.bestScore)
      final capturedUid = currentUser.uid;
      ref.read(firestoreServiceProvider).getLeaderboardScore(player.uid).then((lbScore) {
        // Guard: user may have signed out or switched account
        final stillSignedIn = ref.read(authStateProvider).valueOrNull;
        if (stillSignedIn == null || stillSignedIn.uid != capturedUid) return;

        final best = [player.bestScore, lbScore].reduce((a, b) => a > b ? a : b);
        if (best > ref.read(gameStateProvider).bestScore) {
          notifier.loadSavedState(
            bestScore: best,
            jokers: ref.read(gameStateProvider).jokerInventory,
          );
          if (best > player.bestScore) {
            ref.read(firestoreServiceProvider).updateBestScore(capturedUid, best);
          }
        }
      });
    });

    return MaterialApp.router(
      title: 'Shape Merge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const AccountSyncOverlay(),
          ],
        );
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  /// Reset localStorage to fresh guest defaults on sign-out.
  Future<void> _resetLocalToDefaults(LocalStorageService storage) async {
    await storage.setBestScore(0);
    await storage.saveJokerInventory(const JokerInventory.initial());
    await storage.setPlayerLevel(1);
    await storage.setCurrentXP(0);
    await storage.setTotalXP(0);
    await storage.setCurrentStreak(0);
    await storage.setLongestStreak(0);
    await storage.setNextRewardIndex(0);
    await storage.setGamesPlayed(0);
    await storage.setTotalMerges(0);
    await storage.setDailyChallengesJson('');
    await storage.clearGameCheckpoint();
    await storage.clearLastLoginDate();
    await storage.clearRewardClaimedDate();
    await storage.setNoAdsPurchased(false);
    await storage.setEmojiPackPurchased(false);
  }
}
