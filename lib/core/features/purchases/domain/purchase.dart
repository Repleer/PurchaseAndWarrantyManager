/// Категорії покупок.
enum PurchaseCategory {
  electronics('Електроніка'),
  appliances('Побутова техніка'),
  computers("Комп'ютери"),
  phones('Телефони'),
  furniture('Меблі'),
  other('Інше');

  const PurchaseCategory(this.label);
  final String label;
}

/// Поточний стан гарантії.
enum WarrantyStatus {
  active('Діє'),
  expiringSoon('Скоро завершується'),
  expired('Завершилась');

  const WarrantyStatus(this.label);
  final String label;
}

/// Незмінний запис про покупку та її гарантію.
class Purchase {
  const Purchase({
    required this.id,
    required this.productName,
    required this.store,
    required this.category,
    required this.purchaseDate,
    required this.price,
    required this.warrantyMonths,
    this.notes,
    this.serialNumber,
    this.receiptFileName,
    this.warrantyFileName,
  });

  final String id;
  final String productName;
  final String store;
  final PurchaseCategory category;
  final DateTime purchaseDate;
  final double price;
  final int warrantyMonths;
  final String? notes;
  final String? serialNumber;
  final String? receiptFileName;
  final String? warrantyFileName;

  /// Додає календарні місяці, зберігаючи кінець коротшого місяця.
  DateTime get warrantyUntil {
    final int monthIndex = purchaseDate.month - 1 + warrantyMonths;
    final int year = purchaseDate.year + monthIndex ~/ 12;
    final int month = monthIndex % 12 + 1;
    final int lastDay = DateTime(year, month + 1, 0).day;
    final int day = purchaseDate.day.clamp(1, lastDay);
    return DateTime(year, month, day);
  }

  /// Кількість календарних днів до завершення гарантії.
  int daysLeft(DateTime now) {
    final DateTime until = warrantyUntil;
    return DateTime.utc(
      until.year,
      until.month,
      until.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  }

  /// Статус за залишком днів на вказану дату.
  WarrantyStatus status(DateTime now) {
    final int left = daysLeft(now);
    if (left < 0) return WarrantyStatus.expired;
    if (left <= 60) return WarrantyStatus.expiringSoon;
    return WarrantyStatus.active;
  }

  static const Object _unset = Object();

  /// Створює новий запис, дозволяючи також очищувати необов'язкові поля.
  Purchase copyWith({
    String? id,
    String? productName,
    String? store,
    PurchaseCategory? category,
    DateTime? purchaseDate,
    double? price,
    int? warrantyMonths,
    Object? notes = _unset,
    Object? serialNumber = _unset,
    Object? receiptFileName = _unset,
    Object? warrantyFileName = _unset,
  }) => Purchase(
    id: id ?? this.id,
    productName: productName ?? this.productName,
    store: store ?? this.store,
    category: category ?? this.category,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    price: price ?? this.price,
    warrantyMonths: warrantyMonths ?? this.warrantyMonths,
    notes: identical(notes, _unset) ? this.notes : notes as String?,
    serialNumber: identical(serialNumber, _unset)
        ? this.serialNumber
        : serialNumber as String?,
    receiptFileName: identical(receiptFileName, _unset)
        ? this.receiptFileName
        : receiptFileName as String?,
    warrantyFileName: identical(warrantyFileName, _unset)
        ? this.warrantyFileName
        : warrantyFileName as String?,
  );

  /// Перетворює покупку на JSON-сумісну мапу.
  Map<String, dynamic> toJson() => {
    'id': id,
    'productName': productName,
    'store': store,
    'category': category.name,
    'purchaseDate': purchaseDate.toIso8601String(),
    'price': price,
    'warrantyMonths': warrantyMonths,
    'notes': notes,
    'serialNumber': serialNumber,
    'receiptFileName': receiptFileName,
    'warrantyFileName': warrantyFileName,
  };

  /// Відновлює покупку з JSON-сумісної мапи.
  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
    id: json['id'] as String,
    productName: json['productName'] as String,
    store: json['store'] as String,
    category: PurchaseCategory.values.byName(json['category'] as String),
    purchaseDate: DateTime.parse(json['purchaseDate'] as String),
    price: (json['price'] as num).toDouble(),
    warrantyMonths: json['warrantyMonths'] as int,
    notes: json['notes'] as String?,
    serialNumber: json['serialNumber'] as String?,
    receiptFileName: json['receiptFileName'] as String?,
    warrantyFileName: json['warrantyFileName'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Purchase &&
          id == other.id &&
          productName == other.productName &&
          store == other.store &&
          category == other.category &&
          purchaseDate == other.purchaseDate &&
          price == other.price &&
          warrantyMonths == other.warrantyMonths &&
          notes == other.notes &&
          serialNumber == other.serialNumber &&
          receiptFileName == other.receiptFileName &&
          warrantyFileName == other.warrantyFileName;

  @override
  int get hashCode => Object.hash(
    id,
    productName,
    store,
    category,
    purchaseDate,
    price,
    warrantyMonths,
    notes,
    serialNumber,
    receiptFileName,
    warrantyFileName,
  );
}
