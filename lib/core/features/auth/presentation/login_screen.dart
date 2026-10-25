import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/application/auth_controller.dart';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final AuthController controller = context.read<AuthController>();
    final bool succeeded = await controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!succeeded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.failureMessage ?? 'Не вдалося увійти.')),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    final AuthController controller = context.read<AuthController>();
    final bool succeeded = await controller.signInWithGoogle();
    if (!succeeded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.failureMessage ?? 'Не вдалося увійти через Google.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    final bool isLoading = context.watch<AuthController>().isLoading;

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
              validator: (value) =>
                  Validators.requiredField(value, 'Введіть пароль.'),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Увійти',
              icon: Icons.login,
              leading: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : null,
              expanded: true,
              onPressed: isLoading ? null : () => _submit(),
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
              isLoading: isLoading,
              onPressed: isLoading ? null : () => _signInWithGoogle(),
            ),
          ],
        ),
      ),
    );
  }
}
