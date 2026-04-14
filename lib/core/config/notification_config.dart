// ─────────────────────────────────────────────────────────────
// Notification Config — IDs, channels, scheduling.
//
// To change the reminder delay or channel: edit here.
// ─────────────────────────────────────────────────────────────

abstract final class NotificationConfig {
  /// Unique ID for the streak reminder notification.
  static const int streakReminderId = 42;

  /// Android notification channel.
  static const String channelId = 'shape_merge_streak';
  static const String channelName = 'Série de jeu';
  static const String channelDescription =
      'Rappels pour garder votre série de jeu active.';

  /// Delay before firing the streak reminder.
  static const Duration reminderDelay = Duration(hours: 23);

  /// Payload string sent when the notification is tapped.
  static const String streakPayload = 'streak_reminder';

  /// Default notification title (when l10n not available).
  static const String defaultTitle = 'Votre série est en danger !';

  /// Default notification body (when l10n not available).
  static const String defaultBody =
      'Jouez une partie pour maintenir votre série de jeu.';
}
