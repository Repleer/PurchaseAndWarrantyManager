import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/forgot_password_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/google_account_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/login_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/register_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/home/presentation/home_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/placeholder/presentation/placeholder_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/presentation/profile_screen.dart';


/// Генерує маршрути за іменем. Для десктопного вікна переходи без анімації.
abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final WidgetBuilder builder = switch (settings.name) {
      AppRoutes.register => (_) => const RegisterScreen(),
      AppRoutes.forgotPassword => (_) => const ForgotPasswordScreen(),
      AppRoutes.googleAccount => (_) => const GoogleAccountScreen(),
      AppRoutes.home => (_) => const HomeScreen(),
      AppRoutes.purchases => (_) => const PlaceholderScreen(
            title: 'Покупки та гарантії',
            selectedIndex: 1,
          ),
      AppRoutes.claims => (_) => const PlaceholderScreen(
            title: 'Мої звернення',
            selectedIndex: 2,
          ),
      AppRoutes.profile => (_) => const ProfileScreen(),
      _ => (_) => const LoginScreen(),
    };

    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    );
  }
}
