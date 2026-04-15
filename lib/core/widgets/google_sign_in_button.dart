import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';

/// Reusable Google Sign-In button (blue 3D button with "G" circle icon).
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: Button3D.blue(
        expand: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'G',
                  style: GoogleFonts.fredoka(
                    fontSize: AppTheme.fontGBtn,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.googleBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.signInGoogle.toUpperCase(),
              style: AppTheme.titleStyle(AppTheme.fontBody),
            ),
          ],
        ),
      ),
    );
  }
}
