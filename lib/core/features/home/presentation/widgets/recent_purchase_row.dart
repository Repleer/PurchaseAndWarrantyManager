import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';
import 'package:warranty_and_purchase_manager/core/features/home/data/home_mock_data.dart';

/// Рядок таблиці «Останні чеки»: товар, дата, вартість, гарантія, кнопка «Деталі».
class RecentPurchaseRow extends StatelessWidget {
  const RecentPurchaseRow({
    super.key,
    required this.purchase,
    required this.showDivider,
    required this.onDetails,
  });

  final RecentPurchase purchase;
  final bool showDivider;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(purchase.productName, style: AppTextStyles.bodySmall),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 150,
            child: Text(purchase.purchaseDate, style: AppTextStyles.small),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(purchase.price, style: AppTextStyles.label),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 175,
            child: Text(
              'Діє до ${purchase.warrantyUntil}',
              style: AppTextStyles.small,
            ),
          ),
          const SizedBox(width: 16),
          AppButton(
            label: 'Деталі',
            icon: Icons.north_east,
            variant: AppButtonVariant.ghost,
            onPressed: onDetails,
          ),
        ],
      ),
    );
  }
}
