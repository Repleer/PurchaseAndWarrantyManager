import 'package:flutter/material.dart';
import 'package:warranty_manager/core/theme/app_colors.dart';

/// Варіанти оформлення кнопки.
enum AppButtonVariant {
  /// Заповнена синя кнопка («Увійти», «Зберегти»).
  primary,

  /// Біла кнопка з рамкою («Оновити фото», «Скасувати»).
  secondary,

  /// Текстова кнопка без фону («Створити», «Деталі»).
  ghost,
}

/// Стилізована кнопка дій: висота 44, радіус 12, мінімальна ширина 44.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.variant = AppButtonVariant.primary,
    this.expanded = false,
    this.fontWeight = FontWeight.w400,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Піктограма перед підписом (розмір 18).
  final IconData? icon;

  /// Довільний віджет перед підписом; має пріоритет над [icon].
  final Widget? leading;

  final AppButtonVariant variant;

  /// Розтягнути кнопку на всю доступну ширину.
  final bool expanded;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, Color borderColor) =
        switch (variant) {
      AppButtonVariant.primary => (
          AppColors.primary,
          Colors.white,
          AppColors.primary,
        ),
      AppButtonVariant.secondary => (
          Colors.white,
          AppColors.textPrimary,
          AppColors.inputBorder,
        ),
      AppButtonVariant.ghost => (
          Colors.transparent,
          AppColors.primary,
          Colors.transparent,
        ),
    };

    final Widget? prefix =
        leading ?? (icon == null ? null : Icon(icon, size: 18, color: foreground));

    final Widget button = Material(
      color: background,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (prefix != null) ...[prefix, const SizedBox(width: 8)],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: fontWeight,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
