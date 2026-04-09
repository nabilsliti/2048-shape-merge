import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single source of truth for ALL colors, font sizes, spacing and border radii.
/// No Color literal (0xFF…) should ever appear outside this file.
class AppTheme {
  AppTheme._();

  // ════════════════════════════════════════════════════════════════
  // COLORS
  // ════════════════════════════════════════════════════════════════

  // ── Main background gradient ──────────────────────────────────
  static const Color bgTop = Color(0xFFAA00FF);
  static const Color bgBot = Color(0xFF6200EA);

  // ── App background ────────────────────────────────────────────
  static const Color background   = Color(0xFF0A0020);
  static const Color panel        = Color(0xCC1A0040);
  static const Color panelBg      = Color(0xFF1A0040);
  static const Color panelBorder  = Color(0xFFE040FB);
  static const Color scaffoldBg   = Color(0xFF060018);

  // ── Space / nebula background stops ──────────────────────────
  static const Color spaceDeep1   = Color(0xFF2A0060);
  static const Color spaceDeep2   = Color(0xFF1A0040); // = panelBg
  static const Color spaceDeep3   = Color(0xFF100030);
  static const Color spaceDarkest = Color(0xFF0A0020);
  static const Color sectionBg    = Color(0xFF0D0028); // dark card bg in shop/sections
  static const Color orbPink     = Color(0xFFFF00FF);
  static const Color orbCyan     = Color(0xFF00FFFF);
  static const Color nebulaPink  = Color(0xFFFF00FF);
  // ── Button sets (top face / bottom shadow / border) ──────────
  static const Color greenTop    = Color(0xFF00E676);
  static const Color greenBot    = Color(0xFF00A84E);
  static const Color greenBorder = Color(0xFF69F0AE);

  static const Color blueTop     = Color(0xFFAA00FF);
  static const Color blueDeep    = Color(0xFF7C4DFF); // gradient_button fallback
  static const Color blueBot     = Color(0xFF6200EA);
  static const Color blueBorder  = Color(0xFFEA80FC);

  static const Color orangeTop    = Color(0xFFFF9100);
  static const Color orangeBot    = Color(0xFFE65100);
  static const Color orangeBorder = Color(0xFFFFAB40);

  static const Color yellowTop    = Color(0xFFFFEA00);
  static const Color yellowBot    = Color(0xFFFFD600);
  static const Color yellowBorder = Color(0xFFFFFF8D);

  static const Color redTop    = Color(0xFFFF1744);
  static const Color redBot    = Color(0xFFc40020);
  static const Color redBorder = Color(0xFFFF8A80);
  static const Color redDeep   = Color(0xFFD50000); // no-ads shield extreme dark

  static const Color purpleTop    = Color(0xFFEA80FC);
  static const Color purpleBot    = Color(0xFFAA00FF);
  static const Color purpleBorder = Color(0xFFF3E5F5);

  static const Color grayTop    = Color(0xFF2A1848);
  static const Color grayBot    = Color(0xFF1A0040);
  static const Color grayBorder = Color(0xFF4A2870);

  // ── Semantic aliases ──────────────────────────────────────────
  static const Color blue   = blueTop;
  static const Color green  = greenTop;
  static const Color purple = purpleTop;
  static const Color red    = redTop;
  static const Color orange = orangeTop;
  static const Color text   = Color(0xFFFFFFFF);
  static const Color muted  = Color(0xFFEA80FC);

  // ── Gold spectrum ─────────────────────────────────────────────
  static const Color gold        = Color(0xFFFFEA00); // main gold — electric yellow
  static const Color goldLight   = Color(0xFFFFFF8D); // new-best label, particles
  static const Color goldLabel   = Color(0xFFD4C84A); // sub-labels: XP, BEST, NIV, DAY
  static const Color goldDim     = Color(0xFFC4B842); // score label pulse dim
  static const Color goldAntique = Color(0xFFDAC520); // trophy antique
  static const Color goldDark    = Color(0xFF8B8014); // trophy outlines
  static const Color goldBronze  = Color(0xFFB8A00B); // trophy dark extremity
  static const Color goldPale    = Color(0xFFFFF176); // trophy highlight
  static const Color goldDeep    = Color(0xFFFFD600); // streak badge gold deep
  static const Color goldIce     = Color(0xFFFFFF8D); // streak badge gold ice
  static const Color goldShimmer = Color(0xFFFFFDE7); // trophy score shimmer highlight

