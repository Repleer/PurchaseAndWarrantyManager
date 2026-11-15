import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

/// Тони повідомлення для користувача.
enum FeedbackTone { success, warning, error }

/// Смуга повідомлення: успіх, попередження або помилка.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    super.key,
    required this.message,
    this.isError = false,
    this.tone,
    this.icon,
  });

  final String message;
  final bool isError;
  final FeedbackTone? tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final FeedbackTone selectedTone =
        tone ?? (isError ? FeedbackTone.error : FeedbackTone.success);
    final (
      Color foreground,
      Color background,
      IconData defaultIcon,
    ) = switch (selectedTone) {
      FeedbackTone.success => (
        AppColors.success,
        AppColors.successBackground,
        Icons.check_circle_outline,
      ),
      FeedbackTone.warning => (
        AppColors.warning,
        AppColors.warningBackground,
        Icons.notifications_none,
      ),
      FeedbackTone.error => (
        AppColors.error,
        AppColors.errorBackground,
        Icons.error_outline,
      ),
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon ?? defaultIcon, size: 18, color: foreground),
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
