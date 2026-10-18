import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

/// Каркас десктопного вікна: бічне меню ліворуч і вміст праворуч.
class AppShell extends StatelessWidget {
  /// Каркас для екранів після входу (повне меню та кнопка «Вийти»).
  const AppShell.main({
    super.key,
    required this.selectedIndex,
    required this.child,
  })  : items = AppSidebar.mainItems,
        showLogout = true;

  /// Каркас для екранів авторизації (лише розділ «Авторизація»).
  const AppShell.auth({super.key, required this.child})
      : items = AppSidebar.authItems,
        selectedIndex = 0,
        showLogout = false;

  final List<SidebarItem> items;
  final int selectedIndex;
  final bool showLogout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSidebar(
            items: items,
            selectedIndex: selectedIndex,
            showLogout: showLogout,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
