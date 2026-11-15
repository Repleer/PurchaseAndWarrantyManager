import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../../data/load_status.dart';
import '../../../data/data_failure.dart';
import '../../claims/application/claims_controller.dart';
import '../../claims/domain/claim.dart';
import '../../claims/presentation/claim_details_args.dart';
import '../application/purchases_controller.dart';
import '../domain/purchase.dart';
import 'widgets/purchase_document_card.dart';

/// Деталі покупки та гарантійних документів із PurchasesController.
class PurchaseDetailsScreen extends StatelessWidget {
  const PurchaseDetailsScreen({super.key, required this.purchaseId});

  final String purchaseId;

  void _pending(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _edit(BuildContext context, Purchase purchase) async {
    final Purchase? result = await Navigator.of(context)
        .pushNamed<Purchase>(AppRoutes.purchaseEdit, arguments: purchase);
    if (!context.mounted || result == null) return;
    _pending(context, 'Зміни збережено');
  }

  Future<void> _delete(BuildContext context, String id) async {
    final ClaimsController claims = context.read<ClaimsController>();
    if (claims.status != LoadStatus.ready) {
      await claims.load();
      if (!context.mounted) return;
      if (claims.status != LoadStatus.ready) {
        _pending(
          context,
          claims.errorMessage ?? 'Не вдалося завантажити звернення.',
        );
        return;
      }
    }
    final int relatedCount = claims.forPurchase(id).length;
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Видалити покупку?'),
            content: Text(
              relatedCount == 0
                  ? 'Підтвердіть видалення запису про покупку.'
                  : 'Підтвердіть видалення запису про покупку. '
                        'Буде також видалено $relatedCount звернень',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Скасувати'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Видалити'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final PurchasesController controller = context.read<PurchasesController>();
    final bool deleted = await controller.remove(id);
    if (!context.mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (deleted) {
      String message = 'Покупку видалено';
      try {
        await claims.removeForPurchase(id);
      } on DataFailure catch (error) {
        message =
            'Покупку видалено, але звернення видалено не повністю: '
            '${error.message}';
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Не вдалося видалити покупку.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Purchase? purchase = context.select<PurchasesController, Purchase?>(
      (controller) => controller.byId(purchaseId),
    );
    if (purchase == null) {
      return const AppShell.main(
        selectedIndex: 1,
        child: Center(
          child: Text('Покупку не знайдено', style: AppTextStyles.sectionTitle),
        ),
      );
    }
    final DateTime now = context.read<PurchasesController>().now;
    final WarrantyStatus status = purchase.status(now);
    return AppShell.main(
      selectedIndex: 1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 24, 40, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (status == WarrantyStatus.expiringSoon) ...[
              FeedbackBanner(
                message:
                    'Гарантія завершується ${formatDate(purchase.warrantyUntil)}.',
                tone: FeedbackTone.warning,
                icon: Icons.notifications_none,
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        purchase.productName,
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Перегляньте дані покупки та документи; за потреби подайте звернення.',
                        style: AppTextStyles.small,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'Змінити',
                  icon: Icons.edit_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _edit(context, purchase),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'Заявити про гарантійний випадок',
                  onPressed: () => Navigator.of(context).pushNamed<Claim>(
                    AppRoutes.claimCreate,
                    arguments: purchase.id,
                  ),
                ),
                const SizedBox(width: 8),
                _DeleteButton(onPressed: () => _delete(context, purchase.id)),
              ],
            ),
            Selector<ClaimsController, Claim?>(
              selector: (_, controller) =>
                  controller.latestForPurchase(purchase.id),
              builder: (context, latestClaim, _) {
                if (latestClaim == null) return const SizedBox.shrink();
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      radius: 12,
                      shadow: false,
                      child: Row(
                        children: [
                          const Text(
                            'Звернення по цьому товару',
                            style: AppTextStyles.bodyStrong,
                          ),
                          const SizedBox(width: 12),
                          StatusBadge(
                            label: latestClaim.status.label,
                            tone: switch (latestClaim.status) {
                              ClaimStatus.underReview => StatusTone.warning,
                              ClaimStatus.inProgress => StatusTone.info,
                              ClaimStatus.resolved => StatusTone.success,
                              ClaimStatus.rejected => StatusTone.error,
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '№ ${latestClaim.number} · подано ${formatDate(latestClaim.createdAt)}',
                              style: AppTextStyles.small,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed(
                              AppRoutes.claimDetails,
                              arguments: ClaimDetailsArgs(
                                claimId: latestClaim.id,
                              ),
                            ),
                            child: const Text('Переглянути звернення →'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 594,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 36,
                    child: _PurchaseInfoCard(purchase: purchase, now: now),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 64,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Документи',
                          style: AppTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: PurchaseDocumentCard(
                                  title: 'Чек',
                                  fileName: purchase.receiptFileName,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PurchaseDocumentCard(
                                  title: 'Гарантія',
                                  fileName: purchase.warrantyFileName,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

/// Дані покупки й обчислюваний стан гарантії.
class _PurchaseInfoCard extends StatelessWidget {
  const _PurchaseInfoCard({required this.purchase, required this.now});

  final Purchase purchase;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final WarrantyStatus status = purchase.status(now);
    final int days = purchase.daysLeft(now);
    final String statusLabel = switch (status) {
      WarrantyStatus.expiringSoon =>
        'Завершується через ${formatDaysLeft(days)}',
      WarrantyStatus.active => 'Діє ще ${formatDaysLeft(days)}',
      WarrantyStatus.expired => 'Гарантія завершилась',
    };
    final StatusTone tone = switch (status) {
      WarrantyStatus.expiringSoon => StatusTone.warning,
      WarrantyStatus.active => StatusTone.success,
      WarrantyStatus.expired => StatusTone.error,
    };

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Дані покупки',
                  style: AppTextStyles.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: StatusBadge(label: statusLabel, tone: tone),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _dataRow('Назва товару', purchase.productName),
          _dataRow('Магазин / продавець', purchase.store),
          _dataRow('Категорія', purchase.category.label),
          _dataRow('Дата покупки', formatDate(purchase.purchaseDate)),
          _dataRow('Вартість', formatPrice(purchase.price)),
          _dataRow('Термін гарантії', formatMonths(purchase.warrantyMonths)),
          _dataRow(
            'Дата завершення гарантії',
            formatDate(purchase.warrantyUntil),
          ),
          const SizedBox(height: 12),
          const Text('Нотатки', style: AppTextStyles.small),
          const SizedBox(height: 6),
          Text(
            purchase.notes ?? 'Нотаток немає',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 5),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        Expanded(flex: 42, child: Text(label, style: AppTextStyles.caption)),
        Expanded(flex: 58, child: Text(value, style: AppTextStyles.bodyStrong)),
      ],
    ),
  );
}

/// М'яка червона кнопка видалення з підтвердженням.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.errorBackground,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: AppColors.error, size: 18),
            SizedBox(width: 8),
            Text('Видалити', style: TextStyle(color: AppColors.error)),
          ],
        ),
      ),
    ),
  );
}
