import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  static const _streakReminderId = 42;
  // TODO(l10n): move to l10n when BuildContext is available at scheduling time
  static const _channelId = 'shape_merge_streak';
  static const _channelName = 'Série de jeu';
  static const _channelDescription =
      'Rappels pour garder votre série de jeu active.';

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

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
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
  // TODO(l10n): accept localized title/body from caller when BuildContext is available
  Future<void> scheduleStreakReminder({
    String title = 'Votre série est en danger !',
    String body = 'Jouez une partie pour maintenir votre série de jeu.',
  }) async {
    if (!_initialized) await init();
    if (kIsWeb) return;

    await cancelStreakReminder();

    final fire = tz.TZDateTime.now(tz.local).add(const Duration(hours: 23));

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
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
      payload: 'streak_reminder',
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
}
