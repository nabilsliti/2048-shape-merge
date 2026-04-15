import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/config/app_routes.dart';
import 'package:shape_merge/core/models/leaderboard_entry.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/services/analytics_service.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/game/logic/game_engine.dart';
import 'package:shape_merge/game/models/game_state.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/providers/progression_provider.dart';
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
import 'package:shape_merge/screens/game/widgets/score_popup.dart';
import 'package:shape_merge/core/services/notification_service.dart';
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
  final List<Widget> _effects = [];
  bool _initialized = false;
  late bool _showTutorial = !GameScreen.tutorialSeen;
  bool _scoreSubmitted = false;
  static const _tutorialSeenKey = 'tutorial_seen';

  int _lastPersistedBest = 0;
  ProviderSubscription<int>? _bestScoreListener;

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

        if (!mounted) return;
        // Start the game once board is laid out (setBoardSize called in GameBoard.build)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
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
    _bestScoreListener?.close();
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

  void _submitScore(User user, GameState gameState) {
    // Use the higher of current game score and account bestScore for leaderboard
    final bestForLeaderboard = gameState.score > gameState.bestScore
        ? gameState.score
        : gameState.bestScore;
    const AppLogger('Leaderboard').debug('submitScore: score=$bestForLeaderboard (game=${gameState.score}, best=${gameState.bestScore}), uid=${user.uid}');
    final now = DateTime.now();
    final weekNum = ((now.difference(DateTime(now.year, 1, 1)).inDays + DateTime(now.year, 1, 1).weekday - 1) ~/ 7) + 1;
    final weekKey = '${now.year}-W${weekNum.toString().padLeft(2, '0')}';
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
      weekKey: weekKey,
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
      // Clear checkpoint — game is over, no need to restore
      ref.read(localStorageProvider).whenData((s) => s.clearGameCheckpoint());
      unawaited(AnalyticsService.instance.logGameOver(
        score: gameState.score,
        maxLevel: gameState.maxLevelReached,
        mergeCount: gameState.mergeCount,
        shapesOnBoard: gameState.shapes.length,
      ));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isSignedIn) {
          _submitScore(user, gameState);
          unawaited(_updatePlayerStats(user.uid, gameState.mergeCount));
        } else {
          _updateLocalStats(gameState.mergeCount);
        }
        // Sync daily challenge progress
        ref.read(dailyChallengeProvider.notifier).syncGameResult(
          fusionsThisGame: gameState.mergeCount,
          scoreThisGame: gameState.score,
          jokersUsedThisGame: gameState.jokersUsedThisGame,
          maxLevelReached: gameState.maxLevelReached,
        );
        // Process XP gain
        ref.read(progressionProvider.notifier).processGameEnd(
          score: gameState.score,
          mergeCount: gameState.mergeCount,
          maxLevelReached: gameState.maxLevelReached,
        );
        // User just played — cancel the streak-danger reminder and reschedule
        // for 23 h from now so the reminder fires tomorrow if they don't play.
        NotificationService.instance
            .scheduleStreakReminder();
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
          SafeArea(
            bottom: false,
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
                ref.read(dailyChallengeProvider.notifier).syncGameResult(
                  fusionsThisGame: gs.mergeCount,
                  scoreThisGame: gs.score,
                  jokersUsedThisGame: gs.jokersUsedThisGame,
                  maxLevelReached: gs.maxLevelReached,
                );
                ref.read(progressionProvider.notifier).processGameEnd(
                  score: gs.score,
                  mergeCount: gs.mergeCount,
                  maxLevelReached: gs.maxLevelReached,
                );
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
              isVictory: GameEngine.isVictory(gameState),
              isNewRecord: gameState.score > 0 && gameState.score > _lastPersistedBest,
              isSignedIn: isSignedIn,
              onReplay: () {
                _scoreSubmitted = false;
                _lastPersistedBest = ref.read(gameStateProvider).bestScore;
                ref.read(gameStateProvider.notifier).startNewGame();
              },
              onSignIn: () async {
                await ref.read(authServiceProvider).signInWithGoogle();
                final signedUser = ref.read(authStateProvider).valueOrNull;
                if (signedUser != null && !_scoreSubmitted) {
                  _scoreSubmitted = true;
                  // Read fresh gameState (bestScore may have been updated by auth listener)
                  _submitScore(signedUser, ref.read(gameStateProvider));
                }
              },
            ),
        ],
      ),
      ),
    );
  }

  void _addMergeEffect(Offset position, Color color, int points, int comboCount) {
    setState(() {
      final effectKey = UniqueKey();
      final popupKey = UniqueKey();

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
