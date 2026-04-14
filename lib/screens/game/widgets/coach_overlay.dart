import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/game_state_provider.dart';

part 'coach_painters.dart';

// ── Steps ─────────────────────────────────────────────────────

enum CoachStep {
  welcome,
  waitMerge,
  mergeDone,
  jokers,
  waitJokerLongPress,
  jokerDone,
  jokerUse,
  score,
  capacity,
  merges,
  complete,
}

// ── Global keys registry ──────────────────────────────────────

class CoachKeys {
  CoachKeys._();
  static final board = GlobalKey(debugLabel: 'coach_board');
  static final jokerBar = GlobalKey(debugLabel: 'coach_jokerBar');
  static final hudScore = GlobalKey(debugLabel: 'coach_hudScore');
  static final hudCapacity = GlobalKey(debugLabel: 'coach_hudCapacity');
  static final hudMerges = GlobalKey(debugLabel: 'coach_hudMerges');
}

// ── Overlay ───────────────────────────────────────────────────

class CoachOverlay extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  /// Key used to access state from anywhere (even siblings in a Stack).
  static final stateKey = GlobalKey<CoachOverlayState>();

  CoachOverlay({required this.onComplete}) : super(key: stateKey);

  /// Notifies the coach that the player just performed their first merge.
  static void notifyMerge() {
    stateKey.currentState?.onMerge();
  }

  /// Notifies the coach that the player long-pressed a joker.
  static void notifyJokerLongPress() {
    stateKey.currentState?.onJokerLongPress();
  }

  @override
  ConsumerState<CoachOverlay> createState() => CoachOverlayState();
}