  // ── Shadow tokens ─────────────────────────────────────────────
  static const Color shadowDeep = Color(0xFF050010); // 3D bottom shadow on panels
  static const Color deathBadgeBot = Color(0xFFCC0000); // game-over skull badge

  // ── Text labels ──────────────────────────────────────────────
  static const Color blueLabel = Color(0xFFEA80FC); // "SCORE" label in HUD — neon lavande

  // ── HUD capacity ring ─────────────────────────────────────────
  static const Color capGood   = Color(0xFF69f0ae); // < 60 %
  static const Color capWarn   = Color(0xFFffab40); // 60–85 %
  static const Color capDanger = Color(0xFFff5252); // > 85 %

  // ── Merge counter bolt ────────────────────────────────────────
  static const Color statMerge  = Color(0xFFEA80FC);
  static const Color statMerge2 = Color(0xFFF3E5F5);

  // ── Retention ─────────────────────────────────────────────────
  static const Color streakColor = Color(0xFFFF6B00); // flame streak
  static const Color goalColor   = Color(0xFF00E676); // objectives / checkmarks
  static const Color dangerColor = Color(0xFFFF5252); // streak in danger (= capDanger)
  static const Color cardBg      = Color(0xFF1A0040); // retention card background

  // ── Joker palette ─────────────────────────────────────────────
  static const Color radarColor     = Color(0xFFFFEA00);
  static const Color evolutionColor = orbCyan;           // 0xFF00FFFF (cyan néon)
  static const Color megaBombColor  = Color(0xFFFF6D00);
  static const Color bombGlow       = Color(0xFFFF4444); // bomb ring glow
  static const Color wildcardGlowPurple = Color(0xFFE040FB); // wildcard glow — néon magenta
  static const Color xpBarViolet    = Color(0xFFEA80FC); // XP bar mid-level

  // ── XP badge ──────────────────────────────────────────────────
  static const Color xpBadgeTop    = Color(0xFF7C4DFF);
  static const Color xpBadgeBot    = Color(0xFFEA80FC);
  static const Color xpBadgeBorder = Color(0xFFF3E5F5);

  // ── Streak day badge ──────────────────────────────────────────
  static const Color streakBadgeTop    = Color(0xFF6200EA);
  static const Color streakBadgeBot    = Color(0xFFAA00FF);
  static const Color streakBadgeBorder = Color(0xFFEA80FC);

  // ── Level badge ───────────────────────────────────────────────
  static const Color levelBadgeTop    = Color(0xFFAA00FF);
  static const Color levelBadgeBot    = panelBorder;      // 0xFFE040FB
  static const Color levelBadgeBorder = Color(0xFFF3E5F5);

  // ── Victory / death badges ───────────────────────────────────
  static const Color victoryBadgeTop = gold;           // 0xFFFFEA00
  static const Color victoryBadgeBot = Color(0xFFFFD600);
  static const Color deathBadgeTop   = redTop;         // 0xFFff4747

  // ── Confetti particles ────────────────────────────────────────
  static const Color confetti1 = Color(0xFFAA00FF);
  static const Color confetti2 = Color(0xFFFF00FF);
  static const Color confetti3 = Color(0xFFFFEA00);
  static const Color confetti4 = Color(0xFF00FFFF);

  // ── Profile / auth ────────────────────────────────────────────
  static const Color profileGradTop = Color(0xFFEA80FC);
  static const Color profileGradBot = Color(0xFF7C4DFF);
  static const Color googleBlue     = Color(0xFF4285F4);

  // ── Leaderboard ───────────────────────────────────────────────
  static const Color leaderMyRank = Color(0xFFEA80FC);
  static const Color avatarBg1    = Color(0xFF2A0060);
  static const Color avatarBg2    = Color(0xFF1A0040);

