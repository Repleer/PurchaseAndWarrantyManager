import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/data/load_status.dart';
import 'package:warranty_and_purchase_manager/core/features/analytics/data/analytics_service.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/application/auth_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/data/auth_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/auth_gate.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/application/purchases_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/in_memory_purchase_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/application/claims_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/in_memory_claim_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/warranty_verification_service.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/application/profile_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/data/profile_cache.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/domain/user_profile.dart';
import 'package:warranty_and_purchase_manager/core/routes/app_routes.dart';

class _SessionUser extends Fake implements User {
  @override
  String get uid => 'u1';
}

class _SessionRepository extends Fake implements AuthRepository {
  final StreamController<User?> changes = StreamController<User?>.broadcast();

  @override
  Stream<User?> authStateChanges() => changes.stream;
}

class _SessionAnalytics extends Fake implements AnalyticsService {
  @override
  Future<void> setAuthState({required String? userId}) async {}
}

void main() {
  testWidgets('AuthGate привʼязує покупки до uid і очищує їх після виходу', (
    tester,
  ) async {
    final session = _SessionRepository();
    addTearDown(session.changes.close);
    final auth = AuthController(session, _SessionAnalytics());
    addTearDown(auth.dispose);
    final purchases = PurchasesController(
      InMemoryPurchaseRepository(latency: Duration.zero),
    );
    addTearDown(purchases.dispose);
    final claims = ClaimsController(
      InMemoryClaimRepository(latency: Duration.zero),
      MockWarrantyVerificationService(latency: Duration.zero),
    );
    addTearDown(claims.dispose);
    final profile = ProfileController(
      session,
      InMemoryProfileCache(),
      currentProfileReader: () => UserProfile(
        uid: 'u1',
        email: 'user@example.com',
        providers: const ['password'],
      ),
    );
    addTearDown(profile.dispose);
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<PurchasesController>.value(value: purchases),
          ChangeNotifierProvider<ClaimsController>.value(value: claims),
          ChangeNotifierProvider<ProfileController>.value(value: profile),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          initialRoute: AppRoutes.login,
          onGenerateRoute: (settings) => PageRouteBuilder<void>(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) =>
                Scaffold(body: Center(child: Text(settings.name ?? ''))),
          ),
          builder: (context, child) => AuthGate(
            navigatorKey: navigatorKey,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );

    session.changes.add(_SessionUser());
    await tester.pumpAndSettle();
    expect(purchases.status, LoadStatus.ready);
    expect(purchases.byId('p1'), isNotNull);
    expect(claims.status, LoadStatus.ready);
    expect(claims.byId('c1'), isNotNull);
    expect(profile.profile?.email, 'user@example.com');
    expect(find.text(AppRoutes.home), findsOneWidget);

    session.changes.add(null);
    await tester.pumpAndSettle();
    expect(purchases.status, LoadStatus.initial);
    expect(purchases.items, isEmpty);
    expect(claims.status, LoadStatus.initial);
    expect(claims.items, isEmpty);
    expect(profile.profile, isNull);
    expect(find.text(AppRoutes.login), findsOneWidget);
  });
}
