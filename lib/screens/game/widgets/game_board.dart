import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/game/logic/joker_handler.dart';
import 'package:shape_merge/game/logic/merge_detector.dart';
import 'package:shape_merge/game/models/game_state.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/audio_provider.dart';
import 'package:shape_merge/providers/shape_pack_provider.dart';
import 'package:shape_merge/screens/game/widgets/shape_widget.dart';

class GameBoard extends ConsumerStatefulWidget {
  final void Function(Offset position, Color color, int points, int comboCount)? onMerge;
  final void Function(Offset position, JokerType jokerType)? onJokerUsed;

  const GameBoard({super.key, this.onMerge, this.onJokerUsed});

  @override
  ConsumerState<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends ConsumerState<GameBoard> with TickerProviderStateMixin {
  String? _draggingId;
  // Drag offset is published via a ValueNotifier so that pan updates at 60fps
  // do not trigger a rebuild of the whole Stack (32 shapes). Only the dragged
  // shape's Positioned subtree listens to it.
  final ValueNotifier<Offset?> _dragOffsetNotifier = ValueNotifier<Offset?>(null);
  Offset? _dragStartOffset; // original shape position before drag

  // Snap-back animation state
  AnimationController? _snapBackCtrl;
  String? _snapBackId;
  Offset? _snapBackFrom;
  Offset? _snapBackTo;

  // Fly-to-merge animation state
  AnimationController? _flyToCtrl;
  String? _flyToShapeId;
  String? _flyToTargetId;
  Offset? _flyFrom;
  Offset? _flyTo;
  GameShape? _pendingDragShape;
  String? _recentMergedId;

  @override
  void dispose() {
    _snapBackCtrl?.dispose();
    _flyToCtrl?.dispose();
    _dragOffsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final jokerMode = ref.watch(jokerModeProvider);
    final radarHighlights = ref.watch(radarHighlightProvider);

    return LayoutBuilder(builder: (context, constraints) {
      final boardSize = Size(constraints.maxWidth, constraints.maxHeight);
      ref.read(gameStateProvider.notifier).setBoardSize(boardSize);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Tap on empty space while joker is active → trigger radiation
          if (jokerMode != JokerMode.none) {
            ref.read(vibrationProvider.notifier).vibrateLight();
            ref.read(jokerEmptyTapProvider.notifier).state++;
          }
        },
        child: CustomPaint(
          painter: const _BoardBackgroundPainter(),
          child: RepaintBoundary(
            child: Stack(
              clipBehavior: Clip.hardEdge, // Force les formes à rester dans la zone
              children: [
                for (final shape in gameState.shapes)
                  _buildDraggableShape(shape, gameState, jokerMode, boardSize, radarHighlights),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDraggableShape(
    GameShape shape,
    GameState gameState,
    JokerMode jokerMode,
    Size boardSize,
    Map<String, int> radarHighlights,
  ) {
    final isDragging = _draggingId == shape.id;
    final isSnappingBack = _snapBackId == shape.id && _snapBackCtrl != null && _snapBackCtrl!.isAnimating;
    final isFlyingTo = _flyToShapeId == shape.id && _flyToCtrl != null && _flyToCtrl!.isAnimating;
    final isFlyTarget = _flyToTargetId == shape.id && _flyToCtrl != null && _flyToCtrl!.isAnimating;
    final size = ShapeSizing.forLevel(shape.level);

    var isHighlighted = false;
    if (_draggingId != null && _draggingId != shape.id) {
      final dragged = gameState.shapes.where((s) => s.id == _draggingId).firstOrNull;
      if (dragged != null) {
        isHighlighted = MergeDetector.canMerge(dragged, shape);
      }
    }
    final isRadarHighlighted = radarHighlights.containsKey(shape.id);
    final radarGroupIndex = radarHighlights[shape.id] ?? -1;

    double posX = shape.x;
    double posY = shape.y;
    double extraScale = 1.0;
    if (isSnappingBack && _snapBackFrom != null && _snapBackTo != null) {
      final t = Curves.easeOutCubic.transform(_snapBackCtrl!.value);
      posX = _snapBackFrom!.dx + (_snapBackTo!.dx - _snapBackFrom!.dx) * t;
      posY = _snapBackFrom!.dy + (_snapBackTo!.dy - _snapBackFrom!.dy) * t;
    } else if (isFlyingTo && _flyFrom != null && _flyTo != null) {
      final t = Curves.easeInOutCubic.transform(_flyToCtrl!.value);
      posX = _flyFrom!.dx + (_flyTo!.dx - _flyFrom!.dx) * t;
      posY = _flyFrom!.dy + (_flyTo!.dy - _flyFrom!.dy) * t;
      extraScale = 1.0 - 0.4 * t; // shrink as it approaches target
    } else if (isFlyTarget) {
      final t = Curves.easeOutCubic.transform(_flyToCtrl!.value);
      extraScale = 1.0 + 0.15 * t; // grow slightly (anticipation)
    }

    Widget shapeChild = ShapeWidget(
      shape: shape,
      isDragging: isDragging,
      isHighlighted: isHighlighted,
      isRadarHighlighted: isRadarHighlighted,
      radarGroupIndex: radarGroupIndex,
      isMergeResult: shape.id == _recentMergedId,
      shapePack: ref.watch(shapePackProvider),
    );
    if (extraScale != 1.0) {
      shapeChild = Transform.scale(scale: extraScale, child: shapeChild);
    }

    final gestureDetector = GestureDetector(
      onTap: () {
        if (_flyToShapeId != null) return; // Block taps during merge animation
        _handleShapeTap(shape, jokerMode);
      },
      onPanStart: (details) {
        if (jokerMode != JokerMode.none && jokerMode != JokerMode.radar) {
          // Joker actif (sauf radar) → radiation pour rappeler de taper une forme
          ref.read(vibrationProvider.notifier).vibrateLight();
          ref.read(jokerEmptyTapProvider.notifier).state++;
          return;
        }
        if (jokerMode == JokerMode.radar) return;
        if (_flyToShapeId != null) return; // Block during fly-to
        // Cancel any running snap-back
        _snapBackCtrl?.stop();
        _snapBackId = null;
        ref.read(vibrationProvider.notifier).vibrateLight();
        _dragOffsetNotifier.value = Offset(shape.x, shape.y);
        setState(() {
          _draggingId = shape.id;
          _dragStartOffset = Offset(shape.x, shape.y);
        });
      },
      onPanUpdate: (details) {
        if (_draggingId != shape.id) return;
        final current = _dragOffsetNotifier.value;
        if (current == null) return;
        final halfSize = size / 2;
        // Update notifier only — no setState, only the dragged shape's
        // ValueListenableBuilder rebuilds (isolates 60fps work).
        _dragOffsetNotifier.value = Offset(
          (current.dx + details.delta.dx).clamp(halfSize, boardSize.width - halfSize),
          (current.dy + details.delta.dy).clamp(halfSize, boardSize.height - halfSize),
        );
      },
      onPanEnd: (_) => _handleDrop(shape, boardSize),
      child: shapeChild,
    );

    // Always wrap in ValueListenableBuilder so the widget tree structure stays
    // identical whether or not this shape is being dragged. Changing the
    // structure mid-gesture would break the active GestureDetector.
    // The builder is cheap (only rebuilds a Positioned); the expensive
    // gestureDetector subtree is passed via `child:` and preserved.
    return ValueListenableBuilder<Offset?>(
      key: ValueKey(shape.id),
      valueListenable: _dragOffsetNotifier,
      builder: (context, dragOffset, child) {
        var dx = posX;
        var dy = posY;
        if (_draggingId == shape.id && dragOffset != null) {
          dx = dragOffset.dx;
          dy = dragOffset.dy;
        }
        return Positioned(
          left: dx - size / 2,
          top: dy - size / 2,
          child: child!,
        );
      },
      child: gestureDetector,
    );
  }

  void _handleShapeTap(GameShape shape, JokerMode jokerMode) {
    final notifier = ref.read(gameStateProvider.notifier);
    switch (jokerMode) {
      case JokerMode.bomb:
        notifier.useBomb(shape);
        AudioService.instance.playBomb();
        ref.read(vibrationProvider.notifier).vibrate();
        widget.onJokerUsed?.call(Offset(shape.x, shape.y), JokerType.bomb);
        ref.read(jokerModeProvider.notifier).state = JokerMode.none;
      case JokerMode.reducer:
        notifier.useReducer(shape);
        AudioService.instance.playReducer();
        ref.read(vibrationProvider.notifier).vibrateMedium();
        widget.onJokerUsed?.call(Offset(shape.x, shape.y), JokerType.reducer);
        ref.read(jokerModeProvider.notifier).state = JokerMode.none;
      case JokerMode.wildcard:
        notifier.spawnWildcard(shape.level);
        AudioService.instance.playWildcard();
        ref.read(vibrationProvider.notifier).vibrateMedium();
        widget.onJokerUsed?.call(Offset(shape.x, shape.y), JokerType.wildcard);
        ref.read(jokerModeProvider.notifier).state = JokerMode.none;
      case JokerMode.evolution:
        final evoResult = JokerHandler.useEvolution(
          shape, ref.read(gameStateProvider).shapes, ref.read(gameStateProvider).jokerInventory);
        notifier.useEvolution(shape);
        if (evoResult.evolvedShape != null) {
          AudioService.instance.playEvolution();
          ref.read(vibrationProvider.notifier).vibrate();
          widget.onJokerUsed?.call(Offset(shape.x, shape.y), JokerType.evolution);
          widget.onMerge?.call(
            Offset(evoResult.evolvedShape!.x, evoResult.evolvedShape!.y),
            evoResult.evolvedShape!.color,
            evoResult.scoreBonus,
            0, // evolution joker doesn't count as combo
          );
        }
        ref.read(jokerModeProvider.notifier).state = JokerMode.none;
      case JokerMode.megaBomb:
        notifier.useMegaBomb(shape);
        AudioService.instance.playBomb();
        ref.read(vibrationProvider.notifier).vibrate();
        widget.onJokerUsed?.call(Offset(shape.x, shape.y), JokerType.megaBomb);
        ref.read(jokerModeProvider.notifier).state = JokerMode.none;
      case JokerMode.radar:
        // Radar activates on tap of the orb, not a shape tap
        break;
      case JokerMode.none:
        break;
    }
  }

  void _handleDrop(GameShape shape, Size boardSize) {
    final dragOffset = _dragOffsetNotifier.value;
    if (_draggingId != shape.id || dragOffset == null) return;

    // Detect tap (moved less than 5px)
    final dragDist = (dragOffset - _dragStartOffset!).distance;
    final wasTap = dragDist < 5.0;

    if (wasTap) {
      _dragOffsetNotifier.value = null;
      setState(() {
        _draggingId = null;
        _dragStartOffset = null;
      });
      return;
    }

    // Check for merge target before committing
    final gameState = ref.read(gameStateProvider);
    final target = MergeDetector.findBestTarget(shape, gameState.shapes, dragOffset);

    if (target != null) {
      // Fly-to animation → then merge
      _startFlyToMerge(shape, target, dragOffset);
    } else {
      // No merge — snap back + spawn
      final notifier = ref.read(gameStateProvider.notifier);
      notifier.attemptMerge(shape, dragOffset, wasTap: false);

      final fromOffset = dragOffset;
      final toOffset = _dragStartOffset!;

      _snapBackCtrl?.dispose();
      _snapBackCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      );
      _snapBackId = shape.id;
      _snapBackFrom = fromOffset;
      _snapBackTo = toOffset;

      _snapBackCtrl!.addListener(() => setState(() {}));
      _snapBackCtrl!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _snapBackId = null;
            _snapBackFrom = null;
            _snapBackTo = null;
          });
        }
      });

      ref.read(vibrationProvider.notifier).vibrateLight();
      AudioService.instance.playMergeAbort();

      _dragOffsetNotifier.value = null;
      setState(() {
        _draggingId = null;
        _dragStartOffset = null;
      });

      _snapBackCtrl!.forward();
    }
  }

  // ── Fly-to-merge animation ──────────────────────────────────────────────

  void _startFlyToMerge(GameShape dragged, GameShape target, Offset fromPos) {
    _flyToCtrl?.dispose();
    _flyToCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _flyToShapeId = dragged.id;
    _flyToTargetId = target.id;
    _flyFrom = fromPos;
    _flyTo = Offset(target.x, target.y);
    _pendingDragShape = dragged;

    _flyToCtrl!.addListener(() => setState(() {}));
    _flyToCtrl!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completeMerge();
      }
    });

    setState(() {
      _draggingId = null;
      _dragStartOffset = null;
    });
    _dragOffsetNotifier.value = null;

    // Play merge sound at the start of the fly animation (not after)
    AudioService.instance.playMerge();

    _flyToCtrl!.forward();
  }

  void _completeMerge() {
    if (_pendingDragShape == null || _flyTo == null) {
      // Safety: clear animation state if something went wrong
      setState(() {
        _flyToShapeId = null;
        _flyToTargetId = null;
        _flyFrom = null;
        _flyTo = null;
        _pendingDragShape = null;
      });
      return;
    }
    final notifier = ref.read(gameStateProvider.notifier);
    final result = notifier.attemptMerge(
      _pendingDragShape!,
      _flyTo!,
      wasTap: false,
    );

    if (result.mergedShape != null) {
      _recentMergedId = result.mergedShape!.id;
      // Progressive haptic: heavier on higher combos
      if (result.comboCount >= 5) {
        ref.read(vibrationProvider.notifier).vibrate();
        ref.read(vibrationProvider.notifier).vibrate();
      } else if (result.comboCount >= 3) {
        ref.read(vibrationProvider.notifier).vibrate();
      } else {
        ref.read(vibrationProvider.notifier).vibrateMedium();
      }
      // Progressive sound (combo only — basic merge already played at fly start)
      if (result.comboCount >= 3) {
        AudioService.instance.playCombo(result.comboCount);
      }
      widget.onMerge?.call(
        Offset(result.mergedShape!.x, result.mergedShape!.y),
        result.mergedShape!.color,
        result.pointsEarned,
        result.comboCount,
      );
    }

    setState(() {
      _flyToShapeId = null;
      _flyToTargetId = null;
      _flyFrom = null;
      _flyTo = null;
      _pendingDragShape = null;
    });
  }
}

