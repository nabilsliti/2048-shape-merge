import 'package:flutter/material.dart';
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

class _GameBoardState extends ConsumerState<GameBoard> {
  String? _draggingId;
  Offset? _dragOffset;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final jokerMode = ref.watch(jokerModeProvider);

    return LayoutBuilder(builder: (context, constraints) {
      final boardSize = Size(constraints.maxWidth, constraints.maxHeight);
      ref.read(gameStateProvider.notifier).setBoardSize(boardSize);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: CustomPaint(
            painter: _StarfieldPainter(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final shape in gameState.shapes)
                  _buildDraggableShape(shape, gameState, jokerMode, boardSize),
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
  ) {
    final isDragging = _draggingId == shape.id;
    final size = shapeSize(shape.level);

    // Check if this shape is a valid merge target for the dragged shape
    var isHighlighted = false;
    if (_draggingId != null && _draggingId != shape.id) {
      final List<GameShape> allShapes = gameState.shapes;
      final dragged = allShapes
          .where((s) => s.id == _draggingId)
          .firstOrNull;
      if (dragged != null) {
        isHighlighted = MergeDetector.canMerge(dragged, shape);
      }
    }

    final left = (isDragging ? _dragOffset?.dx ?? shape.x : shape.x) - size / 2;
    final top = (isDragging ? _dragOffset?.dy ?? shape.y : shape.y) - size / 2;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _handleShapeTap(shape, jokerMode),
        onPanStart: (details) {
          if (jokerMode != JokerMode.none) return;
          setState(() {
            _draggingId = shape.id;
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
        notifier.spawnWildcard();
        AudioService.instance.playWildcard();
        ref.read(jokerModeProvider.notifier).state = JokerMode.none;
      case JokerMode.none:
        break;
    }
  }

  void _handleDrop(GameShape shape, Size boardSize) {
    if (_draggingId != shape.id || _dragOffset == null) return;

    final notifier = ref.read(gameStateProvider.notifier);
    final result = notifier.attemptMerge(shape, _dragOffset!);

    if (result.mergedShape != null) {
      AudioService.instance.playMerge();
      widget.onMerge?.call(
        Offset(result.mergedShape!.x, result.mergedShape!.y),
        result.mergedShape!.color,
        result.pointsEarned,
      );
    } else {
      AudioService.instance.playSpawn();
    }

    setState(() {
      _draggingId = null;
      _dragOffset = null;
    });
  }
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.15);
    // Simple static starfield
    final rng = [
      0.1, 0.3, 0.5, 0.7, 0.9, 0.15, 0.45, 0.65, 0.85, 0.25,
      0.35, 0.55, 0.75, 0.95, 0.05, 0.2, 0.4, 0.6, 0.8, 0.12,
    ];
    for (var i = 0; i < 20; i++) {
      final x = rng[i] * size.width;
      final y = rng[(i + 7) % 20] * size.height;
      final r = (i % 3 + 1) * 0.5;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
