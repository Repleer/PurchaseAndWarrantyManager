import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/data/auth_failure.dart';

abstract interface class AuthRepository {
  User? get currentUser;

  Stream<User?> authStateChanges();

  Future<void> signUp({required String email, required String password});

  Future<void> signIn({required String email, required String password});

  Future<void> signInWithGoogle();

  Future<void> linkGoogleToCurrentAccount();

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> updatePhotoUrl(String httpsUrl);

  Future<void> updateDisplayName(String displayName);
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._firebaseAuth, this._googleSignIn);

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  AuthCredential? _pendingGoogleCredential;

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  Future<void> signUp({required String email, required String password}) async {
    await _withMappedAuthErrors(() async {
      final UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      final User? user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          'unknown',
          'Не вдалося створити обліковий запис. Спробуйте ще раз.',
        );
      }
      await user.updateDisplayName(_nameFromEmail(email));
    });
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _withMappedAuthErrors(
      () => _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      try {
        await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
      } on FirebaseAuthException catch (error) {
        if (error.code == 'account-exists-with-different-credential' ||
            error.code == 'email-already-in-use') {
          throw AuthFailure.fromFirebaseException(
            FirebaseAuthException(
              code: 'account-exists-with-different-credential',
              message: error.message,
            ),
          );
        }
        throw AuthFailure.fromFirebaseException(error);
      }
      return;
    }

    final AuthCredential credential = await _googleCredential();
    try {
      await _firebaseAuth.signInWithCredential(credential);
      _pendingGoogleCredential = null;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'account-exists-with-different-credential' ||
          error.code == 'email-already-in-use') {
        _pendingGoogleCredential = credential;
        throw AuthFailure.fromFirebaseException(
          FirebaseAuthException(
            code: 'account-exists-with-different-credential',
            message: error.message,
          ),
        );
      }
      throw AuthFailure.fromFirebaseException(error);
    }
  }

  @override
  Future<void> linkGoogleToCurrentAccount() async {
    final User? user = currentUser;
    if (user == null) {
      throw const AuthFailure(
        'unknown',
        'Спочатку увійдіть у свій обліковий запис.',
      );
    }

    if (kIsWeb) {
      await _withMappedAuthErrors(
        () => user.linkWithPopup(GoogleAuthProvider()),
      );
      return;
    }

    final AuthCredential credential =
        _pendingGoogleCredential ?? await _googleCredential();
    await _withMappedAuthErrors(() => user.linkWithCredential(credential));
    _pendingGoogleCredential = null;
  }

  @override
  Future<void> signOut() async {
    await _withMappedAuthErrors(_firebaseAuth.signOut);
    _pendingGoogleCredential = null;
    try {
      await _googleSignIn.signOut();
    } on GoogleSignInException {
      throw const AuthFailure(
        'google-sign-out-failed',
        'Сеанс завершено, але не вдалося вийти з Google на цьому пристрої.',
      );
    } on PlatformException {
      throw const AuthFailure(
        'google-sign-out-failed',
        'Сеанс завершено, але не вдалося вийти з Google на цьому пристрої.',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _withMappedAuthErrors(
      () => _firebaseAuth.sendPasswordResetEmail(email: email.trim()),
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final User? user = currentUser;
    final String? email = user?.email;
    if (user == null || email == null) {
      throw const AuthFailure(
        'unknown',
        'Увійдіть у свій обліковий запис і повторіть спробу.',
      );
    }
    if (!user.providerData.any(
      (provider) => provider.providerId == 'password',
    )) {
      throw AuthFailure.fromFirebaseException(
        FirebaseAuthException(code: 'google-account-no-password'),
      );
    }

    await _withMappedAuthErrors(() async {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    });
  }

  @override
  Future<void> updatePhotoUrl(String httpsUrl) async {
    final Uri? uri = Uri.tryParse(httpsUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const AuthFailure(
        'invalid-photo-url',
        'Посилання на фото має починатися з https://.',
      );
    }

    final User? user = currentUser;
    if (user == null) {
      throw const AuthFailure(
        'unknown',
        'Увійдіть у свій обліковий запис і повторіть спробу.',
      );
    }
    await _withMappedAuthErrors(() => user.updatePhotoURL(uri.toString()));
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final User? user = currentUser;
    if (user == null) {
      throw const AuthFailure(
        'unknown',
        'Увійдіть у свій обліковий запис і повторіть спробу.',
      );
    }
    await _withMappedAuthErrors(
      () => user.updateDisplayName(displayName.trim()),
    );
  }

  Future<AuthCredential> _googleCredential() async {
    try {
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(
          'google-token-missing',
          'Google не надав токен входу. Перевірте налаштування OAuth.',
        );
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure(
          'google-sign-in-canceled',
          'Вхід через Google скасовано.',
        );
      }
      throw const AuthFailure(
        'google-sign-in-failed',
        'Не вдалося увійти через Google. Спробуйте ще раз.',
      );
    } on PlatformException {
      throw const AuthFailure(
        'google-sign-in-failed',
        'Не вдалося увійти через Google. Перевірте налаштування OAuth.',
      );
    }
  }

  Future<T> _withMappedAuthErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebaseException(error);
    }
  }

  String _nameFromEmail(String email) {
    final String localPart = email.trim().split('@').first;
    final List<String> words = localPart
        .replaceAll(RegExp(r'[._+-]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return localPart;
    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
