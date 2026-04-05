import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/game/logic/game_engine.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/screens/game/overlays/game_over_overlay.dart';
import 'package:shape_merge/screens/game/overlays/pause_overlay.dart';
import 'package:shape_merge/screens/game/widgets/capacity_bar.dart';
import 'package:shape_merge/screens/game/widgets/game_board.dart';
import 'package:shape_merge/screens/game/widgets/hud_bar.dart';
import 'package:shape_merge/screens/game/widgets/joker_bar.dart';
import 'package:shape_merge/screens/game/widgets/merge_effect.dart';
import 'package:shape_merge/screens/game/widgets/score_popup.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final List<Widget> _effects = [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gameStateProvider.notifier).startNewGame();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final authState = ref.watch(authStateProvider);
    final isSignedIn = authState.valueOrNull != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Pause button + HUD
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.pause, color: AppTheme.muted),
                        onPressed: () =>
                            ref.read(gameStateProvider.notifier).togglePause(),
                      ),
                      Expanded(
                        child: HudBar(
                          score: gameState.score,
                          bestScore: gameState.bestScore,
                          shapeCount: gameState.shapes.length,
                          mergeCount: gameState.mergeCount,
                        ),
                      ),
                    ],
                  ),
                ),
                CapacityBar(current: gameState.shapes.length),
                const SizedBox(height: 8),
                // Game board
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Stack(
                      children: [
                        GameBoard(
                          onMerge: (pos, color, points) {
                            _addMergeEffect(pos, color, points);
                          },
                        ),
                        ..._effects,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Joker bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: JokerBar(inventory: gameState.jokerInventory),
                ),
                const SizedBox(height: 8),
                // Ad banner placeholder
                Container(
                  height: 50,
                  color: AppTheme.panel,
                  child: Center(
                    child: Text(
                      'Ad Banner',
                      style: TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            // Overlays
            if (gameState.isPaused)
              PauseOverlay(
                onResume: () =>
                    ref.read(gameStateProvider.notifier).togglePause(),
              ),
            if (!gameState.gameActive)
              GameOverOverlay(
                score: gameState.score,
                mergeCount: gameState.mergeCount,
                maxLevel: gameState.maxLevelReached,
                isVictory: GameEngine.isVictory(gameState),
                isSignedIn: isSignedIn,
                onReplay: () {
                  ref.read(gameStateProvider.notifier).startNewGame();
                },
                onSignIn: () async {
                  await ref.read(authServiceProvider).signInWithGoogle();
                },
              ),
          ],
        ),
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
