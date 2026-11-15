import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/data/load_status.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/application/purchases_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/in_memory_purchase_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/purchase_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/purchases_mock_data.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/domain/purchase.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/domain/purchase_query.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 1);

  test('load повідомляє loading → ready і повертає моки', () async {
    final controller = PurchasesController(
      InMemoryPurchaseRepository(latency: Duration.zero),
      clock: () => now,
    );
    addTearDown(controller.dispose);
    final List<LoadStatus> changes = [];
    controller.addListener(() => changes.add(controller.status));
    controller.bindUser('u1');
    await controller.load();
    expect(changes, containsAllInOrder([LoadStatus.loading, LoadStatus.ready]));
    expect(controller.status, LoadStatus.ready);
    expect(controller.items, PurchasesMockData.items);
    expect(() => controller.items.clear(), throwsUnsupportedError);
    expect(controller.byId('p1')?.productName, 'Навушники Sony WH-1000XM5');
    expect(controller.byId('missing'), isNull);
    expect(controller.expiringSoon.map((p) => p.id), ['p1', 'p2', 'p6']);
    expect(controller.recent.map((p) => p.id), ['p8', 'p3', 'p4']);
  });

  test(
    'failWhen переводить load у failure, повторне завантаження відновлює ready',
    () async {
      bool fail = true;
      final controller = PurchasesController(
        InMemoryPurchaseRepository(
          latency: Duration.zero,
          failWhen: () => fail,
        ),
        clock: () => now,
      );
      addTearDown(controller.dispose);
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
    'чернетка не змінює visibleItems до застосування, сортування одразу',
    () async {
      final controller = PurchasesController(
        InMemoryPurchaseRepository(latency: Duration.zero),
        clock: () => now,
      );
      addTearDown(controller.dispose);
      controller.bindUser('u1');
      await controller.load();
      final int originalLength = controller.visibleItems.length;
      controller.updateDraft((query) => query.copyWith(search: 'Sony'));
      expect(controller.visibleItems, hasLength(originalLength));
      controller.applyFilters();
      expect(controller.visibleItems.map((p) => p.id), ['p1']);
      controller.resetFilters();
      expect(controller.visibleItems, hasLength(originalLength));
      controller.toggleSort(PurchaseSortField.price);
      expect(controller.visibleItems.first.id, 'p6');
      controller.toggleSort(PurchaseSortField.price);
      expect(controller.visibleItems.first.id, 'p5');
      expect(controller.appliedQuery.ascending, isTrue);
      expect(controller.draftQuery.ascending, isTrue);
    },
  );

  test(
    'add/update/remove змінюють нові списки та ізольовані за userId',
    () async {
      final repository = InMemoryPurchaseRepository(latency: Duration.zero);
      final controller = PurchasesController(repository, clock: () => now);
      addTearDown(controller.dispose);
      controller.bindUser('u1');
      await controller.load();
      final List<Purchase> before = controller.items;
      final Purchase created = before.first.copyWith(id: 'p-extra');
      expect(await controller.add(created), isTrue);
      expect(controller.items, isNot(same(before)));
      expect(before, hasLength(PurchasesMockData.items.length));
      expect(controller.byId(created.id), created);
      final List<Purchase> afterAdd = controller.items;
      final Purchase edited = created.copyWith(productName: 'Новий товар');
      expect(await controller.update(edited), isTrue);
      expect(controller.items, isNot(same(afterAdd)));
      expect(controller.byId(created.id), edited);
      final Future<bool> removing = controller.remove(created.id);
      expect(controller.byId(created.id), isNull);
      expect(await removing, isTrue);
      expect(controller.byId(created.id), isNull);
      controller.bindUser('u2');
      await controller.load();
      expect(controller.byId(created.id), isNull);
      expect(controller.items, PurchasesMockData.items);
    },
  );

  test('помилка delete повертає покупку на попередній індекс', () async {
    bool fail = false;
    final controller = PurchasesController(
      InMemoryPurchaseRepository(latency: Duration.zero, failWhen: () => fail),
      clock: () => now,
    );
    addTearDown(controller.dispose);
    controller.bindUser('u1');
    await controller.load();
    final List<Purchase> before = controller.items;
    fail = true;
    final Future<bool> removing = controller.remove('p2');
    expect(controller.byId('p2'), isNull);
    expect(await removing, isFalse);
    expect(controller.items, before);
    expect(controller.items[1].id, 'p2');
    expect(controller.errorMessage, isNotNull);
    controller.clearError();
    expect(controller.errorMessage, isNull);
    expect(
      await controller.add(before.first.copyWith(id: 'not-saved')),
      isFalse,
    );
    expect(controller.isSaving, isFalse);
  });

  test(
    'bindUser(null) очищує стан і не застосовує застарілу відповідь',
    () async {
      final repository = _DeferredRepository();
      final controller = PurchasesController(repository, clock: () => now);
      addTearDown(controller.dispose);
      controller.bindUser('u1');
      controller.bindUser(null);
      expect(controller.status, LoadStatus.initial);
      expect(controller.items, isEmpty);
      expect(controller.draftQuery.search, isEmpty);
      repository.finish(PurchasesMockData.items);
      await Future<void>.delayed(Duration.zero);
      expect(controller.items, isEmpty);
    },
  );

  test(
    'відкладена відповідь після dispose не викликає notifyListeners',
    () async {
      final repository = _DeferredRepository();
      final controller = PurchasesController(repository);
      int notifications = 0;
      controller.addListener(() => notifications++);
      controller.bindUser('u1');
      final int beforeDispose = notifications;
      controller.dispose();
      repository.finish(PurchasesMockData.items);
      await Future<void>.delayed(Duration.zero);
      expect(notifications, beforeDispose);
      expect(controller.items, isEmpty);
    },
  );
}

class _DeferredRepository implements PurchaseRepository {
  final Completer<List<Purchase>> _pending = Completer<List<Purchase>>();

  void finish(List<Purchase> items) => _pending.complete(items);

  @override
  Future<List<Purchase>> fetchAll({required String userId}) => _pending.future;

  @override
  Future<Purchase> create({
    required String userId,
    required Purchase purchase,
  }) => throw UnimplementedError();

  @override
  Future<Purchase> update({
    required String userId,
    required Purchase purchase,
  }) => throw UnimplementedError();

  @override
  Future<void> delete({required String userId, required String purchaseId}) =>
      throw UnimplementedError();
}
