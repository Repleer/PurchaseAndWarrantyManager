import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/claims_mock_data.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/domain/claim.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/domain/claim_query.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/purchases_mock_data.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/domain/purchase.dart';

void main() {
  final List<Claim> claims = ClaimsMockData.items;
  final Map<String, Purchase> purchases = {
    for (final Purchase purchase in PurchasesMockData.items)
      purchase.id: purchase,
  };

  test('пошук за назвою товару не залежить від регістру', () {
    expect(
      applyClaimQuery(
        claims,
        purchases,
        const ClaimQuery(search: '  SONY  '),
      ).map((claim) => claim.id),
      ['c1'],
    );
    expect(
      applyClaimQuery(claims, purchases, const ClaimQuery(search: 'rozetka')),
      isEmpty,
    );
    expect(claims.length, 5);
  });

  test('фільтр за статусом і очищення фільтра', () {
    const ClaimQuery query = ClaimQuery(status: ClaimStatus.inProgress);
    expect(applyClaimQuery(claims, purchases, query).map((claim) => claim.id), [
      'c2',
      'c3',
    ]);
    expect(query.copyWith(clearStatus: true).status, isNull);
    expect(
      applyClaimQuery(claims, purchases, query.copyWith(clearStatus: true)),
      hasLength(5),
    );
    expect(
      applyClaimQuery(
        claims,
        purchases,
        const ClaimQuery(status: ClaimStatus.rejected),
      ),
      isEmpty,
    );
  });

  test('дата подання перемикається між спаданням та зростанням', () {
    expect(
      applyClaimQuery(claims, purchases, const ClaimQuery()).map((c) => c.id),
      ['c1', 'c2', 'c3', 'c4', 'c5'],
    );
    expect(
      applyClaimQuery(
        claims,
        purchases,
        const ClaimQuery(newestFirst: false),
      ).map((c) => c.id),
      ['c5', 'c4', 'c3', 'c2', 'c1'],
    );
    expect(
      applyClaimQuery(claims, purchases, const ClaimQuery()),
      isNot(same(claims)),
    );
  });

  test('за відсутності повʼязаної покупки пошук не знаходить звернення', () {
    expect(
      applyClaimQuery(claims, {}, const ClaimQuery(search: 'Sony')),
      isEmpty,
    );
    expect(applyClaimQuery(claims, {}, const ClaimQuery()), hasLength(5));
  });
}
