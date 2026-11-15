import '../domain/purchase.dart';

/// Контракт доступу до покупок окремого користувача.
abstract interface class PurchaseRepository {
  Future<List<Purchase>> fetchAll({required String userId});

  Future<Purchase> create({required String userId, required Purchase purchase});

  Future<Purchase> update({required String userId, required Purchase purchase});

  Future<void> delete({required String userId, required String purchaseId});
}
