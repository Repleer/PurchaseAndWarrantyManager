import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../../data/load_status.dart';
import '../../../data/data_failure.dart';
import '../../claims/application/claims_controller.dart';
import '../application/purchases_controller.dart';
import '../domain/purchase.dart';
import '../domain/purchase_query.dart';
import 'widgets/purchase_filters_card.dart';
import 'widgets/purchase_table_row.dart';

/// Таблиця покупок із фільтрами й даними PurchasesController.
class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  Future<void> _openForm(BuildContext context, [Purchase? initial]) async {
    final Purchase? result = await Navigator.of(context).pushNamed<Purchase>(
      initial == null ? AppRoutes.purchaseCreate : AppRoutes.purchaseEdit,
      arguments: initial,
    );
    if (!context.mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(initial == null ? 'Покупку додано' : 'Зміни збережено'),
      ),
    );
  }

  Future<void> _delete(BuildContext context, String id) async {
    final ClaimsController? claims = context.read<ClaimsController?>();
    if (claims != null && claims.status != LoadStatus.ready) {
      await claims.load();
      if (!context.mounted) return;
      if (claims.status != LoadStatus.ready) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              claims.errorMessage ?? 'Не вдалося завантажити звернення.',
            ),
          ),
        );
        return;
      }
    }
    final int relatedCount = claims?.forPurchase(id).length ?? 0;
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Видалити покупку?'),
            content: Text(
              relatedCount == 0
                  ? 'Підтвердіть видалення запису про покупку.'
                  : 'Підтвердіть видалення запису про покупку. '
                        'Буде також видалено $relatedCount звернень',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Скасувати'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Видалити'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final PurchasesController controller = context.read<PurchasesController>();
    final bool removed = await controller.remove(id);
    if (!context.mounted) return;
    String message = removed
        ? 'Покупку видалено'
        : controller.errorMessage ?? 'Не вдалося видалити покупку.';
    if (removed && claims != null) {
      try {
        await claims.removeForPurchase(id);
      } on DataFailure catch (error) {
        message =
            'Покупку видалено, але звернення видалено не повністю: '
            '${error.message}';
      }
      if (!context.mounted) return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AppShell.main(
      selectedIndex: 1,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Покупки та гарантії',
                          style: AppTextStyles.pageTitle,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Шукайте, переглядайте та редагуйте записи про покупки й гарантійні документи.',
                          style: AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  AppButton(
                    label: 'Створити запис',
                    icon: Icons.add,
                    onPressed: () => _openForm(context),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
            sliver: SliverToBoxAdapter(child: const PurchaseFiltersCard()),
          ),
          Consumer<PurchasesController>(
            builder: (context, controller, _) {
              if (controller.isLoading ||
                  controller.status == LoadStatus.initial) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.status == LoadStatus.failure) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 36),
                    child: AppCard(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FeedbackBanner(
                            message: controller.errorMessage ?? 'Не вдалося завантажити дані. Спробуйте ще раз.',
                            isError: true,
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            label: 'Спробувати ще раз',
                            onPressed: controller.load,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final List<Purchase> purchases = controller.visibleItems;
              final DateTime now = controller.now;
              if (purchases.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 36),
                    child: AppCard(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Нічого не знайдено',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: controller.resetFilters,
                            child: const Text('Скинути фільтри'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 36),
                sliver: DecoratedSliver(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _TableHeaderDelegate(
                          query: controller.appliedQuery,
                          onSort: controller.toggleSort,
                        ),
                      ),
                      SliverList.separated(
                        itemCount: purchases.length,
                        itemBuilder: (context, index) => PurchaseTableRow(
                          purchase: purchases[index],
                          now: now,
                          onView: () => Navigator.of(context).pushNamed(
                            AppRoutes.purchaseDetails,
                            arguments: purchases[index].id,
                          ),
                          onEdit: () => _openForm(context, purchases[index]),
                          onDelete: () => _delete(context, purchases[index].id),
                        ),
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Закріплена шапка таблиці з клікабельними колонками сортування.
class _TableHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TableHeaderDelegate({required this.query, required this.onSort});

  final PurchaseQuery query;
  final ValueChanged<PurchaseSortField> onSort;

  @override
  double get minExtent => 40;

  @override
  double get maxExtent => 40;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: PurchaseTableColumns.product,
            child: Text('ТОВАР / ПРОДАВЕЦЬ', style: _headerStyle),
          ),
          const Expanded(
            flex: PurchaseTableColumns.category,
            child: Text('КАТЕГОРІЯ', style: _headerStyle),
          ),
          Expanded(
            flex: PurchaseTableColumns.date,
            child: _sortButton('ДАТА', PurchaseSortField.date),
          ),
          Expanded(
            flex: PurchaseTableColumns.price,
            child: _sortButton('ВАРТІСТЬ', PurchaseSortField.price),
          ),
          Expanded(
            flex: PurchaseTableColumns.warranty,
            child: _sortButton('ГАРАНТІЯ', PurchaseSortField.warranty),
          ),
          const Expanded(
            flex: PurchaseTableColumns.actions,
            child: Text('ДІЇ', style: _headerStyle),
          ),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );

  Widget _sortButton(String label, PurchaseSortField field) {
    return TextButton(
      onPressed: () => onSort(field),
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
        foregroundColor: AppColors.textSecondary,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: _headerStyle),
          if (query.sortField == field) ...[
            const SizedBox(width: 1),
            Text(query.ascending ? '↑' : '↓', style: _headerStyle),
          ],
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TableHeaderDelegate oldDelegate) =>
      query.sortField != oldDelegate.query.sortField ||
      query.ascending != oldDelegate.query.ascending;
}
