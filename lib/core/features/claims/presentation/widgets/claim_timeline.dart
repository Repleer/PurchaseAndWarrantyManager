import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../domain/claim.dart';

/// Вертикальна історія змін стану звернення.
class ClaimTimeline extends StatelessWidget {
  const ClaimTimeline({super.key, required this.entries});

  final List<ClaimHistoryEntry> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (int i = 0; i < entries.length; i++)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 30,
                child: Column(
                  children: [
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entries[i].done
                            ? AppColors.successBackground
                            : AppColors.warningBackground,
                      ),
                      child: Icon(
                        entries[i].done ? Icons.check : Icons.schedule,
                        color: entries[i].done
                            ? AppColors.success
                            : AppColors.warning,
                        size: 18,
                      ),
                    ),
                    if (i < entries.length - 1)
                      Expanded(
                        child: Container(width: 1, color: AppColors.border),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: i < entries.length - 1 ? 32 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(entries[i].title, style: AppTextStyles.bodyStrong),
                      const SizedBox(height: 4),
                      Text(
                        formatDateTime(entries[i].at),
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 5),
                      Text(entries[i].note, style: AppTextStyles.small),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
