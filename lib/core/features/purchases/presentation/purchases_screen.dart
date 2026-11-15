import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../data/purchases_mock_data.dart';
import '../domain/purchase.dart';
import '../domain/purchase_query.dart';
import 'widgets/purchase_filters_card.dart';
import 'widgets/purchase_table_row.dart';

/// Таблиця покупок з локальними чернетками фільтрів і сортуванням.
class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final TextEditingController _searchController = TextEditingController();
  PurchaseQuery _draft = const PurchaseQuery();
  PurchaseQuery _applied = const PurchaseQuery();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _apply() => setState(() => _applied = _draft);

  void _reset() {
    _searchController.clear();
    setState(() {
      _draft = const PurchaseQuery();
      _applied = const PurchaseQuery();
    });
  }

  void _sort(PurchaseSortField field) {
    final bool ascending = _applied.sortField == field
        ? !_applied.ascending
        : false;
    setState(() {
      _applied = _applied.copyWith(sortField: field, ascending: ascending);
      _draft = _draft.copyWith(sortField: field, ascending: ascending);
    });
  }

  void _showPending(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final List<Purchase> purchases = applyPurchaseQuery(
      PurchasesMockData.items,
      _applied,
      now,
    );
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
                    onPressed: () => _showPending('Форма — крок 03'),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
            sliver: SliverToBoxAdapter(
              child: PurchaseFiltersCard(
                query: _draft,
                searchController: _searchController,
                onSearchChanged: (search) =>
                    setState(() => _draft = _draft.copyWith(search: search)),
                onCategoryChanged: (category) => setState(
                  () => _draft = _draft.copyWith(
                    category: category,
                    clearCategory: category == null,
                  ),
                ),
                onStatusChanged: (status) => setState(
                  () => _draft = _draft.copyWith(
                    status: status,
                    clearStatus: status == null,
                  ),
                ),
                onApply: _apply,
              ),
            ),
          ),
          if (purchases.isEmpty)
            SliverFillRemaining(
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
                        onPressed: _reset,
                        child: const Text('Скинути фільтри'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
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
                        query: _applied,
                        onSort: _sort,
                      ),
                    ),
                    SliverList.separated(
                      itemCount: purchases.length,
                      itemBuilder: (context, index) => PurchaseTableRow(
                        purchase: purchases[index],
                        now: now,
                        onAction: () =>
                            _showPending('Буде реалізовано на кроці 03'),
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
