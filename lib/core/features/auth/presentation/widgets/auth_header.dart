import 'package:flutter/material.dart';
import 'package:warranty_manager/core/core.dart';

/// Заголовок форми: назва (20 px, Bold) та пояснення (13 px).
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        const SizedBox(height: 6),
        Text(subtitle, style: AppTextStyles.small.copyWith(height: 1.45)),
      ],
    );
  }
}
