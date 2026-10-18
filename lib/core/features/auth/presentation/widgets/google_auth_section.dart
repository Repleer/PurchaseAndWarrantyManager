import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

/// Логотип Google: синій квадрат із літерою «G» (як у макеті).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.google,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Text(
        'G',
        style: TextStyle(
          fontSize: size * 0.56,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Розділювач з написом та кнопка входу / реєстрації через Google.
class GoogleAuthSection extends StatelessWidget {
  const GoogleAuthSection({
    super.key,
    required this.dividerLabel,
    required this.buttonLabel,
    required this.onPressed,
    this.spacing = 16,
  });

  final String dividerLabel;
  final String buttonLabel;
  final VoidCallback onPressed;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: _DividerLine()),
            const SizedBox(width: 12),
            Text(
              dividerLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: _DividerLine()),
          ],
        ),
        SizedBox(height: spacing),
        AppButton(
          label: buttonLabel,
          variant: AppButtonVariant.secondary,
          expanded: true,
          fontWeight: FontWeight.w600,
          leading: const GoogleLogo(),
          onPressed: onPressed,
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.border);
  }
}
