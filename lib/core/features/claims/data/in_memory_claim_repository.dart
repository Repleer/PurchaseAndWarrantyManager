import '../../../data/data_failure.dart';
import '../domain/claim.dart';
import 'claim_repository.dart';
import 'claims_mock_data.dart';

/// Звернення в пам'яті з ізоляцією даних і номерів за користувачем.
class InMemoryClaimRepository implements ClaimRepository {
  InMemoryClaimRepository({
    this.latency = const Duration(milliseconds: 400),
    this.failWhen,
  });

  final Duration latency;
  final bool Function()? failWhen;
  final Map<String, List<Claim>> _byUser = {};
  final Map<String, int> _lastIssuedNumberByUser = {};

  List<Claim> _items(String userId) =>
      _byUser.putIfAbsent(userId, () => List<Claim>.of(ClaimsMockData.items));

  Future<void> _waitAndCheckFailure() async {
    await Future<void>.delayed(latency);
    if (failWhen?.call() ?? false) {
      throw const DataFailure('Не вдалося завантажити дані. Спробуйте ще раз.');
    }
  }

  @override
  Future<List<Claim>> fetchAll({required String userId}) async {
    await _waitAndCheckFailure();
    return List<Claim>.unmodifiable(_items(userId));
  }

  @override
  Future<Claim> create({required String userId, required Claim claim}) async {
    await _waitAndCheckFailure();
    final List<Claim> items = _items(userId);
    if (items.any((item) => item.id == claim.id)) {
      throw const DataFailure('Запис уже існує');
    }
    items.add(claim);
    return claim;
  }

  @override
  Future<Claim> update({required String userId, required Claim claim}) async {
    await _waitAndCheckFailure();
    final List<Claim> items = _items(userId);
    final int index = items.indexWhere((item) => item.id == claim.id);
    if (index < 0) throw const DataFailure('Запис не знайдено');
    items[index] = claim;
    return claim;
  }

  @override
  Future<void> delete({required String userId, required String claimId}) async {
    await _waitAndCheckFailure();
    final List<Claim> items = _items(userId);
    final int index = items.indexWhere((item) => item.id == claimId);
    if (index < 0) throw const DataFailure('Запис не знайдено');
    items.removeAt(index);
  }

  @override
  Future<String> nextNumber({required String userId}) async {
    await _waitAndCheckFailure();
    final int highestInRecords = _items(userId)
        .map((claim) => int.tryParse(claim.number.split('-').last) ?? 0)
        .fold(
          0,
          (int previous, int value) => value > previous ? value : previous,
        );
    final int lastIssued = _lastIssuedNumberByUser[userId] ?? 0;
    final int next =
        (highestInRecords > lastIssued ? highestInRecords : lastIssued) + 1;
    _lastIssuedNumberByUser[userId] = next;
    return 'ГВ-${DateTime.now().year}-${next.toString().padLeft(3, '0')}';
  }
}
