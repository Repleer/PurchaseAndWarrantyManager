import 'purchase.dart';

/// Поле впорядкування таблиці покупок.
enum PurchaseSortField { date, price, warranty }

/// Незмінні параметри пошуку, фільтрації й сортування.
class PurchaseQuery {
  const PurchaseQuery({
    this.search = '',
    this.category,
    this.status,
    this.sortField = PurchaseSortField.date,
    this.ascending = false,
  });

  final String search;
  final PurchaseCategory? category;
  final WarrantyStatus? status;
  final PurchaseSortField sortField;
  final bool ascending;

  /// Копіює запит; прапорці очищення мають пріоритет над значеннями фільтрів.
  PurchaseQuery copyWith({
    String? search,
    PurchaseCategory? category,
    WarrantyStatus? status,
    PurchaseSortField? sortField,
    bool? ascending,
    bool clearCategory = false,
    bool clearStatus = false,
  }) => PurchaseQuery(
    search: search ?? this.search,
    category: clearCategory ? null : category ?? this.category,
    status: clearStatus ? null : status ?? this.status,
    sortField: sortField ?? this.sortField,
    ascending: ascending ?? this.ascending,
  );
}

/// Повертає новий відфільтрований і відсортований список покупок.
List<Purchase> applyPurchaseQuery(
  List<Purchase> items,
  PurchaseQuery query,
  DateTime now,
) {
  final String search = query.search.trim().toLowerCase();
  final List<Purchase> result = items.where((purchase) {
    return (search.isEmpty ||
            purchase.productName.toLowerCase().contains(search) ||
            purchase.store.toLowerCase().contains(search)) &&
        (query.category == null || purchase.category == query.category) &&
        (query.status == null || purchase.status(now) == query.status);
  }).toList();

  result.sort((a, b) {
    final int order = switch (query.sortField) {
      PurchaseSortField.date => a.purchaseDate.compareTo(b.purchaseDate),
      PurchaseSortField.price => a.price.compareTo(b.price),
      PurchaseSortField.warranty => a.warrantyUntil.compareTo(b.warrantyUntil),
    };
    // Стабільний порядок для однакових значень колонки.
    if (order == 0) return a.id.compareTo(b.id);
    return query.ascending ? order : -order;
  });
  return result;
}
