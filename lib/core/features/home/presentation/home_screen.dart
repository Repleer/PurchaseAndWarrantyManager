import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';
import 'package:warranty_and_purchase_manager/core/features/home/data/home_mock_data.dart';
import 'package:warranty_and_purchase_manager/core/features/home/presentation/widgets/expiring_warranty_card.dart';
import 'package:warranty_and_purchase_manager/core/features/home/presentation/widgets/quick_access_card.dart';
import 'package:warranty_and_purchase_manager/core/features/home/presentation/widgets/recent_purchase_row.dart';


/// Головний екран (ФВ-3.3, ФВ-5): швидкий доступ до функцій,
/// гарантії, що скоро закінчуються, та останні чеки.
/// Усі дані захардкоджені у [HomeMockData].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, String route) {
    Navigator.of(context).pushReplacementNamed(route);
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
    final List<RecentPurchase> purchases = HomeMockData.recentPurchases;

    return AppShell.main(
      selectedIndex: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 32, 40, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Головна', style: AppTextStyles.pageTitle),
            const SizedBox(height: 6),
            const Text(HomeMockData.pageSubtitle, style: AppTextStyles.small),
            const SizedBox(height: 24),

            // Швидкий доступ.
            Row(
              children: _equalWidthRow([
                QuickAccessCard(
                  icon: Icons.add,
                  title: 'Нова заявка',
                  subtitle: 'Додати покупку та гарантію',
                  actionLabel: 'Створити',
                  onPressed: () => _open(context, AppRoutes.purchases),
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
                for (final ExpiringWarranty warranty
                    in HomeMockData.expiringWarranties)
                  ExpiringWarrantyCard(
                    warranty: warranty,
                    onTap: () => _open(context, AppRoutes.purchases),
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
                      onDetails: () => _open(context, AppRoutes.purchases),
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
