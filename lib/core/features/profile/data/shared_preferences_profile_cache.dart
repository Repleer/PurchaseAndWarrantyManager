import 'dart:convert';

import '../../../data/app_preferences.dart';
import '../domain/user_profile.dart';
import 'profile_cache.dart';

/// Кеш профілю у SharedPreferences через JSON-модель.
class SharedPreferencesProfileCache implements ProfileCache {
  const SharedPreferencesProfileCache(this._preferences);

  final AppPreferences _preferences;

  @override
  Future<UserProfile?> read(String uid) async {
    final String? raw = _preferences.profileJson(uid);
    if (raw == null) return null;
    try {
      final Object? json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final UserProfile profile = UserProfile.fromJson(json);
      return profile.uid == uid ? profile : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(UserProfile profile) =>
      _preferences.setProfileJson(profile.uid, jsonEncode(profile.toJson()));

  @override
  Future<void> clear(String uid) => _preferences.setProfileJson(uid, null);
}
