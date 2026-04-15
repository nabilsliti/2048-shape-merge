import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/joker_ui.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';
import 'package:vibration/vibration.dart';

/// Reusable joker choice dialog — returns the selected [JokerType] or null.
class JokerChoiceDialog {
  JokerChoiceDialog._();

  /// Shows the joker choice panel as a fullscreen dialog.
  static Future<JokerType?> show(BuildContext context) {
    return showDialog<JokerType>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        fit: StackFit.expand,
        children: [
          const SpaceBackground(darken: 0.5),
          Center(
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: _JokerChoicePanel(),
            ),
          ),
        ],
      ),
    );
  }
}

class _JokerChoicePanel extends StatefulWidget {
  @override
  State<_JokerChoicePanel> createState() => _JokerChoicePanelState();
}

class _JokerChoicePanelState extends State<_JokerChoicePanel>
    with TickerProviderStateMixin {
  JokerType? _selected;
  bool _collecting = false;
  bool _collected = false;

  late final AnimationController _bounceCtrl;
  late final AnimationController _plusOneCtrl;
  late final AnimationController _sparkleCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _plusOneCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _sparkleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _plusOneCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  void _onCollect() {
    if (_collecting || _collected || _selected == null) return;
    setState(() => _collecting = true);
    if (Button3D.vibrationEnabled) Vibration.vibrate(duration: 100);
    AudioService.instance.playReward();
    _bounceCtrl.forward(from: 0);
    _plusOneCtrl.forward(from: 0);
    _sparkleCtrl.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _collected = true);
      Navigator.pop(context, _selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.panelBorder, width: 3),
        boxShadow: const [
          BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 8)),
          BoxShadow(color: Colors.black54, offset: Offset(0, 12), blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gift icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.profileGradTop, AppTheme.profileGradBot],
              ),
              border: Border.all(color: AppTheme.gold, width: 3),
              boxShadow: [
                BoxShadow(color: AppTheme.gold.withValues(alpha: 0.3), blurRadius: 12),
              ],
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(l10n.chooseJoker.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
          ),
          const SizedBox(height: 20),

          // Joker choices
          IgnorePointer(
            ignoring: _collecting,
            child: AnimatedOpacity(
              opacity: _collecting ? 0.4 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _JokerChoiceButton(
                    icon: JokerUI.icon(JokerType.bomb, size: 36),
                    color: JokerUI.color(JokerType.bomb),
                    label: JokerUI.localizedLabel(JokerType.bomb, l10n),
                    selected: _selected == JokerType.bomb,
                    onTap: () => setState(() => _selected = JokerType.bomb),
                  ),
                  _JokerChoiceButton(
                    icon: JokerUI.icon(JokerType.wildcard, size: 36),
                    color: JokerUI.color(JokerType.wildcard),
                    label: JokerUI.localizedLabel(JokerType.wildcard, l10n),
                    selected: _selected == JokerType.wildcard,
                    onTap: () => setState(() => _selected = JokerType.wildcard),
                  ),
                  _JokerChoiceButton(
                    icon: JokerUI.icon(JokerType.reducer, size: 30),
                    color: JokerUI.color(JokerType.reducer),
                    label: JokerUI.localizedLabel(JokerType.reducer, l10n),
                    selected: _selected == JokerType.reducer,
                    onTap: () => setState(() => _selected = JokerType.reducer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Collect button or animation
          if (_collecting)
            _buildCollectAnimation()
          else
            SizedBox(
              width: double.infinity,
              child: Button3D.green(
                expand: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _selected == null ? null : _onCollect,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(l10n.collectReward, style: AppTheme.titleStyle(AppTheme.fontBody)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollectAnimation() {
    final jType = _selected!;
    final color = JokerUI.color(jType);
    final icon = JokerUI.icon(jType, size: 36);

    return SizedBox(
      height: 64,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bounceCtrl, _plusOneCtrl, _sparkleCtrl]),
        builder: (context, _) {
          final double bounceScale;
          if (_bounceCtrl.value < 0.3) {
            bounceScale = 1.0 + (_bounceCtrl.value / 0.3) * 0.5;
          } else if (_bounceCtrl.value < 0.6) {
            bounceScale = 1.5 - ((_bounceCtrl.value - 0.3) / 0.3) * 0.6;
          } else {
            bounceScale = 0.9 + ((_bounceCtrl.value - 0.6) / 0.4) * 0.1;
          }

          final plusT = Curves.easeOutCubic.transform(_plusOneCtrl.value);
          final plusOpacity = (1.0 - _plusOneCtrl.value * 0.8).clamp(0.0, 1.0);
          final plusOffset = -40.0 * plusT;

          final glowIntensity = _bounceCtrl.value < 0.5
              ? _bounceCtrl.value * 2
              : 2 - _bounceCtrl.value * 2;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Sparkles
              if (_sparkleCtrl.isAnimating)
                for (var i = 0; i < 8; i++)
                  Positioned(
                    top: 32 + math.sin((i / 8) * 2 * math.pi) * 30 * _sparkleCtrl.value,
                    left: (MediaQuery.sizeOf(context).width - 96) / 2 +
                        math.cos((i / 8) * 2 * math.pi) * 35 * _sparkleCtrl.value,
                    child: Opacity(
                      opacity: (1.0 - _sparkleCtrl.value).clamp(0.0, 1.0),
                      child: Container(
                        width: 5 * (1 - _sparkleCtrl.value * 0.5),
                        height: 5 * (1 - _sparkleCtrl.value * 0.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),

              // Bouncing joker icon with glow
              Transform.scale(
                scale: _bounceCtrl.isAnimating ? bounceScale : 1.0,
                child: Container(
                  decoration: glowIntensity > 0
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: glowIntensity * 0.7),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        )
                      : null,
                  child: icon,
                ),
              ),

              // "+1" floating up
              if (_plusOneCtrl.isAnimating)
                Positioned(
                  top: plusOffset,
                  child: Opacity(
                    opacity: plusOpacity,
                    child: Text(
                      '+1',
                      style: GoogleFonts.fredoka(
                        fontSize: AppTheme.fontH3,
                        fontWeight: FontWeight.w900,
                        color: color,
                        shadows: [
                          Shadow(color: color.withValues(alpha: 0.8), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _JokerChoiceButton extends StatelessWidget {
  final Widget icon;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _JokerChoiceButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? color.withValues(alpha: 0.2) : AppTheme.panelBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: color, width: selected ? 3 : 1.5),
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: selected ? 0.6 : 0.3), blurRadius: selected ? 20 : 10),
                        const BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 3)),
                      ],
                    ),
                    child: icon,
                  ),
                  if (selected)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
                          ],
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTheme.titleStyle(AppTheme.fontSmall).copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
