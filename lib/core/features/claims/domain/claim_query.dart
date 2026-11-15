import '../../purchases/domain/purchase.dart';
import 'claim.dart';

/// Незмінні параметри пошуку, фільтрації та впорядкування звернень.
class ClaimQuery {
  const ClaimQuery({this.search = '', this.status, this.newestFirst = true});

  final String search;
  final ClaimStatus? status;
  final bool newestFirst;

  /// Повертає запит із заданими змінами; статус можна скинути в null.
  ClaimQuery copyWith({
    String? search,
    ClaimStatus? status,
    bool clearStatus = false,
    bool? newestFirst,
  }) => ClaimQuery(
    search: search ?? this.search,
    status: clearStatus ? null : status ?? this.status,
    newestFirst: newestFirst ?? this.newestFirst,
  );
}

/// Фільтрує за назвою товару й статусом та сортує за датою подання.
List<Claim> applyClaimQuery(
  List<Claim> items,
  Map<String, Purchase> purchases,
  ClaimQuery query,
) {
  final String search = query.search.trim().toLowerCase();
  final List<Claim> result = items.where((claim) {
    final Purchase? purchase = purchases[claim.purchaseId];
    return (search.isEmpty ||
            (purchase?.productName.toLowerCase().contains(search) ?? false)) &&
        (query.status == null || claim.status == query.status);
  }).toList();
  result.sort((a, b) {
    final int comparison = a.createdAt.compareTo(b.createdAt);
    if (comparison == 0) return a.id.compareTo(b.id);
    return query.newestFirst ? -comparison : comparison;
  });
  return result;
}
