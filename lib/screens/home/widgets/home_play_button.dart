import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/config/app_routes.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';

/// Enhanced PLAY button:
///  • Pulsing green glow when at least one daily objective is ≥80% done
///    (visual hook: "tu peux finir un objectif si tu joues maintenant").
///
/// Replaces the old inline Button3D in HomeScreen.
class HomePlayButton extends ConsumerStatefulWidget {
  const HomePlayButton({super.key, required this.rocket});

  /// Pre-built rocket animation widget (kept by parent so its controller
  /// is reused — avoids re-creating per build).
  final Widget rocket;

  @override
  ConsumerState<HomePlayButton> createState() => _HomePlayButtonState();
}

class _HomePlayButtonState extends ConsumerState<HomePlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  bool _hasNearlyCompleteObjective(WidgetRef ref) {
    final state = ref.watch(dailyChallengeProvider);
    if (state == null) return false;
    return state.challenges.any((c) =>
        !c.completed && c.target > 0 && c.current / c.target >= 0.8);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shouldGlow = _hasNearlyCompleteObjective(ref);

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        // Glow only animates when objectives nudge — otherwise no shadow.
        final t = shouldGlow ? _glow.value : 0.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: shouldGlow
                ? [
                    BoxShadow(
                      color: AppTheme.greenTop.withValues(
                        alpha: 0.35 + 0.35 * t,
                      ),
                      blurRadius: 12 + 18 * t,
                      spreadRadius: 1 + 3 * t,
                    ),
                  ]
                : null,
          ),
          child: Button3D.green(
            expand: true,
            onPressed: () => context.push(AppRoutes.game),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.rocket,
                const SizedBox(width: 14),
                Text(
                  l10n.play.toUpperCase(),
                  style: AppTheme.titleStyle(AppTheme.fontH2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
