import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';
import 'package:warranty_and_purchase_manager/core/features/home/data/home_mock_data.dart';

/// Картка гарантії, що скоро закінчується: бейдж із залишком днів, товар, магазин.
class ExpiringWarrantyCard extends StatelessWidget {
  const ExpiringWarrantyCard({
    super.key,
    required this.warranty,
    required this.onTap,
  });

  final ExpiringWarranty warranty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 12,
      shadow: false,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(label: warranty.daysLeftLabel),
              const Icon(
                Icons.north_east,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            warranty.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyStrong,
          ),
          const SizedBox(height: 10),
          Text(warranty.shop, style: AppTextStyles.small),
          const SizedBox(height: 10),
          Text(
            'до ${warranty.expiresOn}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
