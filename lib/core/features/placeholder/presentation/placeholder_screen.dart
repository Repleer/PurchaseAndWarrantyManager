import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

/// Тимчасовий екран для розділів, які буде реалізовано в наступних роботах
/// («Покупки та гарантії», «Мої звернення»).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.selectedIndex,
  });

  final String title;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return AppShell.main(
      selectedIndex: selectedIndex,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 32, 40, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.pageTitle),
            const SizedBox(height: 6),
            const Text(
              'Цей розділ буде реалізовано в наступних лабораторних роботах.',
              style: AppTextStyles.small,
            ),
          ],
        ),
      ),
    );
  }
}