  // Medal — gold
  static const Color medalGold1    = Color(0xFFFFE082);
  static const Color medalGold2    = Color(0xFFFFB300);
  static const Color medalGold3    = Color(0xFFF57F17);
  static const Color medalGoldGlow = Color(0x66FFD740);
  static const Color medalGoldText = Color(0xFF4E342E);
  static const Color medalGoldShine = Color(0xFFFFFDE7);
  // Medal — silver
  static const Color medalSilver1     = Color(0xFFE0E0E0);
  static const Color medalSilver2     = Color(0xFF90A4AE);
  static const Color medalSilver3     = Color(0xFF455A64);
  static const Color medalSilverGlow  = Color(0x55B0BEC5);
  static const Color medalSilverText  = Color(0xFF263238);
  static const Color medalSilverShine = Color(0xFFFFFFFF);
  // Medal — bronze
  static const Color medalBronze1     = Color(0xFFFFCCBC);
  static const Color medalBronze2     = Color(0xFFFF7043);
  static const Color medalBronze3     = Color(0xFFBF360C);
  static const Color medalBronzeGlow  = Color(0x55FF8A65);
  static const Color medalBronzeText  = Color(0xFF3E2723);
  static const Color medalBronzeShine = Color(0xFFFFF3E0);

  // ── Settings dialog (white-mode) ─────────────────────────────
  static const Color settingsBg          = Color(0xFFf8f9fa);
  static const Color settingsBorder      = Color(0xFFe9ecef);
  static const Color settingsCardBorder  = Color(0xFFf0f0f0);
  static const Color settingsCardShadow  = Color(0xFFcccccc);
  static const Color settingsToggleOff   = Color(0xFFcccccc);
  static const Color settingsToggleOffBot = Color(0xFF999999);
  static const Color settingsDarkText    = Color(0xFF333333);
  static const Color settingsSubText     = Color(0xFFcbd5e1);

  // ── Shop cards ────────────────────────────────────────────────
  static const Color shopDarkCard1    = Color(0xFF100030);
  static const Color shopDarkCard2    = Color(0xFF2A0060);
  static const Color shopDarkCard3    = Color(0xFF180045);
  static const Color shopPackStar1    = Color(0xFF00E676);
  static const Color shopPackStar2    = Color(0xFF00A84E);
  static const Color shopPackComet1   = Color(0xFFAA00FF);  // violet néon comet
  static const Color shopPackComet2   = Color(0xFF6200EA);
  static const Color shopPackDiamond1 = Color(0xFFFF00FF);
  static const Color shopPackDiamond2 = Color(0xFF00FFFF);
  static const Color shopSectionCyan  = evolutionColor;    // 0xFF00FFFF (cyan néon)
  static const Color shopSectionPurple = Color(0xFFEA80FC);
  static const Color shopNoAdsRed     = Color(0xFFFF1744);
  static const Color shopStrikeRed    = Color(0xFFFF5252); // Colors.redAccent

  // ── Bag / joker-shop icon ─────────────────────────────────────
  static const Color bagPurpleLight = Color(0xFFF3E5F5);
  static const Color bagPurpleMid   = Color(0xFFEA80FC);
  static const Color bagPurpleDark  = Color(0xFFAA00FF);
  static const Color bagBorder      = Color(0xFF7C4DFF);
  static const Color bagFlapLight   = Color(0xFFFCE4EC);
  static const Color bagFlapDark    = Color(0xFFEA80FC);
  static const Color bagHandle      = Color(0xFFF3E5F5);

  // ── Daily challenge card ──────────────────────────────────────
  static const Color challengeCardTop  = Color(0xFF2A0060);
  static const Color challengeCardBot  = Color(0xFF1A0040);
  static const Color challengeNeonCyan = Color(0xFF00FFFF);
  static const Color challengeNeonBlue = Color(0xFFEA80FC);

  // ── Joker orb states ─────────────────────────────────────────
  static const Color jokerOrbDisabledTop = Color(0xFF1A0048);
  static const Color jokerOrbDisabledBot = Color(0xFF100030);
  static const Color jokerOrbBgDark      = Color(0xFF080018);
  static const Color jokerBadgeEmptyTop  = Color(0xFF2A0058);
  static const Color jokerBadgeEmptyBot  = Color(0xFF1A0048);

