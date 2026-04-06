import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/screens/home/widgets/animated_background.dart';
import 'package:shape_merge/screens/onboarding/rules_page.dart';
import 'package:shape_merge/screens/onboarding/jokers_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SpaceBackground()),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    children: const [RulesPage(), JokersPage()],
                  ),
                ),
                // Page indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: i == _currentPage ? 32 : 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: i == _currentPage ? AppTheme.blueTop : Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: i == _currentPage
                            ? [BoxShadow(color: AppTheme.blueTop.withValues(alpha: 0.5), blurRadius: 8)]
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: _currentPage == 0
                        ? Button3D.purple(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            borderRadius: 18,
                            onPressed: () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_forward, color: Colors.white, size: 24),
                                const SizedBox(width: 10),
                                Text(l10n.next.toUpperCase(), style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                              ],
                            ),
                          )
                        : Button3D.green(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            borderRadius: 18,
                            onPressed: () async {
                              final storage = await LocalStorageService.create();
                              await storage.setOnboardingDone(true);
                              if (context.mounted) context.go('/home');
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 24),
                                const SizedBox(width: 10),
                                Text('🎮 ${l10n.startPlaying}'.toUpperCase(), style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
