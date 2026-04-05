import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsService {
  final _crashlytics = FirebaseCrashlytics.instance;

  Future<void> recordError(Object error, StackTrace stack) =>
      _crashlytics.recordError(error, stack);

  Future<void> setUserId(String uid) =>
      _crashlytics.setUserIdentifier(uid);

  Future<void> log(String message) => _crashlytics.log(message);
}
