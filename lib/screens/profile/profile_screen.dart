import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/config/app_routes.dart';
import 'package:shape_merge/core/config/avatar_catalog.dart';
import 'package:shape_merge/core/constants/retention_ui.dart';
import 'package:shape_merge/core/constants/shape_pack.dart';
import 'package:shape_merge/core/constants/shape_types.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/avatar_picker_grid.dart';
import 'package:shape_merge/core/widgets/google_sign_in_button.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/iap_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/providers/shape_pack_provider.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late String _selectedAvatarId;
  bool _isEditingName = false;
  late TextEditingController _nameCtrl;
  bool _initialized = false;
  bool _signingIn = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _initFromProviders() {
    final user = ref.read(authStateProvider).valueOrNull;
    final player = ref.read(playerProvider).valueOrNull;
    final localStorage = ref.read(localStorageProvider).valueOrNull;
    final isSignedIn = user != null;

    _selectedAvatarId = (isSignedIn ? player?.avatarId : localStorage?.guestAvatar) ?? 'robot';

    final name = isSignedIn
        ? (player?.displayName ?? user.displayName ?? '')
        : (localStorage?.guestName ?? '');
    _nameCtrl.text = name;
    _initialized = true;
  }

  Future<void> _saveAvatar(String avatarId) async {
    setState(() => _selectedAvatarId = avatarId);

    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      await ref.read(firestoreServiceProvider).updateProfile(
        user.uid,
        avatarId: avatarId,
      );
      ref.invalidate(playerProvider);
    } else {
      final localStorage = await ref.read(localStorageProvider.future);
      await localStorage.setGuestAvatar(avatarId);
      ref.invalidate(localStorageProvider);
    }
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isEditingName = false);

    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      await ref.read(firestoreServiceProvider).updateProfile(
        user.uid,
        displayName: name,
      );
      ref.invalidate(playerProvider);
    } else {
      final localStorage = await ref.read(localStorageProvider.future);
      await localStorage.setGuestName(name);
      ref.invalidate(localStorageProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).valueOrNull;
    final player = ref.watch(playerProvider).valueOrNull;
    final localStorage = ref.watch(localStorageProvider).valueOrNull;
    final gameState = ref.watch(gameStateProvider);

    final isSignedIn = user != null;

    if (!_initialized) {
      _initFromProviders();
    } else {
      // Re-sync avatar & name when auth state changes (sign-in / sign-out)
      final freshAvatar = (isSignedIn ? player?.avatarId : localStorage?.guestAvatar) ?? 'robot';
      if (freshAvatar != _selectedAvatarId) {
        _selectedAvatarId = freshAvatar;
      }
      final freshName = isSignedIn
          ? (player?.displayName ?? user.displayName ?? '')
          : (localStorage?.guestName ?? '');
      if (!_isEditingName && freshName != _nameCtrl.text) {
        _nameCtrl.text = freshName;
      }
    }

    final displayName = isSignedIn
        ? (player?.displayName ?? user.displayName ?? l10n.guestPlayer)
        : (localStorage?.guestName ?? l10n.guestPlayer);
    final avatarText = AvatarCatalog.emoji(_selectedAvatarId);
    final bestScore = gameState.bestScore;

    return Stack(
      children: [
        const Positioned.fill(child: SpaceBackground()),
        DefaultTextStyle(
          style: const TextStyle(decoration: TextDecoration.none),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header bar with back arrow + title
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
                  child: SizedBox(
                    height: 50,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Button3D.gold(
                            padding: EdgeInsets.zero,
                            borderRadius: 22,
                            onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: PremiumIcon.back(size: 22),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(l10n.profile.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontH2)),
                        ),
                      ],
                    ),
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      children: [

              // Avatar circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.profileGradTop, AppTheme.profileGradBot],
                  ),
                  border: Border.all(color: AppTheme.gold, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(avatarText, style: const TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 16),

              // Name + edit pencil
              if (_isEditingName)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _nameCtrl,
                        maxLength: 20,
                        autofocus: true,
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          counterText: '',
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onSubmitted: (_) => _saveName(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _saveName,
                      child: const Icon(Icons.check_circle_rounded, color: AppTheme.greenTop, size: 28),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _isEditingName = true),
                      child: const Icon(Icons.edit, color: AppTheme.muted, size: 20),
                    ),
                  ],
                ),

              const SizedBox(height: 4),
              if (isSignedIn && user.email != null)
                Text(
                  user.email!,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),

              // Sign in with Google (guest only) — right under pseudo
              if (!isSignedIn) ...[
                const SizedBox(height: 16),
                GoogleSignInButton(
                  onPressed: _signingIn ? null : () async {
                    setState(() => _signingIn = true);
                    try {
                      final authService = ref.read(authServiceProvider);
                      final cred = await authService.signInWithGoogle();
                      if (!context.mounted) return;
                      if (cred != null) {
                        ref.invalidate(playerProvider);
                        setState(() => _initialized = false);
                      } else if (authService.lastError != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.signInError(authService.lastError!)),
                            duration: const Duration(seconds: 10),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _signingIn = false);
                    }
                  },
                ),
              ],

              const SizedBox(height: 20),

              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.emoji_events_rounded,
                      label: l10n.bestScore,
                      value: '$bestScore',
                      color: RetentionUI.scoreColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.military_tech_rounded,
                      label: l10n.levelLabel,
                      value: '${isSignedIn ? (player?.level ?? localStorage?.playerLevel ?? 1) : (localStorage?.playerLevel ?? 1)}',
                      color: RetentionUI.levelColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.sports_esports_rounded,
                      label: l10n.gamesPlayed,
                      value: '${isSignedIn ? (player?.gamesPlayed ?? 0) : (localStorage?.gamesPlayed ?? 0)}',
                      color: RetentionUI.gamesColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      label: l10n.bestStreak,
                      value: '${isSignedIn ? (player?.longestStreak ?? 0) : (localStorage?.longestStreak ?? 0)}',
                      color: RetentionUI.streakColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Avatar picker card
              Container(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 2),
                decoration: BoxDecoration(
                  color: AppTheme.panelBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: AppTheme.panelBorder, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.chooseAvatar.toUpperCase(),
                      style: GoogleFonts.nunito(
                        fontSize: AppTheme.fontTiny,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.muted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AvatarPickerGrid(
                      selectedAvatarId: _selectedAvatarId,
                      playerLevel: isSignedIn
                          ? (player?.level ?? localStorage?.playerLevel ?? 1)
                          : (localStorage?.playerLevel ?? 1),
                      onAvatarSelected: _saveAvatar,
                      showCheckmark: true,
                      spacing: 6,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Shape pack picker card
              _ShapePackPickerCard(),

              const SizedBox(height: 24),

              // Sign out button (signed in only)
              if (isSignedIn)
                Button3D(
                  topColor: AppTheme.redTop,
                  bottomColor: AppTheme.redBot,
                  borderColor: AppTheme.redTop,
                  expand: true,
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PremiumIcon.logout(size: 24),
                      const SizedBox(width: 8),
                      Text(
                        l10n.signOut.toUpperCase(),
                        style: AppTheme.titleStyle(AppTheme.fontBody),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
      );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.fredoka(
                  fontSize: 11,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShapePackPickerCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentPack = ref.watch(shapePackProvider);
    final emojiUnlocked = ref.watch(emojiPackPurchasedProvider);

    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.panelBorder, width: 2),
      ),
      child: Column(
        children: [
          Text(
            l10n.shapePackLabel.toUpperCase(),
            style: GoogleFonts.nunito(
              fontSize: AppTheme.fontTiny,
              fontWeight: FontWeight.w900,
              color: AppTheme.muted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.4,
            ),
            itemCount: ShapePack.values.length,
            itemBuilder: (ctx, index) {
              final pack = ShapePack.values[index];
              final isSelected = pack == currentPack;
              final isLocked = pack == ShapePack.emoji && !emojiUnlocked;

              return GestureDetector(
                key: ValueKey(pack),
                onTap: () {
                  if (isLocked) return;
                  ref.read(shapePackProvider.notifier).select(pack);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.gold.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppTheme.radiusTiny),
                    border: Border.all(
                      color: isSelected ? AppTheme.gold : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _previewShapes(pack),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _packLabel(pack, l10n),
                              style: GoogleFonts.fredoka(
                                fontSize: AppTheme.fontSmall,
                                fontWeight: FontWeight.w700,
                                color: isLocked ? Colors.white38 : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.gold,
                            size: 18,
                          ),
                        ),
                      if (isLocked)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.lock_rounded,
                            color: Colors.white38,
                            size: 18,
                          ),
                        ),

                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _packLabel(ShapePack pack, AppLocalizations l10n) => switch (pack) {
        ShapePack.classic => l10n.shapePackClassic,
        ShapePack.emoji => l10n.shapePackEmoji,
      };

  static const _previewTypes = [
    ShapeType.circle,
    ShapeType.square,
    ShapeType.triangle,
    ShapeType.star,
  ];

  static const _previewColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFF95E1D3),
  ];

  List<Widget> _previewShapes(ShapePack pack) {
    return List.generate(_previewTypes.length, (i) {
      final type = _previewTypes[i];
      final color = _previewColors[i];
      final svgPath = ShapePackAssets.svgAsset(pack, type);

      if (svgPath != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: SvgPicture.asset(
            svgPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: _ClassicShapeIcon(type: type, color: color, size: 24),
      );
    });
  }
}

class _ClassicShapeIcon extends StatelessWidget {
  const _ClassicShapeIcon({
    required this.type,
    required this.color,
    required this.size,
  });

  final ShapeType type;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ClassicShapePainter(type: type, color: color),
    );
  }
}

class _ClassicShapePainter extends CustomPainter {
  _ClassicShapePainter({required this.type, required this.color});

  final ShapeType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.4;

    switch (type) {
      case ShapeType.circle:
        canvas.drawCircle(Offset(cx, cy), r, paint);
      case ShapeType.square:
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.6, height: r * 1.6);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.15)), paint);
      case ShapeType.triangle:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy + r * 0.8)
          ..lineTo(cx - r, cy + r * 0.8)
          ..close();
        canvas.drawPath(path, paint);
      case ShapeType.diamond:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.7, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r * 0.7, cy)
          ..close();
        canvas.drawPath(path, paint);
      case ShapeType.star:
        final path = Path();
        for (int i = 0; i < 5; i++) {
          final outerAngle = -pi / 2 + (2 * pi / 5) * i;
          final innerAngle = outerAngle + pi / 5;
          final outerX = cx + r * cos(outerAngle);
          final outerY = cy + r * sin(outerAngle);
          final innerX = cx + r * 0.4 * cos(innerAngle);
          final innerY = cy + r * 0.4 * sin(innerAngle);
          if (i == 0) {
            path.moveTo(outerX, outerY);
          } else {
            path.lineTo(outerX, outerY);
          }
          path.lineTo(innerX, innerY);
        }
        path.close();
        canvas.drawPath(path, paint);
      case ShapeType.hexagon:
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = -pi / 2 + (2 * pi / 6) * i;
          final x = cx + r * cos(angle);
          final y = cy + r * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ClassicShapePainter old) => type != old.type || color != old.color;
}
