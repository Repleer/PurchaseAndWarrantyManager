import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../domain/purchase.dart';

/// Спільні пропорції колонок шапки та рядків таблиці.
abstract final class PurchaseTableColumns {
  static const int product = 21;
  static const int category = 13;
  static const int date = 9;
  static const int price = 10;
  static const int warranty = 19;
  static const int actions = 28;
}

/// Рядок покупки з бейджем гарантії та діями.
class PurchaseTableRow extends StatelessWidget {
  const PurchaseTableRow({
    super.key,
    required this.purchase,
    required this.now,
    required this.onAction,
  });

  final Purchase purchase;
  final DateTime now;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final WarrantyStatus warrantyStatus = purchase.status(now);
    final StatusTone tone = switch (warrantyStatus) {
      WarrantyStatus.active => StatusTone.success,
      WarrantyStatus.expiringSoon => StatusTone.warning,
      WarrantyStatus.expired => StatusTone.error,
    };

    return Container(
      color: AppColors.surface,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Row(
        children: [
          Expanded(
            flex: PurchaseTableColumns.product,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  purchase.productName,
                  style: AppTextStyles.bodyStrong,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  purchase.store,
                  style: AppTextStyles.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: PurchaseTableColumns.category,
            child: Text(
              purchase.category.label,
              style: AppTextStyles.small,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: PurchaseTableColumns.date,
            child: Text(
              formatDate(purchase.purchaseDate),
              style: AppTextStyles.small,
            ),
          ),
          Expanded(
            flex: PurchaseTableColumns.price,
            child: Text(
              formatPrice(purchase.price),
              style: AppTextStyles.bodySmall,
            ),
          ),
          Expanded(
            flex: PurchaseTableColumns.warranty,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(
                label: 'до ${formatDate(purchase.warrantyUntil)}',
                tone: tone,
              ),
            ),
          ),
          Expanded(
            flex: PurchaseTableColumns.actions,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onAction,
                  style: _actionStyle,
                  child: const Text('Переглянути'),
                ),
                TextButton(
                  onPressed: onAction,
                  style: _actionStyle,
                  child: const Text('Змінити'),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    onPressed: onAction,
                    tooltip: 'Видалити',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppColors.error,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.errorBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static final ButtonStyle _actionStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: const TextStyle(fontSize: 13),
  );
}
