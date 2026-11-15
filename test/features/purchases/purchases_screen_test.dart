import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/application/purchases_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/in_memory_purchase_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/presentation/purchase_form_screen.dart';
import 'package:warranty_and_purchase_manager/core/routes/app_router.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/presentation/purchases_screen.dart';

void main() {
  testWidgets(
    'чернетка фільтра застосовується кнопкою, а порожній результат скидається',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 988));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = PurchasesController(
        InMemoryPurchaseRepository(latency: Duration.zero),
        clock: () => DateTime(2026, 11, 15),
      )..bindUser('u1');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<PurchasesController>.value(
          value: controller,
          child: const MaterialApp(home: PurchasesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Покупки та гарантії'), findsWidgets);
      expect(find.text('Нічого не знайдено'), findsNothing);

      await tester.tap(find.text('ВАРТІСТЬ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ВАРТІСТЬ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ГАРАНТІЯ'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'немає такого товару',
      );
      await tester.pump();
      expect(find.text('Нічого не знайдено'), findsNothing);

      await tester.tap(find.text('Фільтрувати'));
      await tester.pumpAndSettle();
      expect(find.text('Нічого не знайдено'), findsOneWidget);

      await tester.tap(find.text('Скинути фільтри'));
      await tester.pumpAndSettle();
      expect(find.text('Нічого не знайдено'), findsNothing);
      expect(find.text('Письмовий стіл IKEA MICKE'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller
            ?.text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'помилка завантаження й повторна спроба не чіпають шапку та фільтри',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 988));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      bool fail = true;
      final controller = PurchasesController(
        InMemoryPurchaseRepository(
          latency: Duration.zero,
          failWhen: () => fail,
        ),
      )..bindUser('u1');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<PurchasesController>.value(
          value: controller,
          child: const MaterialApp(home: PurchasesScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Не вдалося завантажити дані. Спробуйте ще раз.'),
        findsOneWidget,
      );
      expect(find.text('Назва товару'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Спробувати ще раз'));
      await tester.pumpAndSettle();
      expect(find.text('Письмовий стіл IKEA MICKE'), findsOneWidget);
    },
  );

  testWidgets('невдале збереження залишає форму й показує банер', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 988));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    bool fail = false;
    final controller = PurchasesController(
      InMemoryPurchaseRepository(latency: Duration.zero, failWhen: () => fail),
    )..bindUser('u1');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<PurchasesController>.value(
        value: controller,
        child: MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const PurchasesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Створити запис'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Тестовий товар');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Тестовий магазин',
    );
    await tester.enterText(find.byType(TextFormField).at(3), '100');
    fail = true;
    await tester.tap(find.text('Зберегти'));
    await tester.pumpAndSettle();
    expect(find.byType(PurchaseFormScreen), findsOneWidget);
    expect(
      find.text('Не вдалося завантажити дані. Спробуйте ще раз.'),
      findsOneWidget,
    );
    expect(
      controller.items.any((item) => item.productName == 'Тестовий товар'),
      isFalse,
    );
    fail = false;
    await tester.tap(find.text('Зберегти'));
    await tester.pumpAndSettle();
    expect(find.text('Покупку додано'), findsOneWidget);
    expect(
      controller.items.any((item) => item.productName == 'Тестовий товар'),
      isTrue,
    );
  });

  testWidgets('видалення з таблиці потребує підтвердження', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 988));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = PurchasesController(
      InMemoryPurchaseRepository(latency: Duration.zero),
    )..bindUser('u1');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<PurchasesController>.value(
        value: controller,
        child: const MaterialApp(home: PurchasesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Видалити').first);
    await tester.pumpAndSettle();
    expect(find.text('Видалити покупку?'), findsOneWidget);
    await tester.tap(find.text('Скасувати'));
    await tester.pumpAndSettle();
    expect(controller.byId('p8'), isNotNull);
    await tester.tap(find.byTooltip('Видалити').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Видалити').last);
    await tester.pumpAndSettle();
    expect(controller.byId('p8'), isNull);
    expect(find.text('Покупку видалено'), findsOneWidget);
  });
}
