import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/models/leaderboard_entry.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/ad_banner_widget.dart';
import 'package:shape_merge/core/widgets/joker_icons.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';
import 'package:shape_merge/screens/settings/profile_dialog.dart';

void _debugFirestore() async {
  try {
    final snap = await FirebaseFirestore.instance.collection('leaderboard').get();
    debugPrint('🔥 Direct Firestore read: ${snap.docs.length} docs');
    for (final doc in snap.docs) {
      debugPrint('  📄 ${doc.id}: ${doc.data()}');
    }
  } catch (e) {
    debugPrint('🔥❌ Direct Firestore read FAILED: $e');
  }
}

/// Standalone screen (used by router for /leaderboard fallback).
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SpaceBackground()),
          const LeaderboardScreenContent(),
        ],
      ),
    );
  }
}

/// Embeddable content widget used inside MainHubScreen tab.
class LeaderboardScreenContent extends ConsumerWidget {
  const LeaderboardScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isSignedIn = ref.watch(authStateProvider).valueOrNull != null;

    if (!isSignedIn) {
      return SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
              child: SizedBox(
                height: 50,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Button3D.yellow(
                        padding: EdgeInsets.zero,
                        borderRadius: 22,
                        onPressed: () => context.go('/home'),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(l10n.leaderboard.toUpperCase(), style: AppTheme.titleStyle(24)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trophy icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4338ca), Color(0xFF6366f1)],
                          ),
                          border: Border.all(color: AppTheme.panelBorder, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, offset: Offset(0, 6), blurRadius: 12),
                          ],
                        ),
                        child: const Center(
                          child: Text('🏆', style: TextStyle(fontSize: 48)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.signInToSave,
                        style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white70, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Button3D.blue(
                          expand: true,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onPressed: () => ref.read(authServiceProvider).signInWithGoogle(),
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
                  ),
                ),
              ),
            ),
            // Ad banner
            const AdBannerWidget(),
          ],
        ),
      );
    }

    final leaderboard = ref.watch(leaderboardProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
            child: SizedBox(
              height: 50,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Button3D.yellow(
                      padding: EdgeInsets.zero,
                      borderRadius: 22,
                      onPressed: () => context.go('/home'),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(l10n.leaderboard.toUpperCase(), style: AppTheme.titleStyle(24)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: leaderboard.when(
              data: (entries) {
                debugPrint('📊 Leaderboard data: ${entries.length} entries');

                if (entries.isEmpty) {
                  _debugFirestore();
                  return Center(
                    child: Text('No scores yet', style: GoogleFonts.nunito(color: AppTheme.muted, fontWeight: FontWeight.w900)),
                  );
                }

                // Find current user entry & rank
                final currentUser = ref.watch(authStateProvider).valueOrNull;
                final myUid = currentUser?.uid;
                final myIndex = entries.indexWhere((e) => e.uid == myUid);
                final meEntry = myIndex >= 0 ? entries[myIndex] : null;
                final myRank = myIndex >= 0 ? myIndex + 1 : null;
                // Show sticky card only if user is NOT visible in the list
                final bool showStickyMe = meEntry != null && myRank != null && myRank > 10;

                // ── Shared card builder ──
                Widget buildCard(LeaderboardEntry entry, int rank, bool isMe, bool isTop3, int visualIndex) {
                  const accents = [Color(0xFFFFD740), Color(0xFFB0BEC5), Color(0xFFFF8A65)];
                  const meAccent = Color(0xFF60a5fa);
                  final accent = isMe ? meAccent : (isTop3 ? accents[visualIndex] : Colors.white.withValues(alpha: 0.08));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: (isTop3 || isMe)
                            ? [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)]
                            : [Colors.white.withValues(alpha: 0.06), Colors.white.withValues(alpha: 0.02)],
                      ),
                      border: Border.all(
                        color: (isTop3 || isMe) ? accent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
                        width: (isTop3 || isMe) ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: (isTop3 || isMe) ? 0.4 : 0.25),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // ── Rank badge ──
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: isTop3
                              ? CustomPaint(painter: _MedalPainter(rank: visualIndex))
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isMe ? meAccent.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.06),
                                    border: Border.all(color: isMe ? meAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$rank',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 14, fontWeight: FontWeight.w700,
                                      color: isMe ? meAccent : Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        // ── Avatar ──
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: (isTop3 || isMe)
                                  ? [accent.withValues(alpha: 0.3), accent.withValues(alpha: 0.1)]
                                  : [const Color(0xFF374151), const Color(0xFF1f2937)],
                            ),
                            border: Border.all(
                              color: (isTop3 || isMe) ? accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 2), blurRadius: 4),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(avatarEmoji(entry.avatarId), style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 8),
                        // ── Name ──
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.displayName,
                                style: GoogleFonts.nunito(
                                  fontSize: 13, fontWeight: FontWeight.w800,
                                  color: isMe ? meAccent : (isTop3 ? Colors.white : Colors.white.withValues(alpha: 0.8)),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isMe)
                                Text(
                                  'You',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                    color: meAccent.withValues(alpha: 0.6),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ── Score ──
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: (isTop3 || isMe) ? accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                            border: Border.all(
                              color: (isTop3 || isMe) ? accent.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Text(
                            '${entry.score}',
                            style: GoogleFonts.fredoka(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: (isTop3 || isMe) ? accent : Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // ── Scrollable list ──
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 6),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final rank = index + 1;
                          final isTop3 = index < 3;
                          final isMe = entry.uid == myUid;
                          return buildCard(entry, rank, isMe, isTop3, index);
                        },
                      ),
                    ),
                    // ── Sticky "my rank" card (only if not in visible list) ──
                    if (showStickyMe)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: buildCard(meEntry, myRank, true, false, 0),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text('Error loading leaderboard', style: GoogleFonts.nunito(color: AppTheme.redTop, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          // Ad banner
          const AdBannerWidget(),
        ],
      ),
    );
  }
}

