import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/game/logic/joker_suggestion_engine.dart';
import 'package:shape_merge/providers/game_state_provider.dart';

/// Tracks move count for suggestion throttling.
final _moveCountProvider = StateProvider<int>((ref) => 0);

/// Tracks the move at which last suggestion was shown.
final _lastSuggestionMoveProvider = StateProvider<int>((ref) => -10);

/// Max times each joker type suggestion is shown before the player "learned" it.
const _maxShowPerType = 3;
const _prefsKeyPrefix = 'jokerHintCount_';

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
  Map<JokerType, int> _shownCounts = {};
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final counts = <JokerType, int>{};
    for (final type in JokerType.values) {
      counts[type] = prefs.getInt('$_prefsKeyPrefix${type.name}') ?? 0;
    }
    if (mounted) setState(() { _shownCounts = counts; _prefsLoaded = true; });
  }

  Future<void> _incrementCount(JokerType type) async {
    _shownCounts[type] = (_shownCounts[type] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefsKeyPrefix${type.name}', _shownCounts[type]!);
  }

  bool _hasReachedLimit(JokerType type) {
    return (_shownCounts[type] ?? 0) >= _maxShowPerType;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);

    if (!_prefsLoaded) return const SizedBox.shrink();

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

        if (suggestion != null && !_hasReachedLimit(suggestion.type)) {
          ref.read(jokerSuggestionProvider.notifier).state = suggestion.type;
          ref.read(_lastSuggestionMoveProvider.notifier).state = moveCount;
          _incrementCount(suggestion.type);

          // Auto-clear after 4 seconds
          Future.delayed(const Duration(seconds: 4), () {
            if (!mounted) return;
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
