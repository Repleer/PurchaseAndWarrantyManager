import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../purchases/application/purchases_controller.dart';
import '../../purchases/domain/purchase.dart';
import '../application/claims_controller.dart';
import '../application/warranty_check_controller.dart';
import '../data/warranty_verification_service.dart';
import '../domain/claim.dart';
import 'claim_details_args.dart';
import 'widgets/attachment_thumbnail.dart';
import 'widgets/warranty_check_dialog.dart';

/// Екран форми зі своїм життєвим циклом перевірки гарантії.
class ClaimFormScreen extends StatelessWidget {
  const ClaimFormScreen({super.key, this.purchaseId, this.initial});

  final String? purchaseId;
  final Claim? initial;

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<WarrantyCheckController>(
        create: (context) => WarrantyCheckController(
          context.read<WarrantyVerificationService>(),
        ),
        child: _ClaimFormBody(purchaseId: purchaseId, initial: initial),
      );
}

/// Локальні поля й вкладення форми.
class _ClaimFormBody extends StatefulWidget {
  const _ClaimFormBody({this.purchaseId, this.initial});

  final String? purchaseId;
  final Claim? initial;

  @override
  State<_ClaimFormBody> createState() => _ClaimFormBodyState();
}

class _ClaimFormBodyState extends State<_ClaimFormBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _serial;
  late final TextEditingController _description;
  late DateTime _defectDate;
  late String? _purchaseId;
  late List<ClaimAttachment> _attachments;
  String? _verifiedSerial;
  String? _failureMessage;

  Purchase? get _purchase => _purchaseId == null
      ? null
      : context.read<PurchasesController>().byId(_purchaseId!);

  @override
  void initState() {
    super.initState();
    final Claim? initial = widget.initial;
    _purchaseId = initial?.purchaseId ?? widget.purchaseId;
    _serial = TextEditingController(
      text: initial?.serialNumber ?? _purchase?.serialNumber ?? '',
    );
    _description = TextEditingController(text: initial?.description ?? '');
    _defectDate = initial?.defectDate ?? DateTime.now();
    _attachments = List.of(initial?.attachments ?? []);
    if (initial?.warrantyVerified == true) {
      _verifiedSerial = _normalized(initial!.serialNumber);
    }
  }

  @override
  void dispose() {
    _serial.dispose();
    _description.dispose();
    super.dispose();
  }

  String _normalized(String value) =>
      value.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  void _selectPurchase(Purchase purchase) {
    setState(() {
      _purchaseId = purchase.id;
      _serial.text = purchase.serialNumber ?? '';
      _defectDate = DateTime.now();
      _verifiedSerial = null;
    });
    context.read<WarrantyCheckController>().reset();
  }

  Future<void> _pickDate() async {
    final Purchase? purchase = _purchase;
    if (purchase == null) return;
    final DateTime today = DateTime.now();
    final DateTime initial = _defectDate.isBefore(purchase.purchaseDate)
        ? purchase.purchaseDate
        : _defectDate.isAfter(today)
        ? today
        : _defectDate;
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: purchase.purchaseDate,
      lastDate: today,
      helpText: 'Дата виникнення несправності',
      cancelText: 'Скасувати',
      confirmText: 'Підтвердити',
    );
    if (selected != null && mounted) setState(() => _defectDate = selected);
  }

  void _showCheck() {
    final Purchase? purchase = _purchase;
    if (purchase == null) return;
    final WarrantyCheckController controller = context
        .read<WarrantyCheckController>();
    controller.run(purchase, _serial.text);
    showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          ChangeNotifierProvider<WarrantyCheckController>.value(
            value: controller,
            child: WarrantyCheckDialog(
              productName: purchase.productName,
              store: purchase.store,
              onRetry: () => controller.run(purchase, _serial.text),
            ),
          ),
    );
  }

  void _addAttachment() {
    final bool isImage = _attachments.length.isEven;
    final AttachmentKind kind = isImage
        ? AttachmentKind.image
        : AttachmentKind.video;
    final int index =
        _attachments.where((item) => item.kind == kind).length + 1;
    setState(
      () => _attachments.add(
        ClaimAttachment(
          fileName: isImage
              ? 'Фото дефекту $index.jpg'
              : 'Відео дефекту $index.mp4',
          kind: kind,
          sizeBytes: isImage ? 2516582 : 13421773,
        ),
      ),
    );
  }

  void _camera() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Камера доступна лише на мобільних пристроях'),
    ),
  );

  String get _attachmentCountLabel {
    final int count = _attachments.length;
    final int lastTwo = count % 100;
    final String noun = lastTwo >= 11 && lastTwo <= 14
        ? 'файлів'
        : switch (count % 10) {
            1 => 'файл',
            >= 2 && <= 4 => 'файли',
            _ => 'файлів',
          };
    return 'Додано $count $noun';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final Purchase? purchase = _purchase;
    if (purchase == null) return;
    final Claim? initial = widget.initial;
    final WarrantyCheckController check = context
        .read<WarrantyCheckController>();
    final bool alreadyVerified =
        initial?.warrantyVerified == true &&
        _verifiedSerial == _normalized(_serial.text) &&
        purchase.id == initial?.purchaseId;
    if ((check.result?.isValid != true && !alreadyVerified) ||
        (initial == null &&
            purchase.status(context.read<PurchasesController>().now) ==
                WarrantyStatus.expired)) {
      _showCheck();
      return;
    }
    if (_failureMessage != null) setState(() => _failureMessage = null);
    final DateTime now = DateTime.now();
    final Claim draft;
    if (initial != null) {
      draft = initial.copyWith(
        defectDate: _defectDate,
        serialNumber: _serial.text.trim(),
        description: _description.text.trim(),
        attachments: _attachments,
        warrantyVerified: true,
      );
    } else {
      draft = Claim(
        id: 'c${now.microsecondsSinceEpoch}',
        number: '',
        purchaseId: purchase.id,
        defectDate: _defectDate,
        serialNumber: _serial.text.trim(),
        description: _description.text.trim(),
        status: ClaimStatus.underReview,
        createdAt: now,
        updatedAt: now,
        attachments: _attachments,
        warrantyVerified: true,
        history: [
          ClaimHistoryEntry(
            title: 'Створено',
            at: now,
            note: 'Звернення успішно надіслано.',
            done: true,
          ),
          ClaimHistoryEntry(
            title: 'Гарантію перевірено',
            at: now,
            note: 'Гарантія чинна до ${formatDate(purchase.warrantyUntil)}.',
            done: true,
          ),
          ClaimHistoryEntry(
            title: 'На розгляді',
            at: now,
            note: 'Очікуємо на відповідь продавця.',
            done: false,
          ),
        ],
      );
    }
    final ClaimsController claims = context.read<ClaimsController>();
    if (initial == null) {
      final Claim? saved = await claims.submit(draft);
      if (!mounted) return;
      if (saved == null) {
        setState(
          () => _failureMessage =
              claims.errorMessage ??
              'Не вдалося надіслати звернення. Спробуйте ще раз.',
        );
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.claimDetails,
        arguments: ClaimDetailsArgs(claimId: saved.id, justCreated: true),
      );
    } else {
      final bool saved = await claims.update(draft);
      if (!mounted) return;
      if (!saved) {
        setState(
          () => _failureMessage =
              claims.errorMessage ??
              'Не вдалося зберегти звернення. Спробуйте ще раз.',
        );
        return;
      }
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(claims.byId(draft.id));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (messenger.mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Зміни збережено')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Purchase? purchase = _purchaseId == null
        ? null
        : context.select<PurchasesController, Purchase?>(
            (controller) => controller.byId(_purchaseId!),
          );
    return AppShell.main(
      selectedIndex: 2,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 28, 40, 36),
          child: SizedBox(
            height: constraints.maxHeight - 64 < 750
                ? 750
                : constraints.maxHeight - 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.initial == null
                      ? 'Заявити про гарантійний випадок'
                      : 'Редагування звернення',
                  style: AppTextStyles.pageTitle,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Оберіть покупку, опишіть несправність і додайте матеріали для розгляду звернення.',
                  style: AppTextStyles.small,
                ),
                const SizedBox(height: 18),
                _selector(purchase),
                const SizedBox(height: 20),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 65, child: _claimDataCard(purchase)),
                        const SizedBox(width: 20),
                        Expanded(flex: 35, child: _attachmentCard()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selector(Purchase? purchase) => LayoutBuilder(
    builder: (context, constraints) => MenuAnchor(
      menuChildren: [
        SizedBox(
          width: constraints.maxWidth - 2,
          height: 300,
          child: ListView(
            primary: false,
            children: [
              for (final Purchase item
                  in context.watch<PurchasesController>().items)
                if (item.status(context.read<PurchasesController>().now) !=
                    WarrantyStatus.expired)
                  MenuItemButton(
                    onPressed: () => _selectPurchase(item),
                    child: SizedBox(
                      width: constraints.maxWidth - 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.productName} · ${item.store} · '
                            'гарантія до ${formatDate(item.warrantyUntil)}',
                            style: AppTextStyles.bodyStrong,
                          ),
                          Text(
                            'Дата покупки: ${formatDate(item.purchaseDate)} · '
                            'Термін гарантії: ${formatMonths(item.warrantyMonths)}',
                            style: AppTextStyles.small,
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
      builder: (context, controller, child) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        radius: 12,
        onTap: widget.initial == null
            ? () => controller.isOpen ? controller.close() : controller.open()
            : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Оберіть покупку', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  Text(
                    purchase == null
                        ? 'Покупку не обрано'
                        : '${purchase.productName} · ${purchase.store} · '
                              'гарантія до ${formatDate(purchase.warrantyUntil)}',
                    style: AppTextStyles.cardTitle,
                  ),
                  if (purchase != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Дата покупки: ${formatDate(purchase.purchaseDate)} · '
                      'Термін гарантії: ${formatMonths(purchase.warrantyMonths)}',
                      style: AppTextStyles.small,
                    ),
                  ],
                ],
              ),
            ),
            if (widget.initial == null)
              Icon(
                controller.isOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    ),
  );

  Widget _claimDataCard(Purchase? purchase) => AppCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Дані звернення', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 16),
        _field(
          'Дата виникнення несправності',
          TextFormField(
            key: ValueKey(_defectDate),
            initialValue: formatDate(_defectDate),
            readOnly: true,
            onTap: _pickDate,
            validator: (_) =>
                purchase != null &&
                    (_defectDate.isBefore(
                          DateTime(
                            purchase.purchaseDate.year,
                            purchase.purchaseDate.month,
                            purchase.purchaseDate.day,
                          ),
                        ) ||
                        _defectDate.isAfter(DateTime.now()))
                ? 'Дата має бути в межах гарантійного випадку.'
                : null,
            style: AppTextStyles.body,
            decoration: _decoration(prefixIcon: Icons.calendar_today_outlined),
          ),
        ),
        const SizedBox(height: 14),
        _field(
          'Серійний номер',
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _serial,
                  validator: (value) => Validators.requiredField(
                    value,
                    'Введіть серійний номер.',
                  ),
                  onChanged: (_) {
                    _verifiedSerial = null;
                    context.read<WarrantyCheckController>().reset();
                  },
                  style: AppTextStyles.body,
                  decoration: _decoration(),
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                label: 'Перевірити гарантію',
                variant: AppButtonVariant.secondary,
                onPressed: purchase == null ? null : _showCheck,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _field(
          'Опис проблеми',
          TextFormField(
            controller: _description,
            maxLines: 5,
            maxLength: 1000,
            inputFormatters: [LengthLimitingTextInputFormatter(1000)],
            validator: Validators.claimDescription,
            style: AppTextStyles.body,
            decoration: _decoration().copyWith(counterText: ''),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Вкажіть, коли й за яких умов виникає несправність та що ви вже '
          'спробували зробити.',
          style: AppTextStyles.small,
        ),
        const Spacer(),
        if (_failureMessage != null) ...[
          FeedbackBanner(message: _failureMessage!, isError: true),
          const SizedBox(height: 10),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton(
              label: 'Скасувати',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 10),
            Builder(
              builder: (context) {
                final bool isSaving = context.select<ClaimsController, bool>(
                  (controller) => controller.isSaving,
                );
                return AppButton(
                  label: widget.initial == null
                      ? 'Надіслати звернення'
                      : 'Зберегти зміни',
                  icon: Icons.check,
                  leading: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : null,
                  onPressed: isSaving ? null : _submit,
                );
              },
            ),
          ],
        ),
      ],
    ),
  );

  Widget _attachmentCard() => AppCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Фото / відео дефекту', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.file_present_outlined,
                    color: AppColors.primary,
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Додайте фото або відео',
                          style: AppTextStyles.bodyStrong,
                        ),
                        Text('JPG, PNG, MP4', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Покажіть дефект або роботу товару.',
                style: AppTextStyles.small,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _smallAction(
                      'Камера',
                      Icons.camera_alt_outlined,
                      _camera,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _smallAction(
                      'Галерея / файл',
                      Icons.folder_open_outlined,
                      _addAttachment,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(_attachmentCountLabel, style: AppTextStyles.label),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            primary: false,
            child: Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                for (int i = 0; i < _attachments.length; i++)
                  SizedBox(
                    width: 150,
                    child: Stack(
                      children: [
                        AttachmentThumbnail(
                          attachment: _attachments[i],
                          width: 150,
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton(
                            tooltip: 'Видалити файл',
                            onPressed: () =>
                                setState(() => _attachments.removeAt(i)),
                            icon: const Icon(Icons.close, size: 16),
                            color: AppColors.error,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              minimumSize: const Size(28, 28),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Чек і гарантійний документ буде додано з даних покупки.',
            style: AppTextStyles.small,
          ),
        ),
      ],
    ),
  );

  Widget _smallAction(String label, IconData icon, VoidCallback onPressed) =>
      Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.inputBorder),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 42,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 17),
                    const SizedBox(width: 6),
                    Text(label, style: AppTextStyles.body),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _field(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: 6),
      child,
    ],
  );

  InputDecoration _decoration({IconData? prefixIcon}) => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColors.surface,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.inputBorder),
    ),
    counterText: '',
  );
}
