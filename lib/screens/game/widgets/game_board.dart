import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/game/logic/merge_detector.dart';
import 'package:shape_merge/game/models/game_state.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/screens/game/widgets/shape_widget.dart';

class GameBoard extends ConsumerStatefulWidget {
  final void Function(Offset position, Color color, int points)? onMerge;

  const GameBoard({super.key, this.onMerge});

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

  @override
  void dispose() {
    _snapBackCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final jokerMode = ref.watch(jokerModeProvider);

    return LayoutBuilder(builder: (context, constraints) {
      final boardSize = Size(constraints.maxWidth, constraints.maxHeight);
      ref.read(gameStateProvider.notifier).setBoardSize(boardSize);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          painter: _BoardBackgroundPainter(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final shape in gameState.shapes)
                _buildDraggableShape(shape, gameState, jokerMode, boardSize),
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
  ) {
    final isDragging = _draggingId == shape.id;
    final isSnappingBack = _snapBackId == shape.id && _snapBackCtrl != null && _snapBackCtrl!.isAnimating;
    final size = shapeSize(shape.level);

    var isHighlighted = false;
    if (_draggingId != null && _draggingId != shape.id) {
      final dragged = gameState.shapes.where((s) => s.id == _draggingId).firstOrNull;
      if (dragged != null) {
        isHighlighted = MergeDetector.canMerge(dragged, shape);
      }
    }

    double posX = shape.x;
    double posY = shape.y;
    if (isDragging && _dragOffset != null) {
      posX = _dragOffset!.dx;
      posY = _dragOffset!.dy;
    } else if (isSnappingBack && _snapBackFrom != null && _snapBackTo != null) {
      final t = Curves.easeOutCubic.transform(_snapBackCtrl!.value);
      posX = _snapBackFrom!.dx + (_snapBackTo!.dx - _snapBackFrom!.dx) * t;
      posY = _snapBackFrom!.dy + (_snapBackTo!.dy - _snapBackFrom!.dy) * t;
    }

    final left = posX - size / 2;
    final top = posY - size / 2;

    return Positioned(
      key: ValueKey(shape.id),
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _handleShapeTap(shape, jokerMode),
        onPanStart: (details) {
          if (jokerMode != JokerMode.none) return;
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
          setState(() {
            _dragOffset = Offset(
              (_dragOffset!.dx + details.delta.dx).clamp(0, boardSize.width),
              (_dragOffset!.dy + details.delta.dy).clamp(0, boardSize.height),
            );
          });
        },
        onPanEnd: (_) => _handleDrop(shape, boardSize),
        child: ShapeWidget(
          shape: shape,
          isDragging: isDragging,
          isHighlighted: isHighlighted,
        ),
      ),
    );
  }

  void _handleShapeTap(GameShape shape, JokerMode jokerMode) {
    final notifier = ref.read(gameStateProvider.notifier);
    switch (jokerMode) {
      case JokerMode.bomb:
        notifier.useBomb(shape);
        AudioService.instance.playBomb();
        ref.read(jokerModeProvider.notifier).state = JokerMode.none;
      case JokerMode.reducer:
        notifier.useReducer(shape);
        AudioService.instance.playReducer();
        ref.read(jokerModeProvider.notifier).state = JokerMode.none;
      case JokerMode.wildcard:
        notifier.spawnWildcard(shape.level);
        AudioService.instance.playWildcard();
        ref.read(jokerModeProvider.notifier).state = JokerMode.none;
      case JokerMode.none:
        break;
    }
  }

  void _handleDrop(GameShape shape, Size boardSize) {
    if (_draggingId != shape.id || _dragOffset == null) return;

    // Detect tap (moved less than 5px)
    final dragDist = (_dragOffset! - _dragStartOffset!).distance;
    final wasTap = dragDist < 5.0;

    final notifier = ref.read(gameStateProvider.notifier);
    final result = notifier.attemptMerge(shape, _dragOffset!, wasTap: wasTap);

    if (result.wasTap) {
      // Tap — do nothing, just reset
      setState(() {
        _draggingId = null;
        _dragOffset = null;
        _dragStartOffset = null;
      });
      return;
    }

    if (result.mergedShape != null) {
      // Merge success
      HapticFeedback.heavyImpact();
      AudioService.instance.playMerge();
      widget.onMerge?.call(
        Offset(result.mergedShape!.x, result.mergedShape!.y),
        result.mergedShape!.color,
        result.pointsEarned,
      );
      setState(() {
        _draggingId = null;
        _dragOffset = null;
        _dragStartOffset = null;
      });
    } else {
      // No merge — animate snap back to original position, then spawn happened in engine
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
      AudioService.instance.playSpawn();

      setState(() {
        _draggingId = null;
        _dragOffset = null;
        _dragStartOffset = null;
      });

      _snapBackCtrl!.forward();
    }
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
    nebulaPaint.color = const Color(0xFF6a11cb).withValues(alpha: 0.04);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.2), 80, nebulaPaint);
    nebulaPaint.color = const Color(0xFF2575fc).withValues(alpha: 0.03);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), 90, nebulaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
