import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/application/auth_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/widgets/auth_layout.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/widgets/google_auth_section.dart';

/// Екран-перехід до справжньої автентифікації Google.
class GoogleAccountScreen extends StatelessWidget {
  const GoogleAccountScreen({super.key});

  Future<void> _signIn(BuildContext context) async {
    final AuthController controller = context.read<AuthController>();
    final bool succeeded = await controller.signInWithGoogle();
    if (!succeeded && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.failureMessage ?? 'Не вдалося увійти через Google.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(4),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Назад до входу або реєстрації',
                    style: AppTextStyles.link,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      GoogleLogo(size: 36),
                      SizedBox(width: 12),
                      Text(
                        'Вхід через Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Виберіть обліковий запис',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Щоб продовжити в застосунку «Менеджер гарантій і покупок», '
                    'виберіть свій обліковий запис Google.',
                    style: AppTextStyles.small.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Обліковий запис Google',
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 10),
                  _ChooserTile(
                    leading: const ProfileAvatar(
                      initials: MockUser.initials,
                      size: 44,
                    ),
                    title: MockUser.name,
                    subtitle: MockUser.email,
                    onTap: () => _signIn(context),
                  ),
                  const SizedBox(height: 8),
                  _ChooserTile(
                    leading: const SizedBox(
                      width: 44,
                      child: Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    title: 'Використати інший обліковий запис',
                    onTap: () => _signIn(context),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 17,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Google надасть застосунку ваше ім’я, електронну адресу '
                          'та фото профілю. Пароль Google не передається.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Виберіть обліковий запис, щоб продовжити.',
                          style: AppTextStyles.caption,
                        ),
                      ),
                      AppButton(
                        label: 'Скасувати',
                        variant: AppButtonVariant.secondary,
                        fontWeight: FontWeight.w600,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Рядок списку облікових записів Google.
class _ChooserTile extends StatelessWidget {
  const _ChooserTile({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.inputBorder),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTextStyles.caption),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
