import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';
import 'package:warranty_and_purchase_manager/core/features/home/presentation/widgets/expiring_warranty_card.dart';
import 'package:warranty_and_purchase_manager/core/features/home/presentation/widgets/quick_access_card.dart';
import 'package:warranty_and_purchase_manager/core/features/home/presentation/widgets/recent_purchase_row.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/domain/purchase.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/application/purchases_controller.dart';

/// Головний екран (ФВ-3.3, ФВ-5): швидкий доступ до функцій,
/// гарантії, що скоро закінчуються, та останні чеки.
/// Дані отримує через PurchasesController.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _openPurchase(BuildContext context, Purchase purchase) {
    Navigator.of(context)
        .pushNamed(AppRoutes.purchaseDetails, arguments: purchase.id);
  }

  Future<void> _create(BuildContext context) async {
    final Purchase? result = await Navigator.of(context)
        .pushNamed<Purchase>(AppRoutes.purchaseCreate);
    if (!context.mounted || result == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Покупку додано')));
  }

  /// Розташовує віджети в рядок однакової ширини з відступом [gap].
  List<Widget> _equalWidthRow(List<Widget> items, double gap) {
    return [
      for (int i = 0; i < items.length; i++) ...[
        if (i > 0) SizedBox(width: gap),
        Expanded(child: items[i]),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final PurchasesController controller = context.watch<PurchasesController>();
    final List<Purchase> purchases = controller.recent;
    final List<Purchase> warranties = controller.expiringSoon;
    final DateTime now = controller.now;

    return AppShell.main(
      selectedIndex: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 32, 40, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Головна', style: AppTextStyles.pageTitle),
            const SizedBox(height: 6),
            const Text(
              'Короткий огляд гарантій, що скоро закінчуються, і ваших останніх покупок.',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 24),

            // Швидкий доступ.
            Row(
              children: _equalWidthRow([
                QuickAccessCard(
                  icon: Icons.add,
                  title: 'Нова заявка',
                  subtitle: 'Додати покупку та гарантію',
                  actionLabel: 'Створити',
                  onPressed: () => _create(context),
                ),
                QuickAccessCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Покупки та гарантії',
                  subtitle: 'Переглянути всі записи',
                  actionLabel: 'Відкрити',
                  onPressed: () => _open(context, AppRoutes.purchases),
                ),
                QuickAccessCard(
                  icon: Icons.account_circle_outlined,
                  title: 'Профіль',
                  subtitle: 'Фото та зміна пароля',
                  actionLabel: 'Переглянути',
                  onPressed: () => _open(context, AppRoutes.profile),
                ),
              ], 14),
            ),
            const SizedBox(height: 24),

            // Гарантії, що закінчуються незабаром.
            const SectionHeader(
              title: 'Гарантії, що закінчуються незабаром',
              trailing: 'Найближчі дати',
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _equalWidthRow([
                for (final Purchase warranty in warranties)
                  ExpiringWarrantyCard(
                    warranty: warranty,
                    now: now,
                    onTap: () => _openPurchase(context, warranty),
                  ),
              ], 14),
            ),
            const SizedBox(height: 24),

            // Останні чеки.
            const SectionHeader(
              title: 'Останні чеки',
              trailing: 'Перейти до деталей за записом',
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              radius: 12,
              shadow: false,
              child: Column(
                children: [
                  for (int i = 0; i < purchases.length; i++)
                    RecentPurchaseRow(
                      purchase: purchases[i],
                      showDivider: i < purchases.length - 1,
                      onDetails: () => _openPurchase(context, purchases[i]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
