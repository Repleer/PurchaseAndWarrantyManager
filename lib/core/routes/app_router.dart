import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/forgot_password_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/google_account_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/login_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/presentation/register_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/home/presentation/home_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claim_details_args.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claim_details_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claims_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claim_purchase_picker_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/presentation/claim_form_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/domain/claim.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/presentation/profile_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/presentation/purchases_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/presentation/purchase_details_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/presentation/purchase_form_screen.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/domain/purchase.dart';

/// Генерує маршрути за іменем. Для десктопного вікна переходи без анімації.
abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (settings.name == AppRoutes.claimCreate ||
        settings.name == AppRoutes.claimEdit) {
      final Widget screen = switch (settings.name) {
        AppRoutes.claimCreate when settings.arguments is String =>
          ClaimFormScreen(purchaseId: settings.arguments as String),
        AppRoutes.claimEdit when settings.arguments is Claim => ClaimFormScreen(
          initial: settings.arguments as Claim,
        ),
        _ => const ClaimsScreen(),
      };
      return PageRouteBuilder<Claim?>(
        settings: settings,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => screen,
      );
    }
    if (settings.name == AppRoutes.purchaseCreate ||
        settings.name == AppRoutes.purchaseEdit) {
      final Widget screen = switch (settings.name) {
        AppRoutes.purchaseCreate when settings.arguments == null =>
          const PurchaseFormScreen(),
        AppRoutes.purchaseEdit when settings.arguments is Purchase =>
          PurchaseFormScreen(initial: settings.arguments as Purchase),
        _ => const PurchasesScreen(),
      };
      return PageRouteBuilder<Purchase?>(
        settings: settings,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => screen,
      );
    }
    final WidgetBuilder builder = switch (settings.name) {
      AppRoutes.register => (_) => const RegisterScreen(),
      AppRoutes.forgotPassword => (_) => const ForgotPasswordScreen(),
      AppRoutes.googleAccount => (_) => const GoogleAccountScreen(),
      AppRoutes.home => (_) => const HomeScreen(),
      AppRoutes.purchases => (_) => const PurchasesScreen(),
      AppRoutes.purchaseDetails =>
        (_) => settings.arguments is String
            ? PurchaseDetailsScreen(purchaseId: settings.arguments as String)
            : const PurchasesScreen(),
      AppRoutes.claims => (_) => const ClaimsScreen(),
      AppRoutes.claimPickPurchase => (_) => const ClaimPurchasePickerScreen(),
      AppRoutes.claimDetails => (_) => switch (settings.arguments) {
        ClaimDetailsArgs args => ClaimDetailsScreen(args: args),
        String id => ClaimDetailsScreen(args: ClaimDetailsArgs(claimId: id)),
        _ => const ClaimsScreen(),
      },
      AppRoutes.profile => (_) => const ProfileScreen(),
      _ => (_) => const LoginScreen(),
    };

    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    );
  }
}
