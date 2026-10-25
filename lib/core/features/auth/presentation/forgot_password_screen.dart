import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/application/auth_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/widgets/auth_header.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/widgets/auth_layout.dart';


/// Екран відновлення пароля (ФВ-1).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController =
      TextEditingController(text: MockUser.email);

  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final AuthController controller = context.read<AuthController>();
    final bool succeeded = await controller.sendPasswordResetEmail(
      email: _emailController.text,
    );
    if (!mounted) return;
    setState(() {
      _feedbackIsError = !succeeded;
      _feedbackMessage = succeeded
          ? 'Лист із інструкцією надіслано на ${_emailController.text.trim()}.'
          : controller.failureMessage ?? 'Не вдалося надіслати лист.';
    });
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
                if (_feedbackMessage != null) {
                  setState(() => _feedbackMessage = null);
                }
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Скинути пароль',
              icon: Icons.send_outlined,
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
              onPressed: isLoading ? null : _submit,
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 20),
              FeedbackBanner(
                message: _feedbackMessage!,
                isError: _feedbackIsError,
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
