import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../../data/load_status.dart';
import '../../purchases/application/purchases_controller.dart';
import '../../purchases/domain/purchase.dart';
import '../application/claims_controller.dart';
import '../domain/claim.dart';
import 'claim_details_args.dart';
import 'widgets/claim_filters_card.dart';
import 'widgets/claim_table_row.dart';

/// Таблиця звернень зі станом від ClaimsController.
class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) => AppShell.main(
    selectedIndex: 2,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(40, 28, 40, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Мої звернення', style: AppTextStyles.pageTitle),
                    SizedBox(height: 6),
                    Text(
                      'Стежте за розглядом гарантійних випадків і відповідями сервісу.',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Нове звернення',
                icon: Icons.add,
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamed(AppRoutes.claimPickPurchase),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const ClaimFiltersCard(),
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
                    child: Row(
                      children: [
                        const Expanded(
                          flex: ClaimTableColumns.product,
                          child: Text('ТОВАР', style: _headerStyle),
                        ),
                        Expanded(
                          flex: ClaimTableColumns.date,
                          child: _DateSortButton(),
                        ),
                        const Expanded(
                          flex: ClaimTableColumns.description,
                          child: Text('ОПИС', style: _headerStyle),
                        ),
                        const Expanded(
                          flex: ClaimTableColumns.status,
                          child: Text('СТАТУС', style: _headerStyle),
                        ),
                        const Expanded(
                          flex: ClaimTableColumns.actions,
                          child: Text('ДІЇ', style: _headerStyle),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Consumer<ClaimsController>(
                      builder: (context, controller, _) {
                        if (controller.status == LoadStatus.loading ||
                            controller.status == LoadStatus.initial) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (controller.status == LoadStatus.failure) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
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
                          );
                        }
                        final List<Purchase> purchases = context
                            .watch<PurchasesController>()
                            .items;
                        final Map<String, Purchase> purchasesById = {
                          for (final Purchase purchase in purchases)
                            purchase.id: purchase,
                        };
                        final List<Claim> claims = controller.visibleItems(
                          purchasesById,
                        );
                        if (claims.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Нічого не знайдено',
                                  style: AppTextStyles.sectionTitle,
                                ),
                                TextButton(
                                  onPressed: controller.resetFilters,
                                  child: const Text('Скинути фільтри'),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: claims.length,
                          itemBuilder: (context, index) {
                            final Claim claim = claims[index];
                            return ClaimTableRow(
                              claim: claim,
                              onView: () => Navigator.of(context).pushNamed(
                                AppRoutes.claimDetails,
                                arguments: ClaimDetailsArgs(claimId: claim.id),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final List<Purchase> purchases = context
                  .select<PurchasesController, List<Purchase>>(
                    (controller) => controller.items,
                  );
              final Map<String, Purchase> purchasesById = {
                for (final Purchase purchase in purchases)
                  purchase.id: purchase,
              };
              final (int count, int total) = context
                  .select<ClaimsController, (int, int)>(
                    (controller) => (
                      controller.visibleItems(purchasesById).length,
                      controller.totalCount,
                    ),
                  );
              return Text(
                'Показано $count із $total звернень',
                style: AppTextStyles.caption,
              );
            },
          ),
        ],
      ),
    ),
  );

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );
}

/// Кнопка сортування дати з точковою підпискою на напрямок.
class _DateSortButton extends StatelessWidget {
  const _DateSortButton();

  @override
  Widget build(BuildContext context) {
    final bool newestFirst = context.select<ClaimsController, bool>(
      (controller) => controller.appliedQuery.newestFirst,
    );
    return TextButton(
      onPressed: context.read<ClaimsController>().toggleDateSort,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        alignment: Alignment.centerLeft,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'ДАТА ${newestFirst ? '↓' : '↑'}',
        style: ClaimsScreen._headerStyle,
      ),
    );
  }
}
