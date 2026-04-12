import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/services/progression_service.dart';
import 'package:shape_merge/providers/progression_provider.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/providers/audio_provider.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/iap_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/providers/streak_provider.dart';
import 'package:shape_merge/screens/home/home_screen.dart';

import 'package:shape_merge/screens/hub/widgets/level_up_overlay.dart';
import 'package:shape_merge/screens/hub/widgets/streak_popup.dart';
import 'package:shape_merge/screens/settings/profile_dialog.dart';

class MainHubScreen extends ConsumerStatefulWidget {
  const MainHubScreen({super.key});

  @override
  ConsumerState<MainHubScreen> createState() => _MainHubScreenState();
}

class _MainHubScreenState extends ConsumerState<MainHubScreen> {
  bool _streakPopupShown = false;

  @override
  Widget build(BuildContext context) {
    // Initialize IAP early to catch pending purchases
    ref.watch(iapReadyProvider);

    // Reset auto-show guard when account changes so the popup can show again
    ref.listen(authStateProvider, (prev, next) {
      final prevUid = prev?.valueOrNull?.uid;
      final nextUid = next.valueOrNull?.uid;
      if (prevUid != nextUid) {
        _streakPopupShown = false;
      }
    });

    // Show streak popup once automatically when a new streak day is earned
    ref.listen(streakProvider, (prev, next) {
      if (next != null && next.reward != null && !next.rewardClaimed && !_streakPopupShown) {
        _streakPopupShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          StreakPopup.show(context, next).then((_) {
            ref.read(streakProvider.notifier).ensureRewardClaimed();
          });
        });
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Stack(
        children: [
          // Global Background
          Positioned.fill(child: _buildGradientBackground()),

          // Home Screen Content
          const Positioned.fill(
            child: HomeScreenContent(),
          ),

          // Top HUD
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopHud(),
          ),

          // Level-up overlay — centered, auto-dismisses after 2.5s
          const Positioned.fill(child: LevelUpOverlay()),
        ],
      ),
    );
  }

  static Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.bgTop, AppTheme.bgBot],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.orbPink.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.orbCyan.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHud extends ConsumerWidget {

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final player = ref.watch(playerProvider).valueOrNull;
    final streakResult = ref.watch(streakProvider);

    final localStorage = ref.watch(localStorageProvider).valueOrNull;
    final streakCount = user != null
        ? (player?.currentStreak ?? localStorage?.currentStreak ?? 0)
        : (localStorage?.currentStreak ?? 0);

    // Level: prefer live progressionProvider result (updated immediately after game)
    final progressionResult = ref.watch(progressionProvider);
    final level = progressionResult?.newLevel
        ?? (user != null
            ? (player?.level ?? localStorage?.playerLevel ?? 1)
            : (localStorage?.playerLevel ?? 1));
    final currentXP = progressionResult?.currentXP
        ?? (user != null
            ? (player?.currentXP ?? localStorage?.currentXP ?? 0)
            : (localStorage?.currentXP ?? 0));
    final xpNeeded = ProgressionService.xpForLevel(level);

    final String currentAvatar;
    if (user != null) {
      currentAvatar = avatarEmoji(player?.avatarId);
    } else {
      currentAvatar = avatarEmoji(localStorage?.guestAvatar);
    }

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 12,
        right: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Settings button
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Button3D.gold(
              padding: EdgeInsets.zero,
              borderRadius: 100,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const SettingsModal(),
                );
              },
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.settings, color: Colors.white, size: 20),
              ),
            ),
          ),

          // ── 3 chips centrés, même taille ──
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (streakCount > 0) ...[
                  RetentionUI.streakBadge(
                    count: streakCount,
                    dayLabel: AppLocalizations.of(context)!.dayLabel,
                    onTap: streakResult != null
                        ? () => StreakPopup.show(context, streakResult).then((_) {
                              ref.read(streakProvider.notifier).ensureRewardClaimed();
                            })
                        : null,
                  ),
                  const SizedBox(width: 6),
                ],
                RetentionUI.levelBadge(level: level, levelShortLabel: AppLocalizations.of(context)!.levelShortLabel),
                const SizedBox(width: 6),
                _AnimatedXpBadge(currentXP: currentXP, xpNeeded: xpNeeded),
              ],
            ),
          ),

          // Avatar / Profile button
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Button3D.gold(
              padding: EdgeInsets.zero,
              borderRadius: 100,
              onPressed: () => showProfileDialog(context, ref),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: Text(currentAvatar, style: const TextStyle(fontSize: AppTheme.fontH4)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Settings Modal — shape-rush style white dialog with toggles
// ═══════════════════════════════════════════════════════════════
class SettingsModal extends ConsumerStatefulWidget {
  const SettingsModal({super.key});

  @override
  ConsumerState<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends ConsumerState<SettingsModal> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = 'v${info.version}+${info.buildNumber}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final soundOn = ref.watch(audioProvider);
    final musicOn = ref.watch(musicProvider);
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.panelBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(color: AppTheme.goldDeep, width: 3),
              boxShadow: [
                BoxShadow(color: AppTheme.goldDeep.withValues(alpha: 0.4), offset: const Offset(0, 8)),
                const BoxShadow(color: Colors.black54, offset: Offset(0, 12), blurRadius: 20),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Settings icon — circular gradient like profile avatar
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
                  child: const Icon(Icons.settings_rounded, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 12),

                // Title
                Text(l10n.settings.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontH4)),
                const SizedBox(height: 20),

                // Sound toggle
                _settingToggle(
                  soundOn ? l10n.soundOn : l10n.soundOff,
                  soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  soundOn,
                  (v) => ref.read(audioProvider.notifier).toggle(),
                ),
                const SizedBox(height: 12),

                // Music toggle
                _settingToggle(
                  musicOn ? l10n.musicOn : l10n.musicOff,
                  musicOn ? Icons.music_note_rounded : Icons.music_off_rounded,
                  musicOn,
                  (v) => ref.read(musicProvider.notifier).toggle(),
                ),
                const SizedBox(height: 16),

                // Language button
                SizedBox(
                  width: double.infinity,
                  child: Button3D.blue(
                    expand: true,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(l10n.languageLabel('FRANÇAIS'),
                                style: AppTheme.titleStyle(AppTheme.fontBody)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(_version, style: GoogleFonts.nunito(
                  fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
          Positioned(
            top: -12,
            right: -12,
            child: Button3D.red(
              padding: const EdgeInsets.all(8),
              borderRadius: 20,
              onPressed: () => Navigator.of(context).pop(),
              child: const PremiumIcon.close(size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingToggle(String title, IconData icon, bool isOn,
      ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isOn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: AppTheme.panelBorder, width: 2),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.gold),
                const SizedBox(width: 10),
                Text(title,
                    style: GoogleFonts.nunito(
                        fontSize: AppTheme.fontRegular,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ],
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 32,
              decoration: BoxDecoration(
                color: isOn ? AppTheme.greenTop : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: isOn ? AppTheme.greenBot : Colors.black26,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 4)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Animated XP Badge — bounce + rolling counter + floating +N XP
// ═══════════════════════════════════════════════════════════════
class _AnimatedXpBadge extends StatefulWidget {
  const _AnimatedXpBadge({required this.currentXP, required this.xpNeeded});

  final int currentXP;
  final int xpNeeded;

  @override
  State<_AnimatedXpBadge> createState() => _AnimatedXpBadgeState();
}

class _AnimatedXpBadgeState extends State<_AnimatedXpBadge>
    with TickerProviderStateMixin {
  late final AnimationController _bounce;
  late final AnimationController _plusLabel;
  late final AnimationController _counterRoll;
  late final AnimationController _ring;
  late final AnimationController _sparkles;

  int _displayXP = 0;
  int _prevXP = 0;
  int _gainedXP = 0;
  bool _isRolling = false;

  @override
  void initState() {
    super.initState();
    _displayXP = widget.currentXP;
    _prevXP = widget.currentXP;
    _bounce = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..addListener(() => setState(() {}));
    _plusLabel = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..addListener(() => setState(() {}));
    _counterRoll = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() {
            _isRolling = false;
            _displayXP = widget.currentXP;
          });
        }
      })
      ..addListener(() => setState(() {}));
    _ring = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..addListener(() => setState(() {}));
    _sparkles = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _AnimatedXpBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentXP == oldWidget.currentXP) return;

    _bounce.forward(from: 0);
    _ring.forward(from: 0);
    _sparkles.forward(from: 0);

    if (widget.currentXP > oldWidget.currentXP) {
      setState(() {
        _prevXP = oldWidget.currentXP;
        _gainedXP = widget.currentXP - oldWidget.currentXP;
        _isRolling = true;
      });
      _plusLabel.forward(from: 0);
      _counterRoll.forward(from: 0);
    } else {
      // Level-up reset — update display immediately
      setState(() {
        _isRolling = false;
        _displayXP = widget.currentXP;
      });
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    _plusLabel.dispose();
    _counterRoll.dispose();
    _ring.dispose();
    _sparkles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bounce: elastic scale 1 → 1.35 → 0.92 → 1
    final double bounceScale;
    if (_bounce.value < 0.3) {
      bounceScale = 1.0 + (_bounce.value / 0.3) * 0.35;
    } else if (_bounce.value < 0.6) {
      bounceScale = 1.35 - ((_bounce.value - 0.3) / 0.3) * 0.43;
    } else {
      bounceScale = 0.92 + ((_bounce.value - 0.6) / 0.4) * 0.08;
    }

    // Glow peaks at bounce peak
    final glowT =
        _bounce.value < 0.5 ? _bounce.value * 2 : 2 - _bounce.value * 2;

    // Rolling counter — fiable avec flag booléen
    final counterShown = _isRolling
        ? (_prevXP +
                (widget.currentXP - _prevXP) *
                    Curves.easeInOut.transform(_counterRoll.value))
            .round()
            .clamp(0, widget.xpNeeded)
        : _displayXP;

    // Floating +N XP label (floats downward to stay visible below status bar)
    final plusProgress = Curves.easeOutCubic.transform(_plusLabel.value);
    final plusOpacity = (1.0 - _plusLabel.value * 1.2).clamp(0.0, 1.0);
    final plusOffset = 50.0 * plusProgress;

    const color = AppTheme.xpBadgeBot;

    final badge = Transform.scale(
      scale: _bounce.isAnimating ? bounceScale : 1.0,
      child: Container(
        constraints: const BoxConstraints(minWidth: 80, minHeight: 46),
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.xpBadgeTop, AppTheme.xpBadgeBot],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.xpBadgeBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55 + glowT * 0.45),
              blurRadius: _bounce.isAnimating ? 14 + glowT * 16 : 14,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(color: Colors.black54, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('⚡', style: TextStyle(fontSize: AppTheme.fontRegular, height: 1)),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.xpLabel,
                    style: AppTheme.titleStyle(AppTheme.fontPico).copyWith(
                        color: AppTheme.goldLabel,
                        letterSpacing: 1,
                        height: 1)),
                Text(
                  '$counterShown/${widget.xpNeeded}',
                  style: GoogleFonts.fredoka(
                    fontSize: AppTheme.fontRegular,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    shadows: const [
                      Shadow(color: Colors.black38, blurRadius: 4)
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Expanding ring
    final ringRadius = 30.0 + _ring.value * 50.0;
    final ringOpacity = (1.0 - _ring.value).clamp(0.0, 1.0) * 0.7;

    return UnconstrainedBox(
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          badge,
          // Expanding ring pulse
          if (_ring.isAnimating)
            Positioned.fill(
              child: Center(
                child: Container(
                  width: ringRadius * 2,
                  height: ringRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: ringOpacity),
                      width: 2.5 * (1 - _ring.value),
                    ),
                  ),
                ),
              ),
            ),
          // Sparkle particles
          if (_sparkles.isAnimating)
            for (var i = 0; i < 8; i++)
              Positioned(
                top: 23 + sin((i / 8) * 2 * pi) * 35 * _sparkles.value - 4,
                left: 40 + cos((i / 8) * 2 * pi) * 45 * _sparkles.value - 4,
                child: Opacity(
                  opacity: (1.0 - _sparkles.value).clamp(0.0, 1.0),
                  child: i.isEven
                      ? Icon(Icons.star, size: 8 * (1 - _sparkles.value * 0.5), color: AppTheme.gold)
                      : Container(
                          width: 5 * (1 - _sparkles.value * 0.5),
                          height: 5 * (1 - _sparkles.value * 0.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)],
                          ),
                        ),
                ),
              ),
        if (_plusLabel.isAnimating && _gainedXP > 0)
          Positioned(
            bottom: plusOffset - 46,
            child: Opacity(
              opacity: plusOpacity,
              child: Text(
                '+$_gainedXP XP',
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontBody,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.gold,
                  shadows: [
                    Shadow(
                        color: AppTheme.gold.withValues(alpha: 0.8), blurRadius: 10),
                    const Shadow(color: Colors.black87, blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
