/// Аргументи маршруту деталей звернення та одноразового тосту.
class ClaimDetailsArgs {
  const ClaimDetailsArgs({required this.claimId, this.justCreated = false});

  final String claimId;
  final bool justCreated;
}
