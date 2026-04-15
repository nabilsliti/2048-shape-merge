import 'dart:math';
import 'package:flutter/material.dart';

import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/screens/game/widgets/coach_overlay.dart';
import 'package:vibration/vibration.dart';

class JokerOrb extends StatefulWidget {
  final JokerType jokerType;
  final Widget icon;
  final int count;
  final bool isActive;
  final bool isSuggested;
  final Color glowColor;
  final List<Color> ringColors;
  final VoidCallback onTap;
  final bool isPremium;
  final int emptyTapTrigger;

  const JokerOrb({
    super.key,
    required this.jokerType,
    required this.icon,
    required this.count,
    required this.isActive,
    required this.isSuggested,
    required this.glowColor,
    required this.ringColors,
    required this.onTap,
    this.isPremium = false,
    this.emptyTapTrigger = 0,
  });

  @override
  State<JokerOrb> createState() => _JokerOrbState();
}

class _JokerOrbState extends State<JokerOrb>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;
  AnimationController? _radiateCtrl;

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

    if (widget.isActive) {
      _scaleCtrl.forward();
    }
  }

  @override
  void didUpdateWidget(JokerOrb old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _scaleCtrl.forward();
    } else if (!widget.isActive && old.isActive) {
      _scaleCtrl.reverse();
    }

    // Trigger radiate animation on empty tap
    if (widget.isActive && widget.emptyTapTrigger != old.emptyTapTrigger && widget.emptyTapTrigger > 0) {
      _triggerRadiate();
    }
  }

  void _triggerRadiate() {
    _radiateCtrl?.dispose();
    _radiateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward().then((_) {
        _radiateCtrl?.dispose();
        _radiateCtrl = null;
        if (mounted) setState(() {});
      });
    setState(() {});
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scaleCtrl.dispose();
    _radiateCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.count <= 0;
    const orbSize = 42.0;

    return GestureDetector(
      onTap: disabled
          ? null
          : () {
              if (Button3D.vibrationEnabled) Vibration.vibrate(duration: 30);
              AudioService.instance.playButtonTap();
              widget.onTap();
            },
      onLongPress: () async {
        if (Button3D.vibrationEnabled) Vibration.vibrate(duration: 60);
        await showJokerInfo(context, widget.jokerType);
        CoachOverlay.notifyJokerLongPress();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseCtrl, _scaleCtrl, if (_radiateCtrl != null) _radiateCtrl!]),
        builder: (context, child) {
          final pulse = sin(_pulseCtrl.value * pi);
          final totalScale = _scaleAnim.value;

          return Transform.scale(
            scale: totalScale,
            child: SizedBox(
              width: orbSize + 8,
              height: orbSize + 6,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Radiation rings (only when empty tap on board)
                  if (_radiateCtrl != null)
                    Positioned(
                      left: 8 - 16,
                      top: 5 - 16,
                      child: CustomPaint(
                        size: const Size(orbSize + 32, orbSize + 32),
                        painter: _RadiationPainter(
                          progress: _radiateCtrl!.value,
                          color: widget.glowColor,
                        ),
                      ),
                    ),

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
                                alpha: (widget.isActive || widget.isSuggested)
                                    ? 0.5 + pulse * 0.2
                                    : 0.15,
                              ),
                              blurRadius: (widget.isActive || widget.isSuggested) ? 16 + pulse * 6 : 8,
                              spreadRadius: (widget.isActive || widget.isSuggested) ? 2 : 0,
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
                                  AppTheme.jokerOrbDisabledTop,
                                  AppTheme.jokerOrbDisabledBot,
                                ]
                              : [
                                  widget.glowColor.withValues(alpha: 0.15),
                                  AppTheme.cardBg,
                                  AppTheme.jokerOrbBgDark,
                                ],
                        ),
                        border: Border.all(
                          color: disabled
                              ? Colors.white.withValues(alpha: 0.06)
                              : (widget.isActive || widget.isSuggested)
                                  ? widget.ringColors[0].withValues(alpha: 0.9)
                                  : widget.ringColors[1].withValues(alpha: 0.4),
                          width: (widget.isActive || widget.isSuggested) ? 2.5 : 1.5,
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
                  AppTheme.jokerBadgeEmptyTop,
                  AppTheme.jokerBadgeEmptyBot,
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: count > 0 ? Colors.white : AppTheme.muted,
            height: 1.0,
            letterSpacing: -0.5,
            shadows: count > 0
                ? const [
                    Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 3),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

// ── Joker info popup (long-press) ──────────────────────────────

Future<void> showJokerInfo(BuildContext context, JokerType type) {
  final l10n = AppLocalizations.of(context)!;
  final color = JokerUI.color(type);

  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _JokerInfoPopup(
      type: type,
      color: color,
      name: JokerUI.localizedLabel(type, l10n),
      description: JokerUI.description(type, l10n),
    ),
  );
}

class _JokerInfoPopup extends StatelessWidget {
  final JokerType type;
  final Color color;
  final String name;
  final String description;

  const _JokerInfoPopup({
    required this.type,
    required this.color,
    required this.name,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.panelBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 24),
              const BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 4), blurRadius: 12),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                ),
                child: Center(child: JokerUI.icon(type, size: 28)),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                name,
                style: AppTheme.titleStyle(AppTheme.fontBody).copyWith(color: color),
              ),
              if (type.isPremium) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
                  ),
                  child: Text('★ PREMIUM', style: AppTheme.titleStyle(AppTheme.fontMicro).copyWith(color: AppTheme.gold)),
                ),
              ],
              const SizedBox(height: 12),
              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTheme.hudStyle.copyWith(
                  fontSize: AppTheme.fontSmall,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Radiation painter (expanding rings on empty tap) ──────────────────────

class _RadiationPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadiationPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 3 rings expanding outward with staggered timing
    for (var i = 0; i < 3; i++) {
      final delay = i * 0.15;
      final t = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final eased = Curves.easeOut.transform(t);
      final radius = maxRadius * 0.4 + maxRadius * 0.6 * eased;
      final opacity = (1.0 - eased) * 0.7;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - eased * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_RadiationPainter old) => progress != old.progress;
}
