import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/ad_banner_widget.dart';
import 'package:shape_merge/providers/audio_provider.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/screens/home/home_screen.dart';
import 'package:shape_merge/screens/settings/profile_dialog.dart';

class MainHubScreen extends ConsumerWidget {
  const MainHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
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

          // Ad Banner — anchored to bottom, above system nav bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AdBannerWidget(),
                Container(
                  color: AppTheme.panelBg,
                  height: MediaQuery.of(context).padding.bottom,
                ),
              ],
            ),
          ),
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
                color: const Color(0xFFff2d87).withOpacity(0.3),
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
                color: const Color(0xFF00d4ff).withOpacity(0.3),
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

    // Determine current avatar
    final String currentAvatar;
    if (user != null) {
      currentAvatar = avatarEmoji(player?.avatarId);
    } else {
      final localStorage = ref.watch(localStorageProvider).valueOrNull;
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
          Button3D.purple(
            padding: EdgeInsets.zero,
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const SettingsModal(),
              );
            },
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(Icons.settings, color: Colors.white, size: 22),
            ),
          ),
          const Spacer(),
          // Avatar / Profile button — aligned right
          Button3D.purple(
            padding: EdgeInsets.zero,
            onPressed: () => showProfileDialog(context, ref),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Text(currentAvatar, style: const TextStyle(fontSize: 22)),
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
  @override
  Widget build(BuildContext context) {
    final soundOn = ref.watch(audioProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFf0f0f0), width: 4),
              boxShadow: const [
                BoxShadow(
                    color: Color(0xFFcccccc), offset: Offset(0, 15)),
                BoxShadow(
                    color: Colors.black54,
                    offset: Offset(0, 25),
                    blurRadius: 30),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("RÉGLAGES",
                    style: GoogleFonts.fredoka(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF333333))),
                const SizedBox(height: 15),
                _settingToggle(
                    "Musique", Icons.music_note, AppTheme.purpleTop, soundOn,
                    (v) {
                  ref.read(audioProvider.notifier).toggle();
                }),
                const SizedBox(height: 20),
                Button3D.blue(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.language, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text("LANGUE : FRANÇAIS",
                                  style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -20,
            right: -15,
            child: Button3D.red(
              padding: EdgeInsets.zero,
              borderRadius: 25,
              onPressed: () => Navigator.of(context).pop(),
              child: const SizedBox(
                width: 50,
                height: 50,
                child: Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingToggle(String title, IconData icon, Color iconColor,
      bool isOn, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isOn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
            color: const Color(0xFFf8f9fa),
            border: Border.all(color: const Color(0xFFe9ecef), width: 2),
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 10),
                Text(title,
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF333333))),
              ],
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 32,
              decoration: BoxDecoration(
                  color:
                      isOn ? AppTheme.greenTop : const Color(0xFFcccccc),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: isOn
                            ? AppTheme.greenBot
                            : const Color(0xFF999999),
                        offset: const Offset(0, 3))
                  ]),
              alignment:
                  isOn ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black38,
                          blurRadius: 6,
                          offset: Offset(0, 4))
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
