import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> logSignUp({required String method}) {
    return _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogin({required String method}) {
    return _analytics.logLogin(loginMethod: method);
  }

  Future<void> logPasswordResetRequested() {
    return _analytics.logEvent(name: 'password_reset_requested');
  }

  Future<void> logPasswordChanged() {
    return _analytics.logEvent(name: 'password_changed');
  }

  Future<void> logProfilePhotoUpdated() {
    return _analytics.logEvent(name: 'profile_photo_updated');
  }

  Future<void> logLogout() {
    return _analytics.logEvent(name: 'logout');
  }

  Future<void> logScreenView(String screenName) {
    return _analytics.logScreenView(screenName: screenName);
  }
}
