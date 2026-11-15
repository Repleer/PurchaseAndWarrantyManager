import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../../purchases/application/purchases_controller.dart';
import '../../../purchases/domain/purchase.dart';
import '../../domain/claim.dart';
import 'claim_status_badge.dart';

/// Спільні пропорції заголовка та рядка таблиці звернень.
abstract final class ClaimTableColumns {
  static const int product = 27;
  static const int date = 10;
  static const int description = 33;
  static const int status = 17;
  static const int actions = 13;
}

/// Рядок гарантійного звернення з пов'язаною покупкою.
class ClaimTableRow extends StatelessWidget {
  const ClaimTableRow({super.key, required this.claim, required this.onView});

  final Claim claim;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final Purchase? purchase = context.select<PurchasesController, Purchase?>(
      (controller) => controller.byId(claim.purchaseId),
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: ClaimTableColumns.product,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase?.productName ?? 'Покупку не знайдено',
                  style: AppTextStyles.bodyStrong,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  purchase == null
                      ? ''
                      : '${purchase.store} · гарантія до ${formatDate(purchase.warrantyUntil)}',
                  style: AppTextStyles.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: ClaimTableColumns.date,
            child: Text(
              formatDate(claim.createdAt),
              style: AppTextStyles.small,
            ),
          ),
          Expanded(
            flex: ClaimTableColumns.description,
            child: Text(
              claim.description,
              style: AppTextStyles.small,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: ClaimTableColumns.status,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ClaimStatusBadge(status: claim.status),
            ),
          ),
          Expanded(
            flex: ClaimTableColumns.actions,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onView,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Переглянути',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
