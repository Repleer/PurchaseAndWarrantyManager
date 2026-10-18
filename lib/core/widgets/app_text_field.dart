import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';


/// Стилізоване поле введення: підпис зверху, піктограма ліворуч, висота 44.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hintText,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hintText;

  /// Підказка під полем (наприклад, «Щонайменше 8 символів.»).
  final String? helperText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  static OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          style: AppTextStyles.body,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            hintText: hintText,
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 13, right: 10),
              child: Icon(icon, size: 17, color: AppColors.textSecondary),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 44,
            ),
            contentPadding: const EdgeInsets.fromLTRB(0, 12, 13, 12),
            border: _border(AppColors.inputBorder),
            enabledBorder: _border(AppColors.inputBorder),
            focusedBorder: _border(AppColors.primary, 1.5),
            errorBorder: _border(AppColors.error),
            focusedErrorBorder: _border(AppColors.error, 1.5),
            errorStyle: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 7),
          Text(helperText!, style: AppTextStyles.caption),
        ],
      ],
    );
  }
}