class _Star {
  const _Star({
    required this.fx,
    required this.fy,
    required this.r,
    required this.brightness,
  });
  final double fx; // 0..1
  final double fy; // 0..1
  final double r;
  final double brightness;
}

class _BoardBackgroundPainter extends CustomPainter {
  const _BoardBackgroundPainter();

  // Stars are computed once and reused across paints / instances.
  static final List<_Star> _stars = _generateStars();

  static List<_Star> _generateStars() {
    final rng = Random(42);
    return List.generate(50, (_) {
      return _Star(
        fx: rng.nextDouble(),
        fy: rng.nextDouble(),
        r: 0.3 + rng.nextDouble() * 1.2,
        brightness: 0.3 + rng.nextDouble() * 0.5,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Stars (same technique as SpaceBackground)
    for (final star in _stars) {
      final x = star.fx * size.width;
      final y = star.fy * size.height;
      final r = star.r;
      final brightness = star.brightness;

      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: brightness * 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 3);
      canvas.drawCircle(Offset(x, y), r * 2, glowPaint);

      final starPaint = Paint()..color = Colors.white.withValues(alpha: brightness);
      canvas.drawCircle(Offset(x, y), r * 0.5, starPaint);
    }

    // Nebula glow
    final nebulaPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    nebulaPaint.color = AppTheme.bgTop.withValues(alpha: 0.04);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.2), 80, nebulaPaint);
    nebulaPaint.color = AppTheme.bgBot.withValues(alpha: 0.03);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), 90, nebulaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
