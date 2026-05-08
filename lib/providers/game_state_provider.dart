import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/services/analytics_service.dart';
import 'package:shape_merge/core/services/app_logger.dart';
import 'package:shape_merge/core/services/firestore_service.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shape_merge/game/logic/game_engine.dart';
export 'package:shape_merge/providers/local_storage_provider.dart';
import 'package:shape_merge/game/logic/joker_handler.dart';
import 'package:shape_merge/game/models/game_state.dart';
import 'package:shape_merge/core/models/game_shape.dart';

/// Signals that a new best-score was just achieved during gameplay.
/// Set to `true` in game_screen when bestScore increases.
/// Consumed (read + reset) by home_screen to trigger celebration.
final newRecordPendingProvider = StateProvider<bool>((ref) => false);

final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});

enum JokerMode { none, bomb, wildcard, reducer, radar, evolution, megaBomb }

final jokerModeProvider = StateProvider<JokerMode>((_) => JokerMode.none);

/// Incremented each time the user taps empty space while a joker is active.
/// Used to trigger radiation animation on the active joker orb.
final jokerEmptyTapProvider = StateProvider<int>((_) => 0);

// Map of shape ID → group index highlighted by radar
final radarHighlightProvider = StateProvider<Map<String, int>>((_) => {});

/// Which joker type the suggestion engine recommends right now (null = none).
final jokerSuggestionProvider = StateProvider<JokerType?>((_) => null);

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(const GameState());

  static const _radarDuration = Duration(seconds: 5);

  Size? _boardSize;
  LocalStorageService? _storage;
  FirestoreService? _firestoreService;
  String? _uid;

  void setBoardSize(Size size) => _boardSize = size;

  void setStorage(LocalStorageService storage) => _storage = storage;

  /// Set signed-in context so jokers are persisted to Firestore instead of localStorage.
  void setSignedIn(String uid, FirestoreService firestoreService) {
    _uid = uid;
    _firestoreService = firestoreService;
  }

  /// Clear signed-in context (sign-out). Jokers go back to localStorage.
  void clearSignedIn() {
    _uid = null;
    _firestoreService = null;
  }

  /// Reload joker inventory from Firestore (e.g. after server-side purchase).
  /// Throws if not signed in or if Firestore read fails.
  Future<void> refreshJokersFromFirestore() async {
    if (_uid == null || _firestoreService == null) {
      throw StateError('Cannot refresh jokers: user not signed in (uid=$_uid)');
    }
    const AppLogger('GameState').info('Refreshing jokers from Firestore for $_uid...');
    final player = await _firestoreService!.getPlayer(_uid!);
    if (player != null) {
      const AppLogger('GameState').info('Jokers from Firestore: bomb=${player.jokerInventory.bomb}, wildcard=${player.jokerInventory.wildcard}, reducer=${player.jokerInventory.reducer}');
      state = state.copyWith(jokerInventory: player.jokerInventory);
    } else {
      const AppLogger('GameState').warning('Player doc not found in Firestore for $_uid');
    }
  }

  /// Whether the user is signed in with Firestore context.
  bool get isSignedIn => _uid != null && _firestoreService != null;

  /// Current joker inventory (read-only access for merge logic).
  JokerInventory get jokerInventory => state.jokerInventory;

  void _saveJokers() {
    if (_uid != null && _firestoreService != null) {
      _firestoreService!.updateJokerInventory(_uid!, state.jokerInventory);
    } else {
      _storage?.saveJokerInventory(state.jokerInventory);
    }
  }

  void startNewGame() {
    if (_boardSize == null) return;
    state = GameEngine.startNewGame(_boardSize!, state);
    _saveCheckpoint();
    unawaited(AnalyticsService.instance.logGameStart());
  }

  void _saveCheckpoint() {
    if (!state.gameActive) {
      _storage?.clearGameCheckpoint();
      return;
    }
    try {
      final json = jsonEncode(state.toJson());
      _storage?.saveGameCheckpoint(json);
    } catch (_) {
      // Best-effort — don't crash the game for a save failure.
    }
  }

  /// Attempts to restore a game that was in progress when the app was killed.
  /// Returns true if a checkpoint was found and restored.
  bool tryRestoreCheckpoint() {
    final raw = _storage?.gameCheckpoint;
    if (raw == null) return false;
    try {
      final map = jsonDecode(raw) as Map<String, Object?>;
      final restored = GameState.fromJson(map);
      if (restored.shapes.isEmpty || !restored.gameActive) {
        _storage?.clearGameCheckpoint();
        return false;
      }
      state = restored.copyWith(
        bestScore: state.bestScore, // Keep authoritative bestScore from provider
        jokerInventory: state.jokerInventory, // Use current persisted jokers
      );
      return true;
    } catch (_) {
      _storage?.clearGameCheckpoint();
      return false;
    }
  }

  void _incrementJokerUsed() {
    state = state.copyWith(jokersUsedThisGame: state.jokersUsedThisGame + 1);
  }

  /// After destructive jokers (bomb, megaBomb, reducer), respawn shapes
  /// if the board is empty or has no mergeable pairs.
  void _checkAfterJoker() {
    if (_boardSize == null) return;
    state = GameEngine.checkAfterJoker(state, _boardSize!);
    _saveCheckpoint();
  }

  void loadSavedState({required int bestScore, required JokerInventory jokers}) {
    state = state.copyWith(bestScore: bestScore, jokerInventory: jokers);
  }

  ({GameShape? mergedShape, int pointsEarned, bool wasTap, int comboCount}) attemptMerge(
    GameShape dragged,
    Offset dropPosition, {
    bool wasTap = false,
  }) {
    if (_boardSize == null) {
      return (mergedShape: null, pointsEarned: 0, wasTap: wasTap, comboCount: 0);
    }
    final result = GameEngine.attemptMerge(
      state,
      dragged,
      dropPosition,
      _boardSize!,
      wasTap: wasTap,
    );
    state = result.state;
    _saveCheckpoint();
    return (mergedShape: result.mergedShape, pointsEarned: result.pointsEarned, wasTap: result.wasTap, comboCount: result.comboCount);
  }

  void updateShapePosition(String shapeId, double x, double y) {
    state = GameEngine.moveDraggedShape(state, shapeId, x, y);
  }

  void useBomb(GameShape target) {
    final shapesBefore = state.shapes.length;
    final result = JokerHandler.useBomb(
      target,
      state.shapes,
      state.jokerInventory,
    );
    final destroyed = shapesBefore - result.shapes.length;
    state = state.copyWith(
      shapes: result.shapes,
      jokerInventory: result.inventory,
      score: state.score + result.scoreBonus,
      shapesDestroyedThisGame: state.shapesDestroyedThisGame + destroyed,
    );
    _incrementJokerUsed();
    unawaited(AnalyticsService.instance.logJokerUsed(JokerType.bomb));
    _saveJokers();
    _checkAfterJoker();
  }

  void spawnWildcard(int level) {
    if (_boardSize == null) return;
    final result = JokerHandler.spawnWildcard(
      state.shapes,
      state.jokerInventory,
      _boardSize!,
      level,
    );
    state = state.copyWith(
      shapes: result.shapes,
      jokerInventory: result.inventory,
    );
    _incrementJokerUsed();
    unawaited(AnalyticsService.instance.logJokerUsed(JokerType.wildcard));
    _saveJokers();
  }

  void useReducer(GameShape target) {
    final result = JokerHandler.useReducer(
      target,
      state.shapes,
      state.jokerInventory,
    );
    state = state.copyWith(
      shapes: result.shapes,
      jokerInventory: result.inventory,
      score: state.score + result.scoreBonus,
    );
    _incrementJokerUsed();
    unawaited(AnalyticsService.instance.logJokerUsed(JokerType.reducer));
    _saveJokers();
    _checkAfterJoker();
  }

  void useEvolution(GameShape target) {
    final result = JokerHandler.useEvolution(
      target,
      state.shapes,
      state.jokerInventory,
    );
    final newScore = state.score + result.scoreBonus;
    final newBest = newScore > state.bestScore ? newScore : state.bestScore;
    final evolved = result.evolvedShape;
    final newMaxLevel = evolved != null && evolved.level > state.maxLevelReached
        ? evolved.level
        : state.maxLevelReached;
    state = state.copyWith(
      shapes: result.shapes,
      jokerInventory: result.inventory,
      score: newScore,
      bestScore: newBest,
      maxLevelReached: newMaxLevel,
    );
    _incrementJokerUsed();
    unawaited(AnalyticsService.instance.logJokerUsed(JokerType.evolution));
    _saveJokers();
  }

  void useMegaBomb(GameShape target) {
    final shapesBefore = state.shapes.length;
    final result = JokerHandler.useMegaBomb(
      target,
      state.shapes,
      state.jokerInventory,
    );
    final destroyed = shapesBefore - result.shapes.length;
    state = state.copyWith(
      shapes: result.shapes,
      jokerInventory: result.inventory,
      score: state.score + result.scoreBonus,
      shapesDestroyedThisGame: state.shapesDestroyedThisGame + destroyed,
    );
    _incrementJokerUsed();
    unawaited(AnalyticsService.instance.logJokerUsed(JokerType.megaBomb));
    _saveJokers();
    _checkAfterJoker();
  }

  /// Revive the game after game over — removes the N lowest-level shapes.
  void revive() {
    if (_boardSize == null || state.gameActive) return;
    final sorted = List<GameShape>.from(state.shapes)
      ..sort((a, b) => a.level.compareTo(b.level));
    final toRemove = sorted.take(ReviveTuning.shapesToRemove).map((s) => s.id).toSet();
    final remaining = state.shapes.where((s) => !toRemove.contains(s.id)).toList();
    state = state.copyWith(
      shapes: remaining,
      gameActive: true,
    );
    state = GameEngine.checkAfterJoker(state, _boardSize!);
    _saveCheckpoint();
  }

  Timer? _radarTimer;
  StateController<Map<String, int>>? _radarHighlightNotifier;

  /// Inject the radar highlight notifier so we don't need WidgetRef.
  void setRadarHighlightNotifier(StateController<Map<String, int>> notifier) {
    _radarHighlightNotifier = notifier;
  }

  void activateRadar() {
    if (state.jokerInventory.countOf(JokerType.radar) <= 0) return;
    final pairs = JokerHandler.findMergeablePairs(state.shapes);
    _radarHighlightNotifier?.state = pairs;
    state = state.copyWith(
      jokerInventory: JokerHandler.useRadar(state.jokerInventory),
      radarActive: true,
    );
    _incrementJokerUsed();
    unawaited(AnalyticsService.instance.logJokerUsed(JokerType.radar));
    _saveJokers();
    _radarTimer?.cancel();
    _radarTimer = Timer(_radarDuration, () {
      if (mounted) {
        state = state.copyWith(radarActive: false);
        _radarHighlightNotifier?.state = {};
      }
    });
  }

  @override
  void dispose() {
    _radarTimer?.cancel();
    super.dispose();
  }

  void addJokers(JokerType type, [int amount = 1]) {
    state = state.copyWith(
      jokerInventory: state.jokerInventory.add(type, amount),
    );
    _saveJokers();
  }

  void updateJokerInventory(JokerInventory inventory) {
    state = state.copyWith(jokerInventory: inventory);
    _saveJokers();
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }
}
