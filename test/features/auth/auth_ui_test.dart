import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/features/analytics/data/analytics_service.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/application/auth_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/data/auth_failure.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/data/auth_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/forgot_password_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/login_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/register_screen.dart';
import 'package:warranty_and_purchase_manager/core/widgets/app_button.dart';

class _FailingAuthRepository extends Fake implements AuthRepository {
  @override
  Future<void> signIn({required String email, required String password}) async {
    throw const AuthFailure(
      'invalid-credential',
      'Неправильний email або пароль.',
    );
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    throw const AuthFailure(
      'email-already-in-use',
      'Цей email уже зареєстровано.',
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    throw const AuthFailure(
      'network-request-failed',
      'Немає з’єднання з інтернетом.',
    );
  }
}

class _Analytics extends Fake implements AnalyticsService {}

void main() {
  Future<void> show(WidgetTester tester, Widget screen) async {
    await tester.binding.setSurfaceSize(const Size(1200, 886));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = AuthController(_FailingAuthRepository(), _Analytics());
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: auth,
        child: MaterialApp(home: screen),
      ),
    );
  }

  testWidgets('вхід показує вибрану через select помилку без зміни маршруту', (
    tester,
  ) async {
    await show(tester, const LoginScreen());
    await tester.enterText(find.byType(TextFormField).last, 'Old12345');
    await tester.tap(find.widgetWithText(AppButton, 'Увійти'));
    await tester.pumpAndSettle();
    expect(find.text('Неправильний email або пароль.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('реєстрація показує помилку контролера', (tester) async {
    await show(tester, const RegisterScreen());
    await tester.enterText(find.byType(TextFormField).last, 'Secure123');
    await tester.tap(find.text('Створити акаунт').first);
    await tester.pumpAndSettle();
    expect(find.text('Цей email уже зареєстровано.'), findsOneWidget);
  });

  testWidgets('відновлення пароля показує помилку через select', (
    tester,
  ) async {
    await show(tester, const ForgotPasswordScreen());
    await tester.tap(find.text('Скинути пароль'));
    await tester.pumpAndSettle();
    expect(find.text('Немає з’єднання з інтернетом.'), findsOneWidget);
  });
}
