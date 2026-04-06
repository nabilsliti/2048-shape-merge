import 'package:flutter/material.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

class ScorePopup extends StatefulWidget {
  final int points;
  final Offset position;
  final VoidCallback onComplete;

  const ScorePopup({
    super.key,
    required this.points,
    required this.position,
    required this.onComplete,
  });

  @override
  State<ScorePopup> createState() => _ScorePopupState();
}

class _ScorePopupState extends State<ScorePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.8)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 15),
      TweenSequenceItem(
          tween: Tween(begin: 1.8, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_controller);

    _position = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -90),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _comboText {
    if (widget.points >= 640) return '🔥 LEGENDARY!';
    if (widget.points >= 320) return '⭐ SUPER MERGE!';
    if (widget.points >= 160) return '✨ AMAZING!';
    if (widget.points >= 80) return '💫 NICE!';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final hasCombo = _comboText.isNotEmpty;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Positioned(
          left: widget.position.dx - 60,
          top: widget.position.dy + _position.value.dy - 30,
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasCombo)
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppTheme.gold,
                          AppTheme.orange,
                          AppTheme.red,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        _comboText,
                        style: AppTheme.scoreStyle.copyWith(
                          fontSize: 18,
                          color: Colors.white,
                          shadows: [],
                        ),
                      ),
                    ),
                  Text(
                    '+${widget.points}',
                    style: AppTheme.scoreStyle.copyWith(
                      fontSize: hasCombo ? 32 : 26,
                      color: AppTheme.gold,
                      shadows: [
                        Shadow(
                          blurRadius: 12,
                          color: AppTheme.orange.withOpacity(0.8),
                        ),
                        const Shadow(blurRadius: 3, color: Colors.black),
                      ],
                    ),
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
