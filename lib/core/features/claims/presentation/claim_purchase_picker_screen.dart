import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../purchases/application/purchases_controller.dart';
import '../../purchases/domain/purchase.dart';
import '../../purchases/domain/purchase_query.dart';
import '../domain/claim.dart';

/// Вибір придбаного товару перед створенням гарантійного звернення.
class ClaimPurchasePickerScreen extends StatefulWidget {
  const ClaimPurchasePickerScreen({super.key});

  @override
  State<ClaimPurchasePickerScreen> createState() =>
      _ClaimPurchasePickerScreenState();
}

class _ClaimPurchasePickerScreenState extends State<ClaimPurchasePickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  PurchaseQuery _draft = const PurchaseQuery();
  PurchaseQuery _applied = const PurchaseQuery();
  String? _selectedId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _apply() => setState(() => _applied = _draft);

  @override
  Widget build(BuildContext context) {
    final PurchasesController purchases = context.watch<PurchasesController>();
    final DateTime now = purchases.now;
    final List<Purchase> items = applyPurchaseQuery(
      purchases.items,
      _applied,
      now,
    );
    final Purchase? selected = _selectedId == null
        ? null
        : purchases.byId(_selectedId!);
    return AppShell.main(
      selectedIndex: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 28, 40, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Вибір покупки', style: AppTextStyles.pageTitle),
            const SizedBox(height: 6),
            const Text(
              'Оберіть покупку, на яку хочете подати гарантійне звернення.',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(14),
              radius: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Назва товару',
                      controller: _searchController,
                      icon: Icons.search,
                      hintText: 'Пошук за назвою',
                      textInputAction: TextInputAction.search,
                      onChanged: (search) => setState(
                        () => _draft = _draft.copyWith(search: search),
                      ),
                      onFieldSubmitted: (_) => _apply(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Статус гарантії',
                          style: AppTextStyles.label,
                        ),
                        const SizedBox(height: 7),
                        DropdownButtonFormField<WarrantyStatus>(
                          key: ValueKey(_draft.status),
                          initialValue: _draft.status,
                          isExpanded: true,
                          style: AppTextStyles.body,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.inputBorder,
                              ),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<WarrantyStatus>(
                              value: null,
                              child: Text('Усі статуси'),
                            ),
                            for (final WarrantyStatus status
                                in WarrantyStatus.values)
                              DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              ),
                          ],
                          onChanged: (status) => setState(
                            () => _draft = _draft.copyWith(
                              status: status,
                              clearStatus: status == null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  AppButton(
                    label: 'Фільтрувати',
                    icon: Icons.filter_list,
                    variant: AppButtonVariant.secondary,
                    onPressed: _apply,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: AppCard(
                padding: EdgeInsets.zero,
                radius: 12,
                shadow: false,
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      color: AppColors.background,
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 28,
                            child: Text(
                              'ТОВАР / ПРОДАВЕЦЬ',
                              style: _headerStyle,
                            ),
                          ),
                          Expanded(
                            flex: 10,
                            child: Text('ПОКУПКА', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 32,
                            child: Text('ДЕТАЛІ', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 19,
                            child: Text('ГАРАНТІЯ', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 11,
                            child: Text('ВИБІР', style: _headerStyle),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(
                              child: Text(
                                'Нічого не знайдено',
                                style: AppTextStyles.sectionTitle,
                              ),
                            )
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final Purchase purchase = items[index];
                                final bool expired =
                                    purchase.status(now) ==
                                    WarrantyStatus.expired;
                                final bool chosen = purchase.id == _selectedId;
                                return InkWell(
                                  onTap: expired
                                      ? null
                                      : () => setState(
                                          () => _selectedId = purchase.id,
                                        ),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 104,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: chosen
                                          ? AppColors.primaryLight
                                          : AppColors.surface,
                                      border: const Border(
                                        bottom: BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 28,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                purchase.productName,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.bodyStrong,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                purchase.store,
                                                style: AppTextStyles.caption,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 10,
                                          child: Text(
                                            formatDate(purchase.purchaseDate),
                                            style: AppTextStyles.small,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 32,
                                          child: Text(
                                            '${purchase.category.label} · ${formatPrice(purchase.price)}',
                                            style: AppTextStyles.small,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 19,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: StatusBadge(
                                              label:
                                                  'до ${formatDate(purchase.warrantyUntil)}',
                                              tone: switch (purchase.status(
                                                now,
                                              )) {
                                                WarrantyStatus.active =>
                                                  StatusTone.success,
                                                WarrantyStatus.expiringSoon =>
                                                  StatusTone.warning,
                                                WarrantyStatus.expired =>
                                                  StatusTone.error,
                                              },
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 11,
                                          child: Tooltip(
                                            message: expired
                                                ? 'Гарантія завершилась'
                                                : '',
                                            child: TextButton(
                                              onPressed: expired
                                                  ? null
                                                  : () => setState(
                                                      () => _selectedId =
                                                          purchase.id,
                                                    ),
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: Text(
                                                chosen ? '✓ Обрано' : 'Обрати',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selected == null
                          ? 'Покупку не обрано'
                          : 'Обрано: ${selected.productName}',
                      style: AppTextStyles.small,
                    ),
                  ),
                  AppButton(
                    label: 'Скасувати',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  Opacity(
                    opacity: selected == null ? 0.45 : 1,
                    child: AppButton(
                      label: 'Продовжити',
                      icon: Icons.check,
                      onPressed: selected == null
                          ? null
                          : () => Navigator.of(context)
                                .pushReplacementNamed<Claim, dynamic>(
                                  AppRoutes.claimCreate,
                                  arguments: selected.id,
                                ),
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

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );
}
