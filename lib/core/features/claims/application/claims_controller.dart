import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../data/app_preferences.dart';
import '../../../data/data_failure.dart';
import '../../../data/load_status.dart';
import '../../purchases/domain/purchase.dart';
import '../data/claim_repository.dart';
import '../data/warranty_verification_service.dart';
import '../domain/claim.dart';
import '../domain/claim_query.dart';

/// Стан звернень, фільтрів і змін для активного користувача.
class ClaimsController extends ChangeNotifier {
  ClaimsController(
    this._repository,
    this.verificationService, {
    DateTime Function()? clock,
    this.preferences,
  }) : _clock = clock ?? DateTime.now;

  final ClaimRepository _repository;
  final WarrantyVerificationService verificationService;
  final AppPreferences? preferences;
  final DateTime Function() _clock;
  String? _userId;
  List<Claim> _items = const [];
  int _session = 0;
  int _loadRequest = 0;
  bool _disposed = false;

  String? get userId => _userId;
  LoadStatus status = LoadStatus.initial;
  ClaimQuery draftQuery = const ClaimQuery();
  ClaimQuery appliedQuery = const ClaimQuery();
  bool isSaving = false;
  String? errorMessage;

  int get totalCount => _items.length;
  List<Claim> get items => _items;

  List<Claim> visibleItems(Map<String, Purchase> purchasesById) =>
      List<Claim>.unmodifiable(
        applyClaimQuery(_items, purchasesById, appliedQuery),
      );

  Claim? byId(String id) {
    for (final Claim claim in _items) {
      if (claim.id == id) return claim;
    }
    return null;
  }

  /// Звернення за покупкою в порядку від найновішого.
  List<Claim> forPurchase(String purchaseId) {
    final List<Claim> claims =
        _items.where((claim) => claim.purchaseId == purchaseId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<Claim>.unmodifiable(claims);
  }

  Claim? latestForPurchase(String purchaseId) {
    final List<Claim> related = forPurchase(purchaseId);
    return related.isEmpty ? null : related.first;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _isCurrent(String uid, int session) =>
      !_disposed && _userId == uid && _session == session;

  void bindUser(String? userId) {
    if (_disposed) return;
    if (userId == null) {
      reset();
      return;
    }
    if (_userId == userId) return;
    _userId = userId;
    _session++;
    _loadRequest++;
    _items = const [];
    draftQuery = const ClaimQuery();
    appliedQuery = const ClaimQuery();
    _restoreFilters(userId);
    isSaving = false;
    errorMessage = null;
    load();
  }

  void reset() {
    if (_disposed) return;
    _userId = null;
    _session++;
    _loadRequest++;
    _items = const [];
    status = LoadStatus.initial;
    draftQuery = const ClaimQuery();
    appliedQuery = const ClaimQuery();
    isSaving = false;
    errorMessage = null;
    _notify();
  }

  Future<void> load() async {
    final String? uid = _userId;
    if (_disposed || uid == null) return;
    final int session = _session;
    final int request = ++_loadRequest;
    status = LoadStatus.loading;
    errorMessage = null;
    _notify();
    try {
      final List<Claim> loaded = await _repository.fetchAll(userId: uid);
      if (!_isCurrent(uid, session) || request != _loadRequest) return;
      _items = List<Claim>.unmodifiable(loaded);
      status = LoadStatus.ready;
      errorMessage = null;
    } on DataFailure catch (error) {
      if (!_isCurrent(uid, session) || request != _loadRequest) return;
      status = LoadStatus.failure;
      errorMessage = error.message;
    } catch (_) {
      if (!_isCurrent(uid, session) || request != _loadRequest) return;
      status = LoadStatus.failure;
      errorMessage = 'Не вдалося завантажити дані. Спробуйте ще раз.';
    }
    _notify();
  }

  void updateDraft(ClaimQuery Function(ClaimQuery) change) {
    if (_disposed) return;
    draftQuery = change(draftQuery);
    _notify();
  }

  void applyFilters() {
    if (_disposed) return;
    appliedQuery = draftQuery;
    _notify();
    _persistFilters();
  }

  void resetFilters() {
    if (_disposed) return;
    draftQuery = const ClaimQuery();
    appliedQuery = const ClaimQuery();
    _notify();
    _persistFilters();
  }

  void toggleDateSort() {
    if (_disposed) return;
    appliedQuery = appliedQuery.copyWith(
      newestFirst: !appliedQuery.newestFirst,
    );
    draftQuery = draftQuery.copyWith(newestFirst: appliedQuery.newestFirst);
    _notify();
    _persistFilters();
  }

  void _restoreFilters(String uid) {
    final String? raw = preferences?.claimsStatusFilter(uid);
    if (raw == null) return;
    String? statusName;
    bool newestFirst = true;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map) {
        final Object? statusValue = decoded['status'];
        if (statusValue is String) statusName = statusValue;
        newestFirst =
            decoded['newestFirst'] != false &&
            decoded['newestFirst'] != 'false';
      } else if (decoded is String) {
        statusName = decoded;
      }
    } catch (_) {
      statusName = raw;
    }
    ClaimStatus? filter;
    for (final ClaimStatus status in ClaimStatus.values) {
      if (status.name == statusName) {
        filter = status;
        break;
      }
    }
    final ClaimQuery restored = ClaimQuery(
      status: filter,
      newestFirst: newestFirst,
    );
    draftQuery = restored;
    appliedQuery = restored;
  }

