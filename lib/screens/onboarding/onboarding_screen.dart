import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/gradient_button.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
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
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: const [
                  RulesPage(),
                  JokersPage(),
                ],
              ),
            ),
            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (i) {
                return Container(
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i == _currentPage ? AppTheme.blue : AppTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _currentPage == 0
                  ? GradientButton(
                      label: l10n.next,
                      icon: Icons.arrow_forward,
                      onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      width: double.infinity,
                    )
                  : GradientButton(
                      label: '🎮 ${l10n.startPlaying}',
                      onPressed: () async {
                        final storage = await LocalStorageService.create();
                        await storage.setOnboardingDone(true);
                        if (context.mounted) context.go('/home');
                      },
                      width: double.infinity,
                      colors: [AppTheme.green, const Color(0xFF2E7D32)],
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
