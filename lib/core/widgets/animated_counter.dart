import 'package:flutter/material.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;

  const AnimatedCounter({super.key, required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 600),
      builder: (context, val, _) {
        return Text(
          '$val',
          style: style ?? AppTheme.scoreStyle,
        );
      },
    );
  }
}
