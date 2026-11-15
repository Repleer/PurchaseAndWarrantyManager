import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../application/purchases_controller.dart';
import '../../domain/purchase.dart';
import '../../domain/purchase_query.dart';

/// Картка з чернеткою пошуку та фільтрів покупок.
class PurchaseFiltersCard extends StatefulWidget {
  const PurchaseFiltersCard({super.key});

  @override
  State<PurchaseFiltersCard> createState() => _PurchaseFiltersCardState();
}

class _PurchaseFiltersCardState extends State<PurchaseFiltersCard> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PurchaseQuery query = context
        .select<PurchasesController, PurchaseQuery>(
          (controller) => controller.draftQuery,
        );
    if (_searchController.text != query.search) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _searchController.text != query.search) {
          _searchController.value = TextEditingValue(
            text: query.search,
            selection: TextSelection.collapsed(offset: query.search.length),
          );
        }
      });
    }
    return AppCard(
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
              onChanged: (search) => context
                  .read<PurchasesController>()
                  .updateDraft((query) => query.copyWith(search: search)),
              onFieldSubmitted: (_) =>
                  context.read<PurchasesController>().applyFilters(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _FilterSelect<PurchaseCategory>(
              label: 'Категорія',
              allLabel: 'Усі категорії',
              value: query.category,
              options: PurchaseCategory.values,
              optionLabel: (value) => value.label,
              onChanged: (category) =>
                  context.read<PurchasesController>().updateDraft(
                    (query) => query.copyWith(
                      category: category,
                      clearCategory: category == null,
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _FilterSelect<WarrantyStatus>(
              label: 'Статус гарантії',
              allLabel: 'Усі статуси',
              value: query.status,
              options: WarrantyStatus.values,
              optionLabel: (value) => value.label,
              onChanged: (status) =>
                  context.read<PurchasesController>().updateDraft(
                    (query) => query.copyWith(
                      status: status,
                      clearStatus: status == null,
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 14),
          AppButton(
            label: 'Фільтрувати',
            icon: Icons.filter_list,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.read<PurchasesController>().applyFilters(),
          ),
        ],
      ),
    );
  }
}

/// Вибір одного значення фільтра або всіх значень.
class _FilterSelect<T> extends StatelessWidget {
  const _FilterSelect({
    required this.label,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  final String label;
  final String allLabel;
  final T? value;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.inputBorder),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 7),
        DropdownButtonFormField<T>(
          key: ValueKey(value),
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: AppTextStyles.body,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text(allLabel, overflow: TextOverflow.ellipsis),
            ),
            for (final T option in options)
              DropdownMenuItem<T>(
                value: option,
                child: Text(
                  optionLabel(option),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
