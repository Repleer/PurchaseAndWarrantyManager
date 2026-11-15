import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/domain/warranty_check.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/purchases_mock_data.dart';

void main() {
  final sony = PurchasesMockData.items.first;
  final now = DateTime(2026, 10, 1);

  test('усі три критерії успішні за чинної гарантії', () {
    final result = checkWarranty(
      purchase: sony,
      serialNumber: ' s01 -1234567-8 ',
      now: now,
    );
    expect(result.items, hasLength(3));
    expect(
      result.items.map((item) => item.state),
      everyElement(CheckItemState.passed),
    );
    expect(
      result.items.first.detail,
      'S01-1234567-8 · Збігається з документом',
    );
    expect(result.items[1].detail, '18.10.2024 · Підтверджено чеком');
    expect(result.isValid, isTrue);
    expect(
      result.message,
      'Гарантія чинна до 18.10.2026. Можна продовжити оформлення звернення.',
    );
  });

  test(
    'чужий серійний номер не проходить, документи лишаються неперевіреними',
    () {
      final result = checkWarranty(
        purchase: sony,
        serialNumber: 'S01-1234567-0',
        now: now,
      );
      expect(result.isValid, isFalse);
      expect(result.items.map((item) => item.state), [
        CheckItemState.failed,
        CheckItemState.unverified,
        CheckItemState.unverified,
      ]);
      expect(result.items.first.detail, contains('Не знайдено в реєстрі'));
      expect(result.message, contains('Перевірте серійний номер'));
    },
  );

  test(
    'після закінчення строку навіть усі пройдені критерії не дають успіху',
    () {
      final result = checkWarranty(
        purchase: sony,
        serialNumber: 'S01-1234567-8',
        now: DateTime(2026, 11, 15),
      );
      expect(
        result.items.map((item) => item.state),
        everyElement(CheckItemState.passed),
      );
      expect(result.isValid, isFalse);
      expect(result.message, 'Гарантія завершилась 18.10.2026.');
    },
  );

  test('відсутні документи не дозволяють підтвердити гарантію', () {
    final withoutReceipt = checkWarranty(
      purchase: sony.copyWith(receiptFileName: null),
      serialNumber: 'S01-1234567-8',
      now: now,
    );
    expect(withoutReceipt.items[1].state, CheckItemState.unverified);
    expect(withoutReceipt.items[2].state, CheckItemState.passed);
    expect(withoutReceipt.isValid, isFalse);
    final withoutWarranty = checkWarranty(
      purchase: sony.copyWith(warrantyFileName: null),
      serialNumber: 'S01-1234567-8',
      now: now,
    );
    expect(withoutWarranty.items[2].state, CheckItemState.unverified);
    expect(withoutWarranty.isValid, isFalse);
  });
}