  // ── Joker icon painters ──────────────────────────────────────
  // Bomb body
  static const Color bombBodyLight  = Color(0xFF555555);
  static const Color bombBodyMid    = Color(0xFF333333);
  static const Color bombBodyDark   = Color(0xFF1a1a1a);
  static const Color bombBodyShade  = Color(0xFF0d0d0d);
  static const Color bombXMark      = Color(0xFFff4444); // = redTop approx
  // Bomb fuse
  static const Color fuseOuter      = goldDark;         // 0xFF8B6914
  static const Color fuseInner      = goldAntique;      // 0xFFDAA520
  static const Color fuseTipLight   = goldPale;         // 0xFFFFE082
  static const Color fuseTipDark    = goldAntique;
  static const Color sparkOrange    = Color(0xFFFF6600);
  static const Color sparkYellow    = Color(0xFFFFDD00);
  static const Color sparkFlame     = Color(0xFFFF8800);
  // Wildcard
  static const Color wildcardGlow   = bgTop;            // 0xFFAA00FF (violet néon)
  static const Color wildcardBody1  = Color(0xFFD050FF);
  static const Color wildcardBody2  = bagPurpleDark;    // 0xFFAA00FF
  static const Color wildcardBody3  = Color(0xFF7C4DFF);
  static const Color wildcardRing   = statMerge;        // 0xFFEA80FC
  // Reducer
  static const Color reducerGlow    = capDanger;        // 0xFFff5252
  static const Color reducerBody1   = jokerBadgeEmptyTop;
  static const Color reducerBody2   = jokerBadgeEmptyBot;
  static const Color reducerBody3   = jokerOrbDisabledBot;
  static const Color reducerArrow1  = Color(0xFFff6b6b);
  static const Color reducerArrow2  = Color(0xFFe53935);
  // Evolution (radar)
  static const Color evolutionGlow  = capGood;          // 0xFF69f0ae (green glow)
  static const Color evolutionFill1 = Color(0xFF69f0ae);
  static const Color evolutionFill2 = Color(0xFF00e676);
  static const Color evolutionFill3 = Color(0xFF00c853);
  static const Color evolutionDark  = Color(0xFF00a843);
  // Radar body (dark card-like)
  static const Color radarBody1     = Color(0xFF2A0058);
  static const Color radarBody2     = Color(0xFF1A0048);
  static const Color radarBody3     = Color(0xFF100030);
  static const Color radarRingBlue  = Color(0xFFEA80FC);
  // Mega bomb
  static const Color megaBombRing1  = redTop;           // 0xFFff4747
  static const Color megaBombRing2  = deathBadgeBot;    // 0xFFcc0000
  static const Color megaBombRingShine = Color(0xFFffaaaa);
  // Rocket flame
  static const Color rocketFlame1   = sparkOrange;      // 0xFFFF6600
  static const Color rocketFlame2   = Color(0xFFFF3300);
  static const Color rocketFlame3   = Color(0xFFFF0000);
  static const Color rocketGlow     = sparkOrange;
  static const Color rocketNozzle1  = goldPale;         // 0xFFFFE082
  static const Color rocketNozzle2  = Color(0xFFFFD54F);
  static const Color rocketNozzle3  = Color(0xFFFF8F00);
  // Rocket body (neon violet)
  static const Color rocketBody1    = Color(0xFFD050FF);
  static const Color rocketBody2    = Color(0xFFAA00FF);
  static const Color rocketBodyBorder = Color(0xFFEA80FC);
  static const Color rocketNoseCone1 = Color(0xFFFFFF8D);
  static const Color rocketNoseCone2 = Color(0xFFFFD600);
  static const Color rocketWindow    = Color(0xFF2A0080);
  static const Color rocketGlass1   = Color(0xFFF3E5F5);
  static const Color rocketGlass2   = Color(0xFFEA80FC);
  static const Color rocketGlass3   = Color(0xFFAA00FF);
  // Rocket white parts
  static const Color rocketPanel1   = Color(0xFFe0e0e0);
  static const Color rocketPanel2   = Color(0xFFfafafa);
  static const Color rocketPanel3   = Color(0xFFffffff);
  static const Color rocketPanel4   = Color(0xFFe8e8e8);
  // Radar star
  static const Color radarStarGold  = Color(0xFFFFEA00);
  static const Color radarStarDark  = Color(0xFFCCB800);
  static const Color radarStarShine = Color(0xFFFFFF8D);
  // Evolution v2 (play button) colors
  static const Color evoRingLight   = Color(0xFFb9f6ca);
  // Home painter (electric yellow circle)
  static const Color homePainterFill1 = Color(0xFFFFFF8D);
  static const Color homePainterFill2 = gold;
  static const Color homePainterFill3 = Color(0xFFCCB800);
  static const Color homePainterRing  = Color(0xFFFFFDE7);

