import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/providers/settings_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    final storage = await LocalStorageService.create();

    if (!mounted) return;

    ref.read(gameStateProvider.notifier).loadSavedState(
          bestScore: storage.bestScore,
          jokers: storage.jokerInventory,
        );

    final onboardingDone = storage.onboardingDone;
    ref.read(onboardingDoneProvider.notifier).state = onboardingDone;

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    if (onboardingDone) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _controller,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: _controller,
              curve: Curves.elasticOut,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔷', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text('SHAPE MERGE', style: AppTheme.titleStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
