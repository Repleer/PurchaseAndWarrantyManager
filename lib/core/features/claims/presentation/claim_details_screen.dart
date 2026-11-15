import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../purchases/application/purchases_controller.dart';
import '../../purchases/domain/purchase.dart';
import '../application/claims_controller.dart';
import '../domain/claim.dart';
import 'claim_details_args.dart';
import 'widgets/attachment_thumbnail.dart';
import 'widgets/claim_status_badge.dart';
import 'widgets/claim_timeline.dart';

/// Деталі звернення з фото, історією та одноразовим повідомленням.
class ClaimDetailsScreen extends StatefulWidget {
  const ClaimDetailsScreen({super.key, required this.args});

  final ClaimDetailsArgs args;

  @override
  State<ClaimDetailsScreen> createState() => _ClaimDetailsScreenState();
}

class _ClaimDetailsScreenState extends State<ClaimDetailsScreen> {
  Timer? _toastTimer;
  late bool _showToast;

  @override
  void initState() {
    super.initState();
    _showToast = widget.args.justCreated;
    if (_showToast) {
      _toastTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showToast = false);
      });
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _withdraw() async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Відкликати звернення?'),
            content: const Text('Підтвердіть відкликання звернення.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Скасувати'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Відкликати'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    final ClaimsController controller = context.read<ClaimsController>();
    final bool withdrawn = await controller.withdraw(widget.args.claimId);
    if (!mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (withdrawn) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.claims);
      messenger.showSnackBar(
        const SnackBar(content: Text('Звернення відкликано')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Не вдалося відкликати звернення.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Claim? selected = context.select<ClaimsController, Claim?>(
      (controller) => controller.byId(widget.args.claimId),
    );
    if (selected == null) {
      return const AppShell.main(
        selectedIndex: 2,
        child: Center(
          child: Text(
            'Звернення не знайдено',
            style: AppTextStyles.sectionTitle,
          ),
        ),
      );
    }
    final Claim claim = selected;
    final Purchase? purchase = context.select<PurchasesController, Purchase?>(
      (controller) => controller.byId(claim.purchaseId),
    );

    return AppShell.main(
      selectedIndex: 2,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(40, 28, 40, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Деталі звернення',
                            style: AppTextStyles.pageTitle,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Звернення № ${claim.number} · створено '
                            '${formatDate(claim.createdAt)} о '
                            '${claim.createdAt.hour.toString().padLeft(2, '0')}:'
                            '${claim.createdAt.minute.toString().padLeft(2, '0')}',
                            style: AppTextStyles.small,
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'Змінити',
                      icon: Icons.edit_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed<Claim>(AppRoutes.claimEdit, arguments: claim),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _withdraw,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.errorBackground,
                        foregroundColor: AppColors.error,
                        minimumSize: const Size(44, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Відкликати'),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: 'Мої звернення',
                      icon: Icons.arrow_back,
                      variant: AppButtonVariant.secondary,
                      onPressed: () =>
                          Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.claims),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  radius: 12,
                  onTap: purchase == null
                      ? null
                      : () => Navigator.of(context).pushNamed(
                          AppRoutes.purchaseDetails,
                          arguments: purchase.id,
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        purchase == null
                            ? 'Покупку не знайдено'
                            : '${purchase.productName} · ${purchase.store} · '
                                  'гарантія до ${formatDate(purchase.warrantyUntil)}',
                        style: AppTextStyles.cardTitle,
                      ),
                      if (purchase != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Дата покупки: ${formatDate(purchase.purchaseDate)} · '
                          'Термін гарантії: ${formatMonths(purchase.warrantyMonths)}',
                          style: AppTextStyles.small,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 634,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 65,
                        child: _ClaimInfoCard(claim: claim, purchase: purchase),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 35,
                        child: _ClaimHistoryCard(entries: claim.history),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showToast)
            Positioned(
              bottom: 24,
              right: 40,
              child: Material(
                color: const Color(0xFFEEFAF5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.success),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Звернення успішно надіслано',
                        style: TextStyle(color: AppColors.success),
                      ),
                      IconButton(
                        tooltip: 'Закрити повідомлення',
                        icon: const Icon(Icons.close, size: 16),
                        color: AppColors.success,
                        onPressed: () => setState(() => _showToast = false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Поля звернення й мініатюри матеріалів дефекту.
class _ClaimInfoCard extends StatelessWidget {
  const _ClaimInfoCard({required this.claim, required this.purchase});

  final Claim claim;
  final Purchase? purchase;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Інформація про звернення',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text('Поточний статус', style: AppTextStyles.small),
            ),
            ClaimStatusBadge(status: claim.status),
          ],
        ),
        const SizedBox(height: 14),
        _dataRow('Дата несправності', formatDate(claim.defectDate)),
        _dataRow('Серійний номер', claim.serialNumber),
        _dataRow('Продавець', purchase?.store ?? 'Невідомо'),
        const SizedBox(height: 16),
        const Text('Опис проблеми', style: AppTextStyles.cardTitle),
        const SizedBox(height: 8),
        Text(claim.description, style: AppTextStyles.body),
        const SizedBox(height: 16),
        const Text('Фото / відео дефекту', style: AppTextStyles.cardTitle),
        const SizedBox(height: 12),
        if (claim.attachments.isEmpty)
          const Text('Матеріали не додано', style: AppTextStyles.small)
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final ClaimAttachment attachment in claim.attachments)
                AttachmentThumbnail(attachment: attachment),
            ],
          ),
      ],
    ),
  );

  Widget _dataRow(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        Expanded(flex: 30, child: Text(label, style: AppTextStyles.caption)),
        Expanded(flex: 70, child: Text(value, style: AppTextStyles.bodyStrong)),
      ],
    ),
  );
}

/// Історія звернення з інформаційним блоком унизу.
class _ClaimHistoryCard extends StatelessWidget {
  const _ClaimHistoryCard({required this.entries});

  final List<ClaimHistoryEntry> entries;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Історія звернення', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 18),
        Expanded(
          child: SingleChildScrollView(
            primary: false,
            child: ClaimTimeline(entries: entries),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Повідомимо вас, щойно статус звернення зміниться.',
            style: AppTextStyles.small,
          ),
        ),
      ],
    ),
  );
}
