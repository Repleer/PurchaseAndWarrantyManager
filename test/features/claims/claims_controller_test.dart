import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/data/load_status.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/application/claims_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/claims_mock_data.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/in_memory_claim_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/warranty_verification_service.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/domain/claim.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/purchases_mock_data.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/domain/purchase.dart';

void main() {
  final DateTime now = DateTime(2026, 11, 15);
  final Map<String, Purchase> purchasesById = {
    for (final Purchase purchase in PurchasesMockData.items)
      purchase.id: purchase,
  };

  ClaimsController createController({bool Function()? failWhen}) {
    final controller = ClaimsController(
      InMemoryClaimRepository(latency: Duration.zero, failWhen: failWhen),
      MockWarrantyVerificationService(latency: Duration.zero),
      clock: () => now,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test(
    'load, bindUser і фільтри мають незалежні чернетку та застосований стан',
    () async {
      final controller = createController();
      final List<LoadStatus> transitions = [];
      controller.addListener(() => transitions.add(controller.status));
      controller.bindUser('u1');
      await controller.load();
      expect(
        transitions,
        containsAllInOrder([LoadStatus.loading, LoadStatus.ready]),
      );
      expect(controller.items, ClaimsMockData.items);
      expect(controller.totalCount, 5);
      expect(controller.byId('c1')?.number, 'ГВ-2026-010');
      expect(controller.latestForPurchase('p1')?.id, 'c1');
      expect(controller.forPurchase('unknown'), isEmpty);
      controller.updateDraft((query) => query.copyWith(search: 'sony'));
      expect(controller.visibleItems(purchasesById), hasLength(5));
      controller.applyFilters();
      expect(controller.visibleItems(purchasesById).map((claim) => claim.id), [
        'c1',
      ]);
      controller.resetFilters();
      expect(controller.visibleItems(purchasesById), hasLength(5));
      controller.toggleDateSort();
      expect(controller.visibleItems(purchasesById).first.id, 'c5');
      expect(controller.draftQuery.newestFirst, isFalse);
      controller.bindUser(null);
      expect(controller.status, LoadStatus.initial);
      expect(controller.totalCount, 0);
      expect(controller.draftQuery.search, isEmpty);
    },
  );

  test(
    'failWhen показує failure; повторне завантаження повертає ready',
    () async {
      bool fail = true;
      final controller = createController(failWhen: () => fail);
      controller.bindUser('u1');
      await controller.load();
      expect(controller.status, LoadStatus.failure);
      expect(
        controller.errorMessage,
        'Не вдалося завантажити дані. Спробуйте ще раз.',
      );
      fail = false;
      await controller.load();
      expect(controller.status, LoadStatus.ready);
      expect(controller.errorMessage, isNull);
    },
  );

  test(
    'submit виділяє зростаючі номери й додає записи в новий список',
    () async {
      final controller = createController();
      controller.bindUser('u1');
      await controller.load();
      final List<Claim> original = controller.items;
      final Claim draft = ClaimsMockData.items.first.copyWith(
        id: 'c-extra-1',
        number: '',
        purchaseId: 'p3',
        createdAt: now,
      );
      final Claim? first = await controller.submit(draft);
      expect(first?.number, 'ГВ-${DateTime.now().year}-011');
      expect(controller.byId('c-extra-1'), first);
      expect(controller.items, isNot(same(original)));
      expect(controller.totalCount, 6);
      final Claim? second = await controller.submit(
        draft.copyWith(id: 'c-extra-2'),
      );
      expect(second?.number, 'ГВ-${DateTime.now().year}-012');
      expect(controller.totalCount, 7);
      expect(
        controller.forPurchase('p3').map((claim) => claim.id),
        containsAll(['c-extra-1', 'c-extra-2', 'c3']),
      );
      expect(() => controller.items.clear(), throwsUnsupportedError);
    },
  );

  test('update додає лише одну подію історії та оновлює timestamp', () async {
    final controller = createController();
    controller.bindUser('u1');
    await controller.load();
    final Claim original = controller.byId('c1')!;
    expect(
      await controller.update(
        original.copyWith(description: 'Оновлений опис проблеми.'),
      ),
      isTrue,
    );
    final Claim updated = controller.byId('c1')!;
    expect(updated.description, 'Оновлений опис проблеми.');
    expect(updated.history.length, original.history.length + 1);
    expect(updated.history.last.title, 'Звернення оновлено');
    expect(updated.history.last.at, now);
    expect(updated.updatedAt, now);
  });

  test(
    'withdraw оптимістично видаляє; при помилці повертає на попередній індекс',
    () async {
      bool fail = false;
      final controller = createController(failWhen: () => fail);
      controller.bindUser('u1');
      await controller.load();
      final List<Claim> before = controller.items;
      fail = true;
      final Future<bool> removing = controller.withdraw('c2');
      expect(controller.byId('c2'), isNull);
      expect(await removing, isFalse);
      expect(controller.items, before);
      expect(controller.items[1].id, 'c2');
      expect(controller.errorMessage, isNotNull);
      controller.clearError();
      expect(controller.errorMessage, isNull);
      fail = false;
      expect(await controller.withdraw('c2'), isTrue);
      expect(controller.byId('c2'), isNull);
    },
  );

  test(
    'removeForPurchase видаляє тільки звернення відповідної покупки',
    () async {
      final controller = createController();
      controller.bindUser('u1');
      await controller.load();
      await controller.removeForPurchase('p1');
      expect(controller.byId('c1'), isNull);
      expect(controller.byId('c2'), isNotNull);
      expect(controller.totalCount, 4);
      await controller.removeForPurchase('unknown');
      expect(controller.totalCount, 4);
    },
  );

  test('запис іншого користувача не показується після перепривʼязки', () async {
    final controller = createController();
    controller.bindUser('u1');
    await controller.load();
    await controller.submit(
      ClaimsMockData.items.first.copyWith(id: 'c-extra', number: ''),
    );
    controller.bindUser('u2');
    await controller.load();
    expect(controller.byId('c-extra'), isNull);
    expect(controller.totalCount, 5);
  });
}
