import 'dart:async';

import '../../../data/data_failure.dart';
import '../../../data/json_file_store.dart';
import '../domain/claim.dart';
import 'claim_repository.dart';
import 'claims_mock_data.dart';

/// Файловий репозиторій звернень із серіалізацією вкладень та історії.
class LocalFileClaimRepository implements ClaimRepository {
  LocalFileClaimRepository(this._store);

  final JsonFileStore _store;
  final Map<String, List<Claim>> _byUser = {};
  final Map<String, Future<List<Claim>>> _loading = {};
  final Map<String, Future<void>> _pendingWrites = {};
  final Map<String, int> _lastIssued = {};

  String _path(String userId) => 'users/$userId/claims.json';

  Future<List<Claim>> _load(String userId) async {
    final List<Claim>? cached = _byUser[userId];
    if (cached != null) return cached;
    final Future<List<Claim>> pending = _loading[userId] ??= _readOrSeed(
      userId,
    );
    try {
      final List<Claim> items = await pending;
      return _byUser.putIfAbsent(userId, () => items);
    } finally {
      if (identical(_loading[userId], pending)) _loading.remove(userId);
    }
  }

  Future<List<Claim>> _readOrSeed(String userId) async {
    final List<Map<String, dynamic>>? data = await _store.readList(
      _path(userId),
    );
    if (data == null) {
      final List<Claim> seeded = List<Claim>.of(ClaimsMockData.items);
      await _store.writeList(
        _path(userId),
        seeded.map((claim) => claim.toJson()).toList(),
      );
      return seeded;
    }
    try {
      return data.map(Claim.fromJson).toList();
    } on DataFailure {
      rethrow;
    } catch (_) {
      throw const DataFailure('Локальні дані пошкоджено');
    }
  }

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

  Future<void> _write(String uid, List<Claim> items) => _store.writeList(
    _path(uid),
    items.map((claim) => claim.toJson()).toList(),
  );

  @override
  Future<List<Claim>> fetchAll({required String userId}) async {
    final Future<void>? pending = _pendingWrites[userId];
    if (pending != null) await pending;
    return List<Claim>.unmodifiable(await _load(userId));
  }

  @override
  Future<Claim> create({required String userId, required Claim claim}) =>
      _serialize(userId, () async {
        final List<Claim> current = await _load(userId);
        if (current.any((item) => item.id == claim.id)) {
          throw const DataFailure('Запис уже існує');
        }
        final List<Claim> next = [...current, claim];
        await _write(userId, next);
        _byUser[userId] = next;
        return claim;
      });

  @override
  Future<Claim> update({required String userId, required Claim claim}) =>
      _serialize(userId, () async {
        final List<Claim> current = await _load(userId);
        final int index = current.indexWhere((item) => item.id == claim.id);
        if (index < 0) throw const DataFailure('Запис не знайдено');
        final List<Claim> next = [...current]..[index] = claim;
        await _write(userId, next);
        _byUser[userId] = next;
        return claim;
      });

  @override
  Future<void> delete({required String userId, required String claimId}) =>
      _serialize<void>(userId, () async {
        final List<Claim> current = await _load(userId);
        final int index = current.indexWhere((item) => item.id == claimId);
        if (index < 0) throw const DataFailure('Запис не знайдено');
        final List<Claim> next = [...current]..removeAt(index);
        await _write(userId, next);
        _byUser[userId] = next;
      });

  @override
  Future<String> nextNumber({required String userId}) =>
      _serialize(userId, () async {
        final List<Claim> current = await _load(userId);
        final int maxFromFile = current
            .map((claim) => int.tryParse(claim.number.split('-').last) ?? 0)
            .fold(
              0,
              (int previous, int value) => value > previous ? value : previous,
            );
        final int last = _lastIssued[userId] ?? 0;
        final int next = (maxFromFile > last ? maxFromFile : last) + 1;
        _lastIssued[userId] = next;
        return 'ГВ-${DateTime.now().year}-${next.toString().padLeft(3, '0')}';
      });
}
