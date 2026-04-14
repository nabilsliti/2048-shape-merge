import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_merge/core/config/app_routes.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/game_state_provider.dart';
import 'package:shape_merge/core/services/notification_service.dart';
import 'package:shape_merge/providers/daily_challenge_provider.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';
import 'package:shape_merge/providers/player_provider.dart';
import 'package:shape_merge/providers/streak_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    final storage = await LocalStorageService.create();
    if (!mounted) return;

    final notifier = ref.read(gameStateProvider.notifier);
    notifier.setStorage(storage);

    // If signed in, load jokers from Firestore; otherwise from localStorage
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      final firestoreService = ref.read(firestoreServiceProvider);
      notifier.setSignedIn(user.uid, firestoreService);
      final player = await ref.read(playerProvider.future);
      notifier.loadSavedState(
        bestScore: player?.bestScore ?? storage.bestScore,
        jokers: player?.jokerInventory ?? storage.jokerInventory,
      );
    } else {
      notifier.loadSavedState(
        bestScore: storage.bestScore,
        jokers: storage.jokerInventory,
      );
    }

    // Check streak on every launch — delivers reward and updates state for popup
    await ref.read(streakProvider.notifier).checkAndUpdate();
    // Load or generate today's daily challenges
    await ref.read(dailyChallengeProvider.notifier).checkRenewal();
    // Init notifications and request permission once; schedule streak reminder.
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermission();
    await NotificationService.instance.scheduleStreakReminder();

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.bgTop, AppTheme.bgBot],
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.orbPink.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.orbCyan.withValues(alpha: 0.3),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: -0.05,
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: 'SHAPE ',
                            style: AppTheme.titleStyle(AppTheme.fontHuge),
                          ),
                          TextSpan(
                            text: 'MERGE\n',
                            style: AppTheme.titleStyle(AppTheme.fontHuge)
                                .copyWith(color: AppTheme.orangeTop),
                          ),
                          TextSpan(
                            text: '2048',
                            style: AppTheme.titleStyle(AppTheme.fontHuge)
                                .copyWith(color: AppTheme.orangeTop),
                          ),
                        ]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
