import 'dart:developer' as dev;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Log severity levels, ordered by priority.
enum LogLevel { debug, info, warning, error }

/// Centralised logging for the entire app.
///
/// - **Debug builds**: all levels printed to the console via `dart:developer`.
/// - **Release builds**: only [warning] and [error] are forwarded to
///   Firebase Crashlytics. [debug] and [info] are silently discarded
///   so there is zero performance cost in production.
///
/// Usage:
/// ```dart
/// const _log = AppLogger('Audio');
/// _log.info('Ready: 5/5 sounds loaded');
/// _log.error('Init failed', error: e, stack: st);
/// ```
class AppLogger {
  const AppLogger(this.tag);

  /// Domain tag, e.g. `Audio`, `IAP`, `Firestore`.
  final String tag;

  /// Minimum level printed in debug builds. Change for local filtering.
  static LogLevel debugMinLevel = LogLevel.debug;

  // ── Public API ──────────────────────────────────────────────────────────

  void debug(String message) => _dispatch(LogLevel.debug, message);

  void info(String message) => _dispatch(LogLevel.info, message);

  void warning(String message, {Object? error, StackTrace? stack}) =>
      _dispatch(LogLevel.warning, message, error: error, stack: stack);

  void error(String message, {Object? error, StackTrace? stack}) =>
      _dispatch(LogLevel.error, message, error: error, stack: stack);

  // ── Internals ───────────────────────────────────────────────────────────

  void _dispatch(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stack,
  }) {
    if (kDebugMode) {
      if (level.index >= debugMinLevel.index) {
        final prefix = switch (level) {
          LogLevel.debug => '🔍',
          LogLevel.info => 'ℹ️',
          LogLevel.warning => '⚠️',
          LogLevel.error => '❌',
        };
        dev.log(
          '$prefix [$tag] $message',
          name: tag,
          level: level.index * 300, // debug=0, info=300, warn=600, err=900
          error: error,
          stackTrace: stack,
        );
      }
    } else {
      // Release: forward warnings and errors to Crashlytics
      if (level == LogLevel.warning || level == LogLevel.error) {
        final crashlytics = FirebaseCrashlytics.instance;
        crashlytics.log('[$tag] $message');
        if (error != null) {
          crashlytics.recordError(
            error,
            stack ?? StackTrace.current,
            reason: '[$tag] $message',
            fatal: false,
          );
        }
      }
    }
  }
}
