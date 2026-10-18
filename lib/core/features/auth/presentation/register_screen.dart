import 'package:flutter/material.dart';
import 'package:warranty_manager/core/core.dart';
import 'package:warranty_manager/features/auth/presentation/widgets/auth_header.dart';
import 'package:warranty_manager/features/auth/presentation/widgets/auth_layout.dart';
import 'package:warranty_manager/features/auth/presentation/widgets/google_auth_section.dart';

/// Екран реєстрації (ФВ-1): email + пароль або реєстрація через Google.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController =
      TextEditingController(text: 'marta.ivanenko@example.com');
  final TextEditingController _passwordController =
      TextEditingController(text: '1234567890');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
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
              title: 'Реєстрація',
              subtitle: 'Створіть обліковий запис за допомогою email і пароля.',
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Email',
              controller: _emailController,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Пароль',
              controller: _passwordController,
              icon: Icons.lock_outline,
              helperText: 'Щонайменше 8 символів.',
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: Validators.password,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Створити акаунт',
              icon: Icons.person_add_alt_1_outlined,
              expanded: true,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
            GoogleAuthSection(
              dividerLabel: 'або',
              buttonLabel: 'Реєстрація через Google',
              spacing: 12,
              onPressed: () => navigator.pushNamed(AppRoutes.googleAccount),
            ),
            const SizedBox(height: 20),
            LinkRow(
              text: 'Вже є обліковий запис?',
              linkText: 'Увійти',
              onTap: () => navigator.pushReplacementNamed(AppRoutes.login),
            ),
            const SizedBox(height: 12),
            LinkRow(
              text: 'Забули пароль?',
              linkText: 'Відновити пароль',
              onTap: () =>
                  navigator.pushReplacementNamed(AppRoutes.forgotPassword),
            ),
          ],
        ),
      ),
    );
  }
}
