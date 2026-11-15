import '../domain/claim.dart';

/// Контракт доступу до звернень і виділення наступного номера.
abstract interface class ClaimRepository {
  Future<List<Claim>> fetchAll({required String userId});

  Future<Claim> create({required String userId, required Claim claim});

  Future<Claim> update({required String userId, required Claim claim});

  Future<void> delete({required String userId, required String claimId});

  Future<String> nextNumber({required String userId});
}
