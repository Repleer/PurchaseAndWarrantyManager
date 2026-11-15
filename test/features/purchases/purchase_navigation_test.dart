import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/application/purchases_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/in_memory_purchase_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/application/claims_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/in_memory_claim_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/warranty_verification_service.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/presentation/purchases_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claim_details_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claim_form_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/purchases_mock_data.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/domain/purchase.dart';
import 'package:warranty_and_purchase_manager/core/routes/app_router.dart';
import 'package:warranty_and_purchase_manager/core/routes/app_routes.dart';

void main() {
  Future<PurchasesController> start(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 988));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = PurchasesController(
      InMemoryPurchaseRepository(latency: Duration.zero),
      clock: () => DateTime(2026, 11, 15),
    )..bindUser('u1');
    addTearDown(controller.dispose);
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
          ChangeNotifierProvider<PurchasesController>.value(value: controller),
          ChangeNotifierProvider<ClaimsController>.value(value: claims),
          Provider<WarrantyVerificationService>.value(value: verification),
        ],
        child: MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const PurchasesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('форма створення перевіряє поля й повертає Purchase списку', (
    tester,
  ) async {
    final controller = await start(tester);
    await tester.tap(find.text('Створити запис'));
    await tester.pumpAndSettle();
    expect(find.text('Дані покупки'), findsOneWidget);
    await tester.tap(find.text('Зберегти'));
    await tester.pumpAndSettle();
    expect(find.text('Заповніть це поле.'), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).at(0), 'Тестовий товар');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Тестовий магазин',
    );
    await tester.enterText(find.byType(TextFormField).at(3), '1200');
    await tester.tap(find.text('Галерея / файл').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('receipt_тестовий_магазин_'), findsOneWidget);
    await tester.tap(find.text('Зберегти'));
    await tester.pumpAndSettle();
    expect(find.text('Покупку додано'), findsOneWidget);
    expect(
      controller.items.any((item) => item.productName == 'Тестовий товар'),
      isTrue,
    );
  });

  testWidgets('деталі з мок-даних показують звернення й відкривають зум', (
    tester,
  ) async {
    await start(tester);
    final BuildContext context = tester.element(find.byType(PurchasesScreen));
    Navigator.of(context).pushNamed(AppRoutes.purchaseDetails, arguments: 'p1');
    await tester.pumpAndSettle();

    expect(find.text('Звернення по цьому товару'), findsOneWidget);
    expect(find.text('Гарантія завершується 18.10.2026.'), findsNothing);
    expect(
      find.text('receipt_rozetka_181024.pdf', findRichText: true),
      findsWidgets,
    );
    await tester.tap(find.byTooltip('Збільшити').first);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip('Закрити'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Змінити'));
    await tester.pumpAndSettle();
    expect(find.text('Навушники Sony WH-1000XM5'), findsWidgets);
  });

  testWidgets('помилковий тип аргументів маршруту веде до списку', (
    tester,
  ) async {
    await start(tester);
    final BuildContext context = tester.element(find.byType(PurchasesScreen));
    Navigator.of(context)
        .pushNamed<Purchase>(AppRoutes.purchaseEdit, arguments: 'p1');
    await tester.pumpAndSettle();
    expect(find.byType(PurchasesScreen), findsWidgets);
    expect(find.text('Покупки та гарантії'), findsWidgets);
  });

  testWidgets('невідомий id показує повідомлення про відсутню покупку', (
    tester,
  ) async {
    await start(tester);
    final BuildContext context = tester.element(find.byType(PurchasesScreen));
    Navigator.of(context)
        .pushNamed(AppRoutes.purchaseDetails, arguments: 'p-not-found');
    await tester.pumpAndSettle();
    expect(find.text('Покупку не знайдено'), findsOneWidget);
  });

  testWidgets('посилання з деталей покупки відкриває звернення', (
    tester,
  ) async {
    await start(tester);
    final BuildContext context = tester.element(find.byType(PurchasesScreen));
    Navigator.of(context).pushNamed(AppRoutes.purchaseDetails, arguments: 'p1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Переглянути звернення →'));
    await tester.pumpAndSettle();
    expect(find.byType(ClaimDetailsScreen), findsOneWidget);
    expect(find.text('Історія звернення'), findsOneWidget);
  });

  testWidgets('кнопка в деталях покупки відкриває форму звернення', (
    tester,
  ) async {
    await start(tester);
    final BuildContext context = tester.element(find.byType(PurchasesScreen));
    Navigator.of(context).pushNamed(AppRoutes.purchaseDetails, arguments: 'p3');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Заявити про гарантійний випадок'));
    await tester.pumpAndSettle();
    expect(find.byType(ClaimFormScreen), findsOneWidget);
    expect(
      find.textContaining('Робот-пилосос Roborock Q8 Max · Foxtrot'),
      findsOneWidget,
    );
  });

  testWidgets('видалення в деталях повертає до таблиці без помилки', (
    tester,
  ) async {
    final controller = await start(tester);
    final BuildContext context = tester.element(find.byType(PurchasesScreen));
    Navigator.of(context).pushNamed(AppRoutes.purchaseDetails, arguments: 'p8');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Видалити'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Видалити').last);
    await tester.pumpAndSettle();
    expect(find.byType(PurchasesScreen), findsOneWidget);
    expect(find.text('Покупку видалено'), findsOneWidget);
    expect(controller.byId('p8'), isNull);
  });

  testWidgets('видалення покупки з деталями каскадно прибирає її звернення', (
    tester,
  ) async {
    final purchases = await start(tester);
    final BuildContext context = tester.element(find.byType(PurchasesScreen));
    final ClaimsController claims = context.read<ClaimsController>();
    Navigator.of(context).pushNamed(AppRoutes.purchaseDetails, arguments: 'p1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Видалити'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Буде також видалено 1 звернень'),
      findsOneWidget,
    );
    await tester.tap(find.text('Видалити').last);
    await tester.pumpAndSettle();
    expect(purchases.byId('p1'), isNull);
    expect(claims.byId('c1'), isNull);
    expect(find.byType(PurchasesScreen), findsOneWidget);
  });

  testWidgets(
    'редагування зберігає id і serialNumber та перераховує гарантію',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 988));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Purchase? result;
      final controller = PurchasesController(
        InMemoryPurchaseRepository(latency: Duration.zero),
      )..bindUser('u1');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<PurchasesController>.value(
          value: controller,
          child: MaterialApp(
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await Navigator.of(context).pushNamed<Purchase>(
                      AppRoutes.purchaseEdit,
                      arguments: PurchasesMockData.items.first,
                    );
                  },
                  child: const Text('Відкрити форму'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Відкрити форму'));
      await tester.pumpAndSettle();
      expect(find.text('18.10.2026'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12 місяців').last);
      await tester.pumpAndSettle();
      expect(find.text('18.10.2025'), findsOneWidget);
      await tester.tap(find.text('Зберегти'));
      await tester.pumpAndSettle();
      expect(result?.id, 'p1');
      expect(result?.serialNumber, 'S01-1234567-8');
      expect(result?.warrantyMonths, 12);
    },
  );
}
