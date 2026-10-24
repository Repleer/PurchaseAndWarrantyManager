import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/widgets/auth_header.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/widgets/auth_layout.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/widgets/google_auth_section.dart';


/// Екран входу (ФВ-1) з перевіркою демонстраційних облікових даних.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Демонстраційні значення, щоб екран збігався з макетом.
  final TextEditingController _emailController =
      TextEditingController(text: MockUser.email);
  final TextEditingController _passwordController =
      TextEditingController(text: '');

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
              title: 'Увійти',
              subtitle: 'Використайте email і пароль вашого облікового запису.',
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
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (value) {
                final String? requiredError =
                    Validators.requiredField(value, 'Введіть пароль.');
                if (requiredError != null) return requiredError;
                if (value != MockUser.password) return 'Неправильний логін або пароль.';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Увійти',
              icon: Icons.login,
              expanded: true,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
            LinkRow(
              text: 'Ще не маєте облікового запису?',
              linkText: 'Створити акаунт',
              onTap: () => navigator.pushReplacementNamed(AppRoutes.register),
            ),
            const SizedBox(height: 12),
            LinkRow(
              text: 'Забули пароль?',
              linkText: 'Відновити пароль',
              onTap: () =>
                  navigator.pushReplacementNamed(AppRoutes.forgotPassword),
            ),
            const SizedBox(height: 20),
            GoogleAuthSection(
              dividerLabel: 'або увійдіть за допомогою',
              buttonLabel: 'Увійти за допомогою Google',
              onPressed: () => navigator.pushNamed(AppRoutes.googleAccount),
            ),
          ],
        ),
      ),
    );
  }
}
