import 'package:firebase_auth/firebase_auth.dart';

/// Помилка автентифікації з повідомленням, придатним для показу користувачу.
class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  final String code;
  final String message;

  static AuthFailure fromFirebaseException(FirebaseAuthException error) {
    const Map<String, String> messages = {
      'invalid-email': 'Введіть коректну адресу електронної пошти.',
      'user-disabled': 'Цей обліковий запис вимкнено.',
      'user-not-found': 'Обліковий запис із таким email не знайдено.',
      'wrong-password': 'Неправильний email або пароль.',
      'invalid-credential': 'Неправильний email або пароль.',
      'email-already-in-use': 'Цей email уже зареєстровано.',
      'weak-password': 'Пароль надто слабкий. Використайте щонайменше 8 символів.',
      'network-request-failed': 'Немає з’єднання з інтернетом. Перевірте мережу.',
      'too-many-requests': 'Забагато спроб. Спробуйте пізніше.',
      'requires-recent-login':
          'Для цієї дії потрібно повторно увійти в обліковий запис.',
      'account-exists-with-different-credential':
          'Цей email уже має інший спосіб входу. Увійдіть у наявний акаунт і '
              'підключіть Google у профілі.',
      'operation-not-allowed':
          'Цей спосіб входу ще не ввімкнено в налаштуваннях Firebase.',
      'credential-already-in-use':
          'Цей Google-акаунт уже пов’язано з іншим обліковим записом.',
      'provider-already-linked': 'Google уже підключено до цього акаунта.',
      'google-account-no-password':
          'Цей акаунт використовує вхід через Google і не має пароля, який '
              'можна змінити.',
      'google-sign-in-canceled': 'Вхід через Google скасовано.',
    };

    return AuthFailure(
      error.code,
      messages[error.code] ?? 'Не вдалося виконати дію. Спробуйте ще раз.',
    );
  }

  @override
  String toString() => message;
}
