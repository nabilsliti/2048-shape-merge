import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/models/leaderboard_entry.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
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
import 'package:shape_merge/screens/game/overlays/tutorial_overlay.dart';
import 'package:shape_merge/screens/game/widgets/game_board.dart';
import 'package:shape_merge/screens/game/widgets/hud_bar.dart';
import 'package:shape_merge/screens/game/widgets/joker_bar.dart';
import 'package:shape_merge/screens/game/widgets/joker_effect.dart';
import 'package:shape_merge/screens/game/widgets/merge_effect.dart';
import 'package:shape_merge/screens/game/widgets/score_popup.dart';
import 'package:shape_merge/core/services/notification_service.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final List<Widget> _effects = [];
  bool _initialized = false;
  bool _showTutorial = false;
  bool _scoreSubmitted = false;
  static const _tutorialSeenKey = 'tutorial_seen';

  int _lastPersistedBest = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final prefs = await SharedPreferences.getInstance();
        final seen = prefs.getBool(_tutorialSeenKey) ?? false;

        // Load persisted best score for comparison — use gameState (loaded
        // from Firestore for signed-in users) as single source of truth.
        _lastPersistedBest = ref.read(gameStateProvider).bestScore;

        // Listen for best score changes and persist immediately
        ref.listenManual(
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

        if (!seen && mounted) {
          setState(() => _showTutorial = true);
        } else {
          ref.read(gameStateProvider.notifier).startNewGame();
        }
      });
    }
  }

  void _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialSeenKey, true);
    if (!mounted) return;
    setState(() => _showTutorial = false);
    _lastPersistedBest = ref.read(gameStateProvider).bestScore;
    ref.read(gameStateProvider.notifier).startNewGame();
  }

  void _submitScore(User user, GameState gameState) {
    // Use the higher of current game score and account bestScore for leaderboard
    final bestForLeaderboard = gameState.score > gameState.bestScore
        ? gameState.score
        : gameState.bestScore;
    debugPrint('🎯 _submitScore called: score=$bestForLeaderboard (game=${gameState.score}, best=${gameState.bestScore}), uid=${user.uid}');
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
    ref.read(firestoreServiceProvider).submitScore(entry);
  }

  // Bug B2 fix: gamesPlayed + totalMerges were never incremented.
  void _updatePlayerStats(String uid, int sessionMerges) {
    ref.read(firestoreServiceProvider).incrementPlayerStats(
      uid,
      mergesThisGame: sessionMerges,
    );
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isSignedIn) {
          _submitScore(user, gameState);
          // Bug B2 fix: increment gamesPlayed + totalMerges (were never updated)
          _updatePlayerStats(user.uid, gameState.mergeCount);
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

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background (same as shape-rush)
          Positioned.fill(child: AppTheme.backgroundWidget()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // HUD bar (same card design)
                Padding(
                  padding: const EdgeInsets.only(left: 3, right: 3, top: 3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXTiny),
                    child: Stack(
                      children: [
                        const Positioned.fill(child: SpaceBackground(lite: true)),
                        HudBar(
                          score: gameState.score,
                          bestScore: gameState.bestScore,
                          shapeCount: gameState.shapes.length,
                          mergeCount: gameState.mergeCount,
                          onPause: () => ref.read(gameStateProvider.notifier).togglePause(),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.radiusXTiny),
                                border: Border.all(
                                  color: AppTheme.panelBorder.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // Game board with pause button inside
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 3, right: 3),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusXTiny),
                          child: Stack(
                            children: [
                              const Positioned.fill(child: SpaceBackground()),
                              Positioned.fill(
                                child: GameBoard(
                                  onMerge: (pos, color, points, comboCount) {
                                    _addMergeEffect(pos, color, points, comboCount);
                                  },
                                  onJokerUsed: (pos, jokerType) {
                                    _addJokerEffect(pos, jokerType);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Border overlay
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.radiusXTiny),
                                border: Border.all(
                                  color: AppTheme.panelBorder.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ..._effects,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // Joker bar (same card design)
                Padding(
                  padding: const EdgeInsets.only(left: 3, right: 3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXTiny),
                    child: Stack(
                      children: [
                        const Positioned.fill(child: SpaceBackground(lite: true)),
                        JokerBar(inventory: gameState.jokerInventory),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.radiusXTiny),
                                border: Border.all(
                                  color: AppTheme.panelBorder.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
              ],
            ),
          ),
          // Overlays
          if (_showTutorial)
            TutorialOverlay(onDismiss: _dismissTutorial),
          if (!_showTutorial && gameState.isPaused)
            PauseOverlay(
              onResume: () => ref.read(gameStateProvider.notifier).togglePause(),
              onQuit: () {
                final gs = ref.read(gameStateProvider);
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
                context.go('/home');
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
