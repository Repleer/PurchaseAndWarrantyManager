import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/features/analytics/data/analytics_service.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/application/auth_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/data/auth_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/presentation/profile_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/application/profile_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/data/profile_cache.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/domain/user_profile.dart';

class _StubRepository extends Fake implements AuthRepository {
  @override
  User? get currentUser => null;
  String? savedPhoto;
  Completer<void>? pendingPhoto;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> updatePhotoUrl(String httpsUrl) async {
    if (pendingPhoto != null) await pendingPhoto!.future;
    savedPhoto = httpsUrl;
  }
}

class _StubAnalytics extends Fake implements AnalyticsService {
  @override
  Future<void> logPasswordChanged() async {}
}

void main() {
  testWidgets('основні картки відповідають макету, додаткові дії — нижче', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 988));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final AuthController controller = AuthController(
      _StubRepository(),
      _StubAnalytics(),
    );
    addTearDown(controller.dispose);
    final profile = ProfileController(
      _StubRepository(),
      InMemoryProfileCache(),
      currentProfileReader: () => UserProfile(
        uid: 'u1',
        email: 'olena@example.com',
        providers: const ['password'],
      ),
    )..bindUser('u1');
    addTearDown(profile.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: controller),
          ChangeNotifierProvider<ProfileController>.value(value: profile),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    expect(find.text('JPG або PNG для нового фото профілю.'), findsOneWidget);
    expect(find.text('Оновити фото'), findsOneWidget);
    expect(find.text('Щонайменше 8 символів.'), findsOneWidget);
    expect(find.text('Підключити Google'), findsOneWidget);
    expect(find.text('Згенерувати тестову помилку'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Old12345');
    await tester.enterText(find.byType(TextFormField).at(1), 'Secure123');
    await tester.enterText(find.byType(TextFormField).at(2), 'Secure123');
    await tester.tap(find.text('Зберегти'));
    await tester.pumpAndSettle();
    expect(find.text('Зміни профілю збережено.'), findsOneWidget);
  });

  testWidgets(
    'оновлення HTTPS-фото використовує ProfileController та показує успіх',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 988));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _StubRepository();
      final auth = AuthController(repository, _StubAnalytics());
      addTearDown(auth.dispose);
      final profile = ProfileController(
        repository,
        InMemoryProfileCache(),
        currentProfileReader: () => UserProfile(
          uid: 'u1',
          email: 'olena@example.com',
          providers: const ['password'],
        ),
      )..bindUser('u1');
      addTearDown(profile.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(value: auth),
            ChangeNotifierProvider<ProfileController>.value(value: profile),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Оновити фото'));
      await tester.pumpAndSettle();
      expect(find.text('Оновити фото профілю'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).last,
        'https://example.com/avatar.png',
      );
      await tester.tap(find.text('Зберегти').last);
      await tester.pumpAndSettle();
      expect(repository.savedPhoto, 'https://example.com/avatar.png');
      expect(profile.profile?.photoUrl, repository.savedPhoto);
      expect(find.text('Зміни профілю збережено.'), findsOneWidget);
    },
  );

  testWidgets('offline-профіль показує примітку під email', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 988));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _StubRepository();
    final auth = AuthController(repository, _StubAnalytics());
    addTearDown(auth.dispose);
    final cache = InMemoryProfileCache();
    await cache.write(
      UserProfile(
        uid: 'u1',
        email: 'cached@example.com',
        providers: const ['password'],
      ),
    );
    final profile = ProfileController(
      repository,
      cache,
      currentProfileReader: () => null,
    )..bindUser('u1');
    addTearDown(profile.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<ProfileController>.value(value: profile),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('cached@example.com'), findsOneWidget);
    expect(find.text('Показано збережені дані'), findsOneWidget);
  });

  testWidgets('кнопка діалогу блокується під час збереження фото', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 988));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _StubRepository()..pendingPhoto = Completer<void>();
    final auth = AuthController(repository, _StubAnalytics());
    addTearDown(auth.dispose);
    final profile = ProfileController(
      repository,
      InMemoryProfileCache(),
      currentProfileReader: () => UserProfile(
        uid: 'u1',
        email: 'olena@example.com',
        providers: const ['password'],
      ),
    )..bindUser('u1');
    addTearDown(profile.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<ProfileController>.value(value: profile),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Оновити фото'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).last,
      'https://example.com/avatar.png',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Зберегти'));
    await tester.pump();
    expect(profile.isSaving, isTrue);
    final FilledButton button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Зберегти'),
    );
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    repository.pendingPhoto!.complete();
    await tester.pumpAndSettle();
    expect(profile.isSaving, isFalse);
    expect(find.text('Зміни профілю збережено.'), findsOneWidget);
  });
}
