import 'dart:async';

import '../../../data/data_failure.dart';
import '../../../data/json_file_store.dart';
import '../domain/purchase.dart';
import 'purchase_repository.dart';
import 'purchases_mock_data.dart';

/// Файловий репозиторій покупок з ізоляцією за UID.
class LocalFilePurchaseRepository implements PurchaseRepository {
  LocalFilePurchaseRepository(this._store);

  final JsonFileStore _store;
  final Map<String, List<Purchase>> _byUser = {};
  final Map<String, Future<List<Purchase>>> _loading = {};
  final Map<String, Future<void>> _pendingWrites = {};

  String _path(String userId) => 'users/$userId/purchases.json';

  Future<List<Purchase>> _load(String userId) async {
    final List<Purchase>? cached = _byUser[userId];
    if (cached != null) return cached;
    final Future<List<Purchase>> pending = _loading[userId] ??= _readOrSeed(
      userId,
    );
    try {
      final List<Purchase> items = await pending;
      return _byUser.putIfAbsent(userId, () => items);
    } finally {
      if (identical(_loading[userId], pending)) _loading.remove(userId);
    }
  }

  Future<List<Purchase>> _readOrSeed(String userId) async {
    final List<Map<String, dynamic>>? data = await _store.readList(
      _path(userId),
    );
    if (data == null) {
      final List<Purchase> seeded = List<Purchase>.of(PurchasesMockData.items);
      await _store.writeList(
        _path(userId),
        seeded.map((purchase) => purchase.toJson()).toList(),
      );
      return seeded;
    }
    try {
      return data.map(Purchase.fromJson).toList();
    } on DataFailure {
      rethrow;
    } catch (_) {
      throw const DataFailure('Локальні дані пошкоджено');
    }
  }

  /// Упорядковує операції над одним файлом, не блокуючи інших користувачів.
  Future<T> _serialize<T>(String uid, Future<T> Function() action) async {
    final Future<void>? previous = _pendingWrites[uid];
    final Completer<void> done = Completer<void>();
    _pendingWrites[uid] = done.future;
    try {
      if (previous != null) await previous;
      return await action();
    } finally {
      done.complete();
      if (identical(_pendingWrites[uid], done.future)) {
        _pendingWrites.remove(uid);
      }
    }
  }

  Future<void> _write(String uid, List<Purchase> items) => _store.writeList(
    _path(uid),
    items.map((purchase) => purchase.toJson()).toList(),
  );

  @override
  Future<List<Purchase>> fetchAll({required String userId}) async {
    final Future<void>? pending = _pendingWrites[userId];
    if (pending != null) await pending;
    return List<Purchase>.unmodifiable(await _load(userId));
  }

  @override
  Future<Purchase> create({
    required String userId,
    required Purchase purchase,
  }) => _serialize(userId, () async {
    final List<Purchase> current = await _load(userId);
    if (current.any((item) => item.id == purchase.id)) {
      throw const DataFailure('Запис уже існує');
    }
    final List<Purchase> next = [...current, purchase];
    await _write(userId, next);
    _byUser[userId] = next;
    return purchase;
  });

  @override
  Future<Purchase> update({
    required String userId,
    required Purchase purchase,
  }) => _serialize(userId, () async {
    final List<Purchase> current = await _load(userId);
    final int index = current.indexWhere((item) => item.id == purchase.id);
    if (index < 0) throw const DataFailure('Запис не знайдено');
    final List<Purchase> next = [...current]..[index] = purchase;
    await _write(userId, next);
    _byUser[userId] = next;
    return purchase;
  });

  @override
  Future<void> delete({required String userId, required String purchaseId}) =>
      _serialize<void>(userId, () async {
        final List<Purchase> current = await _load(userId);
        final int index = current.indexWhere((item) => item.id == purchaseId);
        if (index < 0) throw const DataFailure('Запис не знайдено');
        final List<Purchase> next = [...current]..removeAt(index);
        await _write(userId, next);
        _byUser[userId] = next;
      });
}
