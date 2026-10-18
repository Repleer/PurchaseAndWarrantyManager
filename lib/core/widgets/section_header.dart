import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

/// Заголовок секції з необов’язковим поясненням праворуч.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        if (trailing != null) Text(trailing!, style: AppTextStyles.small),
      ],
    );
  }
}
