import '../../../utils/formatters.dart';
import '../../purchases/domain/purchase.dart';

/// Результат окремого критерію перевірки гарантії.
enum CheckItemState { passed, failed, unverified }

/// Незмінний рядок перевірки гарантійного документа.
class WarrantyCheckItem {
  const WarrantyCheckItem({
    required this.title,
    required this.detail,
    required this.state,
  });

  final String title;
  final String detail;
  final CheckItemState state;
}

/// Підсумок перевірки трьох ознак і терміну дії гарантії.
class WarrantyCheckResult {
  WarrantyCheckResult({
    required List<WarrantyCheckItem> items,
    required this.message,
    required this.warrantyActive,
  }) : items = List.unmodifiable(items);

  final List<WarrantyCheckItem> items;
  final String message;
  final bool warrantyActive;

  bool get isValid =>
      warrantyActive &&
      items.every((item) => item.state == CheckItemState.passed);
}

/// Перевіряє серійний номер, наявність документів та строк гарантії.
WarrantyCheckResult checkWarranty({
  required Purchase purchase,
  required String serialNumber,
  required DateTime now,
}) {
  String normalize(String value) =>
      value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  final bool serialMatches =
      purchase.serialNumber != null &&
      normalize(serialNumber).isNotEmpty &&
      normalize(serialNumber) == normalize(purchase.serialNumber!);
  final bool hasReceipt =
      serialMatches && (purchase.receiptFileName?.trim().isNotEmpty ?? false);
  final bool hasWarranty =
      serialMatches && (purchase.warrantyFileName?.trim().isNotEmpty ?? false);
  final bool warrantyActive = purchase.status(now) != WarrantyStatus.expired;
  final String date = formatDate(purchase.purchaseDate);
  final String until = formatDate(purchase.warrantyUntil);
  final List<WarrantyCheckItem> items = [
    WarrantyCheckItem(
      title: 'Серійний номер',
      detail: serialMatches
          ? '${purchase.serialNumber} · Збігається з документом'
          : '${serialNumber.trim().isEmpty ? '—' : serialNumber.trim()} · Не знайдено в реєстрі',
      state: serialMatches ? CheckItemState.passed : CheckItemState.failed,
    ),
    WarrantyCheckItem(
      title: 'Дата продажу',
      detail:
          '$date · ${hasReceipt ? 'Підтверджено чеком' : 'Не підтверджено'}',
      state: hasReceipt ? CheckItemState.passed : CheckItemState.unverified,
    ),
    WarrantyCheckItem(
      title: 'Печатка продавця',
      detail: hasWarranty
          ? 'Печатку на гарантійному талоні перевірено'
          : 'Потрібна повторна перевірка документа',
      state: hasWarranty ? CheckItemState.passed : CheckItemState.unverified,
    ),
  ];
  final String message;
  if (!serialMatches) {
    message =
        'Перевірте серійний номер і чіткість гарантійного документа та '
        'повторіть перевірку.';
  } else if (!warrantyActive) {
    message = 'Гарантія завершилась $until.';
  } else if (!hasReceipt || !hasWarranty) {
    message = 'Перевірте чек і гарантійний документ та повторіть перевірку.';
  } else {
    message =
        'Гарантія чинна до $until. Можна продовжити оформлення звернення.';
  }
  return WarrantyCheckResult(
    items: items,
    message: message,
    warrantyActive: warrantyActive,
  );
}
