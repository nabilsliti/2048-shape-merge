import 'package:flutter/material.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

/// Premium-styled in-game toast shown when an objective is completed mid-game.
class ObjectiveToast extends StatefulWidget {
  final String label;
  final VoidCallback onDismissed;

  const ObjectiveToast({super.key, required this.label, required this.onDismissed});

  @override
  State<ObjectiveToast> createState() => _ObjectiveToastState();
}

class _ObjectiveToastState extends State<ObjectiveToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slideIn;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // 0–0.15: slide in + fade in
    // 0.15–0.80: hold
    // 0.80–1.0: slide out + fade out
    _slideIn = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -80.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -80.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(_ctrl);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0040), Color(0xFF0D0025)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.orbCyan.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.orbCyan.withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: -2,
            ),
            BoxShadow(
              color: AppTheme.gold.withValues(alpha: 0.15),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clap emoji with gold glow
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gold.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Text('👏', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.label,
                style: AppTheme.titleStyle(AppTheme.fontSmall).copyWith(
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideIn.value),
          child: Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }
}
