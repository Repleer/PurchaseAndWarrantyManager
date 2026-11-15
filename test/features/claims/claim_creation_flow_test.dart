import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/application/claims_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/in_memory_claim_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/warranty_verification_service.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/application/purchases_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/in_memory_purchase_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claim_form_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claim_purchase_picker_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claim_details_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claims_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/domain/claim.dart';
import 'package:warranty_and_purchase_manager/core/routes/app_router.dart';
import 'package:warranty_and_purchase_manager/core/routes/app_routes.dart';

void main() {
  Future<ClaimsController> start(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 988));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final purchases = PurchasesController(
      InMemoryPurchaseRepository(latency: Duration.zero),
    )..bindUser('u1');
    addTearDown(purchases.dispose);
    final verification = MockWarrantyVerificationService(
      latency: Duration.zero,
    );
    final claims = ClaimsController(
      InMemoryClaimRepository(latency: Duration.zero),
      verification,
    )..bindUser('u1');
    addTearDown(claims.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PurchasesController>.value(value: purchases),
          ChangeNotifierProvider<ClaimsController>.value(value: claims),
          Provider<WarrantyVerificationService>.value(value: verification),
        ],
        child: MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const ClaimsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return claims;
  }

  testWidgets(
    'вибір покупки → перевірка гарантії → Claim через Navigator.pop',
    (tester) async {
      final claims = await start(tester);
      await tester.tap(find.text('Нове звернення'));
      await tester.pumpAndSettle();
      expect(find.byType(ClaimPurchasePickerScreen), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Sony');
      await tester.tap(find.text('Фільтрувати'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Гарантія завершилась'), findsOneWidget);
      final TextButton disabled = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Обрати'),
          matching: find.byType(TextButton),
        ),
      );
      expect(disabled.onPressed, isNull);

      await tester.enterText(find.byType(TextFormField).first, 'Roborock');
      await tester.tap(find.text('Фільтрувати'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Обрати'));
      await tester.pumpAndSettle();
      expect(find.text('✓ Обрано'), findsOneWidget);
      await tester.tap(find.text('Продовжити'));
      await tester.pumpAndSettle();
      expect(find.byType(ClaimFormScreen), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).last,
        'Не повертається на зарядну станцію після прибирання.',
      );
      await tester.tap(find.text('Галерея / файл'));
      await tester.tap(find.text('Галерея / файл'));
      await tester.pumpAndSettle();
      expect(find.text('Додано 2 файли'), findsOneWidget);
      await tester.tap(find.text('Надіслати звернення'));
      await tester.pumpAndSettle();
      expect(find.text('Перевірка автентичності гарантії'), findsOneWidget);
      expect(find.text('✓ Гарантію підтверджено'), findsOneWidget);
      await tester.tap(find.text('Продовжити'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Надіслати звернення'));
      await tester.pumpAndSettle();
      expect(find.byType(ClaimDetailsScreen), findsOneWidget);
      expect(find.text('Звернення успішно надіслано'), findsOneWidget);
      expect(claims.totalCount, 6);
      expect(claims.items.last.number, 'ГВ-${DateTime.now().year}-011');
    },
  );

  testWidgets('невдалу перевірку можна повторити після зміни номера', (
    tester,
  ) async {
    await start(tester);
    final BuildContext context = tester.element(find.byType(ClaimsScreen));
    Navigator.of(context)
        .pushNamed<Claim>(AppRoutes.claimCreate, arguments: 'p3');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'НЕВІРНИЙ');
    await tester.tap(find.text('Перевірити гарантію'));
    await tester.pumpAndSettle();
    expect(find.text('ⓘ Не вдалося підтвердити гарантію'), findsOneWidget);
    await tester.tap(find.text('Перевірити ще раз'));
    await tester.pumpAndSettle();
    expect(find.text('ⓘ Не вдалося підтвердити гарантію'), findsOneWidget);
    await tester.tap(find.byTooltip('Закрити'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'RR-Q8-260926');
    await tester.tap(find.text('Перевірити гарантію'));
    await tester.pumpAndSettle();
    expect(find.text('✓ Гарантію підтверджено'), findsOneWidget);
  });

  testWidgets(
    'список у селекторі змінює покупку, серійний номер і скидає перевірку',
    (tester) async {
      await start(tester);
      final BuildContext context = tester.element(find.byType(ClaimsScreen));
      Navigator.of(context)
          .pushNamed<Claim>(AppRoutes.claimCreate, arguments: 'p3');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Перевірити гарантію'));
      await tester.pumpAndSettle();
      expect(find.text('✓ Гарантію підтверджено'), findsOneWidget);
      await tester.tap(find.byTooltip('Закрити'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Оберіть покупку'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.textContaining('Apple Magic Keyboard · iSpace').last,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Apple Magic Keyboard · iSpace'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller
            ?.text,
        'MK-260914-01',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Клавіша пробілу спрацьовує через раз.',
      );
      await tester.tap(find.text('Надіслати звернення'));
      await tester.pumpAndSettle();
      expect(find.text('Перевірка автентичності гарантії'), findsOneWidget);
    },
  );

  testWidgets(
    'редагування незміненого номера зберігає звернення без повторної перевірки',
    (tester) async {
      await start(tester);
      final BuildContext context = tester.element(find.byType(ClaimsScreen));
      Navigator.of(context).pushNamed(AppRoutes.claimDetails, arguments: 'c1');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Змінити'));
      await tester.pumpAndSettle();
      expect(find.byType(ClaimFormScreen), findsOneWidget);
      await tester.tap(find.text('Зберегти зміни'));
      await tester.pumpAndSettle();
      expect(find.byType(ClaimDetailsScreen), findsOneWidget);
      expect(find.text('Зміни збережено'), findsOneWidget);
    },
  );

  testWidgets('діалог показує індикатор під час асинхронної перевірки', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 988));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final purchases = PurchasesController(
      InMemoryPurchaseRepository(latency: Duration.zero),
    )..bindUser('u1');
    addTearDown(purchases.dispose);
    final verification = MockWarrantyVerificationService(
      latency: const Duration(seconds: 2),
    );
    final claims = ClaimsController(
      InMemoryClaimRepository(latency: Duration.zero),
      verification,
    )..bindUser('u1');
    addTearDown(claims.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PurchasesController>.value(value: purchases),
          ChangeNotifierProvider<ClaimsController>.value(value: claims),
          Provider<WarrantyVerificationService>.value(value: verification),
        ],
        child: MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const ClaimsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final BuildContext context = tester.element(find.byType(ClaimsScreen));
    Navigator.of(context)
        .pushNamed<Claim>(AppRoutes.claimCreate, arguments: 'p3');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Перевірити гарантію'));
    await tester.pump();
    expect(find.text('Перевіряємо гарантію…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('✓ Гарантію підтверджено'), findsOneWidget);
  });
}
