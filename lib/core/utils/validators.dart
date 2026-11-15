/// Прості перевірки полів форм (без звернення до бекенду).
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _passwordLetter = RegExp(r'[A-Za-zА-Яа-яІіЇїЄєҐґ]');
  static final RegExp _passwordDigit = RegExp(r'\d');

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
    if (!_passwordLetter.hasMatch(value) || !_passwordDigit.hasMatch(value)) {
      return 'Пароль має містити щонайменше одну літеру й одну цифру.';
    }
    return null;
  }

  static String? newPassword(String? value, String currentPassword) {
    final String? error = password(value);
    if (error != null) return error;
    if (value == currentPassword) {
      return 'Новий пароль має відрізнятися від поточного.';
    }
    return null;
  }

  static String? confirmation(String? value, String original) {
    if (value == null || value.isEmpty) return 'Підтвердіть новий пароль.';
    if (value != original) return 'Паролі не збігаються.';
    return null;
  }

  static String? name(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Введіть ім’я.';
    if (text.length < 2) return 'Ім’я має містити щонайменше 2 символи.';
    return null;
  }

  static String? httpsUrl(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Введіть HTTPS-посилання на фото.';
    final Uri? uri = Uri.tryParse(text);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'Посилання має починатися з https://.';
    }
    return null;
  }

  static String? requiredNumber(String? value) {
    final String? requiredError = requiredField(value, 'Введіть число.');
    if (requiredError != null) return requiredError;
    if (num.tryParse(value!.trim()) == null) return 'Введіть коректне число.';
    return null;
  }

  /// Вартість покупки повинна бути додатним числом.
  static String? positivePrice(String? value) {
    final String text = (value ?? '')
        .replaceAll(RegExp(r'[\s₴]'), '')
        .replaceAll(',', '.');
    if (text.isEmpty) return 'Введіть вартість.';
    final double? price = double.tryParse(text);
    if (price == null || !price.isFinite || price <= 0) {
      return 'Вартість має бути більшою за нуль.';
    }
    return null;
  }

  /// Нотатки можуть містити не більше 500 символів.
  static String? purchaseNotes(String? value) =>
      (value?.length ?? 0) > 500 ? 'Не більше 500 символів.' : null;

  /// Опис гарантійного випадку повинен містити від 10 до 1000 символів.
  static String? claimDescription(String? value) {
    final int length = value?.trim().length ?? 0;
    if (length < 10) return 'Опишіть проблему щонайменше 10 символами.';
    if (length > 1000) return 'Не більше 1000 символів.';
    return null;
  }
}
