import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/audio_provider.dart';
import 'package:shape_merge/providers/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final soundOn = ref.watch(audioProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.settings, style: AppTheme.titleStyle),
        leading: const BackButton(color: AppTheme.text),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sound toggle
          _SettingsTile(
            icon: soundOn ? Icons.volume_up : Icons.volume_off,
            title: soundOn ? l10n.soundOn : l10n.soundOff,
            trailing: Switch(
              value: soundOn,
              onChanged: (_) => ref.read(audioProvider.notifier).toggle(),
              activeColor: AppTheme.blue,
            ),
          ),
          const Divider(color: AppTheme.border),
          // Account
          _SettingsTile(
            icon: Icons.account_circle,
            title: user != null
                ? '${l10n.connected}: ${user.displayName ?? user.email ?? ''}'
                : l10n.notConnected,
            trailing: user != null
                ? TextButton(
                    onPressed: () =>
                        ref.read(authServiceProvider).signOut(),
                    child: Text(
                      l10n.signOut,
                      style: TextStyle(color: AppTheme.red),
                    ),
                  )
                : TextButton(
                    onPressed: () =>
                        ref.read(authServiceProvider).signInWithGoogle(),
                    child: Text(
                      l10n.signInGoogle,
                      style: TextStyle(color: AppTheme.blue),
                    ),
                  ),
          ),
          const Divider(color: AppTheme.border),
          // Version
          _SettingsTile(
            icon: Icons.info_outline,
            title: '${l10n.version} 1.0.0',
          ),
          const Divider(color: AppTheme.border),
          // Privacy
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            onTap: () {
              // TODO: open privacy policy URL
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.muted),
      title: Text(title, style: const TextStyle(color: AppTheme.text)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
