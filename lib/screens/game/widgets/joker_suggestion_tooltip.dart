import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/game_state_provider.dart';

/// Tooltip that floats above the joker bar, pointing to the suggested joker.
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

  /// Index (0–6) of the joker in the bar. The separator occupies index 3.
  /// bomb=0, wildcard=1, reducer=2, [sep=3], radar=4, evolution=5, megaBomb=6
  double _jokerFraction(JokerType type) {
    const total = 7; // 6 orbs + 1 separator
    final index = switch (type) {
      JokerType.bomb => 0,
      JokerType.wildcard => 1,
      JokerType.reducer => 2,
      JokerType.radar => 4,
      JokerType.evolution => 5,
      JokerType.megaBomb => 6,
    };
    // Center of the slot: (index + 0.5) / total
    return (index + 0.5) / total;
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
    final color = JokerUI.glowColor(_visibleType!);
    final fraction = _jokerFraction(_visibleType!);
    final screenWidth = MediaQuery.of(context).size.width;
    // Joker bar has 3px horizontal padding each side
    final barWidth = screenWidth - 6;
    final orbCenterX = 3 + barWidth * fraction;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeOutBack.transform(_ctrl.value.clamp(0.0, 1.0));
        if (t == 0) return const SizedBox.shrink();

        // Tooltip: positioned at bottom, above joker bar
        // Joker bar height ≈ 50px + 3px spacing + 3px bottom
        const jokerBarArea = 56.0;
        const arrowH = 6.0;

        // Clamp tooltip horizontally so it doesn't go offscreen
        const tooltipW = 160.0;
        final tooltipLeft =
            (orbCenterX - tooltipW / 2).clamp(8.0, screenWidth - tooltipW - 8);
        // Arrow points to orbCenterX
        final arrowLeft = orbCenterX - tooltipLeft - 6;

        return Positioned(
          left: tooltipLeft,
          bottom: jokerBarArea + arrowH + 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: _ctrl.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.7 + t * 0.3,
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tooltip body
                    Container(
                      width: tooltipW,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.panelBg.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: color.withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                          const BoxShadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💡',
                              style: TextStyle(fontSize: 16, height: 1)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _localizeReason(l10n, _visibleType!),
                              style: GoogleFonts.fredoka(
                                fontSize: AppTheme.fontMini,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow pointing down toward the joker orb
                    Padding(
                      padding: EdgeInsets.only(left: arrowLeft.clamp(8.0, tooltipW - 20)),
                      child: CustomPaint(
                        size: const Size(12, arrowH),
                        painter: _ArrowDownPainter(
                          fill: AppTheme.panelBg.withValues(alpha: 0.95),
                          border: color.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArrowDownPainter extends CustomPainter {
  final Color fill;
  final Color border;

  _ArrowDownPainter({required this.fill, required this.border});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ArrowDownPainter old) =>
      old.fill != fill || old.border != border;
}
