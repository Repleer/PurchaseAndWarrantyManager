import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/warranty_verification_service.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/domain/warranty_check.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/purchases_mock_data.dart';

void main() {
  test(
    'асинхронний сервіс повертає результат чистої перевірки з тестовим clock',
    () async {
      final purchase = PurchasesMockData.items.first;
      final DateTime now = DateTime(2026, 10, 1);
      final WarrantyVerificationService service =
          MockWarrantyVerificationService(
            latency: Duration.zero,
            clock: () => now,
          );
      final WarrantyCheckResult actual = await service.verify(
        purchase: purchase,
        serialNumber: ' S01-1234567-8 ',
      );
      final WarrantyCheckResult expected = checkWarranty(
        purchase: purchase,
        serialNumber: ' S01-1234567-8 ',
        now: now,
      );
      expect(actual.isValid, expected.isValid);
      expect(actual.message, expected.message);
      expect(
        actual.items.map((item) => item.title),
        expected.items.map((item) => item.title),
      );
      expect(
        actual.items.map((item) => item.detail),
        expected.items.map((item) => item.detail),
      );
      expect(
        actual.items.map((item) => item.state),
        expected.items.map((item) => item.state),
      );
      expect(() => actual.items.clear(), throwsUnsupportedError);
    },
  );

  test('змінний clock дозволяє перевірити завершення гарантії', () async {
    final purchase = PurchasesMockData.items.first;
    DateTime now = DateTime(2026, 10, 1);
    final service = MockWarrantyVerificationService(
      latency: Duration.zero,
      clock: () => now,
    );
    expect(
      (await service.verify(
        purchase: purchase,
        serialNumber: 'S01-1234567-8',
      )).isValid,
      isTrue,
    );
    now = DateTime(2026, 11, 15);
    final WarrantyCheckResult expired = await service.verify(
      purchase: purchase,
      serialNumber: 'S01-1234567-8',
    );
    expect(expired.isValid, isFalse);
    expect(
      expired.message,
      checkWarranty(
        purchase: purchase,
        serialNumber: 'S01-1234567-8',
        now: now,
      ).message,
    );
  });
}
