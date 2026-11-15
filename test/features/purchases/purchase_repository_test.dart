import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/data/data_failure.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/in_memory_purchase_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/purchases_mock_data.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/domain/purchase.dart';

void main() {
  test(
    'fetchAll копіює моки для кожного userId та повертає незмінний знімок',
    () async {
      final repository = InMemoryPurchaseRepository(latency: Duration.zero);
      final List<Purchase> original = await repository.fetchAll(
        userId: 'user-a',
      );
      expect(original, PurchasesMockData.items);
      expect(identical(original, PurchasesMockData.items), isFalse);
      expect(
        () => original.add(PurchasesMockData.items.first),
        throwsUnsupportedError,
      );

      final Purchase created = PurchasesMockData.items.first.copyWith(
        id: 'p-added',
      );
      expect(
        await repository.create(userId: 'user-a', purchase: created),
        created,
      );
      expect(original, hasLength(PurchasesMockData.items.length));
      expect(
        await repository.fetchAll(userId: 'user-a'),
        hasLength(PurchasesMockData.items.length + 1),
      );
      expect(
        await repository.fetchAll(userId: 'user-b'),
        PurchasesMockData.items,
      );
    },
  );

  test('create/update/delete працюють у межах користувача', () async {
    final repository = InMemoryPurchaseRepository(latency: Duration.zero);
    final Purchase created = PurchasesMockData.items.first.copyWith(
      id: 'p-added',
    );
    await repository.create(userId: 'u1', purchase: created);
    final Purchase changed = created.copyWith(productName: 'Оновлений товар');
    expect(await repository.update(userId: 'u1', purchase: changed), changed);
    expect((await repository.fetchAll(userId: 'u1')).last, changed);
    expect(
      (await repository.fetchAll(userId: 'u2')).any((p) => p.id == 'p-added'),
      isFalse,
    );
    await repository.delete(userId: 'u1', purchaseId: 'p-added');
    expect(
      (await repository.fetchAll(userId: 'u1')).any((p) => p.id == 'p-added'),
      isFalse,
    );
    await expectLater(
      repository.update(userId: 'u1', purchase: changed),
      throwsA(
        isA<DataFailure>().having(
          (failure) => failure.message,
          'message',
          'Запис не знайдено',
        ),
      ),
    );
    await expectLater(
      repository.delete(userId: 'u1', purchaseId: 'p-added'),
      throwsA(
        isA<DataFailure>().having(
          (failure) => failure.message,
          'message',
          'Запис не знайдено',
        ),
      ),
    );
  });

  test('failWhen блокує кожну операцію до зміни стану', () async {
    bool fail = true;
    final repository = InMemoryPurchaseRepository(
      latency: Duration.zero,
      failWhen: () => fail,
    );
    final Purchase purchase = PurchasesMockData.items.first;
    for (final Future<Object?> Function() call in [
      () => repository.fetchAll(userId: 'u1'),
      () => repository.create(userId: 'u1', purchase: purchase),
      () => repository.update(userId: 'u1', purchase: purchase),
      () => repository.delete(userId: 'u1', purchaseId: purchase.id),
    ]) {
      await expectLater(
        call(),
        throwsA(
          isA<DataFailure>().having(
            (failure) => failure.message,
            'message',
            'Не вдалося завантажити дані. Спробуйте ще раз.',
          ),
        ),
      );
    }
    fail = false;
    expect(await repository.fetchAll(userId: 'u1'), PurchasesMockData.items);
  });
}
