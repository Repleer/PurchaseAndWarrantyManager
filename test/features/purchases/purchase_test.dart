import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/purchases_mock_data.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/domain/purchase.dart';

void main() {
  final Purchase sony = PurchasesMockData.items.first;

  test('warrantyUntil додає календарні місяці', () {
    expect(sony.warrantyUntil, DateTime(2026, 10, 18));
    expect(
      sony
          .copyWith(purchaseDate: DateTime(2024, 1, 31), warrantyMonths: 1)
          .warrantyUntil,
      DateTime(2024, 2, 29),
    );
    expect(
      sony
          .copyWith(purchaseDate: DateTime(2025, 1, 31), warrantyMonths: 1)
          .warrantyUntil,
      DateTime(2025, 2, 28),
    );
    expect(
      sony
          .copyWith(purchaseDate: DateTime(2025, 12, 31), warrantyMonths: 2)
          .warrantyUntil,
      DateTime(2026, 2, 28),
    );
  });

  test('status враховує межі 60 і 0 днів за фіксованим now', () {
    expect(sony.status(DateTime(2026, 8, 18)), WarrantyStatus.active);
    expect(sony.status(DateTime(2026, 8, 19)), WarrantyStatus.expiringSoon);
    expect(sony.daysLeft(DateTime(2026, 10, 18, 23)), 0);
    expect(sony.status(DateTime(2026, 10, 18)), WarrantyStatus.expiringSoon);
    expect(sony.status(DateTime(2026, 10, 19)), WarrantyStatus.expired);
    expect(
      PurchasesMockData.items
          .map((p) => p.status(DateTime(2026, 11, 15)))
          .toSet(),
      WarrantyStatus.values.toSet(),
    );
  });

  test('JSON round-trip зберігає всі поля та значення рівності', () {
    final Map<String, dynamic> decoded =
        jsonDecode(jsonEncode(sony.toJson())) as Map<String, dynamic>;
    final Purchase restored = Purchase.fromJson(decoded);
    expect(restored, sony);
    expect(restored.hashCode, sony.hashCode);
    expect(decoded['category'], 'electronics');
    expect(decoded['purchaseDate'], '2024-10-18T00:00:00.000');
    expect(restored.copyWith(notes: null).notes, isNull);
    expect(restored.copyWith(notes: null), isNot(sony));
  });
}
