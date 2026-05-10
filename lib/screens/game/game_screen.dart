import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/config/app_routes.dart';
import 'package:shape_merge/core/config/shop_catalog.dart';
import 'package:shape_merge/core/models/daily_challenge.dart';
import 'package:shape_merge/core/models/leaderboard_entry.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/services/analytics_service.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/game/models/game_state.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/ads_provider.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';
import 'package:shape_merge/core/services/iap_service.dart';
import 'package:shape_merge/providers/iap_provider.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/providers/progression_provider.dart';
import 'package:shape_merge/providers/streak_provider.dart';
import 'package:shape_merge/screens/game/overlays/game_over_overlay.dart';
import 'package:shape_merge/screens/game/overlays/pause_overlay.dart';
import 'package:shape_merge/screens/game/widgets/coach_overlay.dart';
import 'package:shape_merge/screens/game/widgets/game_board.dart';
import 'package:shape_merge/screens/game/widgets/hud_bar.dart';
import 'package:shape_merge/screens/game/widgets/joker_bar.dart';
import 'package:shape_merge/screens/game/widgets/joker_effect.dart';
import 'package:shape_merge/screens/game/widgets/joker_hint_banner.dart';
import 'package:shape_merge/screens/game/widgets/joker_suggestion_tooltip.dart';
import 'package:shape_merge/screens/game/widgets/merge_effect.dart';
import 'package:shape_merge/screens/game/widgets/objective_toast.dart';
import 'package:shape_merge/screens/game/widgets/score_popup.dart';
import 'package:shape_merge/core/services/notification_service.dart';
import 'package:shape_merge/core/services/review_service.dart';
import 'package:shape_merge/core/widgets/game_panel.dart';
import 'package:shape_merge/core/widgets/offline_banner.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  /// Pre-loaded in main() before runApp — synchronously available.
  static bool tutorialSeen = false;

  static Future<void> preload() async {
    final prefs = await SharedPreferences.getInstance();
    tutorialSeen = prefs.getBool('tutorial_seen') ?? false;
  }

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  static const _maxConcurrentEffects = 8;

  final List<Widget> _effects = [];
  bool _initialized = false;
  late bool _showTutorial = !GameScreen.tutorialSeen;
  bool _scoreSubmitted = false;
  bool _reviveUsed = false;
  bool _waitingForRescuePurchase = false;
  /// `true` when the most recent game over should trigger an interstitial
  /// on the next "new game" tap. Computed once per game over (when
  /// [_scoreSubmitted] flips), via [AdsService.noteGameOverAndShouldShowInterstitial].
  bool _showInterstitialNext = false;
  static const _tutorialSeenKey = 'tutorial_seen';

  int _lastPersistedBest = 0;
  ProviderSubscription<int>? _bestScoreListener;
  ProviderSubscription<GameState>? _liveObjectiveListener;
  ProviderSubscription<IapResult?>? _iapListener;
  ProviderSubscription<int>? _radarTickListener;
  final List<Widget> _toasts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final gameState = ref.read(gameStateProvider);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (gameState.gameActive && !gameState.isPaused) {
          ref.read(gameStateProvider.notifier).togglePause();
          AudioService.instance.pauseGameMusic();
        }
      case AppLifecycleState.resumed:
        // Game stays paused — user must manually resume via PauseOverlay.
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Load persisted best score for comparison — use gameState (loaded
        // from Firestore for signed-in users) as single source of truth.
        _lastPersistedBest = ref.read(gameStateProvider).bestScore;

        // Listen for IAP purchase results (rescue pack → revive)
        _iapListener = ref.listenManual<IapResult?>(
          lastPurchaseResultProvider,
          (prev, next) {
            if (!_waitingForRescuePurchase || next == null) return;
            // Trigger revive for any pack that contains jokers (excludes pack_emoji
            // and any future cosmetic-only packs). User intent on the rescue button
            // = save the run, regardless of which pack they end up buying.
            final productId = next.productId;
            if (productId == null) return;
            final pack = ShopCatalog.byId(productId);
            final hasJokers = pack != null &&
                (pack.freeJokers + pack.radar + pack.evolution + pack.megaBomb) > 0;
            if (!hasJokers) return;
            if (next.status == IapStatus.purchased) {
              _waitingForRescuePurchase = false;
              _scoreSubmitted = false;
              ref.read(gameStateProvider.notifier).revive();
              if (AudioService.instance.musicEnabled) {
                AudioService.instance.playGameMusic();
              }
              // Bring user back to the game screen automatically.
              if (mounted) context.go(AppRoutes.game);
            } else if (next.status == IapStatus.error) {
              _waitingForRescuePurchase = false;
            }
            ref.read(lastPurchaseResultProvider.notifier).state = null;
          },
        );

        // Listen for best score changes and persist immediately
        _bestScoreListener = ref.listenManual(
          gameStateProvider.select((s) => s.bestScore),
          (previous, next) async {
            if (next > _lastPersistedBest) {
              // Signal to Home screen that a new record was set
              ref.read(newRecordPendingProvider.notifier).state = true;

              final user = ref.read(authStateProvider).valueOrNull;
              if (user != null) {
                // Signed-in: persist to Firestore only (don't pollute localStorage)
                final gameState = ref.read(gameStateProvider);
                _submitScore(user, gameState);
                ref.read(firestoreServiceProvider).updateBestScore(user.uid, next);
              } else {
                // Guest: persist to localStorage
                final st = await ref.read(localStorageProvider.future);
                await st.setBestScore(next);
              }
            }
          },
        );

        // Live objective sync — check after each meaningful game state change
        _liveObjectiveListener = ref.listenManual(
          gameStateProvider,
          (previous, next) {
            if (!next.gameActive || next.isPaused) return;
            if (previous == null) return;
            // Only sync when stats actually changed
            if (next.mergeCount == previous.mergeCount &&
                next.score == previous.score &&
                next.jokersUsedThisGame == previous.jokersUsedThisGame &&
                next.maxLevelReached == previous.maxLevelReached &&
                next.shapesDestroyedThisGame == previous.shapesDestroyedThisGame &&
                next.wildcardMergesThisGame == previous.wildcardMergesThisGame &&
                next.highLevelMergesThisGame == previous.highLevelMergesThisGame &&
                next.boardClearsThisGame == previous.boardClearsThisGame &&
                next.maxComboReached == previous.maxComboReached) {
              return;
            }
            final newlyCompleted = ref.read(dailyChallengeProvider.notifier)
                .syncLiveProgress(
              fusionsSoFar: next.mergeCount,
              scoreSoFar: next.score,
              jokersUsedSoFar: next.jokersUsedThisGame,
              maxLevelSoFar: next.maxLevelReached,
              shapesDestroyedSoFar: next.shapesDestroyedThisGame,
              wildcardMergesSoFar: next.wildcardMergesThisGame,
              highLevelMergesSoFar: next.highLevelMergesThisGame,
              boardClearsSoFar: next.boardClearsThisGame,
              maxComboSoFar: next.maxComboReached,
            );
            for (final challenge in newlyCompleted) {
              _showObjectiveToast(challenge);
            }
          },
        );

        // Radar joker activation: spawn the sonar visual effect at the board
        // centre + play the radar SFX (matches the playable-ad behaviour).
        _radarTickListener = ref.listenManual<int>(
          radarActivationTickProvider,
          (previous, next) {
            if (previous == null || next == previous) return;
            final boardSize = ref.read(gameStateProvider.notifier).boardSize;
            if (boardSize == null) return;
            final centre = Offset(boardSize.width / 2, boardSize.height / 2);
            _addJokerEffect(centre, JokerType.radar);
            AudioService.instance.playJoker('radar');
          },
        );

        if (!mounted) return;
        // Start the game once board is laid out (setBoardSize called in GameBoard.build)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(dailyChallengeProvider.notifier).captureBaseline();
          final notifier = ref.read(gameStateProvider.notifier);
          // Try to restore a game interrupted by a crash or kill
          if (!notifier.tryRestoreCheckpoint()) {
            notifier.startNewGame();
          }
        });
        // Start music
        if (AudioService.instance.musicEnabled) {
          AudioService.instance.playGameMusic();
        }
      });
    }
  }

  @override
  void dispose() {
    _iapListener?.close();
    _bestScoreListener?.close();
    _liveObjectiveListener?.close();
    _radarTickListener?.close();
    WidgetsBinding.instance.removeObserver(this);
    AudioService.instance.stopGameMusic();
    super.dispose();
  }

  void _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialSeenKey, true);
    GameScreen.tutorialSeen = true;
    if (!mounted) return;
    setState(() => _showTutorial = false);
    _lastPersistedBest = ref.read(gameStateProvider).bestScore;
  }

  void _showObjectiveToast(DailyChallenge challenge) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final label = _objectiveLabel(l10n, challenge);
    setState(() {
      final key = UniqueKey();
      _toasts.add(
        ObjectiveToast(
          key: key,
          label: label,
          onDismissed: () {
            if (mounted) setState(() => _toasts.removeWhere((t) => t.key == key));
          },
        ),
      );
    });
    AudioService.instance.playReward();
  }

  static String _objectiveLabel(AppLocalizations l10n, DailyChallenge c) {
    return switch (c.type) {
      ChallengeType.fusions         => l10n.objectiveFusions(c.target),
      ChallengeType.score           => l10n.objectiveScore(c.target),
      ChallengeType.parties         => l10n.objectiveParties(c.target),
      ChallengeType.formeMax        => l10n.objectiveFormeMax(c.target),
      ChallengeType.jokersUses      => l10n.objectiveJokersUses(c.target),
      ChallengeType.shapesDestroyed => l10n.objectiveShapesDestroyed(c.target),
      ChallengeType.wildcardMerges  => l10n.objectiveWildcardMerges(c.target),
      ChallengeType.highLevelMerges => l10n.objectiveHighLevelMerges(c.target),
      ChallengeType.boardClears     => l10n.objectiveBoardClears(c.target),
      ChallengeType.maxCombo        => l10n.objectiveMaxCombo(c.target),
    };
  }

  void _submitScore(User user, GameState gameState) {
    // Use the higher of current game score and account bestScore for leaderboard
    final bestForLeaderboard = gameState.score > gameState.bestScore
        ? gameState.score
        : gameState.bestScore;
    const AppLogger('Leaderboard').debug('submitScore: score=$bestForLeaderboard (game=${gameState.score}, best=${gameState.bestScore}), uid=${user.uid}');
    final now = DateTime.now();
    final player = ref.read(playerProvider).valueOrNull;
    final entry = LeaderboardEntry(
      uid: user.uid,
      displayName: player?.displayName ?? user.displayName ?? user.email ?? AppLocalizations.of(context)!.defaultPlayerName,
      photoUrl: user.photoURL,
      avatarId: player?.avatarId,
      score: bestForLeaderboard,
      maxLevel: gameState.maxLevelReached,
      mergeCount: gameState.mergeCount,
      timestamp: now,
    );
    unawaited(ref.read(firestoreServiceProvider).submitScore(entry).catchError((Object e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.scoreSubmitError),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }));
  }

  // Bug B2 fix: gamesPlayed + totalMerges were never incremented.
  Future<void> _updatePlayerStats(String uid, int sessionMerges) async {
    await ref.read(firestoreServiceProvider).incrementPlayerStats(
      uid,
      mergesThisGame: sessionMerges,
    );
    ref.invalidate(playerProvider);
  }

  Future<void> _updateLocalStats(int sessionMerges) async {
    final storage = await ref.read(localStorageProvider.future);
    await storage.incrementGamesPlayed();
    await storage.addMerges(sessionMerges);
    ref.invalidate(localStorageProvider);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final isSignedIn = user != null;

    // Auto-submit score to leaderboard when game ends
    if (!gameState.gameActive && !_scoreSubmitted) {
      _scoreSubmitted = true;
      _showInterstitialNext = ref
          .read(adsServiceProvider)
          .noteGameOverAndShouldShowInterstitial();
      AudioService.instance.pauseGameMusic();
      // Clear checkpoint — game is over, no need to restore
      ref.read(localStorageProvider).whenData((s) => s.clearGameCheckpoint());
      unawaited(AnalyticsService.instance.logGameOver(
        score: gameState.score,
        maxLevel: gameState.maxLevelReached,
        mergeCount: gameState.mergeCount,
        shapesOnBoard: gameState.shapes.length,
      ));
      // Refresh user properties so Firebase audiences stay accurate.
      unawaited(AnalyticsService.instance.setBestScore(gameState.bestScore));
      unawaited(AnalyticsService.instance
          .setJokersInventory(gameState.jokerInventory));
      final iap = ref.read(iapServiceProvider);
      unawaited(AnalyticsService.instance.setPremiumStatus(
        noAds: iap.noAdsPurchased,
        emojiPack: iap.emojiPackPurchased,
      ));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isSignedIn) {
          _submitScore(user, gameState);
          unawaited(_updatePlayerStats(user.uid, gameState.mergeCount));
        } else {
          _updateLocalStats(gameState.mergeCount);
        }
        // Capture completed count BEFORE syncing to compute delta for XP
        final beforeCompleted = ref
            .read(dailyChallengeProvider)
            ?.challenges
            .where((c) => c.completed)
            .map((c) => c.id)
            .toSet() ??
            {};
        final completedBefore = beforeCompleted.length;
        // Sync `parties` objective — other objectives were already synced live
        ref.read(dailyChallengeProvider.notifier).syncGameEnd();
        final afterChallenges =
            ref.read(dailyChallengeProvider)?.challenges ?? const [];
        final completedAfter =
            afterChallenges.where((c) => c.completed).length;
        final newlyCompleted = completedAfter - completedBefore;
        // Analytics: log each newly completed challenge.
        for (final c in afterChallenges) {
          if (c.completed && !beforeCompleted.contains(c.id)) {
            unawaited(AnalyticsService.instance
                .logChallengeCompleted(challengeId: c.id));
          }
        }
        // Process XP gain — use delta of newly completed objectives, not total
        ref.read(progressionProvider.notifier).processGameEnd(
          score: gameState.score,
          mergeCount: gameState.mergeCount,
          maxLevelReached: gameState.maxLevelReached,
          completedObjectivesDelta: newlyCompleted,
        );
        // User just played — cancel the streak-danger reminder and reschedule
        // for 23 h from now so the reminder fires tomorrow if they don't play.
        NotificationService.instance
            .scheduleStreakReminder(
          l10n: AppLocalizations.of(context),
          streakDays: ref.read(streakProvider)?.streak.currentStreak ?? 0,
        );
        // Maybe request in-app review after a good session
        unawaited(ReviewService.instance.maybeRequestReview(
          gamesPlayed: isSignedIn
              ? (ref.read(playerProvider).valueOrNull?.gamesPlayed ?? 0)
              : (ref.read(localStorageProvider).valueOrNull?.gamesPlayed ?? 0),
          bestScore: gameState.bestScore,
        ));
      });
    }

    return PopScope(
      canPop: !gameState.gameActive,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Game active: pause instead of quitting
        if (!gameState.isPaused) {
          ref.read(gameStateProvider.notifier).togglePause();
          AudioService.instance.pauseGameMusic();
        }
      },
      child: Scaffold(
      body: Stack(
        children: [
          // Gradient background (same as shape-rush)
          Positioned.fill(child: AppTheme.backgroundWidget()),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              children: [
                // HUD bar
                Padding(
                  padding: const EdgeInsets.only(left: 3, right: 3, top: 3),
                  child: GamePanel(
                    lite: true,
                    child: HudBar(
                      score: gameState.score,
                      bestScore: gameState.bestScore,
                      shapeCount: gameState.shapes.length,
                      mergeCount: gameState.mergeCount,
                      onPause: () {
                        ref.read(gameStateProvider.notifier).togglePause();
                        AudioService.instance.pauseGameMusic();
                      },
                      onShop: () {
                        // Silent pause — no overlay visible, just freeze state
                        if (!gameState.isPaused) {
                          ref.read(gameStateProvider.notifier).togglePause();
                          AudioService.instance.pauseGameMusic();
                        }
                        // Switch to shop branch (IndexedStack keeps game alive)
                        context.go(AppRoutes.shop, extra: 'from_game');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // Game board
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 3, right: 3),
                    child: KeyedSubtree(
                      key: CoachKeys.board,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          GamePanel(
                            child: Positioned.fill(
                              child: GameBoard(
                                onMerge: (pos, color, points, comboCount) {
                                  _addMergeEffect(pos, color, points, comboCount);
                                  if (_showTutorial) {
                                    CoachOverlay.notifyMerge();
                                  }
                                },
                                onJokerUsed: (pos, jokerType) {
                                  _addJokerEffect(pos, jokerType);
                                },
                              ),
                            ),
                          ),
                          ..._effects,
                          // Offline indicator — inside the board, top-right
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: IgnorePointer(
                              child: OfflineIndicator(autoPosition: false),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // Joker bar
                Padding(
                  padding: const EdgeInsets.only(left: 3, right: 3),
                  child: KeyedSubtree(
                    key: CoachKeys.jokerBar,
                    child: GamePanel(
                      lite: true,
                      child: JokerBar(inventory: gameState.jokerInventory),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
              ],
            ),
          ),
          // Overlays
          if (!_showTutorial) const JokerHintBanner(),
          if (!_showTutorial) const JokerSuggestionTooltip(),
          // Objective completion toasts — top-center, safe area
          if (_toasts.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).viewPadding.top + 8,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _toasts,
                ),
              ),
            ),
          if (_showTutorial)
            CoachOverlay(onComplete: _dismissTutorial),
          if (!_showTutorial && gameState.isPaused)
            PauseOverlay(
              onResume: () {
                ref.read(gameStateProvider.notifier).togglePause();
                AudioService.instance.resumeGameMusic();
              },
              onQuit: () {
                final gs = ref.read(gameStateProvider);
                // Clear checkpoint — user chose to quit, not continue later
                ref.read(localStorageProvider).whenData((s) => s.clearGameCheckpoint());
                final authState = ref.read(authStateProvider);
                final quitUser = authState.valueOrNull;
                if (quitUser != null) {
                  unawaited(_updatePlayerStats(quitUser.uid, gs.mergeCount));
                } else {
                  _updateLocalStats(gs.mergeCount);
                }
                // No XP and no challenge progress on quit — only on game over.
                // Unpause first so the PauseOverlay is removed from the
                // widget tree before the pop transition animation starts.
                ref.read(gameStateProvider.notifier).togglePause();
                context.pop();
              },
            ),
          if (!gameState.gameActive)
            GameOverOverlay(
              score: gameState.score,
              mergeCount: gameState.mergeCount,
              isNewRecord: gameState.score > 0 && gameState.score > _lastPersistedBest,
              isSignedIn: isSignedIn,
              canFreeContinue: !_reviveUsed,
              onFreeContinue: () => _handleFreeContinue(),
              onSaveWithPack: () => _handleSaveWithPack(),
              onNewGame: () => _handleNewGame(),
            ),
        ],
      ),
      ),
    );
  }

  // ── Step 1: Free continue via rewarded ad ──
  void _handleFreeContinue() {
    final ads = ref.read(adsServiceProvider);
    ads.showRewardedAd(onRewarded: () {
      if (!mounted) return;
      _reviveUsed = true;
      _scoreSubmitted = false;
      ref.read(gameStateProvider.notifier).revive();
      if (AudioService.instance.musicEnabled) {
        AudioService.instance.playGameMusic();
      }
      unawaited(AnalyticsService.instance.logReviveWatched());
    });
  }

  // ── Step 2: Save with rescue pack — navigate to shop tab ──
  void _handleSaveWithPack() {
    // Arm the IAP listener: if user buys any pack with jokers in the shop,
    // revive on return. Use `go` (not push) so the bottom nav highlights
    // the shop tab. The home branch (with game_screen) is preserved by the
    // StatefulShellRoute indexed stack, so this listener stays alive.
    _waitingForRescuePurchase = true;
    context.go(AppRoutes.shop);
  }

  // ── New game (from both steps) ──
  void _handleNewGame() {
    _scoreSubmitted = false;
    _reviveUsed = false;
    _lastPersistedBest = ref.read(gameStateProvider).bestScore;
    ref.read(dailyChallengeProvider.notifier).captureBaseline();
    _maybeShowInterstitial(() {
      ref.read(gameStateProvider.notifier).startNewGame();
      if (AudioService.instance.musicEnabled) {
        AudioService.instance.playGameMusic();
      }
    });
  }

  void _maybeShowInterstitial(VoidCallback then) {
    final noAds = ref.read(noAdsPurchasedProvider);
    if (noAds || !_showInterstitialNext) {
      then();
      return;
    }
    _showInterstitialNext = false;
    final ads = ref.read(adsServiceProvider);
    ads.showInterstitialAd(onDismissed: then);
  }

  void _addMergeEffect(Offset position, Color color, int points, int comboCount) {
    setState(() {
      final effectKey = UniqueKey();
      final popupKey = UniqueKey();

      // Cap concurrent effects to avoid frame drops during fast combos.
      while (_effects.length >= _maxConcurrentEffects - 1) {
        _effects.removeAt(0);
      }

      _effects.add(
        MergeEffect(
          key: effectKey,
          position: position,
          color: color,
          onComplete: () => setState(() {
            _effects.removeWhere((e) => e.key == effectKey);
          }),
        ),
      );

      _effects.add(
        ScorePopup(
          key: popupKey,
          points: points,
          position: position,
          comboCount: comboCount,
          onComplete: () => setState(() {
            _effects.removeWhere((e) => e.key == popupKey);
          }),
        ),
      );
    });
  }

  void _addJokerEffect(Offset position, JokerType jokerType) {
    setState(() {
      final effectKey = UniqueKey();
      // Cap concurrent effects to avoid frame drops during fast combos.
      while (_effects.length >= _maxConcurrentEffects) {
        _effects.removeAt(0);
      }
      _effects.add(
        JokerEffect(
          key: effectKey,
          position: position,
          jokerType: jokerType,
          onComplete: () => setState(() {
            _effects.removeWhere((e) => e.key == effectKey);
          }),
        ),
      );
    });
  }
}
