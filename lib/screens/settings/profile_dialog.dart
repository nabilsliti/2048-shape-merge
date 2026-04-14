import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/config/avatar_catalog.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';

/// Returns emoji string for a given avatar ID (or first avatar as default).
String avatarEmoji(String? avatarId) => AvatarCatalog.emoji(avatarId);

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
    initialName = localStorage?.guestName ?? AppLocalizations.of(context)!.defaultGuestName;
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
    return;
  }

  // Handle sign in
  if (result.signIn) {
    final authService = ref.read(authServiceProvider);
    final cred = await authService.signInWithGoogle();
    if (!context.mounted) return;
    if (cred != null) {
      _showSignInOverlay(context);
    } else if (authService.lastError != null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.signInError(authService.lastError!)),
          duration: const Duration(seconds: 10),
        ),
      );
    }
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

void _showSignInOverlay(BuildContext context) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _SignInOverlayContent(
      message: AppLocalizations.of(context)!.signInSuccess,
      onDone: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _SignInOverlayContent extends StatefulWidget {
  const _SignInOverlayContent({required this.message, required this.onDone});
  final String message;
  final VoidCallback onDone;

  @override
  State<_SignInOverlayContent> createState() => _SignInOverlayContentState();
}

class _SignInOverlayContentState extends State<_SignInOverlayContent> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
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
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 48)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1, end: 1.2, duration: 700.ms, curve: Curves.easeInOut),
              const SizedBox(height: 12),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: AppTheme.fontH2,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
            ],
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 300.ms)
            .then(delay: 1500.ms)
            .fadeOut(duration: 400.ms),
      ),
      ),
    );
  }
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Title
            Text(l10n.editProfile.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontH4)),
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
                  colors: [AppTheme.profileGradTop, AppTheme.profileGradBot],
                ),
                border: Border.all(color: AppTheme.gold, width: 3),
                boxShadow: [
                  BoxShadow(color: AppTheme.gold.withValues(alpha: 0.3), blurRadius: 12),
                ],
              ),
              child: Center(
                child: Text(
                  avatarEmoji(_selectedAvatarId),
                  style: const TextStyle(fontSize: AppTheme.fontEmoji),
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
                    style: GoogleFonts.nunito(fontSize: AppTheme.fontMini, fontWeight: FontWeight.w600, color: AppTheme.muted),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Name field
            Text(l10n.displayName.toUpperCase(),
                style: GoogleFonts.nunito(fontSize: AppTheme.fontTiny, fontWeight: FontWeight.w900, color: AppTheme.muted, letterSpacing: 1)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              maxLength: 20,
              style: GoogleFonts.nunito(fontSize: AppTheme.fontBody, fontWeight: FontWeight.w900, color: Colors.white),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterStyle: GoogleFonts.nunito(color: AppTheme.muted, fontSize: AppTheme.fontNano),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  borderSide: const BorderSide(color: AppTheme.panelBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  borderSide: const BorderSide(color: AppTheme.panelBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  borderSide: const BorderSide(color: AppTheme.gold, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Avatar picker label
            Text(l10n.chooseAvatar.toUpperCase(),
                style: GoogleFonts.nunito(fontSize: AppTheme.fontTiny, fontWeight: FontWeight.w900, color: AppTheme.muted, letterSpacing: 1)),
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
                itemCount: AvatarCatalog.all.length,
                itemBuilder: (ctx, index) {
                  final avatar = AvatarCatalog.all[index];
                  final isSelected = avatar.id == _selectedAvatarId;
                  return GestureDetector(
                    key: ValueKey(avatar.id),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _selectedAvatarId = avatar.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.gold.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
                        border: Border.all(
                          color: isSelected ? AppTheme.gold : Colors.white.withValues(alpha: 0.1),
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(avatar.emoji, style: TextStyle(fontSize: isSelected ? AppTheme.fontH1 : AppTheme.fontH2)),
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
                    Text(l10n.save.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
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
                      Text(l10n.signOut.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
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
                        child: Center(child: Text('G', style: GoogleFonts.fredoka(fontSize: AppTheme.fontGBtn, fontWeight: FontWeight.w900, color: AppTheme.googleBlue)))),
                      const SizedBox(width: 10),
                      Text(l10n.signInGoogle.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
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
        ], // Stack children
      ), // Stack
    ); // Dialog
  }
}
