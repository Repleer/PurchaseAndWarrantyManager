import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

/// Рядок «пояснення ліворуч — посилання праворуч»
/// (наприклад, «Забули пароль?» — «Відновити пароль»).
class LinkRow extends StatelessWidget {
  const LinkRow({
    super.key,
    required this.text,
    required this.linkText,
    required this.onTap,
  });

  final String text;
  final String linkText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(text, style: AppTextStyles.small)),
        const SizedBox(width: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Text(linkText, style: AppTextStyles.link),
        ),
      ],
    );
  }
}
