import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/data/load_status.dart';
import 'package:warranty_and_purchase_manager/core/features/analytics/data/analytics_service.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/data/auth_failure.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/data/auth_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/application/profile_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/data/profile_cache.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/domain/user_profile.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {
  bool failOnPhoto = false;
  String? lastPhotoUrl;

  @override
  Future<void> updatePhotoUrl(String httpsUrl) async {
    if (failOnPhoto) {
      throw const AuthFailure(
        'network-request-failed',
        'Немає з’єднання з інтернетом.',
      );
    }
    lastPhotoUrl = httpsUrl;
  }
}

class _PhotoAnalytics extends Fake implements AnalyticsService {
  int photoEvents = 0;

  @override
  Future<void> logProfilePhotoUpdated() async {
    photoEvents++;
  }
}

void main() {
  final UserProfile cached = UserProfile(
    uid: 'u1',
    email: 'old@example.com',
    photoUrl: 'https://example.com/old.png',
    providers: const ['password'],
  );
  final UserProfile fresh = cached.copyWith(email: 'new@example.com');

  test(
    'спершу показує кеш як offline, потім свіжий профіль і записує кеш',
    () async {
      final cache = InMemoryProfileCache();
      await cache.write(cached);
      final controller = ProfileController(
        _FakeAuthRepository(),
        cache,
        currentProfileReader: () => fresh,
      );
      addTearDown(controller.dispose);
      final List<(String?, bool, LoadStatus)> snapshots = [];
      controller.addListener(() {
        snapshots.add((
          controller.profile?.email,
          controller.isOffline,
          controller.status,
        ));
      });
      controller.bindUser('u1');
      await Future<void>.delayed(Duration.zero);
      expect(snapshots, contains(('old@example.com', true, LoadStatus.ready)));
      expect(snapshots, contains(('new@example.com', false, LoadStatus.ready)));
      expect(controller.profile, fresh);
      expect(controller.isOffline, isFalse);
      expect(await cache.read('u1'), fresh);
    },
  );

  test('updatePhoto оновлює Firebase, профіль і кеш', () async {
    final cache = InMemoryProfileCache();
    final repo = _FakeAuthRepository();
    final analytics = _PhotoAnalytics();
    final controller = ProfileController(
      repo,
      cache,
      currentProfileReader: () => fresh,
      analytics: analytics,
    );
    addTearDown(controller.dispose);
    controller.bindUser('u1');
    await Future<void>.delayed(Duration.zero);
    const String photo = 'https://example.com/new.png';
    expect(await controller.updatePhoto(photo), isTrue);
    expect(repo.lastPhotoUrl, photo);
    expect(controller.profile?.photoUrl, photo);
    expect((await cache.read('u1'))?.photoUrl, photo);
    expect(controller.successMessage, 'Зміни профілю збережено.');
    expect(analytics.photoEvents, 1);
    expect(controller.errorMessage, isNull);
    expect(controller.isSaving, isFalse);
    controller.clearFeedback();
    expect(controller.successMessage, isNull);
  });

  test('AuthFailure показує помилку й не змінює кеш', () async {
    final cache = InMemoryProfileCache();
    await cache.write(cached);
    final repo = _FakeAuthRepository();
    final controller = ProfileController(
      repo,
      cache,
      currentProfileReader: () => fresh,
    );
    addTearDown(controller.dispose);
    controller.bindUser('u1');
    await Future<void>.delayed(Duration.zero);
    repo.failOnPhoto = true;
    expect(
      await controller.updatePhoto('https://example.com/another.png'),
      isFalse,
    );
    expect(controller.errorMessage, 'Немає з’єднання з інтернетом.');
    expect(controller.successMessage, isNull);
    expect(controller.isSaving, isFalse);
    expect((await cache.read('u1'))?.photoUrl, fresh.photoUrl);
  });

  test(
    'коли Firebase недоступний, залишається кеш; вихід очищує стан',
    () async {
      final cache = InMemoryProfileCache();
      await cache.write(cached);
      final controller = ProfileController(
        _FakeAuthRepository(),
        cache,
        currentProfileReader: () => null,
      );
      addTearDown(controller.dispose);
      controller.bindUser('u1');
      await Future<void>.delayed(Duration.zero);
      expect(controller.profile, cached);
      expect(controller.status, LoadStatus.ready);
      expect(controller.isOffline, isTrue);
      controller.bindUser(null);
      expect(controller.profile, isNull);
      expect(controller.status, LoadStatus.initial);
      expect(controller.isOffline, isFalse);
      expect(await cache.read('u1'), cached);
      await cache.clear('u1');
      expect(await cache.read('u1'), isNull);
    },
  );
}
