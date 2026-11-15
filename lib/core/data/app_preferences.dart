import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Невеликі налаштування користувача, ізольовані за UID.
class AppPreferences {
  AppPreferences(this._prefs);

  static Future<AppPreferences> create() async =>
      AppPreferences(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const String _prefix = 'wpm.';
  static const String _lastEmailKey = '${_prefix}last_email';

  String _userKey(String uid, String suffix) => '$_prefix$uid.$suffix';

  String? _readString(String key) {
    try {
      return _prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  String? get lastEmail => _readString(_lastEmailKey);

  Future<void> setLastEmail(String? value) async {
    if (value == null) {
      await _prefs.remove(_lastEmailKey);
    } else {
      await _prefs.setString(_lastEmailKey, value);
    }
  }

  /// Відновлює категорію, статус і порядок таблиці з JSON-рядка.
  Map<String, String>? purchasesFilters(String uid) {
    final String? raw = _readString(_userKey(uid, 'purchases_filters'));
    if (raw == null) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final Map<String, String> result = {};
      for (final MapEntry<dynamic, dynamic> entry in decoded.entries) {
        if (entry.key is! String || entry.value is! String) return null;
        result[entry.key as String] = entry.value as String;
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> setPurchasesFilters(
    String uid,
    Map<String, String> value,
  ) async {
    await _prefs.setString(
      _userKey(uid, 'purchases_filters'),
      jsonEncode(value),
    );
  }

  String? claimsStatusFilter(String uid) =>
      _readString(_userKey(uid, 'claims_filters'));

  Future<void> setClaimsStatusFilter(String uid, String? value) async {
    final String key = _userKey(uid, 'claims_filters');
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }

  String? profileJson(String uid) => _readString(_userKey(uid, 'profile'));

  Future<void> setProfileJson(String uid, String? json) async {
    final String key = _userKey(uid, 'profile');
    if (json == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, json);
    }
  }

  /// Прибирає ключі лише вказаного UID, не зачіпаючи останній email.
  Future<void> clearUser(String uid) async {
    final String prefix = '$_prefix$uid.';
    final List<String> keys = _prefs
        .getKeys()
        .where((key) => key.startsWith(prefix))
        .toList();
    for (final String key in keys) {
      await _prefs.remove(key);
    }
  }
}
