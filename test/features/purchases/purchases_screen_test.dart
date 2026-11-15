import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/presentation/purchases_screen.dart';

void main() {
  testWidgets(
    'чернетка фільтра застосовується кнопкою, а порожній результат скидається',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 988));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: PurchasesScreen()));

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
      expect(find.text('Смартфон Samsung Galaxy A55'), findsOneWidget);
    },
  );
}
