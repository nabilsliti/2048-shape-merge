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

  // ── ANSI colors ──────────────────────────────────────────────────────────

  static const _reset = '\x1B[0m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';
  static const _dim = '\x1B[2m';

  static const _tagWidth = 10;

  // ── Internals ───────────────────────────────────────────────────────────

  void _dispatch(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stack,
  }) {
    if (kDebugMode) {
      if (level.index >= debugMinLevel.index) {
        final now = DateTime.now();
        final ts = '${_two(now.hour)}:${_two(now.minute)}'
            ':${_two(now.second)}.${_three(now.millisecond)}';

        final paddedTag = tag.padRight(_tagWidth);

        final prefix = switch (level) {
          LogLevel.debug => '🔍',
          LogLevel.info => 'ℹ️',
          LogLevel.warning => '⚠️',
          LogLevel.error => '❌',
        };

        final errorSuffix =
            error != null ? ' $_dim── $error$_reset' : '';

        final line = switch (level) {
          LogLevel.warning =>
            '$_dim$ts$_reset │ $_yellow$prefix $paddedTag$_reset │ $_yellow$message$errorSuffix$_reset',
          LogLevel.error =>
            '$_dim$ts$_reset │ $_red$prefix $paddedTag$_reset │ $_red$message$errorSuffix$_reset',
          _ =>
            '$_dim$ts$_reset │ $prefix $paddedTag │ $message$errorSuffix',
        };

        // debugPrint supports ANSI codes in flutter run terminal
        debugPrint(line);

        // Forward stack traces via dev.log for clickable links in IDE
        if (stack != null) {
          dev.log(
            '[$tag] $message',
            name: tag,
            level: level.index * 300,
            error: level == LogLevel.error ? error : null,
            stackTrace: stack,
          );
        }
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

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _three(int n) => n.toString().padLeft(3, '0');
}
