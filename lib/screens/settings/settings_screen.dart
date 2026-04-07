import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/audio_provider.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';
import 'package:shape_merge/screens/settings/profile_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final soundOn = ref.watch(audioProvider);
    final musicOn = ref.watch(musicProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final player = ref.watch(playerProvider).valueOrNull;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SpaceBackground()),
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Button3D.yellow(
                        padding: EdgeInsets.zero,
                        borderRadius: 22,
                        onPressed: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      Text(l10n.settings.toUpperCase(), style: AppTheme.titleStyle(24)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.panelBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.panelBorder, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFF111827), offset: Offset(0, 6)),
                          BoxShadow(color: Colors.black54, offset: Offset(0, 10), blurRadius: 14),
                        ],
                      ),
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            iconColor: soundOn ? AppTheme.greenTop : AppTheme.muted,
                            title: soundOn ? l10n.soundOn : l10n.soundOff,
                            trailing: Switch(
                              value: soundOn,
                              onChanged: (_) => ref.read(audioProvider.notifier).toggle(),
                              activeThumbColor: AppTheme.greenTop,
                              activeTrackColor: AppTheme.greenTop.withValues(alpha: 0.3),
                              inactiveThumbColor: AppTheme.muted,
                            ),
                          ),
                          Divider(color: AppTheme.panelBorder.withValues(alpha: 0.3), height: 1, indent: 20, endIndent: 20),
                          _SettingsTile(
                            icon: musicOn ? Icons.music_note_rounded : Icons.music_off_rounded,
                            iconColor: musicOn ? AppTheme.purpleTop : AppTheme.muted,
                            title: musicOn ? l10n.musicOn : l10n.musicOff,
                            trailing: Switch(
                              value: musicOn,
                              onChanged: (_) => ref.read(musicProvider.notifier).toggle(),
                              activeThumbColor: AppTheme.purpleTop,
                              activeTrackColor: AppTheme.purpleTop.withValues(alpha: 0.3),
                              inactiveThumbColor: AppTheme.muted,
                            ),
                          ),
                          Divider(color: AppTheme.panelBorder.withValues(alpha: 0.3), height: 1, indent: 20, endIndent: 20),
                          _SettingsTile(
                            icon: Icons.account_circle_rounded,
                            iconColor: user != null ? AppTheme.blueTop : AppTheme.muted,
                            title: user != null
                                ? '${l10n.connected}:\n${player?.displayName ?? user.displayName ?? user.email ?? ''}'
                                : l10n.notConnected,
                            trailing: user != null
                                ? TextButton(
                                    onPressed: () => ref.read(authServiceProvider).signOut(),
                                    child: Text(l10n.signOut.toUpperCase(),
                                        style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.redTop)),
                                  )
                                : TextButton(
                                    onPressed: () => ref.read(authServiceProvider).signInWithGoogle(),
                                    child: Text(l10n.signInGoogle.toUpperCase(),
                                        style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.blueTop)),
                                  ),
                          ),
                          if (user != null) ...[
                            Divider(color: AppTheme.panelBorder.withValues(alpha: 0.3), height: 1, indent: 20, endIndent: 20),
                            _ProfileTile(
                              avatarEmoji: avatarEmoji(player?.avatarId),
                              displayName: player?.displayName ?? user.displayName ?? '',
                              onTap: () => showProfileDialog(context, ref),
                            ),
                          ],
                          Divider(color: AppTheme.panelBorder.withValues(alpha: 0.3), height: 1, indent: 20, endIndent: 20),
                          _SettingsTile(
                            icon: Icons.info_rounded,
                            iconColor: AppTheme.purpleTop,
                            title: '${l10n.version} 1.0.0',
                          ),
                          Divider(color: AppTheme.panelBorder.withValues(alpha: 0.3), height: 1, indent: 20, endIndent: 20),
                          _SettingsTile(
                            icon: Icons.privacy_tip_rounded,
                            iconColor: AppTheme.gold,
                            title: l10n.privacyPolicy,
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;

  const _SettingsTile({required this.icon, required this.iconColor, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: iconColor, size: 24, shadows: [Shadow(color: iconColor, blurRadius: 8)]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title.toUpperCase(), style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String avatarEmoji;
  final String displayName;
  final VoidCallback onTap;

  const _ProfileTile({required this.avatarEmoji, required this.displayName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4338ca), Color(0xFF6366f1)],
                ),
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.6), width: 2),
              ),
              child: Center(child: Text(avatarEmoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(l10n.editProfile.toUpperCase(),
                      style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.gold, letterSpacing: 0.5)),
                ],
              ),
            ),
            const Icon(Icons.edit_rounded, color: AppTheme.gold, size: 20),
          ],
        ),
      ),
    );
  }
}
