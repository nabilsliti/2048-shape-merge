import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/models/leaderboard_entry.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/ad_banner_widget.dart';
import 'package:shape_merge/game/logic/game_engine.dart';
import 'package:shape_merge/game/models/game_state.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/screens/game/overlays/game_over_overlay.dart';
import 'package:shape_merge/screens/game/overlays/pause_overlay.dart';
import 'package:shape_merge/screens/game/overlays/tutorial_overlay.dart';
import 'package:shape_merge/screens/game/widgets/game_board.dart';
import 'package:shape_merge/screens/game/widgets/hud_bar.dart';
import 'package:shape_merge/screens/game/widgets/joker_bar.dart';
import 'package:shape_merge/screens/game/widgets/merge_effect.dart';
import 'package:shape_merge/screens/game/widgets/score_popup.dart';
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

        // Load persisted best score for comparison
        final storage = await ref.read(localStorageProvider.future);
        _lastPersistedBest = storage.bestScore;

        // Listen for best score changes and persist immediately
        ref.listenManual(
          gameStateProvider.select((s) => s.bestScore),
          (previous, next) async {
            if (next > _lastPersistedBest) {
              _lastPersistedBest = next;
              final st = await ref.read(localStorageProvider.future);
              await st.setBestScore(next);

              // Submit to leaderboard in real-time
              final user = ref.read(authStateProvider).valueOrNull;
              if (user != null) {
                final gameState = ref.read(gameStateProvider);
                _submitScore(user, gameState);
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
    ref.read(gameStateProvider.notifier).startNewGame();
  }

  void _submitScore(User user, GameState gameState) {
    debugPrint('🎯 _submitScore called: score=${gameState.score}, uid=${user.uid}');
    final now = DateTime.now();
    final weekKey = '${now.year}-W${(now.day ~/ 7) + 1}';
    final player = ref.read(playerProvider).valueOrNull;
    final entry = LeaderboardEntry(
      uid: user.uid,
      displayName: player?.displayName ?? user.displayName ?? user.email ?? 'Player',
      photoUrl: user.photoURL,
      avatarId: player?.avatarId,
      score: gameState.score,
      maxLevel: gameState.maxLevelReached,
      mergeCount: gameState.mergeCount,
      timestamp: now,
      weekKey: weekKey,
    );
    ref.read(firestoreServiceProvider).submitScore(entry);
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
      if (isSignedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _submitScore(user, gameState);
        });
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background (same as shape-rush)
          Positioned.fill(child: AppTheme.backgroundWidget()),
          SafeArea(
            child: Column(
              children: [
                // HUD bar (same card design)
                Padding(
                  padding: const EdgeInsets.only(left: 3, right: 3, top: 3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
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
                                borderRadius: BorderRadius.circular(10),
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
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              const Positioned.fill(child: SpaceBackground()),
                              Positioned.fill(
                                child: GameBoard(
                                  onMerge: (pos, color, points) {
                                    _addMergeEffect(pos, color, points);
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
                                borderRadius: BorderRadius.circular(10),
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
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        const Positioned.fill(child: SpaceBackground(lite: true)),
                        JokerBar(inventory: gameState.jokerInventory),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
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
                // Ad banner
                const AdBannerWidget(),
              ],
            ),
          ),
          // Overlays
          if (_showTutorial)
            TutorialOverlay(onDismiss: _dismissTutorial),
          if (!_showTutorial && gameState.isPaused)
            PauseOverlay(
              onResume: () => ref.read(gameStateProvider.notifier).togglePause(),
            ),
          if (!gameState.gameActive)
            GameOverOverlay(
              score: gameState.score,
              mergeCount: gameState.mergeCount,
              isVictory: GameEngine.isVictory(gameState),
              isNewRecord: gameState.score > 0 && gameState.score >= gameState.bestScore,
              isSignedIn: isSignedIn,
              onReplay: () {
                _scoreSubmitted = false;
                ref.read(gameStateProvider.notifier).startNewGame();
              },
              onSignIn: () async {
                await ref.read(authServiceProvider).signInWithGoogle();
                final signedUser = ref.read(authStateProvider).valueOrNull;
                if (signedUser != null && !_scoreSubmitted) {
                  _scoreSubmitted = true;
                  _submitScore(signedUser, gameState);
                }
              },
            ),
        ],
      ),
    );
  }

  void _addMergeEffect(Offset position, Color color, int points) {
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
          onComplete: () => setState(() {
            _effects.removeWhere((e) => e.key == popupKey);
          }),
        ),
      );
    });
  }
}