  // ── Level colors (shape fill by level) ───────────────────────
  static const List<Color> levelColors = [
    Color(0xFFFF0000), // 1 — rouge pur
    Color(0xFF0000FF), // 2 — bleu pur
    Color(0xFFFFFF00), // 3 — jaune pur
    Color(0xFF00FF00), // 4 — vert pur
    Color(0xFFFF00FF), // 5 — magenta pur
    Color(0xFFFF8000), // 6 — orange pur
    Color(0xFF00FFFF), // 7 — cyan pur
    Color(0xFFFF1493), // 8 — hot pink
  ];

  static Color colorForLevel(int level) =>
      levelColors[(level - 1).clamp(0, levelColors.length - 1)];

  // ════════════════════════════════════════════════════════════════
  // FONT SIZES
  // ════════════════════════════════════════════════════════════════

  static const double fontHuge    = 54.0; // splash title
  static const double fontXXL     = 48.0; // score counter / big emoji
  static const double fontDisplay = 44.0; // home screen big title
  static const double fontEmoji   = 40.0; // large emoji (profile)
  static const double fontXL      = 38.0; // floating title letters
  static const double fontLarge   = 36.0; // default titleStyle
  static const double fontCombo   = 32.0; // combo score popup
  static const double fontH1      = 28.0; // section headlines
  static const double fontH1b     = 26.0; // game-over title
  static const double fontH2      = 24.0; // screen titles
  static const double fontH3      = 22.0; // pause/dialog titles
  static const double fontH4      = 20.0; // badge values
  static const double fontBody    = 18.0; // button labels
  static const double fontRegular = 16.0; // body text, toggles
  static const double fontGBtn    = 15.0; // Google G button
  static const double fontSmall   = 14.0; // secondary text
  static const double fontXSmall  = 13.0; // sub-labels, captions
  static const double fontTiny    = 12.0; // chips, settings labels
  static const double fontMini    = 11.0; // tiny chips
  static const double fontNano    = 10.0; // badge sub-labels
  static const double fontPico    =  9.0; // very small labels
  static const double fontMicro   =  7.0; // micro badge star

  // ════════════════════════════════════════════════════════════════
  // SPACING
  // ════════════════════════════════════════════════════════════════

  // Spacing tokens are intentionally NOT centralized — kept local
  // because spacing is layout-context-dependent.

  // ════════════════════════════════════════════════════════════════
  // BORDER RADII
  // ════════════════════════════════════════════════════════════════

  static const double radiusXL     =  24.0;
  static const double radiusLarge  =  20.0;
  static const double radiusMedium =  16.0;
  static const double radiusSmall  =  14.0; // default Button3D
  static const double radiusTiny   =  12.0;
  static const double radiusXTiny  =  10.0;
  static const double radiusXXTiny =   8.0;

  // ════════════════════════════════════════════════════════════════
  // FONT FAMILIES
  // ════════════════════════════════════════════════════════════════

  static const String fontFamilyTitle = 'Fredoka';

  // ════════════════════════════════════════════════════════════════
  // TEXT STYLES
  // ════════════════════════════════════════════════════════════════

  /// Fredoka Black title with 4-direction black stroke + bottom shadow.
  static TextStyle titleStyle([double size = fontLarge]) => GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        shadows: const [
          Shadow(offset: Offset(-1, -1), color: Colors.black),
          Shadow(offset: Offset(1, -1),  color: Colors.black),
          Shadow(offset: Offset(-1,  1), color: Colors.black),
          Shadow(offset: Offset(1,   1), color: Colors.black),
          Shadow(offset: Offset(0,   4), color: Colors.black54),
        ],
      );

  static TextStyle get scoreStyle => GoogleFonts.fredoka(
        fontSize: fontH1,
        fontWeight: FontWeight.w900,
        color: gold,
        shadows: const [Shadow(offset: Offset(0, 2), color: Colors.black54)],
      );

  static TextStyle get hudStyle => GoogleFonts.nunito(
        fontSize: fontRegular,
        fontWeight: FontWeight.w900,
        color: text,
      );

  // ════════════════════════════════════════════════════════════════
  // MATERIAL THEME
  // ════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: purpleTop,
        secondary: gold,
        tertiary: blueTop,
        surface: panelBg,
        onSurface: text,
        error: redTop,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme)
          .apply(bodyColor: text, displayColor: text),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // BACKGROUND WIDGET
  // ════════════════════════════════════════════════════════════════

  /// Game background (gradient + pink/cyan orbs).
  static Widget backgroundWidget() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgTop, bgBot],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: _orbGradient(orbPink, 300),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _orbGradient(orbCyan, 250),
          ),
        ],
      ),
    );
  }

  static Widget _orbGradient(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.3),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Button3D — 3D juicy button with physical press effect
