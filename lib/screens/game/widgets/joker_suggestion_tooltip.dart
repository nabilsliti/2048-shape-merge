import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/game_state_provider.dart';

/// Tooltip that floats above the joker bar, pointing to the suggested joker.
/// Uses the same design as coach overlay bubbles.
/// Must be placed inside the game screen's main Stack (not inside a ClipRRect).
class JokerSuggestionTooltip extends ConsumerStatefulWidget {
  const JokerSuggestionTooltip({super.key});

  @override
  ConsumerState<JokerSuggestionTooltip> createState() =>
      _JokerSuggestionTooltipState();
}

class _JokerSuggestionTooltipState extends ConsumerState<JokerSuggestionTooltip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  JokerType? _visibleType;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Compute the center X of the joker orb in screen coordinates.
  /// Replicates Row(spaceEvenly) layout with 7 children (6 orbs + 1 separator).
  double _orbCenterX(JokerType type, double screenWidth) {
    const hPad = 6.0; // Padding(symmetric horizontal: 6)
    const orbW = 48.0; // orbSize(34) + 14
    const sepW = 8.0; // separator column approximate intrinsic width
    const widths = [orbW, orbW, orbW, sepW, orbW, orbW, orbW];

    final barInnerW = screenWidth - hPad * 2;
    const totalChildW = orbW * 6 + sepW;
    final gap = (barInnerW - totalChildW) / (widths.length + 1);

    final idx = switch (type) {
      JokerType.bomb => 0,
      JokerType.wildcard => 1,
      JokerType.reducer => 2,
      JokerType.radar => 4,
      JokerType.evolution => 5,
      JokerType.megaBomb => 6,
    };

    var x = hPad + gap * (idx + 1);
    for (var j = 0; j < idx; j++) {
      x += widths[j];
    }
    x += widths[idx] / 2;
    return x;
  }

  String _localizeReason(AppLocalizations l10n, JokerType type) {
    return switch (type) {
      JokerType.bomb => l10n.jokerSuggestHighBomb,
      JokerType.wildcard => l10n.jokerSuggestWildcard,
      JokerType.reducer => l10n.jokerSuggestReducer,
      JokerType.radar => l10n.jokerSuggestRadar,
      JokerType.evolution => l10n.jokerSuggestEvolution,
      JokerType.megaBomb => l10n.jokerSuggestMegaBomb,
    };
  }

  @override
  Widget build(BuildContext context) {
    final suggestedType = ref.watch(jokerSuggestionProvider);

    // Show/hide logic
    if (suggestedType != null && _visibleType != suggestedType) {
      _visibleType = suggestedType;
      _ctrl.forward(from: 0);
    } else if (suggestedType == null && _visibleType != null) {
      _ctrl.reverse().then((_) {
        if (mounted) setState(() => _visibleType = null);
      });
    }

    if (_visibleType == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final orbCenterX = _orbCenterX(_visibleType!, screenWidth);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeOutBack.transform(_ctrl.value.clamp(0.0, 1.0));
        if (t == 0) return const SizedBox.shrink();

        const jokerBarArea = 56.0;
        const arrowH = 10.0;
        const tooltipW = 220.0;

        final tooltipLeft =
            (orbCenterX - tooltipW / 2).clamp(4.0, screenWidth - tooltipW - 4);
        // Arrow points exactly to orbCenterX
        final arrowLeft = orbCenterX - tooltipLeft;

        return Positioned(
          left: tooltipLeft,
          bottom: jokerBarArea + arrowH - 6,
          child: IgnorePointer(
            child: Opacity(
              opacity: _ctrl.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.7 + t * 0.3,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: tooltipW,
                  child: _CoachBubble(
                    text: _localizeReason(l10n, _visibleType!),
                    arrowOffset: arrowLeft,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Coach-style bubble with bottom arrow, matching coach overlay design.
class _CoachBubble extends StatelessWidget {
  final String text;
  final double arrowOffset;

  const _CoachBubble({required this.text, required this.arrowOffset});

  @override
  Widget build(BuildContext context) {
    const arrowSize = 10.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
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
        painter: _CoachBubblePainter(
          arrowOffset: arrowOffset,
          arrowSize: arrowSize,
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 10,
            right: 10,
            top: 8,
            bottom: 8 + arrowSize,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_rounded,
                size: 14,
                color: AppTheme.gold.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  text,
                  style: AppTheme.hudStyle.copyWith(
                    fontSize: AppTheme.fontMini,
                    color: Colors.white.withValues(alpha: 0.90),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter matching coach overlay's _BubblePainter — bottom arrow variant.
class _CoachBubblePainter extends CustomPainter {
  final double arrowOffset;
  final double arrowSize;

  _CoachBubblePainter({required this.arrowOffset, required this.arrowSize});

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 8.0;

    final bodyBottom = size.height - arrowSize;
    final bodyRect = Rect.fromLTWH(0, 0, size.width, bodyBottom);
    final tipX = arrowOffset.clamp(radius + arrowSize, size.width - radius - arrowSize);

    // Build continuous path with bottom arrow
    final path = Path()
      ..moveTo(bodyRect.left + radius, bodyRect.top)
      ..lineTo(bodyRect.right - radius, bodyRect.top)
      ..arcToPoint(Offset(bodyRect.right, bodyRect.top + radius),
          radius: const Radius.circular(radius))
      ..lineTo(bodyRect.right, bodyBottom - radius)
      ..arcToPoint(Offset(bodyRect.right - radius, bodyBottom),
          radius: const Radius.circular(radius))
      ..lineTo(tipX + arrowSize, bodyBottom)
      ..lineTo(tipX, size.height)
      ..lineTo(tipX - arrowSize, bodyBottom)
      ..lineTo(bodyRect.left + radius, bodyBottom)
      ..arcToPoint(Offset(bodyRect.left, bodyBottom - radius),
          radius: const Radius.circular(radius))
      ..lineTo(bodyRect.left, bodyRect.top + radius)
      ..arcToPoint(Offset(bodyRect.left + radius, bodyRect.top),
          radius: const Radius.circular(radius))
      ..close();

    // Gradient fill: deep cosmic purple → dark blue
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xF5140030), // deep purple
        Color(0xF5080020), // dark navy
        Color(0xF5100028), // deep violet
      ],
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(bodyRect)
        ..style = PaintingStyle.fill,
    );

    // Inner top-edge highlight (subtle glass reflection)
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(bodyRect.left, bodyRect.top, bodyRect.width, bodyRect.height * 0.35),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(bodyRect),
    );
    canvas.restore();

    // Cyan neon border
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.orbCyan.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Subtle gold outer glow on border
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.gold.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_CoachBubblePainter old) =>
      arrowOffset != old.arrowOffset || arrowSize != old.arrowSize;
}
