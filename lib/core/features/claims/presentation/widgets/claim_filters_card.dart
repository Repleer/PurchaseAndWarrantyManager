import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../application/claims_controller.dart';
import '../../domain/claim.dart';
import '../../domain/claim_query.dart';

/// Чернетка фільтрів звернень із локальним контролером поля пошуку.
class ClaimFiltersCard extends StatefulWidget {
  const ClaimFiltersCard({super.key});

  @override
  State<ClaimFiltersCard> createState() => _ClaimFiltersCardState();
}

class _ClaimFiltersCardState extends State<ClaimFiltersCard> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ClaimQuery query = context.select<ClaimsController, ClaimQuery>(
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
              label: 'Товар',
              controller: _searchController,
              icon: Icons.search,
              hintText: 'Пошук за назвою',
              textInputAction: TextInputAction.search,
              onChanged: (search) => context
                  .read<ClaimsController>()
                  .updateDraft((query) => query.copyWith(search: search)),
              onFieldSubmitted: (_) =>
                  context.read<ClaimsController>().applyFilters(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Статус', style: AppTextStyles.label),
                const SizedBox(height: 7),
                DropdownButtonFormField<ClaimStatus>(
                  key: ValueKey(query.status),
                  initialValue: query.status,
                  isExpanded: true,
                  style: AppTextStyles.body,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
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
                    const DropdownMenuItem<ClaimStatus>(
                      value: null,
                      child: Text('Усі статуси'),
                    ),
                    for (final ClaimStatus status in ClaimStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: (status) =>
                      context.read<ClaimsController>().updateDraft(
                        (query) => query.copyWith(
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
            onPressed: () => context.read<ClaimsController>().applyFilters(),
          ),
        ],
      ),
    );
  }
}
