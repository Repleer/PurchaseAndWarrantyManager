import 'package:flutter/material.dart';
import 'package:warranty_manager/core/theme/app_colors.dart';

/// Смуга зворотного зв’язку: успіх («Зміни профілю збережено.») або помилка.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({super.key, required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final Color foreground = isError ? AppColors.error : AppColors.success;
    final Color background =
        isError ? AppColors.errorBackground : AppColors.successBackground;

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, height: 1.35, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
