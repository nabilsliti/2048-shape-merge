import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _position = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -60),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) => widget.onComplete());
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
        return Positioned(
          left: widget.position.dx - 30,
          top: widget.position.dy + _position.value.dy,
          child: Opacity(
            opacity: _opacity.value,
            child: Text(
              '+${widget.points}',
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 8, color: Colors.black)],
              ),
            ),
          ),
        );
      },
    );
  }
}
