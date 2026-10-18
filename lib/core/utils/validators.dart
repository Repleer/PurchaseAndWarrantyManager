/// Прості перевірки полів форм (без звернення до бекенду).
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? requiredField(
    String? value, [
    String message = 'Заповніть це поле.',
  ]) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Введіть email.';
    if (!_emailPattern.hasMatch(text)) {
      return 'Некоректна адреса електронної пошти.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Введіть пароль.';
    if (value.length < 8) return 'Пароль має містити щонайменше 8 символів.';
    return null;
  }

  static String? confirmation(String? value, String original) {
    if (value == null || value.isEmpty) return 'Підтвердіть новий пароль.';
    if (value != original) return 'Паролі не збігаються.';
    return null;
  }
}
