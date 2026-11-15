import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../application/warranty_check_controller.dart';
import '../../domain/warranty_check.dart';

/// Діалог результатів перевірки серійного номера й документів.
class WarrantyCheckDialog extends StatelessWidget {
  const WarrantyCheckDialog({
    super.key,
    required this.productName,
    required this.store,
    required this.onRetry,
  });

  final String productName;
  final String store;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Consumer<WarrantyCheckController>(
    builder: (context, controller, _) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 528,
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Перевірка автентичності гарантії',
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Закрити',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('$productName · $store', style: AppTextStyles.small),
              const SizedBox(height: 20),
              if (controller.status != WarrantyCheckStatus.done) ...[
                const SizedBox(height: 35),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 18),
                const Center(child: Text('Перевіряємо гарантію…')),
                const SizedBox(height: 35),
              ] else if (controller.result == null) ...[
                const FeedbackBanner(
                  message: 'Не вдалося перевірити гарантію. Спробуйте ще раз.',
                  isError: true,
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Перевірити ще раз',
                    onPressed: onRetry,
                  ),
                ),
              ] else ...[
                for (final WarrantyCheckItem item in controller.result!.items)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: switch (item.state) {
                              CheckItemState.passed =>
                                AppColors.successBackground,
                              CheckItemState.failed =>
                                AppColors.errorBackground,
                              CheckItemState.unverified => AppColors.background,
                            },
                          ),
                          child: Icon(
                            switch (item.state) {
                              CheckItemState.passed => Icons.check,
                              CheckItemState.failed => Icons.close,
                              CheckItemState.unverified => Icons.remove,
                            },
                            color: switch (item.state) {
                              CheckItemState.passed => AppColors.success,
                              CheckItemState.failed => AppColors.error,
                              CheckItemState.unverified =>
                                AppColors.textSecondary,
                            },
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: AppTextStyles.bodyStrong),
                              const SizedBox(height: 3),
                              Text(item.detail, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: controller.result!.isValid
                        ? AppColors.successBackground
                        : AppColors.errorBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.result!.isValid
                            ? '✓ Гарантію підтверджено'
                            : 'ⓘ Не вдалося підтвердити гарантію',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: controller.result!.isValid
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        controller.result!.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: controller.result!.isValid
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: controller.result!.isValid
                        ? 'Продовжити'
                        : 'Перевірити ще раз',
                    onPressed: controller.result!.isValid
                        ? () => Navigator.pop(context)
                        : onRetry,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
