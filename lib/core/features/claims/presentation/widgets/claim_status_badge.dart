import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../domain/claim.dart';

/// Бейдж статусу звернення з кольорами макета.
class ClaimStatusBadge extends StatelessWidget {
  const ClaimStatusBadge({super.key, required this.status});

  final ClaimStatus status;

  @override
  Widget build(BuildContext context) => StatusBadge(
    label: status.label,
    tone: switch (status) {
      ClaimStatus.underReview => StatusTone.warning,
      ClaimStatus.inProgress => StatusTone.info,
      ClaimStatus.resolved => StatusTone.success,
      ClaimStatus.rejected => StatusTone.error,
    },
  );
}
