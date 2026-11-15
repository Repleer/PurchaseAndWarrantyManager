import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/data/user_profile_mapper.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/domain/user_profile.dart';

class _StubUser extends Fake implements User {
  @override
  String get uid => 'u42';

  @override
  String? get email => 'olena@example.com';

  @override
  String? get displayName => 'Олена';

  @override
  String? get photoURL => null;

  @override
  UserMetadata get metadata => _StubMetadata();

  @override
  List<UserInfo> get providerData => [_StubUserInfo()];
}

class _StubMetadata extends Fake implements UserMetadata {
  @override
  DateTime? get creationTime => DateTime.utc(2024, 10, 18);
}

class _StubUserInfo extends Fake implements UserInfo {
  @override
  String get providerId => 'password';
}

void main() {
  test('JSON round-trip зберігає всі поля та порядок провайдерів', () {
    final UserProfile profile = UserProfile(
      uid: 'u1',
      email: 'olena@example.com',
      displayName: 'Олена',
      photoUrl: 'https://example.com/avatar.jpg',
      createdAt: DateTime.utc(2024, 10, 18, 14, 32),
      providers: ['password', 'google.com'],
    );
    final UserProfile restored = UserProfile.fromJson(
      jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>,
    );
    expect(restored, profile);
    expect(restored.hashCode, profile.hashCode);
    expect(profile.toJson()['createdAt'], '2024-10-18T14:32:00.000Z');
  });

  test('списки захищені; copyWith дозволяє очистити необовʼязкові поля', () {
    final List<String> source = ['password'];
    final UserProfile profile = UserProfile(
      uid: 'u1',
      email: 'user@example.com',
      providers: source,
      photoUrl: 'https://example.com/avatar.jpg',
    );
    source.clear();
    expect(profile.providers, ['password']);
    expect(() => profile.providers.add('google.com'), throwsUnsupportedError);
    final UserProfile cleared = profile.copyWith(
      photoUrl: null,
      displayName: null,
    );
    expect(cleared.photoUrl, isNull);
    expect(cleared, isNot(profile));
    expect(
      UserProfile.fromJson(
        jsonDecode(jsonEncode(cleared.toJson())) as Map<String, dynamic>,
      ),
      cleared,
    );
  });

  test('мапер переносить основні дані Firebase у доменну модель', () {
    final UserProfile profile = fromFirebaseUser(_StubUser());
    expect(profile.uid, 'u42');
    expect(profile.email, 'olena@example.com');
    expect(profile.displayName, 'Олена');
    expect(profile.createdAt, DateTime.utc(2024, 10, 18));
    expect(profile.providers, ['password']);
  });
}
