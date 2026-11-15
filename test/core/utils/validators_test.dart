import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepts a well-formed email', () {
      expect(Validators.email('user@example.com'), isNull);
    });

    test('rejects an empty or malformed email', () {
      expect(Validators.email(' '), isNotNull);
      expect(Validators.email('user@invalid'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('requires eight characters, a letter, and a digit', () {
      expect(Validators.password('Abc1234'), isNotNull);
      expect(Validators.password('password'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password('Secure123'), isNull);
    });

    test('rejects a new password matching the current password', () {
      expect(
        Validators.newPassword('Secure123', 'Secure123'),
        'Новий пароль має відрізнятися від поточного.',
      );
    });
  });

  group('Validators.httpsUrl', () {
    test('accepts HTTPS and rejects HTTP or malformed URLs', () {
      expect(Validators.httpsUrl('https://example.com/photo.png'), isNull);
      expect(Validators.httpsUrl('http://example.com/photo.png'), isNotNull);
      expect(Validators.httpsUrl('https://'), isNotNull);
    });
  });

  test('validates names and numeric fields', () {
    expect(Validators.name('О'), isNotNull);
    expect(Validators.name('Олена'), isNull);
    expect(Validators.requiredNumber('12.5'), isNull);
    expect(Validators.requiredNumber('не число'), isNotNull);
  });

  test('перевіряє додатну вартість та довжину нотаток', () {
    expect(Validators.positivePrice('14 999,50 ₴'), isNull);
    expect(Validators.positivePrice('0'), isNotNull);
    expect(Validators.positivePrice('-5'), isNotNull);
    expect(Validators.positivePrice('abc'), isNotNull);
    expect(Validators.positivePrice(''), isNotNull);
    expect(Validators.purchaseNotes('а' * 500), isNull);
    expect(Validators.purchaseNotes('а' * 501), isNotNull);
  });

  test('перевіряє опис гарантійного звернення', () {
    expect(Validators.claimDescription('коротко'), isNotNull);
    expect(Validators.claimDescription('Несправність повторюється.'), isNull);
    expect(Validators.claimDescription('а' * 1000), isNull);
    expect(Validators.claimDescription('а' * 1001), isNotNull);
  });
}
