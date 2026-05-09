import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shape_merge/core/config/notification_config.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Handles all local notifications for Shape Merge.
///
/// Usage:
///   await NotificationService.instance.init();
///   await NotificationService.instance.scheduleStreakReminder();
///   await NotificationService.instance.cancelStreakReminder();
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _streakReminderId = NotificationConfig.streakReminderId;
  static const _channelId = NotificationConfig.channelId;
  static const _channelName = NotificationConfig.channelName;
  static const _channelDescription = NotificationConfig.channelDescription;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Emits notification payloads when the user taps a notification.
  final _payloadController = StreamController<String>.broadcast();
  Stream<String> get onNotificationTap => _payloadController.stream;

  // ─────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@drawable/ic_stat_notify');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _payloadController.add(payload);
        }
      },
    );
    _initialized = true;
  }

  // ─────────────────────────────────────────────
  // Permissions
  // ─────────────────────────────────────────────

  /// Requests notification permissions on iOS/Android 13+.
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return granted;
    }
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission() ?? false;
      return granted;
    }
    return false;
  }

  // ─────────────────────────────────────────────
  // Streak reminder — scheduled 23 h after "now"
  // ─────────────────────────────────────────────

  /// Schedules (or reschedules) a streak-danger notification 23 h from now.
  /// Cancels any previous streak reminder first.
  ///
  /// Pass [l10n] to localize the title/body in the user's current language.
  /// When [l10n] is null, falls back to the FR strings in [NotificationConfig]
  /// (legacy behaviour kept for callers that don't have a `BuildContext`).
  Future<void> scheduleStreakReminder({
    AppLocalizations? l10n,
    int? streakDays,
  }) async {
    final title = l10n?.notifStreakTitle ?? NotificationConfig.defaultTitle;
    final body = (streakDays != null && streakDays > 0)
        ? (l10n?.notifStreakBodyWithDays(streakDays) ??
            'Votre série de $streakDays jours est en danger ! Jouez pour la maintenir.')
        : (l10n?.notifStreakBody ?? NotificationConfig.defaultBody);
    final channelName = l10n?.notifChannelName ?? _channelName;
    final channelDesc = l10n?.notifChannelDesc ?? _channelDescription;

    if (!_initialized) await init();
    if (kIsWeb) return;

    await cancelStreakReminder();

    final fire = tz.TZDateTime.now(tz.local).add(NotificationConfig.reminderDelay);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        // Small status-bar icon: white silhouette extracted from app_icon.png
        // (Android renders alpha only — colored mipmaps appear as white squares).
        icon: '@drawable/ic_stat_notify',
        // Full-color app_icon shown in the expanded notification & drawer.
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      _streakReminderId,
      title,
      body,
      fire,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: NotificationConfig.streakPayload,
    );
  }

  /// Cancels the pending streak reminder (call after user plays).
  Future<void> cancelStreakReminder() async {
    if (!_initialized) await init();
    if (kIsWeb) return;
    await _plugin.cancel(_streakReminderId);
  }

  /// Cancels all pending notifications.
  Future<void> cancelAll() async {
    if (!_initialized) await init();
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  /// Releases resources. Call from app lifecycle handler if needed.
  void dispose() {
    _payloadController.close();
  }
}
