import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

/// Екран керування профілем (ФВ-2): фото та зміна пароля.
/// Дані захардкоджені ([MockUser]); збереження лише імітується.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _oldController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _saved = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _save() {
    final bool valid = _formKey.currentState!.validate();
    if (valid) {
      _oldController.clear();
      _newController.clear();
      _confirmController.clear();
    }
    setState(() => _saved = valid);
  }

  void _hideFeedback(String _) {
    if (_saved) setState(() => _saved = false);
  }

  void _updatePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Вибір фото профілю буде реалізовано в наступних роботах.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell.main(
      selectedIndex: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 36, 40, 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 360, child: _buildProfileCard()),
            const SizedBox(width: 24),
            Expanded(child: _buildPasswordCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return AppCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const ProfileAvatar(initials: MockUser.initials),
          const SizedBox(height: 24),
          const Text(MockUser.email, style: AppTextStyles.cardTitle),
          const SizedBox(height: 8),
          Text(
            'JPG або PNG для нового фото профілю.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small.copyWith(height: 1.4),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Оновити фото',
            icon: Icons.add_photo_alternate_outlined,
            variant: AppButtonVariant.secondary,
            expanded: true,
            onPressed: _updatePhoto,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return AppCard(
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Змінити пароль', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 6),
              const Text(
                'Підтвердьте поточний пароль і введіть новий.',
                style: AppTextStyles.small,
              ),
              const SizedBox(height: 22),
              AppTextField(
                label: 'Старий пароль',
                controller: _oldController,
                icon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    Validators.requiredField(value, 'Введіть старий пароль.'),
                onChanged: _hideFeedback,
              ),
              const SizedBox(height: 15),
              AppTextField(
                label: 'Новий пароль',
                controller: _newController,
                icon: Icons.vpn_key_outlined,
                helperText: 'Щонайменше 8 символів.',
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: Validators.password,
                onChanged: _hideFeedback,
              ),
              const SizedBox(height: 15),
              AppTextField(
                label: 'Підтвердження нового пароля',
                controller: _confirmController,
                icon: Icons.vpn_key_outlined,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    Validators.confirmation(value, _newController.text),
                onChanged: _hideFeedback,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _saved
                        ? const FeedbackBanner(message: 'Зміни профілю збережено.')
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'Зберегти',
                    icon: Icons.check,
                    onPressed: _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
