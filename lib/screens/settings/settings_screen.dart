import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/services/firestore_service.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shape_merge/core/services/notification_service.dart';
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
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
        child: SingleChildScrollView(
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
                child: const Icon(Icons.settings_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 12),

              // Title
              Text(l10n.settings.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontH4)),
              const SizedBox(height: 20),

              // Sound toggle
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

              // Music toggle
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

              // Account
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
                            style: GoogleFonts.nunito(fontSize: AppTheme.fontTiny, fontWeight: FontWeight.w900, color: AppTheme.redTop)),
                      )
                    : TextButton(
                        onPressed: () => ref.read(authServiceProvider).signInWithGoogle(),
                        child: Text(l10n.signInGoogle.toUpperCase(),
                            style: GoogleFonts.nunito(fontSize: AppTheme.fontTiny, fontWeight: FontWeight.w900, color: AppTheme.blueTop)),
                      ),
              ),

              // Profile tile (signed in only)
              if (user != null) ...[
                Divider(color: AppTheme.panelBorder.withValues(alpha: 0.3), height: 1, indent: 20, endIndent: 20),
                _ProfileTile(
                  avatarEmoji: avatarEmoji(player?.avatarId),
                  displayName: player?.displayName ?? user.displayName ?? '',
                  onTap: () => showProfileDialog(context, ref),
                ),
                Divider(color: AppTheme.panelBorder.withValues(alpha: 0.3), height: 1, indent: 20, endIndent: 20),
                _DeleteAccountTile(uid: user.uid),
              ],
              Divider(color: AppTheme.panelBorder.withValues(alpha: 0.3), height: 1, indent: 20, endIndent: 20),

              // Version
              _SettingsTile(
                icon: Icons.info_rounded,
                iconColor: AppTheme.purpleTop,
                title: '${l10n.version} 1.0.0',
              ),
              Divider(color: AppTheme.panelBorder.withValues(alpha: 0.3), height: 1, indent: 20, endIndent: 20),

              // Privacy
              _SettingsTile(
                icon: Icons.privacy_tip_rounded,
                iconColor: AppTheme.gold,
                title: l10n.privacyPolicy,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
              ),

              const SizedBox(height: 16),

              // Close button
              SizedBox(
                width: double.infinity,
                child: Button3D.green(
                  expand: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PremiumIcon.save(size: 28),
                      const SizedBox(width: 10),
                      Text('OK', style: AppTheme.titleStyle(AppTheme.fontBody)),
                    ],
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
              borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
              border: Border.all(color: iconColor.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: iconColor, size: 24, shadows: [Shadow(color: iconColor, blurRadius: 8)]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title.toUpperCase(), style: GoogleFonts.nunito(fontSize: AppTheme.fontSmall, fontWeight: FontWeight.w900, color: Colors.white)),
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
                  colors: [AppTheme.profileGradTop, AppTheme.profileGradBot],
                ),
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.6), width: 2),
              ),
              child: Center(child: Text(avatarEmoji, style: const TextStyle(fontSize: AppTheme.fontH3))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: GoogleFonts.nunito(fontSize: AppTheme.fontRegular, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(l10n.editProfile.toUpperCase(),
                      style: GoogleFonts.nunito(fontSize: AppTheme.fontMini, fontWeight: FontWeight.w700, color: AppTheme.gold, letterSpacing: 0.5)),
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

class _DeleteAccountTile extends ConsumerWidget {
  final String uid;
  const _DeleteAccountTile({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return _SettingsTile(
      icon: Icons.delete_forever_rounded,
      iconColor: AppTheme.redTop,
      title: l10n.deleteAccount,
      trailing: TextButton(
        onPressed: () => _confirm(context, ref, l10n),
        child: Text(
          l10n.deleteAccount.toUpperCase(),
          style: GoogleFonts.nunito(
              fontSize: AppTheme.fontMini, fontWeight: FontWeight.w900, color: AppTheme.redTop),
        ),
      ),
    );
  }

  Future<void> _confirm(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.panelBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Text(l10n.deleteAccountConfirm,
            style: GoogleFonts.fredoka(
                fontSize: AppTheme.fontH4, fontWeight: FontWeight.w700, color: Colors.white)),
        content: Text(l10n.deleteAccountConfirm,
            style:
                GoogleFonts.nunito(fontSize: AppTheme.fontSmall, color: AppTheme.settingsSubText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.later.toUpperCase(),
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800, color: AppTheme.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteAccount.toUpperCase(),
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900, color: AppTheme.redTop)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    // 1. Delete Firestore data (sub-collections + player doc + leaderboard)
    await ref.read(firestoreServiceProvider).deleteAccount(uid);

    // 2. Clear local storage
    final storage = await ref.read(localStorageProvider.future);
    await storage.clearAllData();

    // 3. Cancel all local notifications
    await NotificationService.instance.cancelAll();

    // 4. Delete Firebase Auth account (must be last)
    try {
      await ref.read(authServiceProvider).currentUser?.delete();
    } catch (e) {
      // Re-auth required on some providers — surface error to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: GoogleFonts.nunito(fontSize: AppTheme.fontXSmall, color: Colors.white),
            ),
            backgroundColor: AppTheme.redTop,
          ),
        );
      }
    }
  }
}
