import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/data/data_failure.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/claims_mock_data.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/in_memory_claim_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/domain/claim.dart';

void main() {
  test(
    'звернення кожного користувача починаються з окремої копії моків',
    () async {
      final repository = InMemoryClaimRepository(latency: Duration.zero);
      final List<Claim> snapshot = await repository.fetchAll(userId: 'u1');
      expect(snapshot, ClaimsMockData.items);
      expect(() => snapshot.clear(), throwsUnsupportedError);
      final Claim created = ClaimsMockData.items.first.copyWith(
        id: 'c-added',
        number: 'ГВ-2026-011',
      );
      await repository.create(userId: 'u1', claim: created);
      expect(snapshot, hasLength(5));
      expect(await repository.fetchAll(userId: 'u1'), hasLength(6));
      expect(await repository.fetchAll(userId: 'u2'), ClaimsMockData.items);

      final Claim changed = created.copyWith(
        description: 'Оновлено звернення.',
      );
      expect(await repository.update(userId: 'u1', claim: changed), changed);
      expect((await repository.fetchAll(userId: 'u1')).last, changed);
      await repository.delete(userId: 'u1', claimId: changed.id);
      expect(await repository.fetchAll(userId: 'u1'), ClaimsMockData.items);
      await expectLater(
        repository.update(userId: 'u1', claim: changed),
        throwsA(
          isA<DataFailure>().having(
            (failure) => failure.message,
            'message',
            'Запис не знайдено',
          ),
        ),
      );
      await expectLater(
        repository.delete(userId: 'u1', claimId: changed.id),
        throwsA(
          isA<DataFailure>().having(
            (failure) => failure.message,
            'message',
            'Запис не знайдено',
          ),
        ),
      );
    },
  );

  test(
    'nextNumber резервує наступний номер окремо для кожного userId',
    () async {
      final repository = InMemoryClaimRepository(latency: Duration.zero);
      final String year = DateTime.now().year.toString();
      expect(await repository.nextNumber(userId: 'u1'), 'ГВ-$year-011');
      expect(await repository.nextNumber(userId: 'u1'), 'ГВ-$year-012');
      expect(await repository.nextNumber(userId: 'u2'), 'ГВ-$year-011');
      await repository.create(
        userId: 'u1',
        claim: ClaimsMockData.items.first.copyWith(
          id: 'c-new',
          number: 'ГВ-$year-020',
        ),
      );
      expect(await repository.nextNumber(userId: 'u1'), 'ГВ-$year-021');
      expect(await repository.nextNumber(userId: 'u2'), 'ГВ-$year-012');
    },
  );

  test('failWhen повертає DataFailure для всіх методів', () async {
    final repository = InMemoryClaimRepository(
      latency: Duration.zero,
      failWhen: () => true,
    );
    final Claim claim = ClaimsMockData.items.first;
    for (final Future<Object?> Function() call in [
      () => repository.fetchAll(userId: 'u1'),
      () => repository.create(userId: 'u1', claim: claim),
      () => repository.update(userId: 'u1', claim: claim),
      () => repository.delete(userId: 'u1', claimId: claim.id),
      () => repository.nextNumber(userId: 'u1'),
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
  });
}
