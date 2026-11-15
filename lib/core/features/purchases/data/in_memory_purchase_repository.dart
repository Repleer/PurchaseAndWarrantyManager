import '../../../data/data_failure.dart';
import '../domain/purchase.dart';
import 'purchase_repository.dart';
import 'purchases_mock_data.dart';

/// Покупки в пам'яті: для кожного користувача окрема копія моків.
class InMemoryPurchaseRepository implements PurchaseRepository {
  InMemoryPurchaseRepository({
    this.latency = const Duration(milliseconds: 400),
    this.failWhen,
  });

  final Duration latency;
  final bool Function()? failWhen;
  final Map<String, List<Purchase>> _byUser = {};

  List<Purchase> _items(String userId) => _byUser.putIfAbsent(
    userId,
    () => List<Purchase>.of(PurchasesMockData.items),
  );

  Future<void> _waitAndCheckFailure() async {
    await Future<void>.delayed(latency);
    if (failWhen?.call() ?? false) {
      throw const DataFailure('Не вдалося завантажити дані. Спробуйте ще раз.');
    }
  }

  @override
  Future<List<Purchase>> fetchAll({required String userId}) async {
    await _waitAndCheckFailure();
    return List<Purchase>.unmodifiable(_items(userId));
  }

  @override
  Future<Purchase> create({
    required String userId,
    required Purchase purchase,
  }) async {
    await _waitAndCheckFailure();
    final List<Purchase> items = _items(userId);
    if (items.any((item) => item.id == purchase.id)) {
      throw const DataFailure('Запис уже існує');
    }
    items.add(purchase);
    return purchase;
  }

  @override
  Future<Purchase> update({
    required String userId,
    required Purchase purchase,
  }) async {
    await _waitAndCheckFailure();
    final List<Purchase> items = _items(userId);
    final int index = items.indexWhere((item) => item.id == purchase.id);
    if (index < 0) throw const DataFailure('Запис не знайдено');
    items[index] = purchase;
    return purchase;
  }

  @override
  Future<void> delete({
    required String userId,
    required String purchaseId,
  }) async {
    await _waitAndCheckFailure();
    final List<Purchase> items = _items(userId);
    final int index = items.indexWhere((item) => item.id == purchaseId);
    if (index < 0) throw const DataFailure('Запис не знайдено');
    items.removeAt(index);
  }
}
