import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/game/logic/joker_suggestion_engine.dart';
import 'package:shape_merge/providers/game_state_provider.dart';

/// Tracks move count for suggestion throttling.
final _moveCountProvider = StateProvider<int>((ref) => 0);

/// Tracks the move at which last suggestion was shown.
final _lastSuggestionMoveProvider = StateProvider<int>((ref) => -10);

/// Invisible widget that evaluates the board each move and pushes
/// the best joker suggestion into [jokerSuggestionProvider].
/// Place anywhere in the widget tree (renders nothing).
class JokerHintBanner extends ConsumerStatefulWidget {
  const JokerHintBanner({super.key});

  @override
  ConsumerState<JokerHintBanner> createState() => _JokerHintBannerState();
}

class _JokerHintBannerState extends ConsumerState<JokerHintBanner> {
  int _lastShapeCount = 0;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);

    // Track moves (shape count changes = a move happened)
    if (gameState.shapes.length != _lastShapeCount && gameState.gameActive) {
      _lastShapeCount = gameState.shapes.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(_moveCountProvider.notifier).state++;

        final moveCount = ref.read(_moveCountProvider);
        final lastSuggestionMove = ref.read(_lastSuggestionMoveProvider);

        final suggestion = JokerSuggestionEngine.evaluate(
          shapes: gameState.shapes,
          inventory: gameState.jokerInventory,
          recentMergeRate: gameState.recentMergeRate,
          movesSinceLastSuggestion: moveCount - lastSuggestionMove,
        );

        if (suggestion != null) {
          ref.read(jokerSuggestionProvider.notifier).state = suggestion.type;
          ref.read(_lastSuggestionMoveProvider.notifier).state = moveCount;

          // Auto-clear after 6 seconds
          Future.delayed(const Duration(seconds: 6), () {
            if (!mounted) return;
            // Only clear if still showing the same suggestion
            if (ref.read(jokerSuggestionProvider) == suggestion.type) {
              ref.read(jokerSuggestionProvider.notifier).state = null;
            }
          });
        }
      });
    }

    // Clear on game over or new game
    if (!gameState.gameActive || gameState.shapes.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(jokerSuggestionProvider.notifier).state = null;
        ref.read(_moveCountProvider.notifier).state = 0;
        ref.read(_lastSuggestionMoveProvider.notifier).state = -10;
      });
    }

    return const SizedBox.shrink();
  }
}
