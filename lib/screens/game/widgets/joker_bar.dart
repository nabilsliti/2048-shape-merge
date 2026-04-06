import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/providers/game_state_provider.dart';

class JokerBar extends ConsumerWidget {
  final JokerInventory inventory;

  const JokerBar({super.key, required this.inventory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(jokerModeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _JokerOrb(
            icon: const JokerIcon.bomb(size: 24),
            count: inventory.bomb,
            isActive: currentMode == JokerMode.bomb,
            glowColor: const Color(0xFFff4444),
            ringColors: const [Color(0xFFff6b6b), Color(0xFFcc0000)],
            onTap: () => _toggleJoker(ref, JokerMode.bomb),
          ),
          _JokerOrb(
            icon: const JokerIcon.wildcard(size: 24),
            count: inventory.wildcard,
            isActive: currentMode == JokerMode.wildcard,
            glowColor: const Color(0xFFaa44ff),
            ringColors: const [Color(0xFFce93d8), Color(0xFF7b1fa2)],
            onTap: () => _toggleJoker(ref, JokerMode.wildcard),
          ),
          _JokerOrb(
            icon: const JokerIcon.reducer(size: 20),
            count: inventory.reducer,
            isActive: currentMode == JokerMode.reducer,
            glowColor: const Color(0xFF448aff),
            ringColors: const [Color(0xFF90caf9), Color(0xFF1565c0)],
            onTap: () => _toggleJoker(ref, JokerMode.reducer),
          ),
        ],
      ),
    );
  }

  void _toggleJoker(WidgetRef ref, JokerMode mode) {
    final current = ref.read(jokerModeProvider);
    ref.read(jokerModeProvider.notifier).state =
        current == mode ? JokerMode.none : mode;
  }
}

class _JokerOrb extends StatefulWidget {
  final Widget icon;
  final int count;
  final bool isActive;
  final Color glowColor;
  final List<Color> ringColors;
  final VoidCallback onTap;

  const _JokerOrb({
    required this.icon,
    required this.count,
    required this.isActive,
    required this.glowColor,
    required this.ringColors,
    required this.onTap,
  });

  @override
  State<_JokerOrb> createState() => _JokerOrbState();
}

class _JokerOrbState extends State<_JokerOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.count <= 0;
    final orbSize = 42.0;

    return GestureDetector(
      onTap: disabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final pulse = sin(_pulseCtrl.value * pi);
          final activeScale = widget.isActive ? 1.0 + pulse * 0.06 : 1.0;

          return Transform.scale(
            scale: activeScale,
            child: SizedBox(
              width: orbSize + 14,
              height: orbSize + 8,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Glow behind the orb
                  if (!disabled)
                    Positioned(
                      left: 8,
                      top: 5,
                      child: Container(
                        width: orbSize,
                        height: orbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.glowColor.withValues(
                                alpha: widget.isActive
                                    ? 0.5 + pulse * 0.2
                                    : 0.15,
                              ),
                              blurRadius: widget.isActive ? 16 + pulse * 6 : 8,
                              spreadRadius: widget.isActive ? 2 : 0,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Main orb container
                  Positioned(
                    left: 8,
                    top: 5,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: orbSize,
                      height: orbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.3),
                          colors: disabled
                              ? [
                                  const Color(0xFF2a2a3a),
                                  const Color(0xFF1a1a28),
                                ]
                              : [
                                  widget.glowColor.withValues(alpha: 0.15),
                                  const Color(0xFF1a1a2e),
                                  const Color(0xFF0d0d1a),
                                ],
                        ),
                        border: Border.all(
                          color: disabled
                              ? Colors.white.withValues(alpha: 0.06)
                              : widget.isActive
                                  ? widget.ringColors[0].withValues(alpha: 0.9)
                                  : widget.ringColors[1].withValues(alpha: 0.4),
                          width: widget.isActive ? 2.5 : 1.5,
                        ),
                      ),
                      child: Opacity(
                        opacity: disabled ? 0.3 : 1.0,
                        child: Center(child: widget.icon),
                      ),
                    ),
                  ),

                  // Count badge — top right
                  Positioned(
                    right: 0,
                    top: 0,
                    child: _CountBadge(
                      count: widget.count,
                      color: widget.glowColor,
                      isActive: widget.isActive,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  final bool isActive;

  const _CountBadge({
    required this.count,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: count > 0
              ? [
                  Color.lerp(color, Colors.white, 0.3)!,
                  color,
                ]
              : [
                  const Color(0xFF3a3a4a),
                  const Color(0xFF2a2a38),
                ],
        ),
        border: Border.all(
          color: count > 0
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: count > 0
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
                const BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '$count',
          style: AppTheme.titleStyle(11).copyWith(
            color: count > 0 ? Colors.white : AppTheme.muted,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
