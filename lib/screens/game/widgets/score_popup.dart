import 'package:flutter/material.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';

class ScorePopup extends StatefulWidget {
  final int points;
  final Offset position;
  final VoidCallback onComplete;
  final int comboCount;

  const ScorePopup({
    super.key,
    required this.points,
    required this.position,
    required this.onComplete,
    this.comboCount = 0,
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

    if (_comboText.isNotEmpty) {
      AudioService.instance.playCombo(widget.points);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _comboText {
    final combo = widget.comboCount;
    if (combo >= 9) return '🔥 LEGENDARY ×$combo';
    if (combo >= 7) return '⭐ SUPER ×$combo';
    if (combo >= 5) return '✨ AMAZING ×$combo';
    if (combo >= 3) return '💫 COMBO ×$combo';
    if (combo >= 2) return 'COMBO ×$combo';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final hasCombo = _comboText.isNotEmpty;
    const popupWidth = 160.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Clamp horizontal position so the popup stays within the board
        final rawLeft = widget.position.dx - popupWidth / 2;
        final clampedLeft = rawLeft.clamp(0.0, double.infinity);

        return Positioned(
          left: clampedLeft,
          top: widget.position.dy + _position.value.dy - 30,
          child: SizedBox(
            width: popupWidth,
            child: Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  if (hasCombo)
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: widget.comboCount >= 7
                            ? [AppTheme.red, AppTheme.orange, AppTheme.gold, AppTheme.red]
                            : widget.comboCount >= 5
                                ? [AppTheme.gold, AppTheme.orange, AppTheme.red]
                                : [AppTheme.gold, AppTheme.orange, AppTheme.gold],
                      ).createShader(bounds),
                      child: Text(
                        _comboText,
                        style: AppTheme.scoreStyle.copyWith(
                          fontSize: widget.comboCount >= 5 ? AppTheme.fontH4 : AppTheme.fontBody,
                          color: Colors.white,
                          shadows: [],
                        ),
                      ),
                    ),
                  Text(
                    '+${widget.points}',
                    style: AppTheme.scoreStyle.copyWith(
                      fontSize: hasCombo ? AppTheme.fontCombo : AppTheme.fontH1b,
                      color: AppTheme.gold,
                      shadows: [
                        Shadow(
                          blurRadius: 12,
                          color: AppTheme.orange.withValues(alpha: 0.8),
                        ),
                        const Shadow(blurRadius: 3, color: Colors.black),
                      ],
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
