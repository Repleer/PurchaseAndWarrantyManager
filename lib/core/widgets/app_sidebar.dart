import 'package:flutter/material.dart';
import 'package:warranty_manager/core/routes/app_routes.dart';
import 'package:warranty_manager/core/theme/app_colors.dart';

/// Пункт бічного меню.
class SidebarItem {
  const SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

/// Бічна навігація шириною 260: назва застосунку, розділи та кнопка «Вийти».
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.showLogout,
  });

  /// Меню після входу: «Головна», «Покупки та гарантії», «Мої звернення», «Профіль».
  static const List<SidebarItem> mainItems = [
    SidebarItem(
      label: 'Головна',
      icon: Icons.dashboard_outlined,
      route: AppRoutes.home,
    ),
    SidebarItem(
      label: 'Покупки та гарантії',
      icon: Icons.receipt_long_outlined,
      route: AppRoutes.purchases,
    ),
    SidebarItem(
      label: 'Мої звернення',
      icon: Icons.find_in_page_outlined,
      route: AppRoutes.claims,
    ),
    SidebarItem(
      label: 'Профіль користувача',
      icon: Icons.account_circle_outlined,
      route: AppRoutes.profile,
    ),
  ];

  /// До входу доступний лише розділ «Авторизація».
  static const List<SidebarItem> authItems = [
    SidebarItem(
      label: 'Авторизація',
      icon: Icons.login,
      route: AppRoutes.login,
    ),
  ];

  final List<SidebarItem> items;
  final int selectedIndex;
  final bool showLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Brand(),
          const SizedBox(height: 24),
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _SidebarTile(item: items[i], selected: i == selectedIndex),
            ),
          const Spacer(),
          if (showLogout)
            _SidebarTile(
              item: const SidebarItem(
                label: 'Вийти',
                icon: Icons.logout,
                route: AppRoutes.login,
              ),
              selected: false,
              // Вихід: закриваємо сеанс і повертаємось до екрана авторизації.
              onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              ),
            ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Менеджер гарантій і покупок',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    this.onTap,
  });

  final SidebarItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primary : AppColors.textSecondary;

    return Material(
      color: selected ? AppColors.primaryLight : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ??
            () {
              final String? current = ModalRoute.of(context)?.settings.name;
              if (current != item.route) {
                Navigator.of(context).pushReplacementNamed(item.route);
              }
            },
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(item.icon, size: 19, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
