import '../../purchases/domain/purchase.dart';
import '../domain/warranty_check.dart';

/// Контракт асинхронної перевірки гарантії покупки.
abstract interface class WarrantyVerificationService {
  Future<WarrantyCheckResult> verify({
    required Purchase purchase,
    required String serialNumber,
  });
}

/// Імітація перевірки; у реальному застосунку тут був би запит до реєстру виробника.
class MockWarrantyVerificationService implements WarrantyVerificationService {
  MockWarrantyVerificationService({
    this.latency = const Duration(milliseconds: 800),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration latency;
  final DateTime Function() _clock;

  @override
  Future<WarrantyCheckResult> verify({
    required Purchase purchase,
    required String serialNumber,
  }) async {
    await Future<void>.delayed(latency);
    return checkWarranty(
      purchase: purchase,
      serialNumber: serialNumber,
      now: _clock(),
    );
  }
}
