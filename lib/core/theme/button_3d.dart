import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shape_merge/core/theme/app_theme.dart';


// ═══════════════════════════════════════════════════════════════
// Button3D — 3D juicy button with physical press effect
// ═══════════════════════════════════════════════════════════════
class Button3D extends StatefulWidget {
  final Widget child;
  final Color topColor;
  final Color bottomColor;
  final Color borderColor;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool expand;
  final double depth;

  const Button3D({
    super.key,
    required this.child,
    required this.topColor,
    required this.bottomColor,
    required this.borderColor,
    this.onPressed,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.expand = false,
    this.depth = 6,
  });

  factory Button3D.green({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false, double depth = 6}) =>
      Button3D(topColor: AppTheme.greenTop, bottomColor: AppTheme.greenBot, borderColor: AppTheme.greenBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, depth: depth, child: child);

  factory Button3D.blue({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false, double depth = 6}) =>
      Button3D(topColor: AppTheme.blueTop, bottomColor: AppTheme.blueBot, borderColor: AppTheme.blueBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, depth: depth, child: child);

  factory Button3D.orange({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false, double depth = 6}) =>
      Button3D(topColor: AppTheme.orangeTop, bottomColor: AppTheme.orangeBot, borderColor: AppTheme.orangeBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, depth: depth, child: child);

  factory Button3D.red({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false, double depth = 6}) =>
      Button3D(topColor: AppTheme.redTop, bottomColor: AppTheme.redBot, borderColor: AppTheme.redBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, depth: depth, child: child);

  factory Button3D.purple({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false, double depth = 6}) =>
      Button3D(topColor: AppTheme.purpleTop, bottomColor: AppTheme.purpleBot, borderColor: AppTheme.purpleBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, depth: depth, child: child);

  factory Button3D.yellow({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false, double depth = 6}) =>
      Button3D(topColor: AppTheme.yellowTop, bottomColor: AppTheme.yellowBot, borderColor: AppTheme.yellowBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, depth: depth, child: child);

  factory Button3D.gold({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false, double depth = 6}) =>
      Button3D(topColor: const Color(0xFFD4A017), bottomColor: const Color(0xFF9B7A0F), borderColor: AppTheme.goldDeep, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, depth: depth, child: child);

  factory Button3D.gray({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false, double depth = 6}) =>
      Button3D(topColor: AppTheme.grayTop, bottomColor: AppTheme.grayBot, borderColor: AppTheme.grayBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, depth: depth, child: child);

  @override
  State<Button3D> createState() => _Button3DState();
}

class _Button3DState extends State<Button3D> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _squashController;
  late Animation<double> _scaleXAnim;
  late Animation<double> _scaleYAnim;

  @override
  void initState() {
    super.initState();
    _squashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scaleXAnim = Tween(begin: 1.0, end: 1.04).animate(CurvedAnimation(parent: _squashController, curve: Curves.easeOut));
    _scaleYAnim = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _squashController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _squashController.dispose();
    super.dispose();
  }

  Widget _wrapWidth(Widget child) =>
      widget.expand ? child : IntrinsicWidth(child: child);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          HapticFeedback.lightImpact();
          _squashController.forward();
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (widget.onPressed != null) {
          _squashController.reverse();
          setState(() => _isPressed = false);
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (widget.onPressed != null) {
          _squashController.reverse();
          setState(() => _isPressed = false);
        }
      },
      child: AnimatedBuilder(
        animation: _squashController,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(_scaleXAnim.value, _scaleYAnim.value, 1.0),
            child: child,
          );
        },
        child: IntrinsicHeight(
          child: _wrapWidth(
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: widget.depth, left: 0, right: 0, bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      color: widget.bottomColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: Offset(0, _isPressed ? widget.depth * 0.33 : widget.depth * 0.83), blurRadius: _isPressed ? widget.depth * 0.5 : widget.depth * 1.33)
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: widget.expand ? double.infinity : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    margin: EdgeInsets.only(top: _isPressed ? widget.depth : 0, bottom: _isPressed ? 0 : widget.depth),
                    decoration: BoxDecoration(
                      color: widget.topColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(color: widget.borderColor, width: 2),
                    ),
                    child: Padding(padding: widget.padding, child: widget.child),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
