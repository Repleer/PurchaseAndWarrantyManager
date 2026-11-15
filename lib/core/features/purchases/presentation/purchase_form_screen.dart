import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../application/purchases_controller.dart';
import '../domain/purchase.dart';

/// Форма створення або редагування покупки через PurchasesController.
class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({super.key, this.initial});

  final Purchase? initial;

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _product;
  late final TextEditingController _store;
  late final TextEditingController _price;
  late final TextEditingController _notes;
  late DateTime _purchaseDate;
  late PurchaseCategory _category;
  late int _months;
  String? _receipt;
  String? _warranty;
  String? _failureMessage;

  static const List<int> _terms = [6, 12, 24, 36, 48, 60];

  @override
  void initState() {
    super.initState();
    final Purchase? initial = widget.initial;
    _product = TextEditingController(text: initial?.productName ?? '');
    _store = TextEditingController(text: initial?.store ?? '');
    _price = TextEditingController(
      text: initial == null
          ? ''
          : initial.price == initial.price.roundToDouble()
          ? initial.price.toStringAsFixed(0)
          : initial.price.toStringAsFixed(2),
    );
    _notes = TextEditingController(text: initial?.notes ?? '');
    _purchaseDate = initial?.purchaseDate ?? DateTime.now();
    _category = initial?.category ?? PurchaseCategory.electronics;
    _months = initial?.warrantyMonths ?? 24;
    _receipt = initial?.receiptFileName;
    _warranty = initial?.warrantyFileName;
  }

  @override
  void dispose() {
    _product.dispose();
    _store.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime get _warrantyUntil => Purchase(
    id: '',
    productName: '',
    store: '',
    category: _category,
    purchaseDate: _purchaseDate,
    price: 0,
    warrantyMonths: _months,
  ).warrantyUntil;

  Future<void> _pickDate() async {
    final DateTime today = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate.isAfter(today) ? today : _purchaseDate,
      firstDate: DateTime(1990),
      lastDate: today,
      helpText: 'Оберіть дату покупки',
      cancelText: 'Скасувати',
      confirmText: 'Підтвердити',
      fieldLabelText: 'Дата покупки',
      errorFormatText: 'Неправильний формат дати',
      errorInvalidText: 'Дата не може бути в майбутньому',
    );
    if (date != null && mounted) setState(() => _purchaseDate = date);
  }

  void _pickDemoFile({required bool receipt}) {
    final String date =
        '${_purchaseDate.day.toString().padLeft(2, '0')}'
        '${_purchaseDate.month.toString().padLeft(2, '0')}'
        '${(_purchaseDate.year % 100).toString().padLeft(2, '0')}';
    String slug(String value) => value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\wа-яіїєґʼ’-]'), '');
    setState(() {
      if (receipt) {
        _receipt =
            'receipt_${slug(_store.text.isEmpty ? 'магазин' : _store.text)}_$date.pdf';
      } else {
        _warranty =
            'warranty_${slug(_product.text.isEmpty ? 'товар' : _product.text)}_${_months}m.jpg';
      }
    });
  }

  void _camera() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Камера доступна лише на мобільних пристроях'),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_failureMessage != null) {
      setState(() => _failureMessage = null);
    }
    final Purchase result = Purchase(
      id: widget.initial?.id ?? 'p${DateTime.now().microsecondsSinceEpoch}',
      productName: _product.text.trim(),
      store: _store.text.trim(),
      category: _category,
      purchaseDate: _purchaseDate,
      price: double.parse(
        _price.text.replaceAll(RegExp(r'[\s₴]'), '').replaceAll(',', '.'),
      ),
      warrantyMonths: _months,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      serialNumber: widget.initial?.serialNumber,
      receiptFileName: _receipt,
      warrantyFileName: _warranty,
    );
    final PurchasesController controller = context.read<PurchasesController>();
    final bool saved = widget.initial == null
        ? await controller.add(result)
        : await controller.update(result);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(result);
    } else {
      setState(() {
        _failureMessage =
            controller.errorMessage ??
            'Не вдалося зберегти покупку. Спробуйте ще раз.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell.main(
      selectedIndex: 1,
      child: Semantics(
        label: widget.initial == null
            ? 'Створення покупки'
            : 'Редагування покупки',
        explicitChildNodes: true,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(40, 28, 40, 36),
            child: SizedBox(
              height: math.max(760, constraints.maxHeight - 64),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 65, child: _detailsCard()),
                    const SizedBox(width: 20),
                    Expanded(flex: 35, child: _documentsCard()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsCard() => AppCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Дані покупки', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 4),
        const Text(
          'Заповніть дані про товар, магазин і гарантію.',
          style: AppTextStyles.small,
        ),
        const SizedBox(height: 16),
        _twoColumns(
          _input('Назва товару', _product, validator: Validators.requiredField),
          _input(
            'Магазин / продавець',
            _store,
            validator: Validators.requiredField,
          ),
        ),
        const SizedBox(height: 14),
        _twoColumns(
          _dropdown<PurchaseCategory>(
            'Категорія',
            value: _category,
            values: PurchaseCategory.values,
            labelOf: (value) => value.label,
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          _field(
            'Дата покупки',
            TextFormField(
              key: ValueKey(_purchaseDate),
              initialValue: formatDate(_purchaseDate),
              readOnly: true,
              onTap: _pickDate,
              style: AppTextStyles.body,
              decoration: _decoration(
                prefixIcon: Icons.calendar_today_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _twoColumns(
          _input(
            'Вартість',
            _price,
            validator: Validators.positivePrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffixText: '₴',
          ),
          _dropdown<int>(
            'Термін гарантії',
            value: _months,
            values: _terms,
            labelOf: formatMonths,
            onChanged: (value) {
              if (value != null) setState(() => _months = value);
            },
          ),
        ),
        const SizedBox(height: 14),
        _field(
          'Дата завершення гарантії',
          TextFormField(
            key: ValueKey(_warrantyUntil),
            initialValue: formatDate(_warrantyUntil),
            readOnly: true,
            style: AppTextStyles.body,
            decoration: _decoration(prefixIcon: Icons.event_available_outlined),
          ),
        ),
        const SizedBox(height: 14),
        _input(
          'Нотатки',
          _notes,
          validator: Validators.purchaseNotes,
          maxLines: 3,
          maxLength: 500,
        ),
      ],
    ),
  );

  Widget _documentsCard() => AppCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Документи', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 4),
        const Text(
          'Додайте фото або скан чека та гарантійного талона.',
          style: AppTextStyles.small,
        ),
        const SizedBox(height: 14),
        _documentZone('Чек', _receipt, receipt: true),
        const SizedBox(height: 14),
        _documentZone('Гарантійний документ', _warranty, receipt: false),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 17,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Збереження доступне офлайн. Після підключення дані синхронізуються.',
                  style: AppTextStyles.small,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_failureMessage != null) ...[
          FeedbackBanner(message: _failureMessage!, isError: true),
          const SizedBox(height: 14),
        ],
        // Стежимо лише за isSaving, щоб не перебудовувати інші частини форми.
        Builder(
          builder: (context) {
            final bool isSaving = context.select<PurchasesController, bool>(
              (controller) => controller.isSaving,
            );
            return AppButton(
              label: 'Зберегти',
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
              expanded: true,
              onPressed: isSaving ? null : _save,
            );
          },
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Скасувати'),
        ),
      ],
    ),
  );

  Widget _documentZone(
    String label,
    String? fileName, {
    required bool receipt,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.background,
      border: Border.all(color: AppColors.inputBorder),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.file_present_outlined,
              color: AppColors.primary,
              size: 30,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodyStrong),
                  const Text('JPG, PNG або PDF', style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          fileName ?? 'Файл не додано',
          style: AppTextStyles.small,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _documentAction(
                label: 'Камера',
                icon: Icons.camera_alt_outlined,
                onPressed: _camera,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _documentAction(
                label: 'Галерея / файл',
                icon: Icons.folder_open_outlined,
                onPressed: () => _pickDemoFile(receipt: receipt),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _twoColumns(Widget left, Widget right) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 14),
      Expanded(child: right),
    ],
  );

  Widget _field(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: 6),
      child,
    ],
  );

  InputDecoration _decoration({IconData? prefixIcon, String? suffixText}) =>
      InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18),
        suffixText: suffixText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        counterText: '',
      );

  Widget _documentAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) => Material(
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

  Widget _input(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? suffixText,
    int maxLines = 1,
    int? maxLength,
  }) => _field(
    label,
    TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: maxLength == null
          ? null
          : [LengthLimitingTextInputFormatter(maxLength)],
      style: AppTextStyles.body,
      decoration: _decoration(suffixText: suffixText),
    ),
  );

  Widget _dropdown<T>(
    String label, {
    required T value,
    required List<T> values,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) => _field(
    label,
    DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      style: AppTextStyles.body,
      decoration: _decoration(),
      items: [
        for (final T option in values)
          DropdownMenuItem<T>(
            value: option,
            child: Text(labelOf(option), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    ),
  );
}
