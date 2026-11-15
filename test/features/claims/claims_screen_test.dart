import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/application/purchases_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/in_memory_purchase_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/application/claims_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/in_memory_claim_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/warranty_verification_service.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claim_details_args.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/domain/claim.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claim_details_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claims_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/presentation/purchase_details_screen.dart';
import 'package:warranty_and_purchase_manager/core/routes/app_router.dart';
import 'package:warranty_and_purchase_manager/core/routes/app_routes.dart';

void main() {
  Future<void> start(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 988));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final purchases = PurchasesController(
      InMemoryPurchaseRepository(latency: Duration.zero),
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
          home: const ClaimsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('чернетка фільтра, порожній стан і деталі працюють', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Показано 5 із 5 звернень'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'невідомий товар');
    await tester.pump();
    expect(find.text('Показано 5 із 5 звернень'), findsOneWidget);
    await tester.tap(find.text('Фільтрувати'));
    await tester.pumpAndSettle();
    expect(find.text('Нічого не знайдено'), findsOneWidget);
    await tester.tap(find.text('Скинути фільтри'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<ClaimStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('В роботі').last);
    await tester.pumpAndSettle();
    expect(find.text('Показано 5 із 5 звернень'), findsOneWidget);
    await tester.tap(find.text('Фільтрувати'));
    await tester.pumpAndSettle();
    expect(find.text('Показано 2 із 5 звернень'), findsOneWidget);
    await tester.tap(find.textContaining('ДАТА').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Переглянути').first);
    await tester.pumpAndSettle();
    expect(find.byType(ClaimDetailsScreen), findsOneWidget);
  });

  testWidgets('деталі Sony, покупка й одноразовий тост', (tester) async {
    await start(tester);
    final BuildContext context = tester.element(find.byType(ClaimsScreen));
    Navigator.of(context).pushNamed(
      AppRoutes.claimDetails,
      arguments: const ClaimDetailsArgs(claimId: 'c1', justCreated: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Історія звернення'), findsOneWidget);
    expect(find.text('Лівий навушник.jpg'), findsOneWidget);
    expect(find.text('JPG · 2,4 МБ'), findsOneWidget);
    expect(find.text('Звернення успішно надіслано'), findsOneWidget);
    await tester.tap(find.byTooltip('Закрити повідомлення'));
    await tester.pumpAndSettle();
    expect(find.text('Звернення успішно надіслано'), findsNothing);
    await tester.tap(find.textContaining('гарантія до 18.10.2026').first);
    await tester.pumpAndSettle();
    expect(find.byType(PurchaseDetailsScreen), findsOneWidget);
  });

  testWidgets('тост зникає за чотири секунди', (tester) async {
    await start(tester);
    final BuildContext context = tester.element(find.byType(ClaimsScreen));
    Navigator.of(context).pushNamed(
      AppRoutes.claimDetails,
      arguments: const ClaimDetailsArgs(claimId: 'c1', justCreated: true),
    );
    await tester.pump();
    expect(find.text('Звернення успішно надіслано'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(find.text('Звернення успішно надіслано'), findsNothing);
  });

  testWidgets('помилка завантаження має кнопку повторної спроби', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 988));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    bool fail = true;
    final purchases = PurchasesController(
      InMemoryPurchaseRepository(latency: Duration.zero),
    )..bindUser('u1');
    addTearDown(purchases.dispose);
    final claims = ClaimsController(
      InMemoryClaimRepository(latency: Duration.zero, failWhen: () => fail),
      MockWarrantyVerificationService(latency: Duration.zero),
    )..bindUser('u1');
    addTearDown(claims.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PurchasesController>.value(value: purchases),
          ChangeNotifierProvider<ClaimsController>.value(value: claims),
        ],
        child: const MaterialApp(home: ClaimsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Не вдалося завантажити дані. Спробуйте ще раз.'),
      findsOneWidget,
    );
    fail = false;
    await tester.tap(find.text('Спробувати ще раз'));
    await tester.pumpAndSettle();
    expect(find.text('Показано 5 із 5 звернень'), findsOneWidget);
  });

  testWidgets('відкликання прибирає звернення зі списку', (tester) async {
    await start(tester);
    final BuildContext context = tester.element(find.byType(ClaimsScreen));
    final ClaimsController controller = context.read<ClaimsController>();
    Navigator.of(context).pushNamed(AppRoutes.claimDetails, arguments: 'c1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Відкликати'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Відкликати').last);
    await tester.pumpAndSettle();
    expect(controller.byId('c1'), isNull);
    expect(find.text('Звернення відкликано'), findsOneWidget);
    expect(find.text('Показано 4 із 4 звернень'), findsOneWidget);
  });
}
