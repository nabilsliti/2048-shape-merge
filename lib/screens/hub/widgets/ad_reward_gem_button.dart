import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/local_storage_provider.dart';

// ═══════════════════════════════════════════════════════════════
// Ad Reward Button — pub icon + dynamic label.
//
// • If cooldown active   → padlock overlay + "M:SS" countdown, button disabled.
// • If daily cap reached → padlock overlay + "Demain", button disabled.
// • Otherwise            → shows "+1 🃏", button enabled.
// ═══════════════════════════════════════════════════════════════
class AdRewardGemButton extends ConsumerStatefulWidget {
  const AdRewardGemButton({super.key, required this.onTap});

  /// Called when the user taps an enabled button. Parent runs the ad +
  /// reveal flow, then calls `recordAdJokerWatched()` on storage so the
  /// countdown picks it up at the next tick.
  final VoidCallback onTap;

  @override
  ConsumerState<AdRewardGemButton> createState() => _AdRewardGemButtonState();
}

class _AdRewardGemButtonState extends ConsumerState<AdRewardGemButton> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatCooldown(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final LocalStorageService? storage =
        ref.watch(localStorageProvider).valueOrNull;

    final cooldown = storage?.adJokerCooldownRemaining ?? Duration.zero;
    final adsLeft = storage?.adJokerAdsLeftToday;
    final reachedCap = adsLeft == 0;
    final inCooldown = cooldown > Duration.zero;
    final canWatch = storage != null && !inCooldown && !reachedCap;

    final String label;
    final List<Color> labelGrad;
    if (reachedCap) {
      label = l10n.adJokerCapBadge;
      labelGrad = const [AppTheme.hubDangerRed1, AppTheme.hubDangerRed2];
    } else if (inCooldown) {
      label = _formatCooldown(cooldown);
      labelGrad = const [AppTheme.hubDangerRed1, AppTheme.hubDangerRed2];
    } else {
      label = '${l10n.rewardPlusN(1)} 🃏';
      labelGrad = const [AppTheme.hubStreakPurple1, AppTheme.hubStreakPurple2];
    }

    // When the daily cap is reached, taps still trigger a snackbar so the
    // user understands why the button is greyed out.
    void handleTap() {
      if (canWatch) {
        widget.onTap();
      } else if (reachedCap) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.adJokerLimitTomorrow,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppTheme.hubDangerRed1,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    return Opacity(
      opacity: canWatch ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: storage == null ? null : handleTap,
        child: SizedBox(
          width: 70,
          height: 82,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.navActiveCircle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    const BoxShadow(
                      color: AppTheme.navActiveShadow,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/pub.webp',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
              // Lock overlay when ad joker is unavailable (daily cap reached
              // OR 5-min cooldown active). Makes the disabled state instantly
              // readable: greyscale circle + padlock icon. The cooldown also
              // shows the M:SS countdown badge below.
              if (reachedCap || inCooldown)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              // "AD" badge top-right
              Positioned(
                top: -2,
                right: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.hubDangerRed1, AppTheme.hubDangerRed2],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    'AD',
                    style: GoogleFonts.fredoka(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
              // Dynamic label (cooldown / cap / +1)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: labelGrad),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.fredoka(
                        fontSize: AppTheme.fontTiny,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
