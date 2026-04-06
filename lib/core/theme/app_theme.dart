import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Background Gradient ──
  static const Color bgTop = Color(0xFF6a11cb);
  static const Color bgBot = Color(0xFF2575fc);

  // ── Button Colors (top, bottom, border) ──
  static const Color greenTop = Color(0xFF00ea54);
  static const Color greenBot = Color(0xFF007c2c);
  static const Color greenBorder = Color(0xFF80ffa5);

  static const Color blueTop = Color(0xFF2ca2ff);
  static const Color blueBot = Color(0xFF005bbb);
  static const Color blueBorder = Color(0xFF8ad1ff);

  static const Color orangeTop = Color(0xFFffaa00);
  static const Color orangeBot = Color(0xFFb85e00);
  static const Color orangeBorder = Color(0xFFFFDF7A);

  static const Color yellowTop = Color(0xFFffd600);
  static const Color yellowBot = Color(0xFFc49b00);
  static const Color yellowBorder = Color(0xFFfff176);

  static const Color redTop = Color(0xFFff4747);
  static const Color redBot = Color(0xFFa80000);
  static const Color redBorder = Color(0xFFffb1b1);

  static const Color purpleTop = Color(0xFFa541ff);
  static const Color purpleBot = Color(0xFF5b00b3);
  static const Color purpleBorder = Color(0xFFd7a8ff);

  static const Color panelBg = Color(0xFF1e1b4b);
  static const Color panelBorder = Color(0xFF4338ca);

  // Legacy aliases
  static const background = Color(0xFF0d0a2a);
  static const panel = Color(0xCC1e1b4b);
  static const blue = blueTop;
  static const green = greenTop;
  static const purple = purpleTop;
  static const gold = Color(0xFFFFD700);
  static const red = redTop;
  static const pink = Color(0xFFFF4081);
  static const orange = orangeTop;
  static const text = Color(0xFFF8F9FA);
  static const muted = Color(0xFFA0A5D0);

  // ── Level Colors ──
  static const List<Color> levelColors = [
    Color(0xFFFF2D55), // red
    Color(0xFF007AFF), // blue
    Color(0xFF30D158), // green
    Color(0xFFFFD60A), // yellow
    Color(0xFFBF5AF2), // purple
    Color(0xFFFF9F0A), // orange
    Color(0xFFFF2D55), // red
    Color(0xFF007AFF), // blue
  ];

  static Color colorForLevel(int level) =>
      levelColors[(level - 1).clamp(0, levelColors.length - 1)];

  // ── Title style with black stroke (like Shape Rush) ──
  static TextStyle titleStyle([double size = 36]) => GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        shadows: const [
          Shadow(offset: Offset(-1, -1), color: Colors.black),
          Shadow(offset: Offset(1, -1), color: Colors.black),
          Shadow(offset: Offset(-1, 1), color: Colors.black),
          Shadow(offset: Offset(1, 1), color: Colors.black),
          Shadow(offset: Offset(0, 4), color: Colors.black54),
        ],
      );

  static TextStyle get scoreStyle => GoogleFonts.fredoka(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: gold,
        shadows: const [Shadow(offset: Offset(0, 2), color: Colors.black54)],
      );

  static TextStyle get hudStyle => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: text,
      );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: blueTop,
        secondary: gold,
        tertiary: purpleTop,
        surface: panelBg,
        onSurface: text,
        error: redTop,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: text, displayColor: text),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  /// Game background widget matching shape-rush (gradient + orbs).
  static Widget backgroundWidget() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgTop, bgBot],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: _orbGradient(const Color(0xFFff2d87), 300),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _orbGradient(const Color(0xFF00d4ff), 250),
          ),
        ],
      ),
    );
  }

  static Widget _orbGradient(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.3),
      ),
    );
  }
}

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
  });

  factory Button3D.green({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false}) =>
      Button3D(topColor: AppTheme.greenTop, bottomColor: AppTheme.greenBot, borderColor: AppTheme.greenBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, child: child);

  factory Button3D.blue({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false}) =>
      Button3D(topColor: AppTheme.blueTop, bottomColor: AppTheme.blueBot, borderColor: AppTheme.blueBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, child: child);

  factory Button3D.orange({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false}) =>
      Button3D(topColor: AppTheme.orangeTop, bottomColor: AppTheme.orangeBot, borderColor: AppTheme.orangeBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, child: child);

  factory Button3D.red({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false}) =>
      Button3D(topColor: AppTheme.redTop, bottomColor: AppTheme.redBot, borderColor: AppTheme.redBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, child: child);

  factory Button3D.purple({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false}) =>
      Button3D(topColor: AppTheme.purpleTop, bottomColor: AppTheme.purpleBot, borderColor: AppTheme.purpleBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, child: child);

  factory Button3D.yellow({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false}) =>
      Button3D(topColor: AppTheme.yellowTop, bottomColor: AppTheme.yellowBot, borderColor: AppTheme.yellowBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, child: child);

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
            transform: Matrix4.identity()..scale(_scaleXAnim.value, _scaleYAnim.value),
            child: child,
          );
        },
        child: IntrinsicHeight(
          child: _wrapWidth(
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 6, left: 0, right: 0, bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      color: widget.bottomColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: Offset(0, _isPressed ? 2 : 5), blurRadius: _isPressed ? 3 : 8)
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: widget.expand ? double.infinity : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    margin: EdgeInsets.only(top: _isPressed ? 6 : 0, bottom: _isPressed ? 0 : 6),
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
