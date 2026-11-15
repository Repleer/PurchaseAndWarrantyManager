import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/app_preferences.dart';
import '../../../data/data_failure.dart';
import '../../../data/load_status.dart';
import '../data/purchase_repository.dart';
import '../domain/purchase.dart';
import '../domain/purchase_query.dart';

/// Стан покупок, фільтрів і CRUD для поточного користувача.
class PurchasesController extends ChangeNotifier {
  PurchasesController(
    this._repository, {
    DateTime Function()? clock,
    this.preferences,
  }) : _clock = clock ?? DateTime.now;

  final PurchaseRepository _repository;
  final AppPreferences? preferences;
  final DateTime Function() _clock;
  String? _userId;
  List<Purchase> _items = const [];
  bool _disposed = false;
  int _session = 0;
  int _loadRequest = 0;

  LoadStatus status = LoadStatus.initial;
  PurchaseQuery draftQuery = const PurchaseQuery();
  PurchaseQuery appliedQuery = const PurchaseQuery();
  bool isSaving = false;
  String? errorMessage;

  DateTime get now => _clock();
  List<Purchase> get items => _items;
  List<Purchase> get visibleItems => List<Purchase>.unmodifiable(
    applyPurchaseQuery(_items, appliedQuery, _clock()),
  );
  bool get isLoading => status == LoadStatus.loading;

