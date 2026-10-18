import 'package:flutter/material.dart';
import 'package:warranty_manager/core/theme/app_colors.dart';

/// Тон бейджа статусу гарантії.
enum StatusTone { warning, success }

/// Заокруглений бейдж із кольоровим індикатором («17 днів»).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusTone.warning,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final bool isWarning = tone == StatusTone.warning;
    final Color foreground = isWarning ? AppColors.warning : AppColors.success;
    final Color background =
        isWarning ? AppColors.warningBackground : AppColors.successBackground;

    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: foreground)),
        ],
      ),
    );
  }
}
