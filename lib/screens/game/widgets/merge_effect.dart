import 'package:flutter/material.dart';

class MergeEffect extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback onComplete;

  const MergeEffect({
    super.key,
    required this.position,
    required this.color,
    required this.onComplete,
  });

  @override
  State<MergeEffect> createState() => _MergeEffectState();
}

class _MergeEffectState extends State<MergeEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale = 1.0 + _controller.value * 2.0;
        final opacity = 1.0 - _controller.value;
        return Positioned(
          left: widget.position.dx - 30 * scale,
          top: widget.position.dy - 30 * scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 60 * scale,
              height: 60 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withValues(alpha: opacity),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: opacity * 0.5),
                    blurRadius: 20 * scale,
                    spreadRadius: 5 * scale,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