// ═══════════════════════════════════════════════════════════════
class Button3D extends StatefulWidget {
  final Widget child;
  final Color topColor;
  final Color bottomColor;
  final Color borderColor;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool expand;

  const Button3D({
    super.key,
    required this.child,
    required this.topColor,
    required this.bottomColor,
    required this.borderColor,
    this.onPressed,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.expand = false,
  });

  factory Button3D.green({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false}) =>
      Button3D(topColor: AppTheme.greenTop, bottomColor: AppTheme.greenBot, borderColor: AppTheme.greenBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, child: child);

  factory Button3D.blue({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false}) =>
      Button3D(topColor: AppTheme.blueTop, bottomColor: AppTheme.blueBot, borderColor: AppTheme.blueBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, child: child);

  factory Button3D.orange({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false}) =>
      Button3D(topColor: AppTheme.orangeTop, bottomColor: AppTheme.orangeBot, borderColor: AppTheme.orangeBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, child: child);

  factory Button3D.red({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false}) =>
      Button3D(topColor: AppTheme.redTop, bottomColor: AppTheme.redBot, borderColor: AppTheme.redBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, child: child);

  factory Button3D.purple({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false}) =>
      Button3D(topColor: AppTheme.purpleTop, bottomColor: AppTheme.purpleBot, borderColor: AppTheme.purpleBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, child: child);

  factory Button3D.yellow({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false}) =>
      Button3D(topColor: AppTheme.yellowTop, bottomColor: AppTheme.yellowBot, borderColor: AppTheme.yellowBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, child: child);

  factory Button3D.gray({required Widget child, VoidCallback? onPressed, EdgeInsetsGeometry? padding, double borderRadius = 14, bool expand = false}) =>
      Button3D(topColor: AppTheme.grayTop, bottomColor: AppTheme.grayBot, borderColor: AppTheme.grayBorder, onPressed: onPressed, padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12), borderRadius: borderRadius, expand: expand, child: child);

  @override
  State<Button3D> createState() => _Button3DState();
}

class _Button3DState extends State<Button3D> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _squashController;
  late Animation<double> _scaleXAnim;
  late Animation<double> _scaleYAnim;

  @override
  void initState() {
    super.initState();
    _squashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scaleXAnim = Tween(begin: 1.0, end: 1.04).animate(CurvedAnimation(parent: _squashController, curve: Curves.easeOut));
    _scaleYAnim = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _squashController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _squashController.dispose();
    super.dispose();
  }

  Widget _wrapWidth(Widget child) =>
      widget.expand ? child : IntrinsicWidth(child: child);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          HapticFeedback.lightImpact();
          _squashController.forward();
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (widget.onPressed != null) {
          _squashController.reverse();
          setState(() => _isPressed = false);
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (widget.onPressed != null) {
          _squashController.reverse();
          setState(() => _isPressed = false);
        }
      },
      child: AnimatedBuilder(
        animation: _squashController,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(_scaleXAnim.value, _scaleYAnim.value),
            child: child,
          );
        },
        child: IntrinsicHeight(
          child: _wrapWidth(
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 6, left: 0, right: 0, bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      color: widget.bottomColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: Offset(0, _isPressed ? 2 : 5), blurRadius: _isPressed ? 3 : 8)
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: widget.expand ? double.infinity : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    margin: EdgeInsets.only(top: _isPressed ? 6 : 0, bottom: _isPressed ? 0 : 6),
                    decoration: BoxDecoration(
                      color: widget.topColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(color: widget.borderColor, width: 2),
                    ),
                    child: Padding(padding: widget.padding, child: widget.child),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