class CoachOverlayState extends ConsumerState<CoachOverlay>
    with TickerProviderStateMixin {
  CoachStep _step = CoachStep.welcome;
  late final AnimationController _anim;
  late Animation<double> _fadeAnim;
  late final AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  void _advance(CoachStep next) {
    _anim.reverse().then((_) {
      if (!mounted) return;
      setState(() => _step = next);
      _anim.forward();
    });
  }

  void onMerge() {
    if (_step == CoachStep.waitMerge) {
      _advance(CoachStep.mergeDone);
    }
  }

  void onJokerLongPress() {
    if (_step == CoachStep.waitJokerLongPress) {
      _advance(CoachStep.jokerDone);
    }
  }

  void _onTap() {
    switch (_step) {
      case CoachStep.welcome:
        _advance(CoachStep.waitMerge);
      case CoachStep.waitMerge:
        return; // Must merge to advance
      case CoachStep.mergeDone:
        _advance(CoachStep.jokers);
      case CoachStep.jokers:
        _advance(CoachStep.waitJokerLongPress);
      case CoachStep.waitJokerLongPress:
        return; // Must long-press to advance
      case CoachStep.jokerDone:
        _advance(CoachStep.jokerUse);
      case CoachStep.jokerUse:
        _advance(CoachStep.score);
      case CoachStep.score:
        _advance(CoachStep.capacity);
      case CoachStep.capacity:
        _advance(CoachStep.merges);
      case CoachStep.merges:
        _advance(CoachStep.complete);
      case CoachStep.complete:
        widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (title, desc, targetKey, passThrough) = _stepContent(l10n);

    // Get spotlight rect for the target key if available
    Rect? spotlightRect;
    if (targetKey != null) {
      spotlightRect = _getRenderRect(targetKey);
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackH = constraints.maxHeight;
          return Stack(
            children: [
              // Dimmed background with spotlight cutout
              // When passThrough, IgnorePointer lets touches reach the game below
              IgnorePointer(
                ignoring: passThrough,
                child: GestureDetector(
                  onTap: _onTap,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, _) => CustomPaint(
                      painter: _SpotlightPainter(
                        spotlightRect: spotlightRect,
                        passThrough: passThrough,
                        pulse: _pulseAnim.value,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),

              // Floating card with message (Positioned must be direct child of Stack)
              _buildCard(title, desc, l10n, spotlightRect, stackH),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(
    String title,
    String desc,
    AppLocalizations l10n,
    Rect? spotlightRect,
    double stackH,
  ) {
    final screenW = MediaQuery.of(context).size.width;
    const arrowSize = 10.0;
    const gap = 6.0; // space between spotlight border and bubble

    if (spotlightRect == null) {
      // No spotlight → centered floating bubble
      return Positioned(
        left: 24,
        right: 24,
        top: stackH * 0.35,
        child: _bubble(title, desc, l10n, arrowSide: _ArrowSide.none),
      );
    }

    // If the target is very tall (like the board), find free spot among shapes
    final isLargeTarget = spotlightRect.height > stackH * 0.35;
    if (isLargeTarget) {
      const bubbleW = 250.0;
      final freePos = _findFreeSpot(spotlightRect, bubbleW);
      return Positioned(
        left: freePos.dx,
        top: freePos.dy,
        width: bubbleW,
        child: _bubble(title, desc, l10n, arrowSide: _ArrowSide.none),
      );
    }

    final showBelow = spotlightRect.center.dy < stackH * 0.5;

    // Horizontal: try to center on the spotlight, but clamp to screen
    const hPad = 12.0;
    const maxBubbleWidth = 260.0;
    final bubbleWidth = maxBubbleWidth.clamp(0.0, screenW - hPad * 2);
    final left = (spotlightRect.center.dx - bubbleWidth / 2)
        .clamp(hPad, screenW - bubbleWidth - hPad);

    // Arrow horizontal offset relative to bubble left
    final arrowDx = (spotlightRect.center.dx - left).clamp(20.0, bubbleWidth - 20.0);

    if (showBelow) {
      return Positioned(
        left: left,
        width: bubbleWidth,
        top: spotlightRect.bottom + gap + arrowSize, // just below spotlight
        child: _bubble(title, desc, l10n,
            arrowSide: _ArrowSide.top, arrowOffset: arrowDx),
      );
    } else {
      // Card above the element — use stackH (real layout height, not screen height)
      return Positioned(
        left: left,
        width: bubbleWidth,
        bottom: stackH - spotlightRect.top + gap + arrowSize,
        child: _bubble(title, desc, l10n,
            arrowSide: _ArrowSide.bottom, arrowOffset: arrowDx),
      );
    }
  }

  Widget _bubble(
    String title,
    String desc,
    AppLocalizations l10n, {
    required _ArrowSide arrowSide,
    double arrowOffset = 0,
  }) {
    const arrowSize = 10.0;

    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.orbCyan.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: 0.10),
                blurRadius: 30,
                spreadRadius: -2,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _BubblePainter(
              arrowSide: arrowSide,
              arrowOffset: arrowOffset,
              arrowSize: arrowSize,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: arrowSide == _ArrowSide.top ? 14 + arrowSize : 14,
                bottom: arrowSide == _ArrowSide.bottom ? 14 + arrowSize : 14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with gem icon
                  Row(
                    children: [
                      Text(
                        '◆ ',
                        style: TextStyle(
                          fontSize: AppTheme.fontSmall,
                          color: AppTheme.orbCyan.withValues(alpha: 0.9),
                        ),
                      ),
                      Flexible(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppTheme.gold, AppTheme.goldLight],
                          ).createShader(bounds),
                          child: Text(
                            title,
                            style: AppTheme.titleStyle(AppTheme.fontBody).copyWith(
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Text(
                    desc,
                    style: AppTheme.hudStyle.copyWith(
                      fontSize: AppTheme.fontSmall,
                      color: Colors.white.withValues(alpha: 0.90),
                      height: 1.35,
                    ),
                  ),
                  if (_step != CoachStep.waitMerge &&
                      _step != CoachStep.waitJokerLongPress) ...[
                    const SizedBox(height: 8),
                    // Pulsing "tap to continue" indicator
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, _) => Opacity(
                        opacity: 0.3 + _pulseAnim.value * 0.35,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              size: 13,
                              color: AppTheme.orbCyan.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.coachTapContinue,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.orbCyan,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Scan candidate positions inside [boardRect] and return the one
  /// with the most distance to all shapes (no overlap guaranteed if possible).
  Offset _findFreeSpot(Rect boardRect, double bubbleW) {
    final gameState = ref.read(gameStateProvider);
    final shapes = gameState.shapes;
    const bubbleH = 110.0; // estimated bubble height with 3 lines of text
    const shapePad = 12.0;

    // Shape centers in screen coordinates
    final shapeCircles = shapes.map((s) {
      final r = shapeSize(s.level) / 2 + shapePad;
      return (
        cx: boardRect.left + s.x,
        cy: boardRect.top + s.y,
        r: r,
      );
    }).toList();

    const inset = 8.0;
    final xMin = boardRect.left + inset;
    final yMin = boardRect.top + inset;
    final xMax = boardRect.right - bubbleW - inset;
    final yMax = boardRect.bottom - bubbleH - inset;

    if (xMax <= xMin || yMax <= yMin) {
      return Offset(boardRect.center.dx - bubbleW / 2, boardRect.center.dy - bubbleH / 2);
    }

    // Scan 20×20 grid for best non-overlapping position
    const steps = 20;
    final stepX = (xMax - xMin) / steps;
    final stepY = (yMax - yMin) / steps;

    var bestPos = Offset(xMin, yMin);
    var bestDist = -1.0;

    for (var gx = 0; gx <= steps; gx++) {
      for (var gy = 0; gy <= steps; gy++) {
        final x = xMin + gx * stepX;
        final y = yMin + gy * stepY;
        final bubbleRect = Rect.fromLTWH(x, y, bubbleW, bubbleH);

        // Check minimum distance from bubble rect to each shape circle
        var minDist = double.infinity;
        for (final s in shapeCircles) {
          // Closest point on bubbleRect to shape center
          final cx = s.cx.clamp(bubbleRect.left, bubbleRect.right);
          final cy = s.cy.clamp(bubbleRect.top, bubbleRect.bottom);
          final dist = math.sqrt((cx - s.cx) * (cx - s.cx) + (cy - s.cy) * (cy - s.cy)) - s.r;
          if (dist < minDist) minDist = dist;
        }

        // dist > 0 means no overlap; pick the spot with the most clearance
        if (minDist > bestDist) {
          bestDist = minDist;
          bestPos = Offset(x, y);
        }
      }
    }

    return bestPos;
  }

  (String title, String desc, GlobalKey? targetKey, bool passThrough) _stepContent(
    AppLocalizations l10n,
  ) {
    return switch (_step) {
      CoachStep.welcome => (
          l10n.coachWelcome,
          l10n.coachWelcomeDesc,
          null,
          false,
        ),
      CoachStep.waitMerge => (
          l10n.coachWaitMerge,
          l10n.coachWaitMergeDesc,
          CoachKeys.board,
          true, // Let player interact with the board
        ),
      CoachStep.mergeDone => (
          l10n.coachMergeDone,
          l10n.coachMergeDoneDesc,
          null,
          false,
        ),
      CoachStep.jokers => (
          l10n.coachJokers,
          l10n.coachJokersDesc,
          CoachKeys.jokerBar,
          false,
        ),
      CoachStep.waitJokerLongPress => (
          l10n.coachWaitJokerLongPress,
          l10n.coachWaitJokerLongPressDesc,
          CoachKeys.jokerBar,
          true, // Let player long-press joker
        ),
      CoachStep.jokerDone => (
          l10n.coachJokerDone,
          l10n.coachJokerDoneDesc,
          null,
          false,
        ),
      CoachStep.jokerUse => (
          l10n.coachJokerUse,
          l10n.coachJokerUseDesc,
          CoachKeys.jokerBar,
          false,
        ),
      CoachStep.score => (
          l10n.coachScore,
          l10n.coachScoreDesc,
          CoachKeys.hudScore,
          false,
        ),
      CoachStep.capacity => (
          l10n.coachCapacity,
          l10n.coachCapacityDesc,
          CoachKeys.hudCapacity,
          false,
        ),
      CoachStep.merges => (
          l10n.coachMerges,
          l10n.coachMergesDesc,
          CoachKeys.hudMerges,
          false,
        ),
      CoachStep.complete => (
          l10n.coachComplete,
          l10n.coachCompleteDesc,
          null,
          false,
        ),
    };
  }

  Rect? _getRenderRect(GlobalKey key) {
    final rb = key.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null || !rb.hasSize) return null;
    final pos = rb.localToGlobal(Offset.zero);
    return pos & rb.size;
  }
}

