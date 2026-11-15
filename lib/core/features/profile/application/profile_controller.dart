import 'package:flutter/foundation.dart';

import '../../../data/load_status.dart';
import '../../analytics/data/analytics_service.dart';
import '../../auth/data/auth_failure.dart';
import '../../auth/data/auth_repository.dart';
import '../data/profile_cache.dart';
import '../data/user_profile_mapper.dart';
import '../domain/user_profile.dart';

/// Стан профілю з миттєвим показом кешу та оновленням із Firebase.
class ProfileController extends ChangeNotifier {
  ProfileController(
    this._repository,
    this._cache, {
    UserProfile? Function()? currentProfileReader,
    this.analytics,
  }) : _reader =
           currentProfileReader ??
           (() {
             final user = _repository.currentUser;
             return user == null ? null : fromFirebaseUser(user);
           });

  final AuthRepository _repository;
  final ProfileCache _cache;
  final UserProfile? Function() _reader;
  final AnalyticsService? analytics;
  String? _uid;
  int _generation = 0;
  bool _disposed = false;

  LoadStatus status = LoadStatus.initial;
  UserProfile? profile;
  bool isOffline = false;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _isCurrent(String uid, int generation) =>
      !_disposed && _uid == uid && _generation == generation;

  /// Прив'язує профіль до сесії або очищує стан після виходу.
  void bindUser(String? uid) {
    if (_disposed) return;
    if (uid == null) {
      reset();
      return;
    }
    if (_uid == uid) return;
    _uid = uid;
    _generation++;
    profile = null;
    isOffline = false;
    isSaving = false;
    errorMessage = null;
    successMessage = null;
    load();
  }

  void reset() {
    if (_disposed) return;
    _uid = null;
    _generation++;
    status = LoadStatus.initial;
    profile = null;
    isOffline = false;
    isSaving = false;
    errorMessage = null;
    successMessage = null;
    _notify();
  }

  /// Спершу віддає кеш, після цього актуальну версію Firebase.
  Future<void> load() async {
    final String? uid = _uid;
    if (_disposed || uid == null) return;
    final int generation = ++_generation;
    status = LoadStatus.loading;
    errorMessage = null;
    _notify();

    try {
      final UserProfile? cached = await _cache.read(uid);
      if (!_isCurrent(uid, generation)) return;
      if (cached != null) {
        profile = cached;
        isOffline = true;
        status = LoadStatus.ready;
        _notify();
      }
    } catch (_) {
      if (!_isCurrent(uid, generation)) return;
      // Кеш не повинен блокувати читання профілю з Firebase.
    }

    try {
      final UserProfile? fresh = _reader();
      if (!_isCurrent(uid, generation)) return;
      if (fresh == null || fresh.uid != uid) {
        if (profile == null) {
          status = LoadStatus.failure;
          errorMessage = 'Не вдалося завантажити профіль. Спробуйте ще раз.';
          _notify();
        }
        return;
      }
      profile = fresh;
      isOffline = false;
      status = LoadStatus.ready;
      errorMessage = null;
      _notify();
      await _cache.write(fresh);
      if (!_isCurrent(uid, generation)) return;
    } on AuthFailure catch (error) {
      if (!_isCurrent(uid, generation)) return;
      status = profile == null ? LoadStatus.failure : LoadStatus.ready;
      errorMessage = error.message;
      _notify();
    } catch (_) {
      if (!_isCurrent(uid, generation)) return;
      status = profile == null ? LoadStatus.failure : LoadStatus.ready;
      errorMessage = 'Не вдалося завантажити профіль. Спробуйте ще раз.';
      _notify();
    }
  }

  /// Оновлює HTTPS-фото через AuthRepository та відразу кешує профіль.
  Future<bool> updatePhoto(String httpsUrl) async {
    final String? uid = _uid;
    if (_disposed || uid == null) {
      if (!_disposed) {
        errorMessage = 'Немає активного користувача.';
        _notify();
      }
      return false;
    }
    final int generation = _generation;
    isSaving = true;
    errorMessage = null;
    successMessage = null;
    _notify();
    try {
      await _repository.updatePhotoUrl(httpsUrl);
      if (!_isCurrent(uid, generation)) return false;
      final UserProfile? updated = (_reader() ?? profile)?.copyWith(
        photoUrl: httpsUrl,
      );
      if (updated == null || updated.uid != uid) {
        errorMessage = 'Не вдалося оновити профіль.';
        isSaving = false;
        _notify();
        return false;
      }
      profile = updated;
      isOffline = false;
      await _cache.write(updated);
      if (!_isCurrent(uid, generation)) return false;
      final AnalyticsService? analyticsService = analytics;
      if (analyticsService != null) {
        try {
          await analyticsService.logProfilePhotoUpdated();
        } catch (_) {
          // Помилка телеметрії не скасовує успішне оновлення фото.
        }
        if (!_isCurrent(uid, generation)) return false;
      }
      isSaving = false;
      successMessage = 'Зміни профілю збережено.';
      _notify();
      return true;
    } on AuthFailure catch (error) {
      if (!_isCurrent(uid, generation)) return false;
      errorMessage = error.message;
    } catch (_) {
      if (!_isCurrent(uid, generation)) return false;
      errorMessage = 'Не вдалося оновити фото. Спробуйте ще раз.';
    }
    isSaving = false;
    _notify();
    return false;
  }

  void clearFeedback() {
    if (_disposed) return;
    errorMessage = null;
    successMessage = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
