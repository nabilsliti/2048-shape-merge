import 'package:flutter/material.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final List<Color>? colors;
  final double? width;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.colors,
    this.width,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.colors ?? [AppTheme.blue, AppTheme.blueDeep];
    final depthColors = gradient.map((c) => c.withOpacity(0.5)).toList();

    return SizedBox(
      width: widget.width,
      height: 64, // Fixed chunky height
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final dy = _controller.value * 6.0; // Button pushes down by 6 pixels
          return Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: Stack(
              children: [
                // 3D Shadow / Base (does not move)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 54,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: depthColors),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
                // Top Button Surface (Moves down)
                Positioned(
                  top: dy,
                  left: 0,
                  right: 0,
                  height: 54,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 24),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: AppTheme.hudStyle.copyWith(
                              color: Colors.white,
                              fontSize: AppTheme.fontH3,
                              height: 1, // center exactly
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