  Purchase? byId(String id) {
    for (final Purchase item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Найближчі три чинні гарантії з терміном до 60 днів.
  List<Purchase> get expiringSoon {
    final DateTime date = _clock();
    final List<Purchase> matching =
        _items
            .where((item) => item.status(date) == WarrantyStatus.expiringSoon)
            .toList()
          ..sort((a, b) => a.daysLeft(date).compareTo(b.daysLeft(date)));
    return List<Purchase>.unmodifiable(matching.take(3));
  }

  /// Три останні покупки незалежно від поточного фільтра.
  List<Purchase> get recent {
    final List<Purchase> sorted = List<Purchase>.of(_items)
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    return List<Purchase>.unmodifiable(sorted.take(3));
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _isCurrent(String userId, int session) =>
      !_disposed && _userId == userId && _session == session;

  /// Прив'язує стан до Firebase uid і завантажує дані нової сесії.
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
    draftQuery = const PurchaseQuery();
    appliedQuery = const PurchaseQuery();
    _restoreFilters(userId);
    isSaving = false;
    errorMessage = null;
    load();
  }

  /// Очищує покупки і фільтри після виходу з акаунта.
  void reset() {
    if (_disposed) return;
    _session++;
    _loadRequest++;
    _userId = null;
    _items = const [];
    status = LoadStatus.initial;
    draftQuery = const PurchaseQuery();
    appliedQuery = const PurchaseQuery();
    isSaving = false;
    errorMessage = null;
    _notify();
  }

  /// Перезавантажує покупки активного користувача.
  Future<void> load() async {
    final String? userId = _userId;
    if (_disposed || userId == null) return;
    final int session = _session;
    final int request = ++_loadRequest;
    status = LoadStatus.loading;
    errorMessage = null;
    _notify();
    try {
      final List<Purchase> loaded = await _repository.fetchAll(userId: userId);
      if (!_isCurrent(userId, session) || request != _loadRequest) return;
      _items = List<Purchase>.unmodifiable(loaded);
      status = LoadStatus.ready;
      errorMessage = null;
    } on DataFailure catch (error) {
      if (!_isCurrent(userId, session) || request != _loadRequest) return;
      status = LoadStatus.failure;
      errorMessage = error.message;
    } catch (_) {
      if (!_isCurrent(userId, session) || request != _loadRequest) return;
      status = LoadStatus.failure;
      errorMessage = 'Не вдалося завантажити дані. Спробуйте ще раз.';
    }
    _notify();
  }

  void updateDraft(PurchaseQuery Function(PurchaseQuery) change) {
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
    draftQuery = const PurchaseQuery();
    appliedQuery = const PurchaseQuery();
    _notify();
    _persistFilters();
  }

  void toggleSort(PurchaseSortField field) {
    if (_disposed) return;
    final bool ascending = appliedQuery.sortField == field
        ? !appliedQuery.ascending
        : false;
    appliedQuery = appliedQuery.copyWith(
      sortField: field,
      ascending: ascending,
    );
    draftQuery = draftQuery.copyWith(sortField: field, ascending: ascending);
    _notify();
    _persistFilters();
  }

  void _restoreFilters(String uid) {
    final Map<String, String>? settings = preferences?.purchasesFilters(uid);
    if (settings == null) return;
    final PurchaseCategory? category = _enumByName(
      PurchaseCategory.values,
      settings['category'],
    );
    final WarrantyStatus? warrantyStatus = _enumByName(
      WarrantyStatus.values,
      settings['status'],
    );
    final PurchaseSortField sortField =
        _enumByName(PurchaseSortField.values, settings['sortField']) ??
        PurchaseSortField.date;
    final PurchaseQuery restored = PurchaseQuery(
      category: category,
      status: warrantyStatus,
      sortField: sortField,
      ascending: settings['ascending'] == 'true',
    );
    draftQuery = restored;
    appliedQuery = restored;
  }

  T? _enumByName<T extends Enum>(Iterable<T> values, String? name) {
    for (final T value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  void _persistFilters() {
    final String? uid = _userId;
    final AppPreferences? prefs = preferences;
    if (_disposed || uid == null || prefs == null) return;
    final PurchaseQuery query = appliedQuery;
    unawaited(
      prefs
          .setPurchasesFilters(uid, {
            'category': query.category?.name ?? '',
            'status': query.status?.name ?? '',
            'sortField': query.sortField.name,
            'ascending': query.ascending.toString(),
          })
          .catchError((Object _) {}),
    );
  }

  Future<bool> add(Purchase purchase) async {
    final String? userId = _userId;
    if (_disposed || userId == null) return _noSession();
    final int session = _session;
    isSaving = true;
    errorMessage = null;
    _notify();
    try {
      final Purchase saved = await _repository.create(
        userId: userId,
        purchase: purchase,
      );
      if (!_isCurrent(userId, session)) return false;
      _items = List<Purchase>.unmodifiable([..._items, saved]);
      isSaving = false;
      status = LoadStatus.ready;
      _notify();
      return true;
    } on DataFailure catch (error) {
      if (!_isCurrent(userId, session)) return false;
      errorMessage = error.message;
    } catch (_) {
      if (!_isCurrent(userId, session)) return false;
      errorMessage = 'Не вдалося зберегти покупку. Спробуйте ще раз.';
    }
    isSaving = false;
    _notify();
    return false;
  }

  Future<bool> update(Purchase purchase) async {
    final String? userId = _userId;
    if (_disposed || userId == null) return _noSession();
    final int session = _session;
    isSaving = true;
    errorMessage = null;
    _notify();
    try {
      final Purchase saved = await _repository.update(
        userId: userId,
        purchase: purchase,
      );
      if (!_isCurrent(userId, session)) return false;
      final List<Purchase> next = List<Purchase>.of(_items);
      final int index = next.indexWhere((item) => item.id == saved.id);
      if (index < 0) {
        errorMessage = 'Запис не знайдено';
        isSaving = false;
        _notify();
        return false;
      }
      next[index] = saved;
      _items = List<Purchase>.unmodifiable(next);
      isSaving = false;
      status = LoadStatus.ready;
      _notify();
      return true;
    } on DataFailure catch (error) {
      if (!_isCurrent(userId, session)) return false;
      errorMessage = error.message;
    } catch (_) {
      if (!_isCurrent(userId, session)) return false;
      errorMessage = 'Не вдалося зберегти покупку. Спробуйте ще раз.';
    }
    isSaving = false;
    _notify();
    return false;
  }

  /// Видаляє оптимістично, а після помилки відновлює той самий індекс.
  Future<bool> remove(String id) async {
    final String? userId = _userId;
    if (_disposed || userId == null) return _noSession();
    final int session = _session;
    final int index = _items.indexWhere((item) => item.id == id);
    final Purchase? removed = index < 0 ? null : _items[index];
    if (removed != null) {
      final List<Purchase> next = List<Purchase>.of(_items)..removeAt(index);
      _items = List<Purchase>.unmodifiable(next);
    }
    errorMessage = null;
    _notify();
    try {
      await _repository.delete(userId: userId, purchaseId: id);
      if (!_isCurrent(userId, session)) return false;
      return true;
    } on DataFailure catch (error) {
      if (!_isCurrent(userId, session)) return false;
      errorMessage = error.message;
    } catch (_) {
      if (!_isCurrent(userId, session)) return false;
      errorMessage = 'Не вдалося видалити покупку. Спробуйте ще раз.';
    }
    if (removed != null && byId(id) == null) {
      final List<Purchase> restored = List<Purchase>.of(_items)
        ..insert(index.clamp(0, _items.length), removed);
      _items = List<Purchase>.unmodifiable(restored);
    }
    _notify();
    return false;
  }

  bool _noSession() {
    if (_disposed) return false;
    errorMessage = 'Немає активного користувача.';
    _notify();
    return false;
  }

  void clearError() {
    if (_disposed) return;
    errorMessage = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _session++;
    _loadRequest++;
    super.dispose();
  }
}
