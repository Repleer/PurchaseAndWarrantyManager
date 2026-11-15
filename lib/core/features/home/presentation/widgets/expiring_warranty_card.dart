import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/domain/purchase.dart';

/// Картка гарантії, що скоро закінчується: бейдж із залишком днів, товар, магазин.
class ExpiringWarrantyCard extends StatelessWidget {
  const ExpiringWarrantyCard({
    super.key,
    required this.warranty,
    required this.now,
    required this.onTap,
  });

  final Purchase warranty;
  final DateTime now;
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
              StatusBadge(label: formatDaysLeft(warranty.daysLeft(now))),
              const Icon(Icons.north_east, size: 18, color: AppColors.primary),
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
          Text(warranty.store, style: AppTextStyles.small),
          const SizedBox(height: 10),
          Text(
            'до ${formatDate(warranty.warrantyUntil)}',
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
