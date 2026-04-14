import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Offset? _dragOffset;
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
            HapticFeedback.lightImpact();
            ref.read(jokerEmptyTapProvider.notifier).state++;
          }
        },
        child: CustomPaint(
          painter: _BoardBackgroundPainter(),
          child: Stack(
            clipBehavior: Clip.hardEdge, // Force les formes à rester dans la zone
            children: [
              for (final shape in gameState.shapes)
                _buildDraggableShape(shape, gameState, jokerMode, boardSize, radarHighlights),
            ],
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
    final size = shapeSize(shape.level);

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
    if (isDragging && _dragOffset != null) {
      posX = _dragOffset!.dx;
      posY = _dragOffset!.dy;
    } else if (isSnappingBack && _snapBackFrom != null && _snapBackTo != null) {
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

    final left = posX - size / 2;
    final top = posY - size / 2;

    Widget shapeChild = ShapeWidget(
      shape: shape,
      isDragging: isDragging,
      isHighlighted: isHighlighted,
      isRadarHighlighted: isRadarHighlighted,
      radarGroupIndex: radarGroupIndex,
      isMergeResult: shape.id == _recentMergedId,
    );
    if (extraScale != 1.0) {
      shapeChild = Transform.scale(scale: extraScale, child: shapeChild);
    }

    return Positioned(
      key: ValueKey(shape.id),
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _handleShapeTap(shape, jokerMode),
        onPanStart: (details) {
          if (jokerMode != JokerMode.none && jokerMode != JokerMode.radar) {
            // Joker actif (sauf radar) → radiation pour rappeler de taper une forme
            HapticFeedback.lightImpact();
            ref.read(jokerEmptyTapProvider.notifier).state++;
            return;
          }
          if (jokerMode == JokerMode.radar) return;
          if (_flyToShapeId != null) return; // Block during fly-to
          // Cancel any running snap-back
          _snapBackCtrl?.stop();
          _snapBackId = null;
          HapticFeedback.lightImpact();
          setState(() {
            _draggingId = shape.id;
            _dragStartOffset = Offset(shape.x, shape.y);
            _dragOffset = Offset(shape.x, shape.y);
          });
        },
        onPanUpdate: (details) {
          if (_draggingId != shape.id) return;
          final shapeSize = size;
          final halfSize = shapeSize / 2;
          setState(() {
            _dragOffset = Offset(
              (_dragOffset!.dx + details.delta.dx).clamp(halfSize, boardSize.width - halfSize),
              (_dragOffset!.dy + details.delta.dy).clamp(halfSize, boardSize.height - halfSize),
            );
          });
        },
        onPanEnd: (_) => _handleDrop(shape, boardSize),
        child: shapeChild,
      ),
    );
  }

  void _handleShapeTap(GameShape shape, JokerMode jokerMode) {
    final notifier = ref.read(gameStateProvider.notifier);
    switch (jokerMode) {
      case JokerMode.bomb:
        notifier.useBomb(shape);
        AudioService.instance.playBomb();
        widget.onJokerUsed?.call(Offset(shape.x, shape.y), JokerType.bomb);
        ref.read(jokerModeProvider.notifier).state = JokerMode.none;
      case JokerMode.reducer:
        notifier.useReducer(shape);
        AudioService.instance.playReducer();
        widget.onJokerUsed?.call(Offset(shape.x, shape.y), JokerType.reducer);
        ref.read(jokerModeProvider.notifier).state = JokerMode.none;
      case JokerMode.wildcard:
        notifier.spawnWildcard(shape.level);
        AudioService.instance.playWildcard();
        widget.onJokerUsed?.call(Offset(shape.x, shape.y), JokerType.wildcard);
        ref.read(jokerModeProvider.notifier).state = JokerMode.none;
      case JokerMode.evolution:
        final evoResult = JokerHandler.useEvolution(
          shape, ref.read(gameStateProvider).shapes, ref.read(gameStateProvider).jokerInventory);
        notifier.useEvolution(shape);
        if (evoResult.evolvedShape != null) {
          AudioService.instance.playMerge();
          HapticFeedback.heavyImpact();
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
    if (_draggingId != shape.id || _dragOffset == null) return;

    // Detect tap (moved less than 5px)
    final dragDist = (_dragOffset! - _dragStartOffset!).distance;
    final wasTap = dragDist < 5.0;

    if (wasTap) {
      setState(() {
        _draggingId = null;
        _dragOffset = null;
        _dragStartOffset = null;
      });
      return;
    }

    // Check for merge target before committing
    final gameState = ref.read(gameStateProvider);
    final target = MergeDetector.findBestTarget(shape, gameState.shapes, _dragOffset!);

    if (target != null) {
      // Fly-to animation → then merge
      _startFlyToMerge(shape, target, _dragOffset!);
    } else {
      // No merge — snap back + spawn
      final notifier = ref.read(gameStateProvider.notifier);
      notifier.attemptMerge(shape, _dragOffset!, wasTap: false);

      final fromOffset = _dragOffset!;
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

      HapticFeedback.selectionClick();
      AudioService.instance.playMergeAbort();

      setState(() {
        _draggingId = null;
        _dragOffset = null;
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
      _dragOffset = null;
      _dragStartOffset = null;
    });

    // Play merge sound at the start of the fly animation (not after)
    AudioService.instance.playMerge();

    _flyToCtrl!.forward();
  }

  void _completeMerge() {
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
        HapticFeedback.heavyImpact();
        HapticFeedback.heavyImpact();
      } else if (result.comboCount >= 3) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
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

class _BoardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);

    // Stars (same technique as SpaceBackground)
    for (var i = 0; i < 50; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.3 + rng.nextDouble() * 1.2;
      final brightness = 0.3 + rng.nextDouble() * 0.5;

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
