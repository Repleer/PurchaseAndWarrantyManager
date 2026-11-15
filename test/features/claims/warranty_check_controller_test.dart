import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/application/warranty_check_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/warranty_verification_service.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/domain/warranty_check.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/purchases_mock_data.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/domain/purchase.dart';

void main() {
  final Purchase purchase = PurchasesMockData.items.first;

  test('idle → checking → done, результат надходить із сервісу', () async {
    final controller = WarrantyCheckController(
      MockWarrantyVerificationService(
        latency: Duration.zero,
        clock: () => DateTime(2026, 10, 1),
      ),
    );
    addTearDown(controller.dispose);
    expect(controller.status, WarrantyCheckStatus.idle);
    expect(controller.result, isNull);
    final Future<void> pending = controller.run(purchase, 'S01-1234567-8');
    expect(controller.status, WarrantyCheckStatus.checking);
    await pending;
    expect(controller.status, WarrantyCheckStatus.done);
    expect(controller.result?.isValid, isTrue);
    controller.reset();
    expect(controller.status, WarrantyCheckStatus.idle);
    expect(controller.result, isNull);
  });

  test('reset і dispose ігнорують результат попередньої перевірки', () async {
    final service = _DeferredVerificationService();
    final controller = WarrantyCheckController(service);
    final Future<void> pending = controller.run(purchase, 'S01-1234567-8');
    controller.reset();
    service.complete(
      checkWarranty(
        purchase: purchase,
        serialNumber: 'S01-1234567-8',
        now: DateTime(2026, 10, 1),
      ),
    );
    await pending;
    expect(controller.status, WarrantyCheckStatus.idle);
    expect(controller.result, isNull);
    controller.dispose();
  });
}

class _DeferredVerificationService implements WarrantyVerificationService {
  final Completer<WarrantyCheckResult> _pending =
      Completer<WarrantyCheckResult>();

  void complete(WarrantyCheckResult result) => _pending.complete(result);

  @override
  Future<WarrantyCheckResult> verify({
    required Purchase purchase,
    required String serialNumber,
  }) => _pending.future;
}
