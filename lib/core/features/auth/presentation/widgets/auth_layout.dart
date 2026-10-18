import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

/// Спільний макет екранів авторизації: бічне меню + велика біла картка з формою.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppShell.auth(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 36, 40, 40),
        child: SizedBox.expand(
          child: AppCard(
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }
}