  void _persistFilters() {
    final String? uid = _userId;
    final AppPreferences? prefs = preferences;
    if (_disposed || uid == null || prefs == null) return;
    final ClaimQuery query = appliedQuery;
    unawaited(
      prefs
          .setClaimsStatusFilter(
            uid,
            jsonEncode({
              'status': query.status?.name ?? '',
              'newestFirst': query.newestFirst,
            }),
          )
          .catchError((Object _) {}),
    );
  }

  /// Присвоює наступний номер і повертає створене звернення.
  Future<Claim?> submit(Claim draft) async {
    final String? uid = _userId;
    if (_disposed || uid == null) {
      _noSession();
      return null;
    }
    final int session = _session;
    isSaving = true;
    errorMessage = null;
    _notify();
    try {
      final String number = await _repository.nextNumber(userId: uid);
      if (!_isCurrent(uid, session)) return null;
      final Claim created = await _repository.create(
        userId: uid,
        claim: draft.copyWith(number: number),
      );
      if (!_isCurrent(uid, session)) return null;
      _items = List<Claim>.unmodifiable([..._items, created]);
      status = LoadStatus.ready;
      isSaving = false;
      _notify();
      return created;
    } on DataFailure catch (error) {
      if (!_isCurrent(uid, session)) return null;
      errorMessage = error.message;
    } catch (_) {
      if (!_isCurrent(uid, session)) return null;
      errorMessage = 'Не вдалося надіслати звернення. Спробуйте ще раз.';
    }
    isSaving = false;
    _notify();
    return null;
  }

  /// Оновлює звернення та додає подію до історії.
  Future<bool> update(Claim claim) async {
    final String? uid = _userId;
    if (_disposed || uid == null) return _noSession();
    final int session = _session;
    isSaving = true;
    errorMessage = null;
    _notify();
    try {
      final DateTime now = _clock();
      final Claim saved = await _repository.update(
        userId: uid,
        claim: claim.copyWith(
          updatedAt: now,
          history: [
            ...claim.history,
            ClaimHistoryEntry(
              title: 'Звернення оновлено',
              at: now,
              note: 'Дані звернення змінено.',
              done: true,
            ),
          ],
        ),
      );
      if (!_isCurrent(uid, session)) return false;
      final List<Claim> next = List<Claim>.of(_items);
      final int index = next.indexWhere((item) => item.id == saved.id);
      if (index < 0) {
        isSaving = false;
        errorMessage = 'Запис не знайдено';
        _notify();
        return false;
      }
      next[index] = saved;
      _items = List<Claim>.unmodifiable(next);
      status = LoadStatus.ready;
      isSaving = false;
      _notify();
      return true;
    } on DataFailure catch (error) {
      if (!_isCurrent(uid, session)) return false;
      errorMessage = error.message;
    } catch (_) {
      if (!_isCurrent(uid, session)) return false;
      errorMessage = 'Не вдалося зберегти звернення. Спробуйте ще раз.';
    }
    isSaving = false;
    _notify();
    return false;
  }

  /// Видаляє оптимістично й відновлює на тому самому місці при помилці.
  Future<bool> withdraw(String id) async {
    final String? uid = _userId;
    if (_disposed || uid == null) return _noSession();
    final int session = _session;
    final int index = _items.indexWhere((item) => item.id == id);
    final Claim? removed = index < 0 ? null : _items[index];
    if (removed != null) {
      final List<Claim> next = List<Claim>.of(_items)..removeAt(index);
      _items = List<Claim>.unmodifiable(next);
    }
    errorMessage = null;
    _notify();
    try {
      await _repository.delete(userId: uid, claimId: id);
      if (!_isCurrent(uid, session)) return false;
      return true;
    } on DataFailure catch (error) {
      if (!_isCurrent(uid, session)) return false;
      errorMessage = error.message;
    } catch (_) {
      if (!_isCurrent(uid, session)) return false;
      errorMessage = 'Не вдалося відкликати звернення. Спробуйте ще раз.';
    }
    if (removed != null && byId(id) == null) {
      final List<Claim> next = List<Claim>.of(_items)
        ..insert(index.clamp(0, _items.length), removed);
      _items = List<Claim>.unmodifiable(next);
    }
    _notify();
    return false;
  }

  /// Видаляє всі звернення покупки після її видалення.
  Future<void> removeForPurchase(String purchaseId) async {
    for (final Claim claim in forPurchase(purchaseId)) {
      if (!await withdraw(claim.id)) {
        throw DataFailure(errorMessage ?? 'Не вдалося видалити звернення.');
      }
    }
  }

  void clearError() {
    if (_disposed) return;
    errorMessage = null;
    _notify();
  }

  bool _noSession() {
    if (_disposed) return false;
    errorMessage = 'Немає активного користувача.';
    _notify();
    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    _session++;
    _loadRequest++;
    super.dispose();
  }
}
