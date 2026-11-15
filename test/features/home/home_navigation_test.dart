import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/features/analytics/data/analytics_service.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/application/auth_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/data/auth_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/home/presentation/home_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/home/presentation/widgets/expiring_warranty_card.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/presentation/profile_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/presentation/purchase_details_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/presentation/purchase_form_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/presentation/purchases_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/application/purchases_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/in_memory_purchase_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/application/claims_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/in_memory_claim_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/warranty_verification_service.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/application/profile_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/data/profile_cache.dart';
import 'package:warranty_and_purchase_manager/core/routes/app_router.dart';

class _StubRepository extends Fake implements AuthRepository {
  @override
  User? get currentUser => null;
}

class _StubAnalytics extends Fake implements AnalyticsService {}

void main() {
  Future<void> start(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 988));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final purchases = PurchasesController(
      InMemoryPurchaseRepository(latency: Duration.zero),
      clock: () => DateTime(2026, 10, 1),
    )..bindUser('u1');
    addTearDown(purchases.dispose);
    final claims = ClaimsController(
      InMemoryClaimRepository(latency: Duration.zero),
      MockWarrantyVerificationService(latency: Duration.zero),
    )..bindUser('u1');
    addTearDown(claims.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PurchasesController>.value(value: purchases),
          ChangeNotifierProvider<ClaimsController>.value(value: claims),
        ],
        child: MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('картка гарантії відкриває деталі конкретної покупки', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.byType(ExpiringWarrantyCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(PurchaseDetailsScreen), findsOneWidget);
    expect(find.text('Навушники Sony WH-1000XM5'), findsWidgets);
  });

  testWidgets('останні чеки ведуть у деталі відповідного товару', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Деталі').first);
    await tester.pumpAndSettle();
    expect(find.byType(PurchaseDetailsScreen), findsOneWidget);
    expect(find.text('Письмовий стіл IKEA MICKE'), findsWidgets);
  });

  testWidgets('швидкі дії відкривають форму та список покупок', (tester) async {
    await start(tester);
    await tester.tap(find.text('Створити'));
    await tester.pumpAndSettle();
    expect(find.byType(PurchaseFormScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(PurchaseFormScreen))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Відкрити'));
    await tester.pumpAndSettle();
    expect(find.byType(PurchasesScreen), findsOneWidget);
  });

  testWidgets('швидка дія «Профіль» відкриває профіль ЛР4', (tester) async {
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
      currentProfileReader: () => null,
    );
    addTearDown(profile.dispose);
    final purchases = PurchasesController(
      InMemoryPurchaseRepository(latency: Duration.zero),
      clock: () => DateTime(2026, 10, 1),
    )..bindUser('u1');
    addTearDown(purchases.dispose);
    final claims = ClaimsController(
      InMemoryClaimRepository(latency: Duration.zero),
      MockWarrantyVerificationService(latency: Duration.zero),
    )..bindUser('u1');
    addTearDown(claims.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: controller),
          ChangeNotifierProvider<ProfileController>.value(value: profile),
          ChangeNotifierProvider<PurchasesController>.value(value: purchases),
          ChangeNotifierProvider<ClaimsController>.value(value: claims),
        ],
        child: MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Переглянути'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}
