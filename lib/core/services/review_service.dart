import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/services/app_logger.dart';

/// In-app review prompt strategy.
///
/// Triggers after:
/// - At least 5 games played
/// - At least 3 days since install
/// - Not shown in the last 60 days
/// - Max 3 prompts ever
class ReviewService {
  ReviewService._();
  static final instance = ReviewService._();

  static const _keyLastPrompt = 'review_lastPrompt';
  static const _keyPromptCount = 'review_promptCount';
  static const _keyInstallDate = 'review_installDate';

  static const _minGamesPlayed = 5;
  static const _minDaysSinceInstall = 3;
  static const _cooldownDays = 60;
  static const _maxPrompts = 3;

  static const _log = AppLogger('ReviewService');

  /// Call after each game ends. Checks conditions and shows review prompt if eligible.
  Future<void> maybeRequestReview({
    required int gamesPlayed,
    required int bestScore,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Track install date (first launch)
      if (!prefs.containsKey(_keyInstallDate)) {
        await prefs.setInt(_keyInstallDate, DateTime.now().millisecondsSinceEpoch);
      }

      // Check prompt count
      final promptCount = prefs.getInt(_keyPromptCount) ?? 0;
      if (promptCount >= _maxPrompts) return;

      // Check min games
      if (gamesPlayed < _minGamesPlayed) return;

      // Check min days since install
      final installMs = prefs.getInt(_keyInstallDate) ?? DateTime.now().millisecondsSinceEpoch;
      final installDate = DateTime.fromMillisecondsSinceEpoch(installMs);
      if (DateTime.now().difference(installDate).inDays < _minDaysSinceInstall) return;

      // Check cooldown since last prompt
      final lastPromptMs = prefs.getInt(_keyLastPrompt) ?? 0;
      if (lastPromptMs > 0) {
        final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
        if (DateTime.now().difference(lastPrompt).inDays < _cooldownDays) return;
      }

      // Check if store supports in-app review
      final inAppReview = InAppReview.instance;
      if (!await inAppReview.isAvailable()) {
        _log.debug('In-app review not available');
        return;
      }

      // Show review prompt
      _log.info('Requesting in-app review (prompt #${promptCount + 1})');
      await inAppReview.requestReview();

      // Record prompt
      await prefs.setInt(_keyLastPrompt, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_keyPromptCount, promptCount + 1);
    } catch (e) {
      _log.warning('Review request failed: $e');
    }
  }
}
