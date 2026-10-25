import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class CrashlyticsService {
  CrashlyticsService.firebase(this._crashlytics);

  CrashlyticsService.sentry() : _crashlytics = null;

  final FirebaseCrashlytics? _crashlytics;

  bool get usesFirebaseCrashlytics => _crashlytics != null;

  void generateTestCrash() {
    final FirebaseCrashlytics? crashlytics = _crashlytics;
    if (crashlytics != null) {
      crashlytics.crash();
      return;
    }
    unawaited(
      Sentry.captureException(
        StateError('Тестова помилка моніторингу'),
        stackTrace: StackTrace.current,
      ),
    );
  }
}
