import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:warranty_and_purchase_manager/core/features/analytics/data/analytics_service.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/data/auth_failure.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/data/auth_repository.dart';

enum AuthStatus { initial, loading, success, failure }

class AuthController extends ChangeNotifier {
  AuthController(this._repository, this._analytics);

  final AuthRepository _repository;
  final AnalyticsService _analytics;

  AuthStatus _status = AuthStatus.initial;
  String? _failureMessage;

  AuthStatus get status => _status;
  bool get isLoading => _status == AuthStatus.loading;
  String? get failureMessage => _failureMessage;
  User? get currentUser => _repository.currentUser;

  Stream<User?> authStateChanges() => _repository.authStateChanges();

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    final bool succeeded = await _run(
      () => _repository.signUp(email: email, password: password),
    );
    if (succeeded) await _recordAnalytics(_analytics.logSignUp(method: 'password'));
    return succeeded;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final bool succeeded = await _run(
      () => _repository.signIn(email: email, password: password),
    );
    if (succeeded) await _recordAnalytics(_analytics.logLogin(method: 'password'));
    return succeeded;
  }

  Future<bool> signInWithGoogle() async {
    final bool succeeded = await _run(_repository.signInWithGoogle);
    if (succeeded) await _recordAnalytics(_analytics.logLogin(method: 'google'));
    return succeeded;
  }

  Future<bool> linkGoogleToCurrentAccount() {
    return _run(_repository.linkGoogleToCurrentAccount);
  }

  Future<bool> signOut() async {
    final bool succeeded = await _run(_repository.signOut);
    if (succeeded) await _recordAnalytics(_analytics.logLogout());
    return succeeded;
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    final bool succeeded = await _run(
      () => _repository.sendPasswordResetEmail(email: email),
    );
    if (succeeded) {
      await _recordAnalytics(_analytics.logPasswordResetRequested());
    }
    return succeeded;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final bool succeeded = await _run(
      () => _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
    if (succeeded) await _recordAnalytics(_analytics.logPasswordChanged());
    return succeeded;
  }

  Future<bool> updatePhotoUrl(String httpsUrl) async {
    final bool succeeded =
        await _run(() => _repository.updatePhotoUrl(httpsUrl));
    if (succeeded) await _recordAnalytics(_analytics.logProfilePhotoUpdated());
    return succeeded;
  }

  Future<bool> updateDisplayName(String displayName) {
    return _run(() => _repository.updateDisplayName(displayName));
  }

  Future<bool> _run(Future<void> Function() action) async {
    _status = AuthStatus.loading;
    _failureMessage = null;
    notifyListeners();

    try {
      await action();
      _status = AuthStatus.success;
      return true;
    } on AuthFailure catch (failure) {
      _status = AuthStatus.failure;
      _failureMessage = failure.message;
      return false;
    } finally {
      if (_status == AuthStatus.loading) _status = AuthStatus.initial;
      notifyListeners();
    }
  }

  Future<void> _recordAnalytics(Future<void> event) async {
    try {
      await event;
    } on FirebaseException catch (error) {
      debugPrint('Не вдалося записати подію Analytics: ${error.message}');
    }
  }
}
