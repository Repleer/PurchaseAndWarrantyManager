import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/purchases_mock_data.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/domain/purchase.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/domain/purchase_query.dart';

void main() {
  final List<Purchase> items = PurchasesMockData.items;
  final DateTime now = DateTime(2026, 11, 15);

  test('пошук не залежить від регістру й шукає також за продавцем', () {
    expect(
      applyPurchaseQuery(
        items,
        const PurchaseQuery(search: '  SoNy  '),
        now,
      ).map((p) => p.id),
      ['p1'],
    );
    expect(
      applyPurchaseQuery(
        items,
        const PurchaseQuery(search: 'ISPACE'),
        now,
      ).map((p) => p.id),
      ['p4'],
    );
    expect(items.length, 9);
  });

  test('категорію та статус можна застосувати й скинути', () {
    const PurchaseQuery query = PurchaseQuery(
      category: PurchaseCategory.phones,
      status: WarrantyStatus.expiringSoon,
    );
    expect(
      applyPurchaseQuery(
        items,
        const PurchaseQuery(category: PurchaseCategory.appliances),
        now,
      ).map((p) => p.id),
      containsAll(['p2', 'p3', 'p5']),
    );
    expect(
      applyPurchaseQuery(
        items,
        const PurchaseQuery(status: WarrantyStatus.expiringSoon),
        now,
      ).map((p) => p.id),
      ['p7'],
    );
    expect(applyPurchaseQuery(items, query, now).map((p) => p.id), ['p7']);
    expect(
      applyPurchaseQuery(
        items,
        query.copyWith(clearCategory: true),
        now,
      ).map((p) => p.id),
      ['p7'],
    );
    expect(
      applyPurchaseQuery(
        items,
        query.copyWith(clearStatus: true),
        now,
      ).map((p) => p.id),
      ['p7'],
    );
    expect(query.copyWith(clearCategory: true).category, isNull);
    expect(query.copyWith(clearStatus: true).status, isNull);
    expect(
      applyPurchaseQuery(
        items,
        const PurchaseQuery(status: WarrantyStatus.expired),
        now,
      ).map((p) => p.id),
      containsAll(['p1', 'p2', 'p6', 'p9']),
    );
    expect(
      applyPurchaseQuery(
        items,
        const PurchaseQuery(status: WarrantyStatus.active),
        now,
      ).map((p) => p.id),
      contains('p8'),
    );
  });

  test('сортує дату за спаданням та зростанням', () {
    expect(
      applyPurchaseQuery(items, const PurchaseQuery(), now).first.id,
      'p7',
    );
    expect(
      applyPurchaseQuery(
        items,
        const PurchaseQuery(ascending: true),
        now,
      ).first.id,
      'p9',
    );
  });

  test('сортує за ціною в обох напрямках', () {
    expect(
      applyPurchaseQuery(
        items,
        const PurchaseQuery(sortField: PurchaseSortField.price),
        now,
      ).first.id,
      'p6',
    );
    expect(
      applyPurchaseQuery(
        items,
        const PurchaseQuery(
          sortField: PurchaseSortField.price,
          ascending: true,
        ),
        now,
      ).first.id,
      'p5',
    );
  });

  test('сортує за датою закінчення гарантії в обох напрямках', () {
    expect(
      applyPurchaseQuery(
        items,
        const PurchaseQuery(sortField: PurchaseSortField.warranty),
        now,
      ).first.id,
      'p3',
    );
    expect(
      applyPurchaseQuery(
        items,
        const PurchaseQuery(
          sortField: PurchaseSortField.warranty,
          ascending: true,
        ),
        now,
      ).first.id,
      'p9',
    );
    expect(
      applyPurchaseQuery(items, const PurchaseQuery(), now),
      isNot(same(items)),
    );
  });
}
