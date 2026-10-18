import 'package:flutter/material.dart';
import 'package:warranty_manager/core/core.dart';
import 'package:warranty_manager/features/auth/presentation/widgets/auth_header.dart';
import 'package:warranty_manager/features/auth/presentation/widgets/auth_layout.dart';

/// Екран відновлення пароля (ФВ-1). Лист не надсилається — лише
/// відображається повідомлення про успішне надсилання.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController =
      TextEditingController(text: MockUser.email);

  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _sent = _formKey.currentState!.validate());
  }

  @override
  Widget build(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);

    return AuthLayout(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: 'Відновити пароль',
              subtitle: 'Вкажіть email облікового запису, і ми надішлемо лист '
                  'із посиланням для відновлення пароля.',
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Email',
              controller: _emailController,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: Validators.email,
              onChanged: (_) {
                if (_sent) setState(() => _sent = false);
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Скинути пароль',
              icon: Icons.send_outlined,
              expanded: true,
              onPressed: _submit,
            ),
            if (_sent) ...[
              const SizedBox(height: 20),
              FeedbackBanner(
                message:
                    'Лист із інструкцією надіслано на ${_emailController.text.trim()}.',
              ),
            ],
            const SizedBox(height: 20),
            LinkRow(
              text: 'Вже пам’ятаєте пароль?',
              linkText: 'Увійти',
              onTap: () => navigator.pushReplacementNamed(AppRoutes.login),
            ),
            const SizedBox(height: 12),
            LinkRow(
              text: 'Ще не маєте облікового запису?',
              linkText: 'Створити акаунт',
              onTap: () => navigator.pushReplacementNamed(AppRoutes.register),
            ),
          ],
        ),
      ),
    );
  }
}
