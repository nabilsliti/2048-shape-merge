import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';

/// Predefined avatar list — emoji-based for simplicity
const avatarList = [
  {'id': 'robot', 'emoji': '🤖'},
  {'id': 'alien', 'emoji': '👾'},
  {'id': 'rocket', 'emoji': '🚀'},
  {'id': 'fire', 'emoji': '🔥'},
  {'id': 'star', 'emoji': '⭐'},
  {'id': 'diamond', 'emoji': '💎'},
  {'id': 'crown', 'emoji': '👑'},
  {'id': 'lightning', 'emoji': '⚡'},
  {'id': 'skull', 'emoji': '💀'},
  {'id': 'ghost', 'emoji': '👻'},
  {'id': 'ninja', 'emoji': '🥷'},
  {'id': 'wizard', 'emoji': '🧙'},
  {'id': 'dragon', 'emoji': '🐉'},
  {'id': 'unicorn', 'emoji': '🦄'},
  {'id': 'phoenix', 'emoji': '🐦‍🔥'},
  {'id': 'cat', 'emoji': '🐱'},
  {'id': 'wolf', 'emoji': '🐺'},
  {'id': 'eagle', 'emoji': '🦅'},
  {'id': 'trophy', 'emoji': '🏆'},
  {'id': 'heart', 'emoji': '❤️'},
];

/// Returns emoji string for a given avatar ID (or default)
String avatarEmoji(String? avatarId) {
  if (avatarId == null) return '👤';
  final match = avatarList.where((a) => a['id'] == avatarId);
  return match.isNotEmpty ? match.first['emoji']! : '👤';
}

/// Shows the profile editing dialog — works for both signed-in and guest users
Future<void> showProfileDialog(BuildContext context, WidgetRef ref) async {
  final user = ref.read(authStateProvider).valueOrNull;
  final player = ref.read(playerProvider).valueOrNull;
  final localStorage = ref.read(localStorageProvider).valueOrNull;

  final isSignedIn = user != null;
  final String initialName;
  final String? initialAvatar;

  if (isSignedIn) {
    initialName = player?.displayName ?? user.displayName ?? '';
    initialAvatar = player?.avatarId;
  } else {
    initialName = localStorage?.guestName ?? 'Guest';
    initialAvatar = localStorage?.guestAvatar;
  }

  final result = await showDialog<_ProfileResult>(
    context: context,
    builder: (ctx) => _ProfileEditDialog(
      initialName: initialName,
      initialAvatarId: initialAvatar,
      isSignedIn: isSignedIn,
      email: user?.email,
    ),
  );

  if (result == null || !context.mounted) return;

  // Handle sign out
  if (result.signOut) {
    await ref.read(authServiceProvider).signOut();
    ref.invalidate(playerProvider);
    return;
  }

  // Handle sign in
  if (result.signIn) {
    await ref.read(authServiceProvider).signInWithGoogle();
    ref.invalidate(playerProvider);
    return;
  }

  // Save profile
  if (isSignedIn) {
    await ref.read(firestoreServiceProvider).updateProfile(
      user.uid,
      displayName: result.name,
      avatarId: result.avatarId,
    );
    ref.invalidate(playerProvider);
  } else if (localStorage != null) {
    await localStorage.setGuestName(result.name);
    await localStorage.setGuestAvatar(result.avatarId);
    ref.invalidate(localStorageProvider);
  }
}

class _ProfileResult {
  final String name;
  final String avatarId;
  final bool signOut;
  final bool signIn;
  const _ProfileResult(this.name, this.avatarId, {this.signOut = false, this.signIn = false});
}

class _ProfileEditDialog extends StatefulWidget {
  final String initialName;
  final String? initialAvatarId;
  final bool isSignedIn;
  final String? email;

  const _ProfileEditDialog({
    required this.initialName,
    this.initialAvatarId,
    required this.isSignedIn,
    this.email,
  });

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  late final TextEditingController _nameCtrl;
  late String _selectedAvatarId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _selectedAvatarId = widget.initialAvatarId ?? 'robot';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _dismiss(_ProfileResult result) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.panelBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.panelBorder, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0xFF111827), offset: Offset(0, 8)),
            BoxShadow(color: Colors.black54, offset: Offset(0, 12), blurRadius: 20),
          ],
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Title
            Text(l10n.editProfile.toUpperCase(), style: AppTheme.titleStyle(20)),
            const SizedBox(height: 20),

            // Current avatar preview
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4338ca), Color(0xFF6366f1)],
                ),
                border: Border.all(color: AppTheme.gold, width: 3),
                boxShadow: [
                  BoxShadow(color: AppTheme.gold.withValues(alpha: 0.3), blurRadius: 12),
                ],
              ),
              child: Center(
                child: Text(
                  avatarEmoji(_selectedAvatarId),
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),

            // Email badge (signed in only)
            if (widget.isSignedIn && widget.email != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.greenTop, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    widget.email!,
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.muted),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Name field
            Text(l10n.displayName.toUpperCase(),
                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.muted, letterSpacing: 1)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              maxLength: 20,
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterStyle: GoogleFonts.nunito(color: AppTheme.muted, fontSize: 10),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.panelBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.panelBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.gold, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Avatar picker label
            Text(l10n.chooseAvatar.toUpperCase(),
                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.muted, letterSpacing: 1)),
            const SizedBox(height: 8),

            // Avatar grid
            SizedBox(
              height: 180,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: avatarList.length,
                itemBuilder: (ctx, index) {
                  final avatar = avatarList[index];
                  final isSelected = avatar['id'] == _selectedAvatarId;
                  return GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _selectedAvatarId = avatar['id']!);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.gold.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.gold : Colors.white.withValues(alpha: 0.1),
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(avatar['emoji']!, style: TextStyle(fontSize: isSelected ? 28 : 24)),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: Button3D.green(
                expand: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  _dismiss(_ProfileResult(name, _selectedAvatarId));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PremiumIcon.save(size: 28),
                    const SizedBox(width: 10),
                    Text(l10n.save.toUpperCase(), style: AppTheme.titleStyle(18)),
                  ],
                ),
              ),
            ),

            // Sign out button (signed in only)
            if (widget.isSignedIn) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Button3D.red(
                  expand: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () => _dismiss(const _ProfileResult('', '', signOut: true)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PremiumIcon.logout(size: 28),
                      const SizedBox(width: 10),
                      Text(l10n.signOut.toUpperCase(), style: AppTheme.titleStyle(18)),
                    ],
                  ),
                ),
              ),
            ],

            // Sign in with Google (guest only)
            if (!widget.isSignedIn) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Button3D.blue(
                  expand: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () => _dismiss(const _ProfileResult('', '', signIn: true)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Center(child: Text('G', style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF4285F4)))),
                      ),
                      const SizedBox(width: 10),
                      Text(l10n.signInGoogle.toUpperCase(), style: AppTheme.titleStyle(18)),
                    ],
                  ),
                ),
              ),
            ],
          ], // children
          ), // Column
        ), // SingleChildScrollView
        ), // GestureDetector
      ), // Container
    ); // Dialog
  }
}
