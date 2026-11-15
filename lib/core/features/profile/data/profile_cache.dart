import '../domain/user_profile.dart';

/// Контракт локального кешу профілів за UID.
abstract interface class ProfileCache {
  Future<UserProfile?> read(String uid);

  Future<void> write(UserProfile profile);

  Future<void> clear(String uid);
}

/// Тимчасовий кеш у пам'яті до підключення збереження на пристрої.
class InMemoryProfileCache implements ProfileCache {
  final Map<String, UserProfile> _byUid = {};

  @override
  Future<UserProfile?> read(String uid) async => _byUid[uid];

  @override
  Future<void> write(UserProfile profile) async {
    _byUid[profile.uid] = profile;
  }

  @override
  Future<void> clear(String uid) async {
    _byUid.remove(uid);
  }
}
