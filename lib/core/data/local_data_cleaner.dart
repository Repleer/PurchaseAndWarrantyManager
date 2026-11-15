import 'app_preferences.dart';
import 'json_file_store.dart';

/// Явно видаляє налаштування та JSON-файли одного користувача.
class LocalDataCleaner {
  const LocalDataCleaner(this._preferences, this._store);

  final AppPreferences _preferences;
  final JsonFileStore _store;

  Future<void> clear(String uid) async {
    await _preferences.clearUser(uid);
    await _store.deleteDir('users/$uid');
  }
}
