import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({required this.onDismiss, super.key});

  final VoidCallback onDismiss;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final slides = [
      _Slide(emoji: '🔀', title: l10n.onboardingTitle1, desc: l10n.onboardingDesc1),
      _Slide(emoji: '🃏', title: l10n.onboardingTitle2, desc: l10n.onboardingDesc2),
      _Slide(emoji: '💀', title: l10n.onboardingTitle3, desc: l10n.onboardingDesc3),
    ];

    final isLast = _page == slides.length - 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        const SpaceBackground(darken: 0.6),
        SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 16),
                  child: TextButton(
                    onPressed: widget.onDismiss,
                    child: Text(
                      l10n.skipTutorial,
                      style: GoogleFonts.nunito(
                        color: Colors.white54,
                        fontSize: AppTheme.fontRegular,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              // Slides
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: slides.length,
                  itemBuilder: (_, i) => slides[i],
                ),
              ),

              // Dots
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? AppTheme.gold : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

              // Button
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                child: Button3D.green(
                  expand: true,
                  onPressed: () {
                    if (isLast) {
                      widget.onDismiss();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      isLast ? l10n.startPlaying : l10n.next,
                      style: GoogleFonts.fredoka(
                        fontSize: AppTheme.fontBody,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.emoji, required this.title, required this.desc});

  final String emoji;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          Text(
            title.toUpperCase(),
            style: AppTheme.titleStyle(AppTheme.fontH1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.white70,
              fontSize: AppTheme.fontBody,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
