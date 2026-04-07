import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/providers/game_state_provider.dart';

class JokerBar extends ConsumerWidget {
  final JokerInventory inventory;

  const JokerBar({super.key, required this.inventory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(jokerModeProvider);
    final inv = inventory;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _JokerOrb(
            icon: JokerUI.icon(JokerType.bomb, size: 18),
            count: inv.bomb,
            isActive: currentMode == JokerMode.bomb,
            glowColor: JokerUI.glowColor(JokerType.bomb),
            ringColors: JokerUI.ringColors(JokerType.bomb),
            onTap: () => _toggle(ref, JokerMode.bomb),
          ),
          _JokerOrb(
            icon: JokerUI.icon(JokerType.wildcard, size: 18),
            count: inv.wildcard,
            isActive: currentMode == JokerMode.wildcard,
            glowColor: JokerUI.glowColor(JokerType.wildcard),
            ringColors: JokerUI.ringColors(JokerType.wildcard),
            onTap: () => _toggle(ref, JokerMode.wildcard),
          ),
          _JokerOrb(
            icon: JokerUI.icon(JokerType.reducer, size: 16),
            count: inv.reducer,
            isActive: currentMode == JokerMode.reducer,
            glowColor: JokerUI.glowColor(JokerType.reducer),
            ringColors: JokerUI.ringColors(JokerType.reducer),
            onTap: () => _toggle(ref, JokerMode.reducer),
          ),
          // ── séparateur premium ──
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 1, height: 20, color: AppTheme.gold.withValues(alpha: 0.5)),
              const SizedBox(height: 2),
              Text('★', style: TextStyle(fontSize: 7, color: AppTheme.gold.withValues(alpha: 0.8))),
              const SizedBox(height: 2),
              Container(width: 1, height: 20, color: AppTheme.gold.withValues(alpha: 0.5)),
            ],
          ),
          _JokerOrb(
            icon: JokerUI.icon(JokerType.radar, size: 16),
            count: inv.radar,
            isActive: currentMode == JokerMode.radar,
            glowColor: JokerUI.glowColor(JokerType.radar),
            ringColors: JokerUI.ringColors(JokerType.radar),
            onTap: () => _activateRadar(ref),
            isPremium: true,
          ),
          _JokerOrb(
            icon: JokerUI.icon(JokerType.evolution, size: 16),
            count: inv.evolution,
            isActive: currentMode == JokerMode.evolution,
            glowColor: JokerUI.glowColor(JokerType.evolution),
            ringColors: JokerUI.ringColors(JokerType.evolution),
            onTap: () => _toggle(ref, JokerMode.evolution),
            isPremium: true,
          ),
          _JokerOrb(
            icon: JokerUI.icon(JokerType.megaBomb, size: 16),
            count: inv.megaBomb,
            isActive: currentMode == JokerMode.megaBomb,
            glowColor: JokerUI.glowColor(JokerType.megaBomb),
            ringColors: JokerUI.ringColors(JokerType.megaBomb),
            onTap: () => _toggle(ref, JokerMode.megaBomb),
            isPremium: true,
          ),
        ],
      ),
    );
  }

  void _toggle(WidgetRef ref, JokerMode mode) {
    final current = ref.read(jokerModeProvider);
    ref.read(jokerModeProvider.notifier).state =
        current == mode ? JokerMode.none : mode;
  }

  void _activateRadar(WidgetRef ref) {
    final current = ref.read(jokerModeProvider);
    if (current == JokerMode.radar) {
      ref.read(jokerModeProvider.notifier).state = JokerMode.none;
      return;
    }
    ref.read(gameStateProvider.notifier).activateRadar(ref);
  }
}

class _JokerOrb extends StatefulWidget {
  final Widget icon;
  final int count;
  final bool isActive;
  final Color glowColor;
  final List<Color> ringColors;
  final VoidCallback onTap;
  final bool isPremium;

  const _JokerOrb({
    required this.icon,
    required this.count,
    required this.isActive,
    required this.glowColor,
    required this.ringColors,
    required this.onTap,
    this.isPremium = false,
  });

  @override
  State<_JokerOrb> createState() => _JokerOrbState();
}

class _JokerOrbState extends State<_JokerOrb>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = Tween(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack),
    );

    if (widget.isActive) _scaleCtrl.forward();
  }

  @override
  void didUpdateWidget(_JokerOrb old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _scaleCtrl.forward();
    } else if (!widget.isActive && old.isActive) {
      _scaleCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.count <= 0;
    final orbSize = 34.0;

    return GestureDetector(
      onTap: disabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseCtrl, _scaleCtrl]),
        builder: (context, child) {
          final pulse = sin(_pulseCtrl.value * pi);
          final totalScale = _scaleAnim.value;

          return Transform.scale(
            scale: totalScale,
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
