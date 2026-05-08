import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shape_merge/core/config/app_routes.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/audio_provider.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final soundEnabled = ref.watch(audioProvider);
    final musicEnabled = ref.watch(musicProvider);

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
                          child: Text(l10n.settings.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontH2)),
                        ),
                      ],
                    ),
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                        // Sound toggle
                        _SettingsTile(
                icon: soundEnabled ? Icons.volume_up : Icons.volume_off,
                label: l10n.soundSettings,
                trailing: Switch(
                  value: soundEnabled,
                  activeThumbColor: AppTheme.greenTop,
                  onChanged: (_) {
                    ref.read(audioProvider.notifier).toggle();
                  },
                ),
              ),

              // Music toggle
              _SettingsTile(
                icon: musicEnabled ? Icons.music_note : Icons.music_off,
                label: l10n.musicSettings,
                trailing: Switch(
                  value: musicEnabled,
                  activeThumbColor: AppTheme.greenTop,
                  onChanged: (_) {
                    ref.read(musicProvider.notifier).toggle();
                  },
                ),
              ),

              // Vibration toggle
              _SettingsTile(
                icon: Icons.vibration,
                label: l10n.vibrationSettings,
                iconStrikethrough: !ref.watch(vibrationProvider),
                trailing: Switch(
                  value: ref.watch(vibrationProvider),
                  activeThumbColor: AppTheme.greenTop,
                  onChanged: (_) {
                    ref.read(vibrationProvider.notifier).toggle();
                  },
                ),
              ),


              const SizedBox(height: 24),
              const SizedBox(height: 16),

              // Version info
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: l10n.version,
                trailing: Text(
                  _version,
                  style: GoogleFonts.fredoka(
                    fontSize: AppTheme.fontSmall,
                    color: Colors.white54,
                  ),
                ),
              ),

              const SizedBox(height: 80),
                      ],
                    ),
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
    this.iconStrikethrough = false,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final bool iconStrikethrough;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              children: [
                Icon(icon, color: Colors.white70, size: 24),
                if (iconStrikethrough)
                  CustomPaint(
                    size: const Size(24, 24),
                    painter: _StrikethroughPainter(),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: AppTheme.fontBody,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _StrikethroughPainter extends CustomPainter {
  static final _paint = Paint()
    ..color = Colors.white70
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.9, size.height * 0.9),
      _paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