// ─── Premium rank badge painter ─────────────────────────────
class _MedalPainter extends CustomPainter {
  final int rank; // 0=gold, 1=silver, 2=bronze

  _MedalPainter({required this.rank});

  static const _configs = [
    // Gold
    (g1: Color(0xFFFFE082), g2: Color(0xFFFFB300), g3: Color(0xFFF57F17), glow: Color(0x66FFD740), text: Color(0xFF4E342E), shine: Color(0xFFFFFDE7)),
    // Silver
    (g1: Color(0xFFE0E0E0), g2: Color(0xFF90A4AE), g3: Color(0xFF455A64), glow: Color(0x55B0BEC5), text: Color(0xFF263238), shine: Color(0xFFFFFFFF)),
    // Bronze
    (g1: Color(0xFFFFCCBC), g2: Color(0xFFFF7043), g3: Color(0xFFBF360C), glow: Color(0x55FF8A65), text: Color(0xFF3E2723), shine: Color(0xFFFFF3E0)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = _configs[rank.clamp(0, 2)];
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.44;

    // ── Glow ──
    canvas.drawCircle(Offset(cx, cy), r * 1.3, Paint()
      ..color = c.glow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // ── Hexagon path ──
    Path hex(double radius, [double offsetY = 0]) {
      final p = Path();
      for (var i = 0; i < 6; i++) {
        final a = (i * pi / 3) - pi / 2;
        final px = cx + radius * cos(a);
        final py = cy + offsetY + radius * sin(a);
        if (i == 0) p.moveTo(px, py); else p.lineTo(px, py);
      }
      p.close();
      return p;
    }

    // ── Shadow ──
    canvas.drawPath(hex(r, 2), Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // ── Main hexagon fill ──
    final hexPath = hex(r);
    final hexRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawPath(hexPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c.g1, c.g2, c.g3],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(hexRect));

    // ── Bevel stroke ──
    canvas.drawPath(hexPath, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c.shine.withValues(alpha: 0.7), c.g3.withValues(alpha: 0.3)],
      ).createShader(hexRect));

    // ── Inner hex ring ──
    canvas.drawPath(hex(r * 0.7), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = c.shine.withValues(alpha: 0.2));

    // ── Number ──
    final tp = TextPainter(
      text: TextSpan(
        text: '${rank + 1}',
        style: TextStyle(
          fontSize: r * 0.7,
          fontWeight: FontWeight.w900,
          color: c.text,
          height: 1.0,
          shadows: [Shadow(color: c.shine.withValues(alpha: 0.5), offset: const Offset(0, -0.5))],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    // ── Specular shine ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - r * 0.15, cy - r * 0.22), width: r * 0.45, height: r * 0.2),
      Paint()..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.4), Colors.white.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCenter(center: Offset(cx - r * 0.15, cy - r * 0.22), width: r * 0.45, height: r * 0.2)),
    );
  }

  @override
  bool shouldRepaint(covariant _MedalPainter old) => old.rank != rank;
}
